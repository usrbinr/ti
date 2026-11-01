NULL

# create generics -----------

#' Create Calendar Table
#' @param x ti object
#' @param ... Not used.
#'
#' @returns dbi object
#' @export
#' @description
#' [create_calendar()] summarizes a tibble to target time unit and completes the calendar to ensure
#' no missing days, month, quarter or years. If a grouped tibble is passed through it will complete the calendar
#' for each combination of the group
#' @details
#' This is in internal function to make it easier to ensure data has no missing dates to
#'  simplify the use of time intelligence functions downstream of the application.
#' If you want to summarize to a particular group, simply pass the tibble through to the [dplyr::group_by()] argument
#' prior to function and the function will make summarize and make a complete calendar for each group item.
#' @keywords internal
create_calendar <- S7::new_generic("create_calendar", "x")

#' @rdname create_calendar
S7::method(create_calendar, ti) <- function(x, ...) {
  # Follow along with a dummy example: run devtools::load_all(), then the line(s)
  # below, then the body one step at a time.
  # x <- contoso::sales |>
  #   dplyr::group_by(store_key) |>
  #   wow(.date = order_date, .value = net_revenue)

  #
  # Inspect any intermediate table with dplyr::collect(), e.g.
  # day_dbi |> dplyr::collect() or summary_dbi |> dplyr::collect()

  # Daily calendar with each day's period start; both the calendar rows and the
  # data are assigned to periods through it, so they always agree
  day_dbi <- calendar_day_sql(
    .con = dbplyr::remote_con(x@datum@data),
    start_date = x@datum@min_date,
    end_date = x@datum@max_date,
    calendar_type = x@datum@calendar_type,
    time_unit = x@time_unit@value,
    week_start = x@datum@week_start,
    fiscal_year_start = x@datum@fiscal_year_start
  )

  period_map <- day_dbi |>
    dplyr::select(.ti_day = date, .ti_period_date = period_date)

  summary_dbi <-
    x@datum@data |>
    dplyr::ungroup() |>
    make_db_tbl() |>
    dplyr::mutate(.ti_day = as.Date(!!x@datum@date_quo)) |>
    dplyr::inner_join(period_map, by = ".ti_day") |>
    dplyr::summarise(
      !!x@value@value_vec := sum(!!x@value@value_quo, na.rm = TRUE),
      .by = c(.ti_period_date, !!!x@datum@group_quo)
    ) |>
    dplyr::rename(date = .ti_period_date)

  active_bounds <-
    summary_dbi |>
    dplyr::summarise(
      min_g = min(date, na.rm = TRUE),
      max_g = max(date, na.rm = TRUE),
      .by = c(!!!x@datum@group_quo)
    )

  master_dates <-
    calendar_periods(
      day_dbi,
      start_date = x@datum@min_date,
      time_unit = x@time_unit@value
    )

  if (x@datum@group_indicator) {
    calendar_dbi <-
      master_dates |>
      dplyr::cross_join(
        active_bounds |> dplyr::distinct(!!!x@datum@group_quo)
      ) |>
      dplyr::inner_join(
        active_bounds,
        by = dplyr::join_by(!!!x@datum@group_quo)
      ) |>
      dplyr::filter(date >= min_g & date <= max_g) |>
      dplyr::select(-min_g, -max_g)
  } else {
    calendar_dbi <- master_dates
  }

  full_dbi <-
    calendar_dbi |>
    dplyr::full_join(
      summary_dbi,
      by = dplyr::join_by(date, !!!x@datum@group_quo)
    ) |>
    dplyr::mutate(
      missing_date_indicator = dplyr::if_else(is.na(!!x@value@value_quo), 1, 0),
      !!x@value@value_vec := dplyr::coalesce(!!x@value@value_quo, 0)
    )

  return(full_dbi)
}


#' @title Execute time-intelligence or segments class objects to return the underlying transformed table
#' @param x ti object
#' @param ... Not used.
#' @description
#' The `calculate()` function takes an object created by a time function (like `ytd()`, `mtd()`, or `qtd()`) or a segment function (like `cohort()` or `abc()`) and executes the underlying transformation logic.
#' It translates the function blueprint into an actionable query, returning the final data table.
#'
#' @details
#' The TI and segment functions in **ti**—such as `ytd()` or `cohort()` and others—are designed to be **lazy and database-friendly**.
#' They do not perform the heavy data transformation immediately.
#' Instead, they return a blueprint object (of class `ti`,`segment_abc` or `segment_cohort`) that contains all the parameters and logic needed for the calculation.
#'
#' **`calculate()`** serves as the **execution engine**.
#'
#' When called, it interprets the blueprint and generates optimized R code or SQL code (using the `dbplyr` package) that is then executed efficiently on the data source, whether it's an in-memory `tibble` or a 'DuckDB' table.
#' This approach minimizes data transfer and improves performance for large datasets.
#'
#' The resulting table will be sorted by the relevant date column to ensure the correct temporal ordering of the calculated metrics.
#'
#'
#' @returns dbi object
#' @export
#' @examples
#' \donttest{
#' x <- ytd(contoso::sales,.date=order_date,.value=quantity,calendar_type="standard")
#' calculate(x)
#' }
calculate <- S7::new_generic("calculate", "x")

