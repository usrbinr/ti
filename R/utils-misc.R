#' Validate an input is YYYY-MM-DD format
#'
#' @param x date column
#'
#' @return logical
#' @keywords internal
is_yyyy_mm_dd <- function(x) {

out <-   suppressWarnings(!is.na(lubridate::ymd(x)))

return(out)


}



#' Generate CLI actions
#'
#' @param x input to test against
#' @param word the key word to validate
#'
#' @returns list
#' @keywords internal
generate_cli_action <- function(x,word){


  # x <- "test"
  # word <- "test"
  out <- list()

  if(any(x %in% stringr::str_to_lower(word))){

    out[[word]] <- c(cli::col_green(cli::symbol$tick),stringr::str_to_title(word))

  }else{

    out[[word]] <- c(cli::col_red(cli::symbol$cross),stringr::str_to_title(word))
  }

  return(out)
}



#' Make Action field CLI args
#'
#' @param x action class
#'
#' @returns list
#' @keywords internal
make_action_cli <- function(x){

  out <- list()

  # if(any(x %in% c("aggregate"))){
  #
  #   out$aggregate <- paste0(cli::col_green(cli::symbol$tick)," Aggregate")
  #
  # }else{
  #
  #   out$aggregate <- c(cli::col_red(cli::symbol$cross),"Aggregate")
  # }

  out[1] <- generate_cli_action(x,"aggregate")

  out[2] <- generate_cli_action(x,"shift")

  out[3] <- generate_cli_action(x,"compare")

  out[4] <- generate_cli_action(x,"proportion of total")

  out[5] <- generate_cli_action(x,"count distinct")

  return(out)

}



#' Prints function header info
#'
#' @param x ti or segment obj
#'
#' @returns print
#' @keywords internal
print_fn_info <- function(x) {

  cli::cli_h1(x@fn@fn_long_name)
  cli::cli_text("Function: {.code {x@fn@fn_name}} was executed")
  cli::cli_h2("Description:")
  cli::cli_par()
  cli::cli_text(x@action@method)
}

#' Prints functions next steps
#'
#' @returns print
#' @keywords internal
print_next_steps <- function(){

  cli::cli_h2("Next Steps:")

  cli::cli_li("Use {.code calculate()} to return the results")

  cli::cli_rule()
}


#' Print action steps
#'
#' @param x an S7 class
#'
#' @returns cli messages
#' @keywords internal
print_actions_steps <- function(x){

  cli::cli_h2("Actions:")


  if(any(stringr::str_detect(x@action@value[[1]],"32m"))){


    cli::cli_text(x@action@value[[1]]," ",cli::col_blue(x@value@value_vec))

  }else{

    cli::cli_text(x@action@value[[1]])

  }

  #shift

  cli::cli_text(x@action@value[[2]]," ",cli::col_green(stats::na.omit(x@fn@lag_n))," ",cli::col_green(stats::na.omit(x@fn@shift)))

  #compare

  cli::cli_text(x@action@value[[3]]," ",cli::col_br_magenta(stats::na.omit(x@fn@compare)))


  ## prop of total

  if(any(stringr::str_detect(x@action@value[[4]],"32m"))){


    cli::cli_text(x@action@value[[4]])

  }else{

    cli::cli_text(x@action@value[[4]])

  }

  ## distinct count


  if(any(stringr::str_detect(x@action@value[[5]],"32m"))){


    cli::cli_text(x@action@value[[5]]," ",cli::col_blue(x@value@value_vec))

  }else{

    cli::cli_text(x@action@value[[5]])

  }


}




