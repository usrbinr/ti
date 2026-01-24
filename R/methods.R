

# create generics -----------

create_calendar <- S7::new_generic("create_calendar","x")


calculate <- S7::new_generic("calculate","x")

#' Create Calendar Table
#' @name create_calendar
#' @param x ti object
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
S7::method(create_calendar,ti) <- function(x){


  summary_dbi <- x@datum@data |>
    dplyr::ungroup() |>
    make_db_tbl() |>
    dplyr::mutate(
      date = lubridate::floor_date(!!x@datum@date_quo, unit = !!x@time_unit@value,week_start = 7),
      time_unit = !!x@time_unit@value
    ) |>
    dplyr::summarise(
      !!x@value@value_vec := sum(!!x@value@value_quo, na.rm = TRUE),
      .by = c(date, !!!x@datum@group_quo)
    )

  active_bounds <- summary_dbi |>
    dplyr::summarise(
      min_g = min(date, na.rm = TRUE),
      max_g = max(date, na.rm = TRUE),
      .by = c(!!!x@datum@group_quo)
    )


  master_dates <- seq_date_sql(
    start_date    = x@datum@min_date,
    end_date      = x@datum@max_date,
    calendar_type = x@datum@calendar_type,
    time_unit     = x@time_unit@value,
    .con          = dbplyr::remote_con(x@datum@data)
  )

  if (x@datum@group_indicator) {

    calendar_dbi <- master_dates |>
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
#' @name calculate
#' @param x ti object
#' @description
#' The `calculate()` function takes an object created by a time function (like `ytd()`, `mtd()`, or `qtd()`) or a segment function (like `cohort()` or `abc()`) and executes the underlying transformation logic.
#' It translates the function blueprint into an actionable query, returning the final data table.
#'
#' @details
#' The TI and segment functions in **fpaR**—such as `ytd()` or `cohort()` and others—are designed to be **lazy and database-friendly**.
#' They do not perform the heavy data transformation immediately.
#' Instead, they return a blueprint object (of class `ti`,`segment_abc` or `segment_cohort`) that contains all the parameters and logic needed for the calculation.
#'
#' **`calculate()`** serves as the **execution engine**.
#'
#' When called, it interprets the blueprint and generates optimized R code or SQL code (using the `dbplyr` package) that is then executed efficiently on the data source, whether it's an in-memory `tibble` or a remote database backend (like `duckdb` or `snowflake`).
#' This approach minimizes data transfer and improves performance for large datasets.
#'
#' The resulting table will be sorted by the relevant date column to ensure the correct temporal ordering of the calculated metrics.
#'
#'
#' @returns dbi object
#' @export
#' @examples
#'\dontrun{
#' x <- ytd(sales,.date=order_date,.value=quantity,calendar_type="standard")
#' calculate(x)
#'}

S7::method(calculate,ti) <- function(x){

  out <-   x@fn@fn_exec(x)|>
      dbplyr::window_order(date)

  return(out)

}


#' @rdname calculate
#' @name calculate
#' @export
S7::method(calculate,segment_cohort) <- function(x){

  out <- x@fn@fn_exec(x)

  return(out)

}



#' @rdname calculate
#' @name calculate
#' @export
S7::method(calculate,segment_abc) <- function(x){

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
S7::method(print, ti) <- function(x,...){


  ## subset function descriptions from table


  value_chr     <-   x@value@value_vec
  group_count   <-   x@datum@group_count
  calendar_type <-   x@datum@calendar_type



  ## start print message


  ### general information

  cli::cli_h1(x@fn@fn_long_name)
  cli::cli_text("Function: {.code { x@fn@fn_name}} was executed")
  cli::cli_h2("Description:")
  cli::cli_par()

  cli::cli_text(x@action@method)

  cli::builtin_theme()

  ### Calendar information


  cli::cli_h2("Calendar:")
  cli::cat_bullet(paste("The calendar aggregated",cli::col_br_magenta(x@datum@date_vec),"to the",cli::col_yellow(x@time_unit@value),"time unit"))
  cli::cat_bullet("A ",cli::col_br_red(x@datum@calendar_type)," calendar is created with ",cli::col_green(x@datum@group_count," groups"))
  cli::cat_bullet(paste("Calendar ranges from",cli::col_br_green(x@datum@min_date),"to",cli::col_br_green(x@datum@max_date)))
  cli::cat_bullet(paste(cli::col_blue(x@datum@date_missing),"days were missing and replaced with 0"))
  cli::cat_bullet("New date column ",stringr::str_flatten_comma(cli::col_br_red(x@fn@new_date_column_name),last = " and ")," was created from ",cli::col_br_magenta(x@datum@date_vec))
  cli::cat_line("")

  ## Action information

  print_actions_steps(x)


  cli::cat_line("")
  ## print groups if groups exist

  if(x@datum@group_indicator){

  cli::cli_text("{stringr::str_flatten_comma(x@datum@group_vec,last = ' and ')} groups are in the table")
  cli::cat_line("")
  }

  ## Next Steps information

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
S7::method(print,segment_abc) <- function(x,...){


  n_values_len <- length(x@category@category_values)

  print_fn_info(x)

  ### Category Values information
  cli::cli_h2("Category Information")


  if(x@value@value_vec=="n"){

    cli::cat_bullet(

      paste(
        "The data set is summarized by"
        ,cli::col_br_magenta(stringr::str_flatten_comma(x@datum@group_vec))
        ,"and then"
        ,cli::col_br_magenta("counts")
        ,"each group member's contribution of the total and then finally calculates the"
        ,cli::col_br_magenta("count")
        ,"of each groups rolling cumulative porportion of the total"
      )

    )

  }else{

    cli::cat_bullet(
      paste(
        "The data set is summarized by"
        ,cli::col_br_magenta(stringr::str_flatten_comma(x@datum@group_vec))
        ,"and then sums each group member's"
        ,cli::col_br_magenta(x@value@value_vec)
        ,"contribution of the total"
        ,cli::col_br_magenta(x@value@value_vec)
        ,"and then finally calculates each groups rolling cumulative porportion of the total"
      )
    )

  }

  cli::cat_bullet(
    paste(
      "Then cumulative distribution was then arranged from lowest to highest and finally classified into"
      ,n_values_len
      ,"break points"
      ,cli::col_yellow(stringr::str_flatten_comma(scales::percent(x@category@category_values)))
      ," and labelled into the following categories"
      ,cli::col_br_blue(stringr::str_flatten_comma(x@category@category_names))
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
S7::method(print,segment_cohort) <- function(x,...){



  print_fn_info(x)

  ### Category Values information
  cli::cli_h2("Category Information")

    cli::cat_line("")

    cli::cat_bullet(
      paste(
        "The data set is grouped by the"
        ,cli::col_br_magenta(x@value@value_vec)
        ,"and segments each group member by their first"
        ,cli::col_br_magenta(x@datum@date_vec)
        ,"entry to define their cohort"
        ,cli::col_br_magenta(x@value@value_vec)
      )
    )
    cli::cat_bullet("This creates cohort ID that each member is assigned to eg; January 2020, February 2020, etc")

    cli::cat_bullet(
      paste(
        "The distinct count of each"
        ,cli::col_br_magenta(x@value@value_vec)
        ,"member in the cohort is then tracked over time"
      )
    )



    ## add if condition for abc vs. cohort
    cli::cli_h2("Calendar:")
    cli::cat_bullet(paste("The calendar aggregated",cli::col_br_magenta(x@datum@date_vec),"to the",cli::col_yellow(x@time_unit@value),"time unit"))
    cli::cat_bullet("A ",cli::col_br_red(x@datum@calendar_type)," calendar is created with ",cli::col_green(x@datum@group_count," groups"))
    cli::cat_bullet(paste("Calendar ranges from",cli::col_br_green(x@datum@min_date),"to",cli::col_br_green(x@datum@max_date)))
    cli::cat_bullet(paste(cli::col_blue(x@datum@date_missing),"days were missing and replaced with 0"))
    cli::cat_bullet("New date column ",stringr::str_flatten_comma(cli::col_br_red(x@fn@new_date_column_name),last = " and ")," was created from ",cli::col_br_magenta(x@datum@date_vec))
    cli::cat_line("")

  cli::cat_line("")

  print_actions_steps(x)

  print_next_steps()

}



# complete_calendar <- S7::new_generic("complete_calendar","x")



# S7::method(complete_calendar,ti) <- function(x){
#
#
#   calendar_dbi<- x@datum@data |>
#     dplyr::count(!!x@datum@date_quo) |>
#     dplyr::select(-n)
#
#
#   date_vec <- x@datum@date_vec
#
#   out <- calendar_dbi |>
#     dplyr::mutate(
#       year_start_date=lubridate::floor_date(!!x@datum@date_quo,unit = "year")
#       ,year_end_date=dplyr::sql(glue::glue("date_trunc('year', {date_vec}) + INTERVAL '1' YEAR"))
#       ,quarter_start_date=lubridate::floor_date(!!x@datum@date_quo,unit = "quarter")
#       ,quarter_end_date=dplyr::sql(glue::glue("date_trunc('quarter', {date_vec}) + INTERVAL '1' quarter"))
#       ,month_start_date=lubridate::floor_date(!!x@datum@date_quo,unit = "month")
#       ,month_end_date=dplyr::sql(glue::glue("date_trunc('month', {date_vec}) + INTERVAL '1' month"))
#       ,week_start_date=lubridate::floor_date(!!x@datum@date_quo,unit = "week")
#       ,week_end_date=dplyr::sql(glue::glue("date_trunc('month', {date_vec}) + INTERVAL '1' month"))
#       ,day_of_week=lubridate::wday(!!x@datum@date_quo,label = FALSE)
#       ,day_of_week_label=lubridate::wday(!!x@datum@date_quo,label = TRUE)
#       ,days_in_year=year_end_date-year_start_date
#       ,days_in_quarter=quarter_end_date-quarter_start_date
#       ,days_in_month=dplyr::sql(glue::glue("last_day({date_vec})"))
#       ,days_complete_in_week=!!x@datum@date_quo-week_start_date
#       ,days_remaining_in_week=week_end_date-!!x@datum@date_quo
#       ,days_remaining_in_quarter=quarter_end_date-!!x@datum@date_quo
#       ,days_remaining_in_month=month_end_date-!!x@datum@date_quo
#       ,days_remaining_in_year=year_end_date-!!x@datum@date_quo
#       ,days_complete_in_year=!!x@datum@date_quo-year_start_date
#       ,days_complete_in_quarter=!!x@datum@date_quo-quarter_start_date
#       ,days_complete_in_month=!!x@datum@date_quo-month_start_date
#       ,days_complete_in_year=!!x@datum@date_quo-year_start_date
#       ,weekend_indicator=dplyr::if_else(day_of_week_label %in% c("Saturday","Sunday"),1,0)
#     ) |>
#     dplyr::mutate(
#       dplyr::across(dplyr::contains("date"),\(x) as.Date(x))
#     )
#
#   return(out)
#
# }