#' @rdname calculate
S7::method(calculate, ti) <- function(x, ...) {
  # Follow along with a dummy example: run devtools::load_all(), then the line(s)
  # below, then the body one step at a time.
  # x <- ytd(contoso::sales, .date = order_date, .value = net_revenue)
  # x@fn@fn_exec    # the *_fn() that will run, here ytd_fn()

  out <- x@fn@fn_exec(x) |>
    dbplyr::window_order(date)

  return(out)
}


#' @rdname calculate
S7::method(calculate, segment_cohort) <- function(x, ...) {
  # Follow along with a dummy example: run devtools::load_all(), then the line(s)
  # below, then the body one step at a time.
  # x <- cohort(contoso::sales, .date = order_date, .value = customer_key)

  out <- x@fn@fn_exec(x)

  return(out)
}


#' @rdname calculate
S7::method(calculate, segment_abc) <- function(x, ...) {
  # Follow along with a dummy example: run devtools::load_all(), then the line(s)
  # below, then the body one step at a time.
  # x <- contoso::sales |>
  #   dplyr::group_by(store_key) |>
  #   abc(category_values = c(0.5, 0.8, 1), .value = net_revenue)

  out <- x@fn@fn_exec(x) |>
    dplyr::arrange(row_id)

  return(out)
}


#' @title Print ti objects
#' @name print
#' @param ... unused. Please ignore.
#' @param x ti object
#'
#' @returns ti object
#' @export
#' @keywords internal
#'
S7::method(print, ti) <- function(x, ...) {
  # Follow along with a dummy example: run devtools::load_all(), then the line(s)
  # below, then the body one step at a time.
  # x <- contoso::sales |>
  #   dplyr::group_by(store_key) |>
  #   pmtd(.date = order_date, .value = net_revenue)

  print_fn_info(x)

  print_calendar_info(x)

  print_assumptions(x)

  print_actions_steps(x)

  cli::cat_line("")

  print_next_steps()
}


#' Print segment objects
#' @name print
#' @param x A \code{ti} object.
#' @param ... Unused. Present for S3/S7 compatibility; additional arguments are ignored.
#
#'
#' @return segment object
#' @keywords internal
#'
S7::method(print, segment_abc) <- function(x, ...) {
  # Follow along with a dummy example: run devtools::load_all(), then the line(s)
  # below, then the body one step at a time.
  # x <- contoso::sales |>
  #   dplyr::group_by(store_key) |>
  #   abc(category_values = c(0.5, 0.8, 1), .value = net_revenue)

  n_values_len <- length(x@category@category_values)

  print_fn_info(x)

  ### Category Values information
  cli::cli_h2("Category Information")

  if (x@value@value_vec == "n") {
    cli::cat_bullet(
      paste(
        "The data set is summarized by",
        cli::col_br_magenta(paste(x@datum@group_vec, collapse = ", ")),
        "and then",
        cli::col_br_magenta("counts"),
        "each group member's contribution of the total and then finally calculates the",
        cli::col_br_magenta("count"),
        "of each groups rolling cumulative proportion of the total"
      )
    )
  } else {
    cli::cat_bullet(
      paste(
        "The data set is summarized by",
        cli::col_br_magenta(paste(x@datum@group_vec, collapse = ", ")),
        "and then sums each group member's",
        cli::col_br_magenta(x@value@value_vec),
        "contribution of the total",
        cli::col_br_magenta(x@value@value_vec),
        "and then finally calculates each groups rolling cumulative proportion of the total"
      )
    )
  }

  cli::cat_bullet(
    paste(
      "Then cumulative distribution was then arranged from lowest to highest and finally classified into",
      n_values_len,
      "break points",
      cli::col_yellow(paste(
        paste0(round(x@category@category_values * 100), "%"),
        collapse = ", "
      )),
      " and labelled into the following categories",
      cli::col_br_blue(paste(x@category@category_names, collapse = ", "))
    )
  )

  cli::cat_line("")

  print_actions_steps(x)

  print_next_steps()
}


#' Print segment objects
#' @name print
#' @param x A \code{ti} object.
#' @param ... Unused. Present for S3/S7 compatibility; additional arguments are ignored.
#
#'
#' @return segment object
#' @keywords internal
#'
S7::method(print, segment_cohort) <- function(x, ...) {
  # Follow along with a dummy example: run devtools::load_all(), then the line(s)
  # below, then the body one step at a time.
  # x <- cohort(contoso::sales, .date = order_date, .value = customer_key)

  print_fn_info(x)

  ### Category Values information
  cli::cli_h2("Category Information")

  cli::cat_line("")

  cli::cat_bullet(
    paste(
      "The data set is grouped by the",
      cli::col_br_magenta(x@value@value_vec),
      "and segments each group member by their first",
      cli::col_br_magenta(x@datum@date_vec),
      "entry to define their cohort",
      cli::col_br_magenta(x@value@value_vec)
    )
  )
  cli::cat_bullet(
    "This creates cohort ID that each member is assigned to eg; January 2020, February 2020, etc"
  )

  cli::cat_bullet(
    paste(
      "The distinct count of each",
      cli::col_br_magenta(x@value@value_vec),
      "member in the cohort is then tracked over time"
    )
  )

  ## add if condition for abc vs. cohort
  print_calendar_info(x)

  cli::cat_line("")

  print_actions_steps(x)

  print_next_steps()
}