#' @title Add Comprehensive Date-Based Attributes to a Data Frame
#'
#' @description
#' This function takes a data frame and a date column and generates a wide set of
#' derived date attributes. These include start/end dates for year, quarter,
#' month, and week; day-of-week indicators; completed and remaining days in each
#' time unit; and additional convenience variables such as weekend indicators.
#'
#' It is designed for time-based feature engineering and is useful in reporting,
#' forecasting, time-series modeling, and data enrichment workflows.
#'
#' @param .data A data frame or tibble containing at least one date column.
#' @param .date A column containing `Date` values, passed using tidy-eval
#'   (e.g., `{{ date_col }}`).
#'
#' @details
#' The function creates the following groups of attributes:
#'
#' **1. Start and end dates**
#'   - `year_start_date`, `year_end_date`
#'   - `quarter_start_date`, `quarter_end_date`
#'   - `month_start_date`, `month_end_date`
#'   - `week_start_date`, `week_end_date`
#'
#' **2. Day-of-week fields**
#'   - `day_of_week` – numeric day of the week (1–7)
#'   - `day_of_week_label` – ordered factor label (e.g., Mon, Tue, …)
#'
#' **3. Duration fields**
#'   - `days_in_year` – total days in the year interval
#'   - `days_in_quarter` – total days in the quarter interval
#'   - `days_in_month` – total days in the month
#'
#' **4. Completed/remaining days**
#'   - `days_complete_in_week`, `days_remaining_in_week`
#'   - `days_complete_in_month`, `days_remaining_in_month`
#'   - `days_complete_in_quarter`, `days_remaining_in_quarter`
#'   - `days_complete_in_year`, `days_remaining_in_year`
#'
#' **5. Miscellaneous**
#'   - `weekend_indicator` – equals 1 if Saturday or Sunday; otherwise 0
#'
#' All date-derived fields ending in `_date` are coerced to class `Date`.
#'
#' @return A tibble containing the original data along with all generated
#'   date-based attributes.
#' @keywords internal

augment_standard_calendar_tbl <- function(.data,.date){

  # create attibutes
  out <- .data |>
    dplyr::mutate(
      year_start_date=lubridate::floor_date({{.date}},unit = "year")
      ,year_end_date=lubridate::ceiling_date({{.date}},unit = "year")-1
      ,quarter_start_date=lubridate::floor_date({{.date}},unit = "quarter")
      ,quarter_end_date=lubridate::ceiling_date({{.date}},unit = "quarter")-1
      ,month_start_date=lubridate::floor_date({{.date}},unit = "month")
      ,month_end_date=lubridate::ceiling_date({{.date}},unit = "month")-1
      ,week_start_date=lubridate::floor_date({{.date}},unit = "week")
      ,week_end_date=lubridate::ceiling_date({{.date}},unit = "week")-1
      ,day_of_week=lubridate::wday({{.date}},label = FALSE)
      ,day_of_week_label=lubridate::wday({{.date}},label = TRUE)
      ,day_of_year=lubridate::day({{.date}})
      ,month_of_year_label_abb=lubridate::month({{.date}},label = TRUE,abbr = TRUE)
      ,month_of_year_label_full_name=lubridate::month({{.date}},label=TRUE,abbr = FALSE)
      ,month_of_year=lubridate::month({{.date}},label=FALSE)
      ,days_in_year=year_end_date-year_start_date
      ,days_in_quarter=quarter_end_date-quarter_start_date
      ,days_in_month=lubridate::days_in_month({{.date}})
      ,days_complete_in_week={{.date}}-week_start_date
      ,days_remaining_in_week=week_end_date-{{.date}}
      ,days_remaining_in_quarter=quarter_end_date-{{.date}}
      ,days_remaining_in_month=month_end_date-{{.date}}
      ,days_remaining_in_year=year_end_date-{{.date}}
      ,days_complete_in_year={{.date}}-year_start_date
      ,days_complete_in_quarter={{.date}}-quarter_start_date
      ,days_complete_in_month={{.date}}-month_start_date
      ,days_complete_in_year={{.date}}-year_start_date

      ,weekend_indicator=dplyr::if_else(day_of_week_label %in% c("Saturday","Sunday"),1,0)
    ) |>
    dplyr::mutate(
      dplyr::across(dplyr::contains("date"),\(x) as.Date(x))
    )

  return(out)

}



