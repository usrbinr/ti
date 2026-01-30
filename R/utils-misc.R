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

  if(any(x %in% tolower(word))){

    out[[word]] <- c(cli::col_green(cli::symbol$tick),tools::toTitleCase(word))

  }else{

    out[[word]] <- c(cli::col_red(cli::symbol$cross),tools::toTitleCase(word))
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

#' Print calendar information block
#'
#' @param x ti or segment obj
#'
#' @returns print
#' @keywords internal
print_calendar_info <- function(x) {
  cli::cli_h2("Calendar:")
  cli::cat_bullet(paste("The calendar aggregated",cli::col_br_magenta(x@datum@date_vec),"to the",cli::col_yellow(x@time_unit@value),"time unit"))
  cli::cat_bullet("A ",cli::col_br_red(x@datum@calendar_type)," calendar is created with ",cli::col_green(x@datum@group_count," groups"))
  cli::cat_bullet(paste("Calendar ranges from",cli::col_br_green(x@datum@min_date),"to",cli::col_br_green(x@datum@max_date)))
  cli::cat_bullet(paste(cli::col_blue(x@datum@date_missing),"days were missing and replaced with 0"))
  cli::cat_bullet("New date column ",paste(cli::col_br_red(x@fn@new_date_column_name), collapse = ", ")," was created from ",cli::col_br_magenta(x@datum@date_vec))
  cli::cat_line("")
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


  if(any(grepl("32m",x@action@value[[1]]))){


    cli::cli_text(x@action@value[[1]]," ",cli::col_blue(x@value@value_vec))

  }else{

    cli::cli_text(x@action@value[[1]])

  }

  #shift

  cli::cli_text(x@action@value[[2]]," ",cli::col_green(stats::na.omit(x@fn@lag_n))," ",cli::col_green(stats::na.omit(x@fn@shift)))

  #compare

  cli::cli_text(x@action@value[[3]]," ",cli::col_br_magenta(stats::na.omit(x@fn@compare)))


  ## prop of total

  if(any(grepl("32m", x@action@value[[4]]))){


    cli::cli_text(x@action@value[[4]])

  }else{

    cli::cli_text(x@action@value[[4]])

  }

  ## distinct count


  if(any(grepl("32m", x@action@value[[5]]))){


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
  # We need extra years on both sides to cover the full date range
  cal_years <- (lubridate::year(start_date) - 1):(lubridate::year(end_date) + 1)

  # For each calendar year, find the week_start weekday nearest to the 1st of fiscal_year_start month
  fy_starts <- vapply(cal_years, function(yr) {
    anchor <- as.Date(paste0(yr, "-", sprintf("%02d", fiscal_year_start), "-01"))
    # Find the nearest target weekday to this anchor
    anchor_wday <- lubridate::wday(anchor)  # 1=Sun..7=Sat
    diff <- target_wday - anchor_wday
    if (diff > 3) diff <- diff - 7
    if (diff < -3) diff <- diff + 7
    as.numeric(anchor + diff)
  }, numeric(1))

  fy_starts <- as.Date(fy_starts, origin = "1970-01-01")
  fy_starts <- sort(unique(fy_starts))

  # Build the calendar by iterating over fiscal years
  all_rows <- vector("list", length(fy_starts) - 1)

  for (i in seq_len(length(fy_starts) - 1)) {
    fy_start <- fy_starts[i]
    fy_end <- fy_starts[i + 1] - 1
    n_days <- as.integer(fy_end - fy_start) + 1
    n_weeks <- n_days / 7

    # Fiscal year label: the year containing most of the fiscal year
    fiscal_year <- lubridate::year(fy_start + 180)

    # 52 or 53 week year
    if (n_weeks == 53) {
      # Add extra week to the last month of the last quarter
      weeks_per_month <- c(rep(pattern, 4))
      weeks_per_month[12] <- weeks_per_month[12] + 1L
    } else if (n_weeks == 52) {
      weeks_per_month <- rep(pattern, 4)
    } else {
      next
    }

    # Assign fiscal month/quarter/week to each date
    current_date <- fy_start
    fiscal_week <- 0L

    for (m in seq_along(weeks_per_month)) {
      fiscal_month <- m
      fiscal_quarter <- ((m - 1) %/% 3) + 1
      n_weeks_in_month <- weeks_per_month[m]

      for (w in seq_len(n_weeks_in_month)) {
        fiscal_week <- fiscal_week + 1L
        week_dates <- current_date + 0:6

        # Only include dates in our target range
        week_dates <- week_dates[week_dates >= start_date & week_dates <= end_date]

        if (length(week_dates) > 0) {
          all_rows[[length(all_rows) + 1]] <- tibble::tibble(
            date = week_dates,
            year = fiscal_year,
            quarter = fiscal_quarter,
            month = fiscal_month,
            week = fiscal_week
          )
        }

        current_date <- current_date + 7
      }
    }
  }

  out <- dplyr::bind_rows(all_rows)
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
    ,week_start = 7
    ,fiscal_year_start = 1) {



  # assertthat::assert_that(assertthat::is.string(start_date), msg = "start_date must be a string (YYYY-MM-DD)")

  assertthat::assert_that(any(time_unit %in% c("day", "month","quarter", "week","year")),msg = "time_unit must be one of: 'day', 'week', 'quarter', 'month' or 'year'")

  # assertthat::assert_that(assertthat::is.string(end_date), msg = "end_date must be a string (YYYY-MM-DD)")

  assertthat::assert_that(any(calendar_type %in% c("standard", "445", "454", "544")),msg = "calendar_type must be one of: 'standard', '445', '454', '544'")

  assertthat::assert_that(assertthat::is.number(week_start) && week_start %in% 1:7,msg = "week_start must be an integer between 1 (Monday) and 7 (Sunday)")


  if(calendar_type %in% c("445", "454", "544")){

    retail_tbl <- generate_retail_calendar(
      start_date = start_date,
      end_date = end_date,
      calendar_type = calendar_type,
      fiscal_year_start = fiscal_year_start,
      week_start = week_start
    )

    retail_tbl <- retail_tbl |>
      dplyr::mutate(
        date = as.Date(date),
        year = as.integer(year),
        quarter = as.integer(quarter),
        month = as.integer(month),
        week = as.integer(week)
      )

    # Push to DB as temp table
    dplyr::copy_to(.con, retail_tbl, name = "retail_calendar", overwrite = TRUE)

    calendar_dbi <- dplyr::tbl(.con, "retail_calendar")

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
        date=lubridate::floor_date(date, unit = time_unit)
      ) |>
      dplyr::summarise(
        .by=dplyr::any_of(group_col_vec)
        ,n=dplyr::n()
      ) |>
      dplyr::select(-c(n))

    return(out)
  }

  if(calendar_type=='standard'){

    dialect <- detect_sql_dialect(.con)

    if (dialect == "snowflake") {
      date_seq_sql <- glue::glue_sql("
  SELECT
    DATEADD(day, SEQ4(), {start_date}::DATE)::DATE AS date
    ,EXTRACT(YEAR FROM DATEADD(day, SEQ4(), {start_date}::DATE)) AS year
    ,EXTRACT(QUARTER FROM DATEADD(day, SEQ4(), {start_date}::DATE)) AS quarter
    ,EXTRACT(MONTH FROM DATEADD(day, SEQ4(), {start_date}::DATE)) AS month
    ,FLOOR((EXTRACT(DOY FROM DATEADD(day, SEQ4(), {start_date}::DATE)) - 1) / 7) + 1 AS week
  FROM TABLE(GENERATOR(ROWCOUNT => DATEDIFF(day, {start_date}::DATE, {end_date}::DATE) + 1))
",.con=.con)
    } else {
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


#' Detect SQL dialect from a DBI connection
#'
#' @param .con A DBI connection object
#' @return A character string: "snowflake", "duckdb", or "postgres"
#' @keywords internal
detect_sql_dialect <- function(.con) {
  cls <- tolower(paste(class(.con), collapse = " "))
  if (grepl("snowflake", cls)) return("snowflake")
  if (grepl("duckdb", cls)) return("duckdb")
  if (grepl("postgres|pq", cls)) return("postgres")
  return("duckdb") # default fallback
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

