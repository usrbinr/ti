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



#' Record which of the standard steps a calculation performs
#'
#' @param x Character vector of the steps the function performs.
#'
#' @returns A named logical vector with one element per standard step:
#'   aggregate, shift, compare, proportion of total and count distinct.
#' @keywords internal
make_action_cli <- function(x){

  # Follow along with a dummy example: run devtools::load_all(), then the line(s)
  # below, then the body one step at a time.
  # x <- c("aggregate", "shift")

  steps <- c("aggregate", "shift", "compare", "proportion of total", "count distinct")

  stats::setNames(steps %in% tolower(x), steps)

}



#' Prints function header info
#'
#' @param x ti or segment obj
#'
#' @returns print
#' @keywords internal
print_fn_info <- function(x) {

  # Follow along with a dummy example: run devtools::load_all(), then the line(s)
  # below, then the body one step at a time.
  # x <- wow(contoso::sales, .date = order_date, .value = net_revenue)

  # the description text (action@method) refers to these by name
  value_chr     <- x@value@value_vec
  calendar_type <- x@datum@calendar_type

  cli::cli_h1(x@fn@fn_long_name)
  cli::cli_text("Function: {.code {x@fn@fn_name}} (nothing has been calculated yet)")
  cli::cli_h2("Description:")
  cli::cli_par()
  cli::cli_text(x@action@method)
}


#' Period that each date belongs to
#'
#' @description
#' Labels dates with their period in R, using the same definitions as the
#' calendar SQL: weeks start on `week_start` and week 1 contains 1 January on
#' the standard calendar; fiscal labels from [generate_retail_calendar()] on the
#' retail calendars.
#'
#' @param dates A `Date` vector.
#' @param time_unit One of "day", "week", "month", "quarter" or "year".
#' @param calendar_type One of "standard", "445", "454" or "544".
#' @param week_start Integer 1 (Monday) to 7 (Sunday).
#' @param fiscal_year_start Integer 1-12.
#' @returns A character vector of period keys, one per date.
#' @keywords internal
period_keys <- function(dates, time_unit, calendar_type = "standard", week_start = 7, fiscal_year_start = 1) {

  # Follow along with a dummy example: run devtools::load_all(), then the line(s)
  # below, then the body one step at a time.
  # dates <- as.Date(c("2023-12-31", "2024-01-01", "2024-01-06", "2024-01-07"))
  # time_unit <- "week"
  # calendar_type <- "standard"
  # week_start <- 7
  # fiscal_year_start <- 1

  if (time_unit == "day") return(as.character(dates))

  if (calendar_type == "standard") {
    jan1 <- lubridate::floor_date(dates, "year")
    labels <- data.frame(
      year = lubridate::year(dates),
      quarter = lubridate::quarter(dates),
      month = lubridate::month(dates),
      week = (lubridate::yday(dates) - 1 + lubridate::wday(jan1, week_start = week_start) - 1) %/% 7 + 1
    )
  } else {
    cal <- generate_retail_calendar(min(dates), max(dates), calendar_type, fiscal_year_start, week_start)
    labels <- cal[match(dates, cal$date), c("year", "quarter", "month", "week")]
  }

  cols <- list(year = "year", quarter = c("year", "quarter"), month = c("year", "month"), week = c("year", "week"))[[time_unit]]
  do.call(paste, unname(as.list(labels[cols])))
}