#' @title Add Comprehensive Date-Based Attributes to a DBI lazy frame
#'
#' @description
#' This function takes a data frame and a date column and generates a wide set of
#' derived date attributes. These include start/end dates for year, quarter,
#' month, and week; day-of-week indicators; completed and remaining days in each
#' time unit; and additional convenience variables such as weekend indicators.
#'
#' It is designed for time-based feature engineering and is useful in reporting,
#' forecasting, time-series modeling, and data enrichment workflows.
#'
#' @param .data A data frame or tibble containing at least one date column.
#' @param .date A column containing `Date` values, passed using tidy-eval
#'   (e.g., `{{ date_col }}`).
#'
#' @details
#' The function creates the following groups of attributes:
#'
#' **1. Start and end dates**
#'   - `year_start_date`, `year_end_date`
#'   - `quarter_start_date`, `quarter_end_date`
#'   - `month_start_date`, `month_end_date`
#'   - `week_start_date`, `week_end_date`
#'
#' **2. Day-of-week fields**
#'   - `day_of_week` – numeric day of the week (1–7)
#'   - `day_of_week_label` – ordered factor label (e.g., Mon, Tue, …)
#'
#' **3. Duration fields**
#'   - `days_in_year` – total days in the year interval
#'   - `days_in_quarter` – total days in the quarter interval
#'   - `days_in_month` – total days in the month
#'
#' **4. Completed/remaining days**
#'   - `days_complete_in_week`, `days_remaining_in_week`
#'   - `days_complete_in_month`, `days_remaining_in_month`
#'   - `days_complete_in_quarter`, `days_remaining_in_quarter`
#'   - `days_complete_in_year`, `days_remaining_in_year`
#'
#' **5. Miscellaneous**
#'   - `weekend_indicator` – equals 1 if Saturday or Sunday; otherwise 0
#'
#' All date-derived fields ending in `_date` are coerced to class `Date`.
#'
#' @return A dbi containing the original data along with all generated
#'   date-based attributes.
#' @keywords internal
augment_standard_calendar_dbi <- function(.data,.date){


  date_vec <- rlang::as_label(.date)

out <-
  .data |>
  dplyr::mutate(
    year_start_date=lubridate::floor_date({{.date}},unit = "year")
    ,year_end_date=dplyr::sql(glue::glue("date_trunc('year', {date_vec}) + INTERVAL '1' YEAR"))
    ,quarter_start_date=lubridate::floor_date({{.date}},unit = "quarter")
    ,quarter_end_date=dplyr::sql(glue::glue("date_trunc('quarter', {date_vec}) + INTERVAL '1' quarter"))
    ,month_start_date=lubridate::floor_date({{.date}},unit = "month")
    ,month_end_date=dplyr::sql(glue::glue("date_trunc('month', {date_vec}) + INTERVAL '1' month"))
    ,week_start_date=lubridate::floor_date({{.date}},unit = "week")
    ,week_end_date=dplyr::sql(glue::glue("date_trunc('month', {date_vec}) + INTERVAL '1' month"))
    ,day_of_week=lubridate::wday({{.date}},label = FALSE)
    ,day_of_week_label=lubridate::wday({{.date}},label = TRUE)
    ,day_of_year=lubridate::day({{.date}})
    ,month_of_year_label_abb=lubridate::month({{.date}},label = TRUE,abbr = TRUE)
    ,month_of_year_label_full_name=lubridate::month({{.date}},label=TRUE,abbr = FALSE)
    ,month_of_year=lubridate::month({{.date}},label=FALSE)
    ,days_in_year=year_end_date-year_start_date
    ,days_in_quarter=quarter_end_date-quarter_start_date
    ,days_in_month=dplyr::sql(glue::glue("last_day({date_vec})"))
    ,days_complete_in_week={{.date}}-week_start_date
    ,days_remaining_in_week=week_end_date-{{.date}}
    ,days_remaining_in_quarter=quarter_end_date-{{.date}}
    ,days_remaining_in_month=month_end_date-{{.date}}
    ,days_remaining_in_year=year_end_date-{{.date}}
    ,days_complete_in_year={{.date}}-year_start_date
    ,days_complete_in_quarter={{.date}}-quarter_start_date
    ,days_complete_in_month={{.date}}-month_start_date
    ,days_complete_in_year={{.date}}-year_start_date
    ,weekend_indicator=dplyr::if_else(day_of_week_label %in% c("Saturday","Sunday"),1,0)
  ) |>
 dplyr::mutate(
    dplyr::across(dplyr::contains("date"),\(x) as.Date(x))
  )

return(out)

}





