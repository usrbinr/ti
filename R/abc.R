#' @title ABC classification function
#' @name abc
#'
#' @param .data tibble or dbi object (either grouped or ungrouped)
#' @param category_values vector of break points between 0 and 1
#' @param .value optional: if left blank,[abc()] will use the number of rows per group to categorize, alternatively you can pass a column name to categorize
#'
#' @description
#' -  For your group variable, [abc()]  will categorize which groups make up what proportion of the totals according to the category_values that you have entered
#' -  The function returns a segment object which prints out the execution steps and actions that it will take to categorize your data
#' -  Use [calculate] to return the results
#' @details
#' -  This function is helpful to understand which groups of make up what proportion of the cumulative contribution
#' -  If you do not provide a `.value` then it will count the transactions per group, if you provide `.value` then it will [sum()] the `.value` per group
#' -  The function creates a `segment` object, which pre-processes the data into its components
#'
#' @returns abc object
#' @export
#'
#' @examples
#' \donttest{
#' contoso::sales |>
#'   dplyr::group_by(product_key) |>
#'   abc(c(.1,.5,.7,.96,1), .value = gross_margin)
#' }
#'
abc <- function(.data,category_values,.value){

  if(!missing(.value)){
    value_vec <- deparse(substitute(.value))

    # Validate value column exists
    col_names <- colnames(.data)
    if (!value_vec %in% col_names) {
      cli::cli_abort(c(
        "Column {.field {value_vec}} not found in data.",
        "i" = "Available columns: {.field {col_names}}"
      ))
    }

    # Validate value column is numeric (for local data frames only)
    if (inherits(.data, "data.frame") && !inherits(.data, "tbl_lazy")) {
      value_col <- .data[[value_vec]]
      if (!is.numeric(value_col)) {
        cli::cli_abort(c(
          "Column {.field {value_vec}} must be numeric.",
          "x" = "Column {.field {value_vec}} has type {.cls {class(value_col)}}.",
          "i" = "Convert with {.code as.numeric()}."
        ))
      }
    }
  }else{
    value_vec="n"
  }


  x <-   segment_abc(
    datum                      = datum(.data,date_vec = NA,calendar_type = NA_character_)
    ,value                    = value(value_vec = value_vec,new_column_name_vec = "abc")
    ,category                 = category(category_values=category_values)
    ,fn = fn(
      fn_exec                 = abc_fn
      ,fn_name                = "ABC"
      ,fn_long_name           = "ABC Classification"
      ,lag_n                  = NA_integer_
      ,new_date_column_name   = NA_character_
      )
    ,time_unit                =time_unit(value="day")
    ,action=action(
      value = c("proportion of total","Aggregate")
      ,method= "This calculates a rolling cumulative distribution of variable
      and segments each group member's contribution by the break points provided.
      Helpful to know which group member's proportional contribution to the total.
      ")
    )

  if (!x@datum@group_indicator) {
    cli::cli_abort("{.fn abc} expects a grouped tibble or dbi object. Please use {.fn group_by} to pass a grouped object.")
  }


return(x)

}


#' Classify a group by proportion of a variable (A,B,C,...)
#'
#' @param x segment object
#'
#' @description
#' This returns a table that will segment your data into A,B or C segments based on custom
#' thresholds
#'
#' @return a dbi objection
#' @keywords internal
abc_fn <- function(x){

  # 1. AGGREGATE DATA
  # We handle both count-based (n) and sum-based (.value) categorization
  if (x@value@value_vec != "n") {
    summary_dbi <- x@datum@data |>
      dplyr::summarize(
        !!x@value@new_column_name_vec := sum(!!x@value@value_quo, na.rm = TRUE),
        .groups = "drop"
      )
  } else {
    summary_dbi <- x@datum@data |>
      dplyr::summarize(
        !!x@value@new_column_name_vec := dplyr::n(),
        .groups = "drop"
      )
  }

  # 2. CALCULATE CUMULATIVE STATS
  # Using window functions to prepare the 'cum_unit_prop' for bucket matching
  stats_dbi <- summary_dbi |>
    dbplyr::window_order(desc(!!x@value@new_column_name_quo)) |>
    dplyr::mutate(
      cum_sum       = cumsum(!!x@value@new_column_name_quo),
      prop_total    = !!x@value@new_column_name_quo / max(cum_sum, na.rm = TRUE),
      cum_prop_total = cumsum(prop_total),
      row_id        = dplyr::row_number(),
      max_row_id    = max(row_id, na.rm = TRUE),
      cum_unit_prop = row_id / max_row_id # This determines the ABC bucket
    )

  # 3. PREPARE THE LOOKUP TABLE (The Optimization)
  con <- dbplyr::remote_con(stats_dbi)

  # Ensure category names exist (default to A, B, C... if empty)
  cat_names <- if (is.null(x@category@category_names)) LETTERS[seq_along(x@category@category_values)] else x@category@category_names

  cat_lookup_df <- data.frame(
    category_value = x@category@category_values,
    category_name  = cat_names
  )

  # Copy the tiny threshold table to the database
  category_dbi <- dplyr::copy_to(
    dest = con,
    df = cat_lookup_df,
    name = paste0("tmp_abc_", format(Sys.time(), "%Y%m%d%H%M%S"), "_", sample(1e8, 1)),
    overwrite = TRUE,
    temporary = TRUE
  )

  # 4. PERFORM THE OPTIMIZED JOIN
  # Instead of an inequality join which is essentially a filtered Cartesian product:
  #
  out <- stats_dbi |>
    dplyr::cross_join(category_dbi) |>
    # Find all thresholds that are greater than or equal to our current position
    dplyr::filter(cum_unit_prop <= category_value) |>
    # Use a window function to pick the 'closest' (smallest) threshold
    dplyr::mutate(
      dist_rank = rank(category_value),
      .by = row_id
    ) |>
    dplyr::filter(dist_rank == 1) |>
    # Cleanup intermediate columns
    dplyr::select(
      -dist_rank,
      -category_value,
      -max_row_id,
      -cum_unit_prop
    )

  return(out)


}


#' @title Cohort Analysis
#' @name cohort
#' @param .data tibble or dbi object
#' @param .date date column
#' @param .value id column
#' @param period_label do you want period labels or the dates c(TRUE , FALSE)
#' @param time_unit do you want summarize the date column to 'day', 'week', 'month','quarter' or 'year'
#'
#' @description
#' Database-friendly cohort analysis function.
#' A remake of \url{https://github.com/PeerChristensen/cohorts}, combining
#' `cohort_table_month`, `cohort_table_year`, and `cohort_table_day` into a single package.
#' Rewritten for database compatibility and tested with Snowflake and DuckDB.
#'
#' @details
#' - Groups your `.value` column by shared time attributes from the `.date` column.
#' - Assigns each member to a cohort based on their first entry in `.date`.
#' - Aggregates the cohort by the `time_unit` argument (`day`, `week`, `month`, `quarter`, or `year`).
#' - Computes the distinct count of each cohort member over time.
#' @return segment object
#' @export
#'
cohort <- function(.data,.date,.value,time_unit="month",period_label=FALSE){

  x <-  segment_cohort(
    datum= datum(
      .data
      ,calendar_type = "standard"
      ,date_vec = rlang::as_label(rlang::enquo(.date))
    )
    ,fn = fn(
      fn_exec = cohort_fn
      ,fn_name = "cohort"
      ,fn_long_name = "Time Based Cohort"
      ,new_date_column_name = "cohort_date"
      ,shift = NA_character_
      ,compare = NA_character_
      ,lag_n = NA_integer_
      ,label=period_label
    )
    ,time_unit = time_unit(value=time_unit)
    ,value = value(
      value_vec = rlang::as_label(rlang::enquo(.value))
      ,new_column_name_vec = "cohort"
    )
    ,action = action(
      value="count distinct"
      ,method="
      This segments groups based on a shared time related dimension
      so you can track a cohort's trend over time
      "
      )
  )

  return(x)
}



#' Internal function for the cohort segment object
#'
#' @param x segment object
#'
#' @returns function
#' @keywords internal
cohort_fn <- function(x){

  ## summary table

  summary_dbi <-   x@datum@data  |>
    dplyr::mutate(date = lubridate::floor_date(!!x@datum@date_quo,unit=!!x@time_unit@value)) |>
    dplyr::group_by(!!x@value@value_quo) |>
    dplyr::mutate(cohort_date = min(date,na.rm=TRUE)) |>
    # dbplyr::window_order(date) |>
    dplyr::group_by(cohort_date, date) |>
    dplyr::summarise(
      !!x@value@new_column_name_vec:= dplyr::n_distinct(!!x@value@value_quo)
      ,.groups = "drop"
    ) |>
    dplyr::mutate(period_id=dplyr::sql("DENSE_RANK() OVER (ORDER BY date)"))


  if(!x@fn@label){

    out <- summary_dbi |>
      dplyr::select(-period_id) |>
      tidyr::pivot_wider(
        names_from=date
        ,values_from=!!x@value@new_column_name_quo
        ,values_fill=0
      ) |>
      dbplyr::window_order(cohort_date) |>
      dplyr::mutate(
        cohort_id = dplyr::row_number()
      ) |>
      dplyr::relocate(
        cohort_date
        ,cohort_id
        ,dplyr::any_of(
          as.character(
            as.Date(x@datum@min_date:x@datum@max_date)
          )
        )
      ) |>
      janitor::clean_names()

  }else{

    out <- summary_dbi |>
      dplyr::select(-date) |>
      tidyr::pivot_wider(
        names_from=period_id
        ,values_from=x@value@new_column_name_quo
        ,names_prefix = "p_"
        ,values_fill = 0
      ) |>
      dplyr::ungroup() |>
      dbplyr::window_order(cohort_date) |>
      dplyr::mutate(cohort_id = dplyr::row_number()) |>
      dplyr::relocate(
        cohort_date
        ,cohort_id
        ,dplyr::num_range(prefix="p_",1:dplyr::last_col())
      )

  }
  return(out)

}

utils::globalVariables(c("category", "delta", "row_id_rank", "cohort_date", "period_id", "cohort_id", "category_value", "dist_rank"))