#' Print calendar information block
#'
#' @param x ti or segment obj
#'
#' @returns print
#' @keywords internal
print_calendar_info <- function(x) {

  # Follow along with a dummy example: run devtools::load_all(), then the line(s)
  # below, then the body one step at a time.
  # x <- contoso::sales |>
  #   dplyr::group_by(store_key) |>
  #   wow(.date = order_date, .value = net_revenue)

  unit <- x@time_unit@value

  # one query for the distinct dates; everything below is computed from them
  dates <- x@datum@data |>
    dplyr::ungroup() |>
    dplyr::distinct(.ti_day = as.Date(!!x@datum@date_quo)) |>
    dplyr::pull(.ti_day)
  dates <- sort(dates[!is.na(dates)])

  cli::cli_h2("Calendar:")
  cli::cat_bullet(paste("The calendar aggregated",cli::col_br_magenta(x@datum@date_vec),"to the",cli::col_yellow(unit),"time unit"))
  cli::cat_bullet("A ",cli::col_br_red(x@datum@calendar_type)," calendar is created with ",cli::col_green(x@datum@group_count," groups"))

  if (length(dates) > 0) {
    cli::cat_bullet(paste("Calendar ranges from",cli::col_br_green(format(dates[1])),"to",cli::col_br_green(format(dates[length(dates)]))))

    keys <- function(d) period_keys(d, unit, x@datum@calendar_type, x@datum@week_start, x@datum@fiscal_year_start)
    all_periods <- unique(keys(seq(dates[1], dates[length(dates)], by = "day")))
    n_missing <- length(setdiff(all_periods, unique(keys(dates))))
    cli::cat_bullet(paste(
      cli::col_blue(n_missing), "of", length(all_periods), paste0(unit, "s"),
      if (S7::S7_inherits(x, ti)) "had no data and are filled with 0" else "had no data"
    ))
  }

  cli::cat_bullet("New date column ",paste(cli::col_br_red(x@fn@new_date_column_name), collapse = ", ")," was created from ",cli::col_br_magenta(x@datum@date_vec))
  cli::cat_line("")
}