#' @title Add Comprehensive Date-Based Attributes to a DBI  lazy frame or tibble object
#' @name augment_standard_calendar
#' @description
#' This function takes a data frame and a date column and generates a wide set of
#' derived date attributes. These include start/end dates for year, quarter,
#' month, and week; day-of-week indicators; completed and remaining days in each
#' time unit; and additional convenience variables such as weekend indicators.
#'
#' It is designed for time-based feature engineering and is useful in reporting,
#' forecasting, time-series modeling, and data enrichment workflows.
#'
#' @param .data A data frame or tibble containing at least one date column.
#' @param .date A column containing `Date` values, passed using tidy-eval
#'   (e.g., `{{ date_col }}`).
#'
#' @details
#' The function creates the following groups of attributes:
#'
#' **1. Start and end dates**
#'   - `year_start_date`, `year_end_date`
#'   - `quarter_start_date`, `quarter_end_date`
#'   - `month_start_date`, `month_end_date`
#'   - `week_start_date`, `week_end_date`
#'
#' **2. Day-of-week fields**
#'   - `day_of_week` – numeric day of the week (1–7)
#'   - `day_of_week_label` – ordered factor label (e.g., Mon, Tue, …)
#'
#' **3. Duration fields**
#'   - `days_in_year` – total days in the year interval
#'   - `days_in_quarter` – total days in the quarter interval
#'   - `days_in_month` – total days in the month
#'
#' **4. Completed/remaining days**
#'   - `days_complete_in_week`, `days_remaining_in_week`
#'   - `days_complete_in_month`, `days_remaining_in_month`
#'   - `days_complete_in_quarter`, `days_remaining_in_quarter`
#'   - `days_complete_in_year`, `days_remaining_in_year`
#'
#' **5. Miscellaneous**
#'   - `weekend_indicator` – equals 1 if Saturday or Sunday; otherwise 0
#'
#' All date-derived fields ending in `_date` are coerced to class `Date`.
#' @export
#' @return A dbi or  tibble containing the original data along with all generated
#'   date-based attributes.
#'
augment_standard_calendar <- function(.data,.date){

  data_class <- class(.data)

  .date_var <- rlang::enquo(.date)

  assertthat::assert_that(
    any(data_class %in% c("tbl","tbl_lazy"))
    ,msg = ".data must be regular tibble or DBI lazy object"
    )

  if(any(data_class %in% "tbl_lazy")){

    out <- augment_standard_calendar_dbi(.data = .data,.date = .date_var)

    return(out)


  }


  if(any(data_class %in% "tbl")){

    out <- augment_standard_calendar_tbl(.data = .data,.date = !!.date_var)

    return(out)
  }



}


#' Title
#'
#' @param .data DBI object
#' @param x ti object
#' @keywords internal
#' @returns DBI object
#'
complete_standard_calendar <- function(.data,x){


  if(any(x@fn@new_date_column_name %in% "year")){

    .data <- .data |>
      dplyr::mutate(
        year=lubridate::year(date)
      )

  }
  if(any(x@fn@new_date_column_name %in% "quarter")){

    .data <- .data |>
      dplyr::mutate(
        quarter=lubridate::quarter(date)
      )

  }

  if(any(x@fn@new_date_column_name %in% "month")){

    .data <- .data |>
      dplyr::mutate(
        month=lubridate::month(date)
      )

  }



  if(any(x@fn@new_date_column_name %in% "week")){

    .data <- .data |>
      dplyr::mutate(
        week=dplyr::sql("DATE_PART('week',date)")
      )

  }


  if(any(x@fn@new_date_column_name %in% "day")){

    .data <- .data |>
      dplyr::mutate(
        day=lubridate::day(date)
      )

  }

  return(.data)

}


#' Title
#'
#' @param x ti object
#' @keywords internal
#'
#' @returns DBI object
#'
create_full_dbi <- function(x){

    full_dbi <-
      create_calendar(x) |>
      complete_standard_calendar(x=x)



  return(full_dbi)

}

#' Make an in memory database from a table
#'
#' @param x tibble or dbi object
#' @export
#' @returns dbi object
#' @keywords internal
#' Coerce data into a DuckDB-backed lazy table
#'
#' @description
#' Ensures the input is a database-backed object. If a data.frame is provided,
#' it is registered into a temporary, in-memory DuckDB instance. If already
#' a `tbl_dbi`, it is returned unchanged.
#'
#' @param x A tibble, data.frame, or tbl_dbi object.
#' @return A \code{tbl_dbi} object backed by DuckDB.
#'
#' @details
#' When converting a data.frame, this function preserves existing \code{dplyr}
#' groups. It uses DuckDB's \code{duckdb_register}, which is a virtual registration
#' and does not perform a physical copy of the data, making it extremely fast.
#'
#' @export
#' @keywords internal
make_db_tbl <- function(x) {

  # 1. Type Validation
  assertthat::assert_that(
    inherits(x, "data.frame") || inherits(x, "tbl_dbi"),
    msg = "Input must be a data.frame, tibble, or tbl_dbi object."
  )

  # 2. Return early if already in a DB
  if (inherits(x, "tbl_dbi")) {
    return(x)
  }

  # 3. Convert data.frame to DuckDB
  # Extract group metadata
  groups_lst <- dplyr::groups(x)

  # Use a global or session-persistent connection to avoid overhead
  # DuckDB ':memory:' is faster than tempfile() for small/medium sets
  con <- DBI::dbConnect(duckdb::duckdb(), ":memory:")

  # Register the data.frame as a virtual table
  # This is O(1) complexity because it references R memory directly
  duckdb::duckdb_register(con, name = "virtual_table", df = x)


  # Create the lazy table and re-apply groups
  out <- dplyr::tbl(con, "virtual_table") |>
    dplyr::group_by(!!!groups_lst)

  return(out)
}