#' Print the assumptions behind a time intelligence calculation
#'
#' @description
#' One line per convention that decides the numbers: what a row is, how
#' periods are compared, how weeks and fiscal years are defined, and how groups
#' are handled. Built only from the object's settings; it runs no query.
#'
#' @param x A `ti` object.
#' @returns print
#' @keywords internal
print_assumptions <- function(x) {

  # Follow along with a dummy example: run devtools::load_all(), then the line(s)
  # below, then the body one step at a time.
  # x <- contoso::sales |>
  #   dplyr::group_by(store_key) |>
  #   pmtd(.date = order_date, .value = net_revenue)

  fn_name <- x@fn@fn_name
  grain <- x@time_unit@value
  lag_n <- if (is.na(x@fn@lag_n)) 1 else x@fn@lag_n
  groups <- paste(x@datum@group_vec, collapse = ", ")
  grouped <- isTRUE(x@datum@group_indicator)
  day_names <- c("Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday")
  week_day <- day_names[x@datum@week_start]

  family <- c(
    ytd = "td", qtd = "td", mtd = "td", wtd = "td", atd = "td",
    yoy = "xox", qoq = "xox", mom = "xox", wow = "xox", dod = "xox",
    pytd = "ptd", pqtd = "ptd", pmtd = "ptd", pwtd = "ptd",
    yoytd = "xoxtd", qoqtd = "xoxtd", momtd = "xoxtd", wowtd = "xoxtd",
    ytdopy = "tdopx", qtdopq = "tdopx", mtdopm = "tdopx", wtdopw = "tdopx"
  )[[fn_name]]
  unit <- c(
    ytd = "year", qtd = "quarter", mtd = "month", wtd = "week", atd = NA,
    yoy = "year", qoq = "quarter", mom = "month", wow = "week", dod = "day",
    pytd = "year", pqtd = "quarter", pmtd = "month", pwtd = "week",
    yoytd = "year", qoqtd = "quarter", momtd = "month", wowtd = "week",
    ytdopy = "year", qtdopq = "quarter", mtdopm = "month", wtdopw = "week"
  )[[fn_name]]

  n_units <- function(n, u) paste(n, if (n == 1) u else paste0(u, "s"))
  earlier <- function(u) {
    if (u == "quarter") return(n_units(3 * lag_n, "month"))
    n_units(lag_n, u)
  }

  lines <- character()

  # what one row is
  per_group <- if (grouped) paste(" per", groups) else ""
  lines <- c(lines, if (grain == "day") {
    paste0("One row per day", per_group)
  } else {
    paste0("One row per ", grain, per_group, ", dated by the first day of the ", grain)
  })

  # how the numbers are built
  lines <- c(lines, switch(family,
    td = if (is.na(unit)) {
      "Running total from the first date, never reset"
    } else {
      paste("Running total that restarts at the start of each", unit)
    },
    xox = paste0(
      "Each ", unit, "'s total is shown next to the total ", earlier(unit), " earlier; ",
      if (lag_n == 1) paste0("the first ", unit, " has no earlier ", unit, " and shows NA")
      else paste0("the first ", n_units(lag_n, unit), " have no earlier ", unit, " and show NA")
    ),
    ptd = ,
    xoxtd = c(
      if (unit == "week") {
        paste("Each day is compared with the same weekday", earlier("week"), "earlier")
      } else {
        paste("Each day is compared with the same day", earlier(unit), "earlier;",
              "on the last day of a month, with the end of the earlier month")
      },
      "Days whose earlier date is before the data starts show NA"
    ),
    tdopx = paste0(
      "Each day's running total is shown next to ",
      if (lag_n == 1 && unit != "quarter") paste0("the previous ", unit, "'s full total")
      else paste0("the full total of the ", unit, " ", earlier(unit), " earlier"),
      "; NA when there is no earlier ", unit
    )
  ))

  # how weeks and fiscal years are defined
  uses_weeks <- identical(unit, "week") || grain == "week"
  if (x@datum@calendar_type == "standard") {
    if (uses_weeks) {
      lines <- c(lines, paste0(
        "Weeks start on ", week_day, "; week 1 contains 1 January, ",
        "so the weeks either side of 1 January can be partial"
      ))
    }
  } else {
    lines <- c(lines, paste0(
      x@datum@calendar_type, " fiscal calendar: the fiscal year starts on the ", week_day,
      " nearest to 1 ", month.name[x@datum@fiscal_year_start],
      ", and fiscal weeks start on ", week_day
    ))
  }

  if (grouped) {
    lines <- c(lines, paste0(
      "Running totals and comparisons stay within each ", groups,
      "; each group's calendar runs from its first to its last ", grain, " with data"
    ))
  }

  con_class <- class(dbplyr::remote_con(x@datum@data))
  if (!any(grepl("duckdb", con_class, ignore.case = TRUE))) {
    lines <- c(lines, paste0("Runs on ", con_class[1], ", which ti has not been tested with yet"))
  }

  cli::cli_h2("Assumptions:")
  # "{line}" inserts the text as-is, so braces in column names are not interpreted
  purrr::walk(lines, \(line) cli::cli_bullets(c("*" = "{line}")))
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

  # Follow along with a dummy example: run devtools::load_all(), then the line(s)
  # below, then the body one step at a time.
  # x <- wow(contoso::sales, .date = order_date, .value = net_revenue, lag_n = 2)

  cli::cli_h2("Actions:")

  steps <- x@action@value

  detail <- list(
    "aggregate"           = cli::col_blue(x@value@value_vec),
    "shift"               = cli::col_green(paste(
      stats::na.omit(x@fn@lag_n),
      paste0(stats::na.omit(x@fn@shift), if (isTRUE(x@fn@lag_n > 1)) "s" else "")
    )),
    "compare"             = cli::col_br_magenta(stats::na.omit(x@fn@compare)),
    "proportion of total" = character(),
    "count distinct"      = cli::col_blue(x@value@value_vec)
  )

  purrr::iwalk(steps, \(done, step) {
    mark <- if (isTRUE(done)) cli::col_green(cli::symbol$tick) else cli::col_red(cli::symbol$cross)
    extra <- if (isTRUE(done)) paste(detail[[step]], collapse = " ") else ""
    cli::cat_line(mark, " ", tools::toTitleCase(step), if (nzchar(extra)) paste0(" ", extra))
  })

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
    ,week_end_date=dplyr::sql(glue::glue("date_trunc('week', {date_vec}) + INTERVAL '1' week"))
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

  if (!any(data_class %in% c("tbl", "tbl_lazy"))) {
    cli::cli_abort("{.arg .data} must be a regular tibble or DBI lazy object.")
  }

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

  # Follow along with a dummy example: run devtools::load_all(), then the line(s)
  # below, then the body one step at a time.
  # x <- wow(contoso::sales, .date = order_date, .value = net_revenue)
  # .data <- create_calendar(x)

  # Retail calendars already have fiscal year/quarter/month/week from the mapping table
  if(x@datum@calendar_type %in% c("445", "454", "544")){
    return(.data)
  }

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



  # week comes from the calendar (seq_date_sql()), which honours week_start


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

  # Follow along with a dummy example: run devtools::load_all(), then the line(s)
  # below, then the body one step at a time.
  # x <- contoso::sales |>
  #   dplyr::group_by(store_key) |>
  #   wow(.date = order_date, .value = net_revenue)

    full_dbi <-
      create_calendar(x) |>
      complete_standard_calendar(x=x)

  return(full_dbi)

}