#' Generate a Cross-Dialect SQL Date Series
#'
#' @description
#' Creates a lazy `dbplyr` table containing a continuous sequence of dates.
#' The function automatically detects the SQL dialect of the connection and
#' dispatches the most efficient native series generator (e.g., `GENERATE_SERIES`
#' for DuckDB/Postgres or `GENERATOR` for Snowflake).
#'
#' @details
#' This function is designed to be "nestable," meaning the resulting SQL can be
#' used safely inside larger `dplyr` pipelines. It avoids `WITH` clauses in
#' dialects like DuckDB to prevent parser errors when `dbplyr` wraps the query
#' in a subquery (e.g., `SELECT * FROM (...) AS q01`).
#'
#' For unit testing, the function supports `dbplyr` simulation objects. If a
#' `TestConnection` is detected, it returns a `lazy_frame` to avoid metadata
#' field queries that would otherwise fail on a mock connection.
#' @param week_start description
#' @param start_date A character string in 'YYYY-MM-DD' format or a Date object
#' representing the start of the series.
#' @param end_date A character string in 'YYYY-MM-DD' format or a Date object
#' representing the end of the series.
#' @param time_unit A character string specifying the interval. Must be one of:
#' \code{"day"}, \code{"week"}, \code{"month"}, \code{"quarter"}, or \code{"year"}.
#' @param .con A valid DBI connection object (e.g., DuckDB, Postgres, Snowflake)
#' or a \code{dbplyr} simulated connection.
#'
#' @return A \code{tbl_lazy} (SQL) object with a single column \code{date}.
#'
#' @examples
#' \dontrun{
#' con <- DBI::dbConnect(duckdb::duckdb())
#' # Generates a daily sequence for the year 2025
#' calendar <- seq_date_sql("2025-01-01", "2025-12-31", "day", con)
#' }
#'
#' @keywords internal
seq_date_sql <- function(
    .con
    ,start_date
    ,end_date
    ,calendar_type = "standard"
    ,time_unit="day"
    ,week_start = 7) {



  # assertthat::assert_that(assertthat::is.string(start_date), msg = "start_date must be a string (YYYY-MM-DD)")

  assertthat::assert_that(any(time_unit %in% c("day", "month","quarter", "week","year")),msg = "time_unit must be one of: 'day', 'week','quarter, 'month' or 'year'")

  # assertthat::assert_that(assertthat::is.string(end_date), msg = "end_date must be a string (YYYY-MM-DD)")

  assertthat::assert_that(any(calendar_type %in% c("standard")),msg = "calendar_type must be: 'standard'")

  assertthat::assert_that(assertthat::is.number(week_start) && week_start %in% 1:7,msg = "week_start must be an integer between 1 (Monday) and 7 (Sunday)")


  if(calendar_type=='standard'){

    date_seq_sql <- glue::glue_sql("
  WITH DATE_SERIES AS (
  SELECT

  GENERATE_SERIES(
     MIN(DATE_TRUNC('day', DATE {start_date}::date))::DATE
    ,MAX(DATE_TRUNC('day', DATE {end_date}::date))::DATE
    ,INTERVAL '1 day'
  ) AS DATE_LIST),

  CALENDAR_TBL AS (
        SELECT

        UNNEST(DATE_LIST)::DATE AS date

        FROM DATE_SERIES

        )
  SELECT *
  ,EXTRACT(YEAR FROM date) AS year
  ,EXTRACT(QUARTER FROM date) AS quarter
  ,EXTRACT(month FROM date) AS month
  ,FLOOR((EXTRACT(DOY FROM date) - 1) / 7) + 1 AS week

  FROM CALENDAR_TBL

",.con=.con)
  }



  calendar_dbi <-  dplyr::tbl(.con,dplyr::sql(date_seq_sql))


  time_unit_lst <- list(
    year="year"
    ,quarter=c("year","quarter")
    ,month=c("year","quarter","month")
    ,week=c("year","quarter","month","week")
    ,day=c("year","quarter","month","week","day")
  )

  group_col_vec <- c("date",time_unit_lst[[time_unit]])


  out <-
    calendar_dbi |>
    dplyr::mutate(
      day=lubridate::day(date)
    ) |>
    dplyr::mutate(
      date=lubridate::floor_date(date,unit = time_unit)
    ) |>
    dplyr::summarise(
      .by=dplyr::any_of(group_col_vec)
      ,n=dplyr::n()
    ) |>
    dplyr::select(-c(n))

  return(out)

}


utils::globalVariables(
  c(
    "desc",
    "var",
    "cum_sum",
    "prop_total",
    "row_id",
    "max_row_id",
    "dim_category",
    "cum_prop_total",
    "cum_unit_prop",
    "dim_threshold",
    ":=",
    "out_tbl",
    "dir_path",
    "map_chr",
    "as_label",
    "n",
    "prop_n",
    "lead",
    "pull",
    "relocate",
    "select",
    "order_date",
    "quantity",
    "fn_name_lower",
    "test",
    ".cluster",
    "centers_input",
    "kmeans_models",
    "kmeans_results",
    "tot.withinss",
    "sql",
    "quarter",
    "quater",
    "date_lag",
    "month",
    "week",
    "year",
    "year_start_date",
    "year_end_date",
    "quarter_start_date",
    "quarter_end_date",
    "month_start_date",
    "month_end_date",
    "week_start_date",
    "week_end_date",
    "day_of_week_label",
    "days_in_month",
    "year_index",
    "week_index",
    "day"
  )
)