#' Coerce data into a DuckDB-backed lazy table
#'
#' @description
#' Ensures the input is a database-backed object. If a data.frame is provided,
#' it is registered into a temporary, in-memory DuckDB instance. If already
#' a `tbl_dbi`, it is returned unchanged.
#'
#' @param x A tibble, data.frame, or tbl_dbi object.
#' @returns A \code{tbl_dbi} object backed by DuckDB.
#' @export
#'
#' @details
#' When converting a data.frame, this function preserves existing \code{dplyr}
#' groups. It uses DuckDB's \code{duckdb_register}, which is a virtual registration
#' and does not perform a physical copy of the data, making it extremely fast.
#'
#' @keywords internal
make_db_tbl <- function(x) {

  # Follow along with a dummy example: run devtools::load_all(), then the line(s)
  # below, then the body one step at a time.
  # x <- dplyr::group_by(contoso::sales, store_key)

  # 1. Type Validation
  if (!inherits(x, "data.frame") && !inherits(x, "tbl_dbi")) {
    cli::cli_abort("Input must be a {.cls data.frame}, {.cls tibble}, or {.cls tbl_dbi} object.")
  }

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


#' Generate a retail (4-4-5, 4-5-4, or 5-4-4) calendar mapping table
#'
#' @param start_date Start date (Date or character YYYY-MM-DD)
#' @param end_date End date (Date or character YYYY-MM-DD)
#' @param calendar_type One of "445", "454", "544"
#' @param fiscal_year_start Integer 1-12, month the fiscal year starts nearest to
#' @param week_start Integer 1-7, day of week (1=Monday, 7=Sunday)
#'
#' @return A tibble with columns: date, year, quarter, month, week
#' @keywords internal
generate_retail_calendar <- function(start_date, end_date, calendar_type, fiscal_year_start = 1, week_start = 7) {

  # Follow along with a dummy example: run devtools::load_all(), then the line(s)
  # below, then the body one step at a time.
  # start_date <- as.Date("2024-01-01")
  # end_date <- as.Date("2024-12-31")
  # calendar_type <- "445"
  # fiscal_year_start <- 1
  # week_start <- 7

  start_date <- as.Date(start_date)
  end_date <- as.Date(end_date)

  # Map week_start (1=Mon..7=Sun) to wday values
  # lubridate::wday uses 1=Sun,2=Mon,...,7=Sat by default
  # We need the target weekday number for base R/lubridate
  target_wday <- (week_start %% 7) + 1  # convert 1=Mon..7=Sun to 1=Sun..7=Sat

  # Determine the pattern of weeks per month in each quarter
  pattern <- switch(calendar_type,
    "445" = c(4L, 4L, 5L),
    "454" = c(4L, 5L, 4L),
    "544" = c(5L, 4L, 4L)
  )

  # Find fiscal year start dates for a range of calendar years
  # We need extra years on both sides to cover the full date range. A fiscal
  # year is only built when the next one's start is known, and a fiscal year can
  # start a few days before 1 January, so look two years past end_date
  cal_years <- (lubridate::year(start_date) - 1):(lubridate::year(end_date) + 2)

  # For each calendar year, find the week_start weekday nearest to the 1st of fiscal_year_start month
  fy_starts <- purrr::map_dbl(cal_years, \(yr) {
    anchor <- as.Date(paste0(yr, "-", sprintf("%02d", fiscal_year_start), "-01"))
    # Find the nearest target weekday to this anchor
    anchor_wday <- lubridate::wday(anchor)  # 1=Sun..7=Sat
    diff <- target_wday - anchor_wday
    if (diff > 3) diff <- diff - 7
    if (diff < -3) diff <- diff + 7
    as.numeric(anchor + diff)
  })

  fy_starts <- as.Date(fy_starts, origin = "1970-01-01")
  fy_starts <- sort(unique(fy_starts))

  # Build one fiscal year per pair of consecutive start dates: one row per day,
  # labelled with its fiscal week, month and quarter
  all_rows <- purrr::map2(fy_starts[-length(fy_starts)], fy_starts[-1], \(fy_start, next_fy_start) {

    n_weeks <- as.integer(next_fy_start - fy_start) / 7

    # 52 or 53 week year; a 53rd week is added to the last month of the year
    if (!n_weeks %in% c(52, 53)) return(NULL)
    weeks_per_month <- rep(pattern, 4)
    if (n_weeks == 53) weeks_per_month[12] <- weeks_per_month[12] + 1L

    day_offset <- seq_len(7 * n_weeks) - 1
    fiscal_week <- as.integer(day_offset %/% 7) + 1L
    fiscal_month <- rep(seq_along(weeks_per_month), weeks_per_month)[fiscal_week]

    tibble::tibble(
      date = fy_start + day_offset,
      # Fiscal year label: the year containing most of the fiscal year
      year = lubridate::year(fy_start + 180),
      quarter = ((fiscal_month - 1) %/% 3) + 1,
      month = fiscal_month,
      week = fiscal_week
    )
  })

  # Only include dates in our target range
  out <- dplyr::bind_rows(all_rows) |>
    dplyr::filter(date >= start_date, date <= end_date)
  out <- dplyr::distinct(out, date, .keep_all = TRUE)
  out <- dplyr::arrange(out, date)

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
#' @param week_start Integer 1-7, the day weeks start on (1 = Monday, 7 = Sunday).
#' @param calendar_type One of "standard", "445", "454" or "544".
#' @param fiscal_year_start Integer 1-12, month the fiscal year starts nearest to (retail calendars only).
#' @param start_date A character string in 'YYYY-MM-DD' format or a Date object
#' representing the start of the series.
#' @param end_date A character string in 'YYYY-MM-DD' format or a Date object
#' representing the end of the series.
#' @param time_unit A character string specifying the interval. Must be one of:
#' \code{"day"}, \code{"week"}, \code{"month"}, \code{"quarter"}, or \code{"year"}.
#' @param .con A valid DBI connection object (e.g., DuckDB, Postgres, Snowflake)
#' or a \code{dbplyr} simulated connection.
#'
#' @return A \code{tbl_lazy} (SQL) object with one row per period: \code{date}
#' (the period's first day) and the calendar label columns for \code{time_unit}.
#'
#' @keywords internal
seq_date_sql <- function(
    .con
    ,start_date
    ,end_date
    ,calendar_type = "standard"
    ,time_unit="day"
    ,week_start = 7
    ,fiscal_year_start = 1) {

  # Follow along with a dummy example: run devtools::load_all(), then the line(s)
  # below, then the body one step at a time.
  # .con <- DBI::dbConnect(duckdb::duckdb())
  # start_date <- as.Date("2024-01-10")
  # end_date <- as.Date("2024-03-31")
  # calendar_type <- "standard"
  # time_unit <- "week"
  # week_start <- 7
  # fiscal_year_start <- 1



  valid_time_units <- c("day", "month", "quarter", "week", "year")
  if (!any(time_unit %in% valid_time_units)) {
    cli::cli_abort("{.arg time_unit} must be one of: {.val {valid_time_units}}.")
  }

  valid_calendar_types <- c("standard", "445", "454", "544")
  if (!any(calendar_type %in% valid_calendar_types)) {
    cli::cli_abort("{.arg calendar_type} must be one of: {.val {valid_calendar_types}}.")
  }

  if (!is.numeric(week_start) || length(week_start) != 1 || !week_start %in% 1:7) {
    cli::cli_abort("{.arg week_start} must be an integer between 1 (Monday) and 7 (Sunday).")
  }


  day_dbi <- calendar_day_sql(
    .con              = .con
    ,start_date       = start_date
    ,end_date         = end_date
    ,calendar_type    = calendar_type
    ,time_unit        = time_unit
    ,week_start       = week_start
    ,fiscal_year_start = fiscal_year_start
  )

  out <- calendar_periods(day_dbi, start_date = start_date, time_unit = time_unit)

  return(out)

}


#' Label columns returned for each time unit
#' @noRd
calendar_label_cols <- function(time_unit) {
  list(
    year     = "year"
    ,quarter = c("year", "quarter")
    ,month   = c("year", "quarter", "month")
    ,week    = c("year", "quarter", "month", "week")
    ,day     = c("year", "quarter", "month", "week", "day")
  )[[time_unit]]
}


#' Build a daily calendar with each day's period start date
#'
#' @description
#' Returns one row per day with the calendar labels (`year`, `quarter`, `month`,
#' `week`, `day`) and `period_date`, the first day of the period of `time_unit`
#' that the day belongs to. Periods are defined by the labels, never by flooring
#' dates, so a period is exactly the set of days that share its labels:
#'
#' * standard calendar: weeks start on `week_start` and week 1 is the week that
#'   contains 1 January, so only the weeks around 1 January are partial
#'   (the same convention as Excel's `WEEKNUM()`). Weeks do not split at month
#'   ends; a week's month and quarter are those of its first day.
#' * retail calendars: fiscal year, quarter, month and week from
#'   [generate_retail_calendar()].
#'
#' The calendar starts 371 days before `start_date` so that the period containing
#' `start_date` is dated by its true first day, even for 53-week fiscal years.
#'
#' @inheritParams seq_date_sql
#' @returns A `tbl_lazy` with columns `date`, `year`, `quarter`, `month`, `week`,
#'   `day` and `period_date`.
#' @keywords internal
calendar_day_sql <- function(
    .con
    ,start_date
    ,end_date
    ,calendar_type = "standard"
    ,time_unit = "day"
    ,week_start = 7
    ,fiscal_year_start = 1) {

  # Follow along with a dummy example: run devtools::load_all(), then the line(s)
  # below, then the body one step at a time.
  # .con <- DBI::dbConnect(duckdb::duckdb())
  # start_date <- as.Date("2024-01-10")
  # end_date <- as.Date("2024-03-31")
  # calendar_type <- "standard"
  # time_unit <- "week"
  # week_start <- 7
  # fiscal_year_start <- 1

  ext_start <- as.Date(start_date) - 371

  if (calendar_type %in% c("445", "454", "544")) {

    retail_tbl <- generate_retail_calendar(
      start_date = ext_start,
      end_date = end_date,
      calendar_type = calendar_type,
      fiscal_year_start = fiscal_year_start,
      week_start = week_start
    ) |>
      dplyr::mutate(
        date = as.Date(date),
        year = as.integer(year),
        quarter = as.integer(quarter),
        month = as.integer(month),
        week = as.integer(week)
      )

    # Inline the calendar into the query as VALUES, so nothing is written to the
    # database (works with read-only access) and each query keeps its own calendar
    calendar_dbi <- dbplyr::copy_inline(.con, retail_tbl)

  } else {

    # 0 = Sunday ... 6 = Saturday, matching ISODOW %% 7
    week_start_dow <- as.integer(week_start %% 7)
    start_chr <- format(ext_start)
    end_chr <- format(as.Date(end_date))

    dialect <- detect_sql_dialect(.con)

    if (dialect == "snowflake") {
      # Snowflake GENERATOR requires ROWCOUNT to be a literal constant
      row_count <- as.integer(as.Date(end_date) - ext_start) + 1L
      date_seq_sql <- glue::glue_sql("
  SELECT
    date
    ,EXTRACT(YEAR FROM date) AS year
    ,EXTRACT(QUARTER FROM date) AS quarter
    ,EXTRACT(MONTH FROM date) AS month
    ,FLOOR((DAYOFYEAR(date) - 1 + MOD(MOD(DAYOFWEEKISO(DATE_TRUNC('year', date)), 7) - {week_start_dow} + 7, 7)) / 7) + 1 AS week
  FROM (
    SELECT DATEADD(day, SEQ4(), {start_chr}::DATE)::DATE AS date
    FROM TABLE(GENERATOR(ROWCOUNT => {row_count}))
  )
", .con = .con)
    } else {
      date_seq_sql <- glue::glue_sql("
  WITH DATE_SERIES AS (
  SELECT

  GENERATE_SERIES(
     MIN(DATE_TRUNC('day', DATE {start_chr}::date))::DATE
    ,MAX(DATE_TRUNC('day', DATE {end_chr}::date))::DATE
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
  ,FLOOR((EXTRACT(DOY FROM date) - 1 + ((CAST(EXTRACT(ISODOW FROM DATE_TRUNC('year', date)) AS INTEGER) % 7) - {week_start_dow} + 7) % 7) / 7) + 1 AS week

  FROM CALENDAR_TBL

", .con = .con)
    }

    calendar_dbi <- dplyr::tbl(.con, dplyr::sql(date_seq_sql))
  }

  calendar_dbi <- calendar_dbi |>
    dplyr::mutate(day = lubridate::day(date))

  if (time_unit == "day") {
    return(dplyr::mutate(calendar_dbi, period_date = date))
  }

  # Columns that identify one period; quarter is implied by month
  period_cols <- list(
    year     = "year"
    ,quarter = c("year", "quarter")
    ,month   = c("year", "month")
    ,week    = c("year", "week")
  )[[time_unit]]

  calendar_dbi |>
    dplyr::mutate(
      period_date = min(date, na.rm = TRUE)
      ,.by = dplyr::all_of(period_cols)
    )
}


#' One row per period that overlaps the requested range
#'
#' @param day_dbi Output of [calendar_day_sql()].
#' @param start_date First date of the requested range.
#' @param time_unit Time unit of the periods.
#' @returns A `tbl_lazy` with `date` (the period's first day) and the label
#'   columns for `time_unit`, taken from that first day.
#' @keywords internal
calendar_periods <- function(day_dbi, start_date, time_unit) {

  # Follow along with a dummy example: run devtools::load_all(), then the line(s)
  # below, then the body one step at a time.
  # .con <- DBI::dbConnect(duckdb::duckdb())
  # day_dbi <- calendar_day_sql(.con, "2024-01-10", "2024-03-31", time_unit = "week")
  # start_date <- as.Date("2024-01-10")
  # time_unit <- "week"

  start_chr <- format(as.Date(start_date))

  in_range <- day_dbi |>
    dplyr::filter(date >= as.Date(!!start_chr)) |>
    dplyr::distinct(period_date)

  day_dbi |>
    dplyr::filter(date == period_date) |>
    dplyr::semi_join(in_range, by = "period_date") |>
    dplyr::select(date, dplyr::all_of(calendar_label_cols(time_unit)))
}


#' Detect SQL dialect from a DBI connection
#'
#' @param .con A DBI connection object
#' @return A character string: "snowflake", "duckdb", or "postgres"
#' @keywords internal
detect_sql_dialect <- function(.con) {

  # Follow along with a dummy example: run devtools::load_all(), then the line(s)
  # below, then the body one step at a time.
  # .con <- DBI::dbConnect(duckdb::duckdb())
  cls <- tolower(paste(class(.con), collapse = " "))
  if (grepl("duckdb", cls)) return("duckdb")

  dialect <- if (grepl("snowflake", cls)) "snowflake" else if (grepl("postgres|pq", cls)) "postgres" else NA_character_

  if (is.na(dialect)) {
    cli::cli_abort(c(
      "{.pkg ti} does not support this database connection yet.",
      "x" = "Connection class: {.cls {class(.con)}}.",
      "i" = "{.pkg ti} is tested with 'DuckDB' and with data frames, which it runs in 'DuckDB'.",
      "i" = "Support for other databases will come in a later release."
    ))
  }

  cli::cli_warn(
    c(
      "{.pkg ti} has not been tested with this database yet.",
      "i" = "Check results against a 'DuckDB' or data frame run before relying on them."
    ),
    .frequency = "once",
    .frequency_id = paste0("ti_untested_", dialect)
  )

  dialect
}

#' Generate dialect-appropriate date addition SQL
#'
#' @param .con A DBI connection object
#' @param unit A character string: "month", "week", etc.
#' @param n_expr An expression string for the number of units
#' @param date_col A character string for the date column name
#' @return A `dplyr::sql` object
#' @keywords internal
sql_date_add <- function(.con, unit, n_expr, date_col = "date") {
  dialect <- detect_sql_dialect(.con)
  if (dialect == "snowflake") {
    dplyr::sql(glue::glue("DATEADD({unit}, {n_expr}, {date_col})"))
  } else {
    dplyr::sql(glue::glue("{date_col} + INTERVAL '1 {unit}' * {n_expr}"))
  }
}

#' Same point in time in an earlier period
#'
#' @description
#' SQL for the cutoff date used by the previous-period-to-date functions:
#' `date` moved back `lag_n` weeks, months, quarters or years. Moving back by
#' months clamps to the end of a shorter month (31 May minus 3 months is
#' 29 February), and when `date` is the last day of its month the cutoff is the
#' last day of the earlier month, so 28 February 2025 compares with the whole of
#' February 2024 and 30 April with the whole of January.
#'
#' @param .con A DBI connection
#' @param unit One of "week", "month", "quarter" or "year"
#' @param lag_n Number of periods to move back
#' @returns A SQL expression on the `date` column
#' @keywords internal
sql_period_cutoff <- function(.con, unit, lag_n) {

  # Follow along with a dummy example: run devtools::load_all(), then the line(s)
  # below, then the body one step at a time.
  # .con <- DBI::dbConnect(duckdb::duckdb())
  # unit <- "month"
  # lag_n <- 1
  #
  # then see the cutoff it produces for a few dates:
  # dplyr::tbl(.con, dplyr::sql("SELECT * FROM (VALUES (DATE '2024-03-15'), (DATE '2024-03-30'), (DATE '2024-03-31')) t(date)")) |>
  #   dplyr::mutate(cutoff = !!sql_period_cutoff(.con, unit, lag_n)) |> dplyr::collect()

  lag_n <- as.integer(lag_n)
  dialect <- detect_sql_dialect(.con)

  if (unit == "week") {
    days <- 7L * lag_n
    if (dialect == "snowflake") return(dplyr::sql(glue::glue("DATEADD(day, -{days}, date)")))
    return(dplyr::sql(glue::glue("CAST(date - INTERVAL '1 day' * {days} AS DATE)")))
  }

  months <- lag_n * c(month = 1L, quarter = 3L, year = 12L)[[unit]]

  if (dialect == "snowflake") {
    shifted <- glue::glue("DATEADD(month, -{months}, date)")
    month_end <- \(e) glue::glue("LAST_DAY({e})")
  } else {
    shifted <- glue::glue("CAST(date - INTERVAL '1 month' * {months} AS DATE)")
    month_end <- \(e) glue::glue("CAST(DATE_TRUNC('month', {e}) + INTERVAL '1 month' - INTERVAL '1 day' AS DATE)")
  }

  dplyr::sql(glue::glue(
    "CASE WHEN date = {month_end('date')} THEN {month_end(shifted)} ELSE {shifted} END"
  ))
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
    "sql",
    "quarter",
    "date_lag",
    ".ti_td",
    ".ti_cutoff",
    ".ti_day",
    ".ti_period_date",
    "period_date",
    "days_in_comparison_period",
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

