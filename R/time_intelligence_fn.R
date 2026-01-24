
## year related functions---------------

#' Year-to-date execution function
#' @name ytd_fn
#' @param x ti object
#' @description
#' [ytd_fn()] is the function that is called by [ytd()] when passed through to [calculate]
#' @seealso [ytd()] for the function's class
#' @details
#' This is internal non exported function that is nested in ti class and is called upon when the underlying function is called
#' by [calculate]
#' This will return a dbi object that can converted to a tibble object with [dplyr::collect()]
#' @returns dbi object
#' @keywords internal
ytd_fn <- function(x){


  # create calendar table

  full_dbi <- create_full_dbi(x)


 # aggregate the data and create the cumulative sum

  out_dbi <- full_dbi |>
    dbplyr::window_order(date) |>
    dplyr::mutate(
      !!x@value@new_column_name_vec:=base::cumsum(!!x@value@value_quo)
      ,.by=c(year,!!!x@datum@group_quo)
    ) |>
    dplyr::relocate(
      date,year
    ) |>
    dplyr::relocate(
      dplyr::any_of("missing_date_indicator")
      ,.after = dplyr::last_col() # Ensures this is the final column
    )

  return(out_dbi)
}


#' @title Previous year-to-date execution function
#' @name pytd_fn
#' @param x ti object
#' @description
#' [pytd_fn()] is the function that is called by [pytd()] when passed through to [calculate]
#' @seealso [pytd()] for the function's intent
#' @details
#' This is internal non exported function that is nested in ti class and is called upon when the underlying function is called
#' by [calculate]
#' This will return a dbi object that can converted to a tibble object with [dplyr::collect()]
#' @returns dbi object
#' @keywords internal
pytd_fn <- function(x){


  # x <- fpaR::pytd(.data =sales ,.date = order_date,.value = margin,calendar_type = "standard",lag_n = 2)


  # create calendar table
  # full_dbi <-  create_calendar(x) |>
  #   dplyr::mutate(
  #     year=lubridate::year(date)
  #     ,.before = 1
  #   )

  full_dbi <- create_full_dbi(x)

  # create lag table

  lag_dbi <- full_dbi|>
    dbplyr::window_order(date) |>
    dplyr::mutate(
      date_lag=as.Date(date+lubridate::years(!!x@fn@lag_n))
      ,!!x@value@new_column_name_vec:=cumsum(!!x@value@value_quo)
      ,.by=c(year,!!!x@datum@group_quo)
    ) |>
    dplyr::select(-c(date,year,!!x@value@value_quo))


  # join tables together
  out_dbi <-   dplyr::full_join(
    full_dbi
    ,lag_dbi
    ,by=dplyr::join_by(date==date_lag,!!!x@datum@group_quo)
  ) |>
    dplyr::select(-c(!!x@value@value_quo)) |>
    dbplyr::window_order(date) |>
    dplyr::group_by(date,year,!!!x@datum@group_quo) |>
    tidyr::fill(date,.direction = "down") |>
    dplyr::ungroup() |>
    dplyr::summarise(
      dplyr::across(dplyr::contains(x@value@value_vec),\(x) sum(x,na.rm=TRUE))
      ,.by=c(date,year,!!!x@datum@group_quo)
    ) |>
    dplyr::relocate(date,year) |>
    dplyr::relocate(dplyr::any_of("missing_date_indicator"),.after=dplyr::last_col())

  return(out_dbi)

}


#' @title Current year to date over previous year-to-date exection function
#' @name yoytd_fn
#' @param x ti object
#' @description
#' [yoytd_fn()] is the function that is called by [yoytd()] when passed through to [calculate]
#' @seealso [yoytd()] for the function's intent
#' @details
#' This is internal non exported function that is nested in ti class and is called upon when the underlying function is called
#' by [calculate]
#' This will return a dbi object that can converted to a tibble object with [dplyr::collect()]
#' @returns dbi object
#' @keywords internal
yoytd_fn <- function(x){



  # ytd tabl

  ytd_dbi <- ytd(.data=x@datum@data,.date=!!x@datum@date_quo,.value = !!x@value@value_quo,calendar_type = x@datum@calendar_type) |>
    ytd_fn()

  #pytd table

  pytd_dbi <- pytd(.data=x@datum@data,.date=!!x@datum@date_quo,.value = !!x@value@value_quo,calendar_type = x@datum@calendar_type,lag_n = x@fn@lag_n) |>
    pytd_fn()


  # join tables together

  out_dbi <-
    dplyr::full_join(
    ytd_dbi
    ,pytd_dbi
    ,by=dplyr::join_by(date==date,year,!!!x@datum@group_quo)
  ) |>
    dplyr::group_by(date,!!!x@datum@group_quo) |>
    tidyr::fill(date,.direction = "down") |>
    dplyr::ungroup() |>
    dplyr::summarise(
      dplyr::across(dplyr::contains(x@value@value_vec),\(x) sum(x,na.rm=TRUE))
      ,.by=c(date,!!!x@datum@group_quo)
    ) |>
    dplyr::mutate(
      year=lubridate::year(date)
    ) |>
    dplyr::relocate(date,year) |>
    dplyr::relocate(dplyr::any_of("missing_date_indicator"),.after=dplyr::last_col())

  return(out_dbi)

}


#' @title Current year-to-date over previous period year-to-date eeecution function
#' @name yoy_fn
#' @param x ti object
#' @description
#' [yoy_fn()] is the function that is called by [yoy()] when passed through to [calculate]
#' @seealso [yoy()] for the function's intent
#' @details
#' This is internal non exported function that is nested in ti class and is called upon when the underlying function is called
#' by [calculate]
#' This will return a dbi object that can converted to a tibble object with [dplyr::collect()]
#' @returns dbi object
#' @keywords internal
yoy_fn <- function(x){

  # create calendar
  # full_dbi <-  create_calendar(x)




  full_dbi <- create_full_dbi(x)
    # dplyr::select(-c(year))

  # create lag
  lag_dbi <-
    full_dbi |>
    dplyr::select(-c(year)) |>
    dbplyr::window_order(date,!!!x@datum@group_quo) |>
    dplyr::mutate(
      date_lag=dplyr::lead(date,n = !!x@fn@lag_n)
      ,!!x@value@new_column_name_vec:=!!x@value@value_quo
      # ,days_in_current_period=sql("day(last_day(date))")
      # , days_in_previous_period=sql("day(last_day(date_lag))")
      ,.by=c(!!!x@datum@group_quo)
    ) |>
    dplyr::select(-c(date,!!x@value@value_quo,missing_date_indicator))

  # bring tables together
  out_dbi <-
    dplyr::left_join(
    full_dbi
    ,lag_dbi
    ,by=dplyr::join_by(date==date_lag,!!!x@datum@group_quo)
  ) |>
    dplyr::relocate(date,year) |>
    dplyr::relocate(dplyr::any_of("missing_date_indicator"),.after=dplyr::last_col())


  return(out_dbi)

}

#' Year-to-date over full prior period year
#' @name ytdopy_fn
#' @param x ti object
#' @description
#' [ytdopy_fn()] is the function that is called by [ytdopy()] when passed through to [calculate]
#' @seealso [ytdopy()] for the function's intent
#' @details
#' This is internal non exported function that is nested in ti class and is called upon when the underlying function is called
#' by [calculate]
#' This will return a dbi object that can converted to a tibble object with[dplyr::collect()]
#' @returns dbi object
#' @keywords internal
ytdopy_fn <- function(x){

  # year-to-date table
  ytd_dbi <-
    x@datum@data |>
    dplyr::group_by(!!!x@datum@group_quo) |>
    ytd(.data = _,.date = !!x@datum@date_quo,.value = !!x@value@value_quo,calendar_type = x@datum@calendar_type) |>
    calculate() |>
    dplyr::select(-c(missing_date_indicator))

  #aggregate to prior year

  py_dbi <-
    x@datum@data |>
    dplyr::group_by(!!!x@datum@group_quo) |>
    yoy(.data = _,.date = !!x@datum@date_quo,.value = !!x@value@value_quo,calendar_type = x@datum@calendar_type,lag_n = x@fn@lag_n) |>
    calculate() |>
    dplyr::select(-c(missing_date_indicator,date,!!x@value@value_quo))

  # join together

 out_dbi <-  ytd_dbi |>
   dplyr::select(
     -c(!!x@value@value_quo)
   ) |>
    dplyr::left_join(
      py_dbi
      ,by=dplyr::join_by(year,!!!x@datum@group_quo)
    ) |>
   dplyr::relocate(date,year) |>
   dplyr::relocate(dplyr::any_of("missing_date_indicator"),.after=dplyr::last_col())

  return(out_dbi)
}


## quarter related functions -----------------

#' Quarter-to-date execution function
#' @name qtd_fn
#' @param x ti object
#' @description
#' [qtd_fn()] is the function that is called by [qtd()] when passed through to [calculate]
#' @seealso [qtd()] for the function's intent
#' @details
#' This is internal non exported function that is nested in ti class and is called upon when the underlying function is called
#' by [calculate]
#' This will return a dbi object that can converted to a tibble object with [dplyr::collect()]
#' @returns dbi object
#' @keywords internal
qtd_fn <- function(x){

# x <- fpaR::qtd(.data,.date = order_date,.value = margin,calendar_type = "standard")

  # full_dbi <-  create_calendar(x) |>
  #   dplyr::mutate(
  #     year=lubridate::year(date)
  #     ,quarter=lubridate::quarter(date)
  #     ,.before = 1
  #   )

  full_dbi <- create_full_dbi(x)

    out_dbi <- full_dbi |>
    dbplyr::window_order(date) |>
    dplyr::mutate(
      !!x@value@new_column_name_vec:=base::cumsum(!!x@value@value_quo)
      ,.by=c(year,quarter,!!!x@datum@group_quo)
    ) |>
    dplyr::ungroup() |>
    dplyr::relocate(date,year) |>
    dplyr::relocate(dplyr::any_of("missing_date_indicator"),.after=dplyr::last_col())

  return(out_dbi)

}

#' Previous quarter-to-date for tibble objects
#' @name pqtd_fn
#' @param x ti object
#' @description
#' [pqtd_fn()] is the function that is called by [pqtd()] when passed through to [calculate]
#' @seealso [pqtd()] for the function's intent
#' @details
#' This is internal non exported function that is nested in ti class and is called upon when the underlying function is called
#' by [calculate]
#' This will return a dbi object that can converted to a tibble object with [dplyr::collect()]
#' @returns dbi object
#' @keywords internal
pqtd_fn <- function(x){


 lag_n_vec <-  x@fn@lag_n |> rlang::as_label()

  # create calendar table

  # full_dbi <-  create_calendar(x) |>
  #   dplyr::mutate(
  #     year=lubridate::year(date)
  #     ,quarter=lubridate::quarter(date)
  #     ,.before = 1
  #   )

  full_dbi <- create_full_dbi(x)

  lag_dbi <- full_dbi |>
    dbplyr::window_order(date,quarter,year) |>
    dplyr::mutate(
      date_lag=as.Date(dplyr::sql(glue::glue("date + INTERVAL '3 months' * {lag_n_vec}")))
    ) |>
    dplyr::mutate(
      !!x@value@new_column_name_vec:=cumsum(!!x@value@value_quo)
      ,.by=c(year,quarter,!!!x@datum@group_quo)
    ) |>
    dplyr::select(-c(date,year,quarter,!!x@value@value_quo))


  # join tables together
  out_dbi <-   dplyr::full_join(
    full_dbi
    ,lag_dbi
    ,by=dplyr::join_by(date==date_lag,!!!x@datum@group_quo)
  ) |>
    dplyr::select(-c(!!x@value@value_quo)) |>
    dbplyr::window_order(date,year,quarter,!!!x@datum@group_quo) |>
    dplyr::group_by(date,year,quarter,!!!x@datum@group_quo) |>
    tidyr::fill(date,.direction = "down") |>
    dplyr::ungroup() |>
    dplyr::summarise(
      dplyr::across(dplyr::contains(x@value@value_vec),\(x) sum(x,na.rm=TRUE))
      ,.by=c(date,year,quarter,!!!x@datum@group_quo)
    ) |>
    dplyr::filter(
      !is.na(year)
    ) |>
    dplyr::relocate(date,year) |>
    dplyr::relocate(dplyr::any_of("missing_date_indicator"),.after=dplyr::last_col())

  return(out_dbi)

}


#' Current quarter to date over previous quarter-to-date for tibble objects
#' @name qoqtd_fn
#' @param x ti object
#' @description
#' [qoqtd_fn()] is the function that is called by [qoqtd()] when passed through to [calculate]
#' @seealso [qoqtd()] for the function's intent
#' @details
#' This is internal non exported function that is nested in ti class and is called upon when the underlying function is called
#' by [calculate]
#' This will return a dbi object that can converted to a tibble object with [dplyr::collect()]
#' @returns dbi object
#' @keywords internal
qoqtd_fn <- function(x){

  # ytd table

qtd_dbi <- qtd(.data=x@datum@data,.date=!!x@datum@date_quo,.value = !!x@value@value_quo,calendar_type = x@datum@calendar_type) |>
  qtd_fn()

  # pytd table

  pqtd_dbi <- pqtd(.data=x@datum@data,.date=!!x@datum@date_quo,.value = !!x@value@value_quo,calendar_type = x@datum@calendar_type,lag_n = x@fn@lag_n) |>
    pqtd_fn()

  # join tables together

  out_dbi <-   dplyr::full_join(
    qtd_dbi
    ,pqtd_dbi
    ,by=dplyr::join_by(date==date,year,quarter,!!!x@datum@group_quo)
  ) |>
    dplyr::group_by(date,year,quarter,!!!x@datum@group_quo) |>
    tidyr::fill(date,.direction = "down") |>
    dplyr::ungroup() |>
    dplyr::summarise(
      dplyr::across(dplyr::contains(x@value@value_vec),\(x) sum(x,na.rm=TRUE))
      ,.by=c(date,year,quarter,!!!x@datum@group_quo)
    ) |>
    dplyr::filter(
      !is.na(year)
    ) |>
    dplyr::relocate(date,year) |>
    dplyr::relocate(dplyr::any_of("missing_date_indicator"),.after=dplyr::last_col())

  return(out_dbi)

}


#' Quarter-over-quarter execution function
#' @name qoq_fn
#' @param x ti object
#' @description
#' [qoq_fn()] is the function that is called by [qoq()] when passed through to [calculate]
#' @seealso [qoq()] for the function's intent
#' @details
#' This is internal non exported function that is nested in ti class and is called upon when the underlying function is called
#' by [calculate]
#' This will return a dbi object that can converted to a tibble object with [dplyr::collect()]
#' @returns dbi object
#' @keywords internal
qoq_fn <- function(x){

  # create calendar
  # full_dbi <-  fpaR::create_calendar(x)

  full_dbi <- create_full_dbi(x)

  # create lag
  lag_dbi <- full_dbi |>
    dplyr::select(-c(year,quarter)) |>
    dbplyr::window_order(date,!!!x@datum@group_quo) |>
    dplyr::mutate(
      date_lag=dplyr::lead(date,n = !!x@fn@lag_n)
      ,!!x@value@new_column_name_vec:=!!x@value@value_quo
      ,.by=c(!!!x@datum@group_quo)
    ) |>
    dplyr::select(-c(date,!!x@value@value_quo,missing_date_indicator))

  # bring tables together
  out_dbi <-   dplyr::left_join(
    full_dbi
    ,lag_dbi
    ,by=dplyr::join_by(date==date_lag,!!!x@datum@group_quo)
  ) |>
    dplyr::relocate(date,year,quarter) |>
    dplyr::relocate(dplyr::any_of("missing_date_indicator"),.after=dplyr::last_col())

  return(out_dbi)
}



#' quarter-to-date over previous quarter execution function
#' @name qtdopq_fn
#' @param x ti object
#' @description
#' [qtdopq_fn()] is the function that is called by [qtdopq()] when passed through to [calculate]
#' @seealso [qtdopq()] for the function's intent
#' @details
#' This is internal non exported function that is nested in ti class and is called upon when the underlying function is called
#' by [calculate]
#' This will return a dbi object that can converted to a tibble object with [dplyr::collect()]
#' @returns dbi object
#' @keywords internal
qtdopq_fn <- function(x){

  # year-to-date table

  qtd_dbi <-
    x@datum@data |>
    dplyr::group_by(!!!x@datum@group_quo) |>
    qtd(.data = _,.date = !!x@datum@date_quo,.value = !!x@value@value_quo,calendar_type = x@datum@calendar_type) |>
    calculate() |>
    dplyr::select(-c(missing_date_indicator,!!x@value@value_quo))

  qoq_dbi <-
    x@datum@data |>
    dplyr::group_by(!!!x@datum@group_quo) |>
    qoq(.data = _,.date = !!x@datum@date_quo,.value = !!x@value@value_quo,calendar_type = x@datum@calendar_type,lag_n = x@fn@lag_n) |>
    calculate() |>
    dplyr::select(-c(missing_date_indicator,date,!!x@value@value_quo))

  # join together

  out_dbi <-
    qtd_dbi |>
    dplyr::left_join(
      qoq_dbi
      ,by=dplyr::join_by(year,quarter,!!!x@datum@group_quo)
    ) |>
    dplyr::relocate(date,year,quarter)

  return(out_dbi)
}

## month related functions -------------------------

#' Month-to-date execution function
#' @name mtd_fn
#' @param x ti object
#' @description
#' [mtd_fn()] is the function that is called by [mtd()] when passed through to [calculate]
#' @seealso [mtd()] for the function's intent
#' @details
#' This is internal non exported function that is nested in ti class and is called upon when the underlying function is called
#' by [calculate]
#' This will return a dbi object that can converted to a tibble object with [dplyr::collect()]
#' @returns dbi object
#' @keywords internal
mtd_fn <- function(x){

#
#   full_dbi <-  create_calendar(x) |>
#     dplyr::mutate(
#       year=lubridate::year(date)
#       ,month=lubridate::month(date)
#       ,.before = 1
#     )

  full_dbi <- create_full_dbi(x)

  out_dbi <- full_dbi |>
    dbplyr::window_order(date) |>
    dplyr::mutate(
      !!x@value@new_column_name_vec:=cumsum(!!x@value@value_quo)
      ,.by=c(year,month,!!!x@datum@group_quo)
    ) |>
    dplyr::relocate(date,year,month) |>
    dplyr::relocate(dplyr::any_of("missing_date_indicator"),.after=dplyr::last_col())

  return(out_dbi)

}



#' Previous month-to-date execution function
#' @name pmtd_fn
#' @param x ti object
#' @description
#' [pmtd_fn()] is the function that is called by [pmtd()] when passed through to [calculate]
#' @seealso [pmtd()] for the function's intent
#' @details
#' This is internal non exported function that is nested in ti class and is called upon when the underlying function is called
#' by [calculate]
#' This will return a dbi object that can converted to a tibble object with [dplyr::collect()]
#' @returns dbi object
#' @keywords internal
pmtd_fn <- function(x){


  # x <- pmtd(sales,order_date,quantity,calendar_type = "standard",lag_n = 1)


 lag_n_vec <-  x@fn@lag_n |>
   rlang::as_label()
  # create calendar table

  # full_dbi <-  create_calendar(x) |>
  #   dplyr::mutate(
  #     year=lubridate::year(date)
  #     ,month=lubridate::month(date)
  #     ,.before = 1
  #   ) |>
  #   dplyr::select(-c(missing_date_indicator))


  full_dbi <- create_full_dbi(x) |>
    dplyr::select(-c(missing_date_indicator))

  # create lag table
  lag_dbi <- full_dbi |>
    dbplyr::window_order(date) |>
    dplyr::mutate(
      date_lag=as.Date(dplyr::sql(glue::glue("date + INTERVAL '1 months' * {lag_n_vec}")))
      ,!!x@value@new_column_name_vec:=cumsum(!!x@value@value_quo)
      ,.by=c(year,month,!!!x@datum@group_quo)
    ) |>
    dplyr::select(-c(month,year,!!x@value@value_quo)) |>
    dplyr::mutate(
      month=lubridate::month(date_lag)
      ,year=lubridate::year(date_lag)
    ) |>
    dplyr::mutate(
      days_in_comparison_period=lubridate::day(date)
    ) |>
    dplyr::select(-c(year,month,date))

  # join tables together
  out_dbi <-  dplyr::full_join(
    full_dbi
    ,lag_dbi
    ,by=dplyr::join_by(date==date_lag,!!!x@datum@group_quo)
  ) |>
    dplyr::select(-c(!!x@value@value_quo)) |>
    dbplyr::window_order(date,!!!x@datum@group_quo) |>
    tidyr::fill(c(days_in_comparison_period,!!x@value@new_column_name_quo),.direction = "down") |>
    dplyr::summarise(
      !!x@value@new_column_name_vec:=max(!!x@value@new_column_name_quo,na.rm=TRUE)
      ,days_in_comparison_period=max(days_in_comparison_period,na.rm=TRUE)
      ,.by=c(date,year,month,!!!x@datum@group_quo)
    ) |>
    dplyr::relocate(date,year,month) |>
    dplyr::relocate(dplyr::any_of("missing_date_indicator"),.after=dplyr::last_col())


  return(out_dbi)


}


#' Current year to date over previous year-to-date for tibble objects
#' @name momtd_fn
#' @param x ti object
#' @description
#' [momtd_fn()] is the function that is called by [momtd()] when passed through to [calculate]
#' @seealso [momtd()] for the function's intent
#' @details
#' This is internal non exported function that is nested in ti class and is called upon when the underlying function is called
#' by [calculate]
#' This will return a dbi object that can converted to a tibble object with [dplyr::collect()]
#' @returns dbi object
#' @keywords internal
momtd_fn <- function(x){

  # mtd table

  mtd_dbi <- mtd(.data = x@datum@data,.date = !!x@datum@date_quo,.value = !!x@value@value_quo,calendar_type = x@datum@calendar_type) |>
    calculate()

  # pmtd table

  pmtd_dbi <- pmtd(.data = x@datum@data,.date = !!x@datum@date_quo,.value = !!x@value@value_quo,calendar_type = x@datum@calendar_type,lag_n = x@fn@lag_n) |>
    calculate()

  # join tables together

  out_dbi <-
    dplyr::full_join(
    mtd_dbi
    ,pmtd_dbi
    ,by=dplyr::join_by(date==date,year,month,!!!x@datum@group_quo)
  ) |>
    dplyr::summarise(
      dplyr::across(dplyr::contains(x@value@value_vec),\(x) sum(x,na.rm=TRUE))
      ,.by=c(date,year,month,!!!x@datum@group_quo)
    ) |>
    dplyr::relocate(date,year,month)


  return(out_dbi)

}


#' month-over-month execution function
#' @name mom_fn
#' @param x ti object
#' @description
#' [mom_fn()] is the function that is called by [mom()] when passed through to [calculate]
#' @seealso [mom()] for the function's intent
#' @details
#' This is internal non exported function that is nested in ti class and is called upon when the underlying function is called
#' by [calculate]
#' This will return a dbi object that can converted to a tibble object with [dplyr::collect()]
#' @returns dbi object
#' @keywords internal
mom_fn <- function(x){

  # full_dbi <-  create_calendar(x)

  full_dbi <- create_full_dbi(x)


  # create lag
  lag_dbi <- full_dbi |>
    dplyr::select(-c(year,quarter,month)) |>
    dbplyr::window_order(date,!!!x@datum@group_quo) |>
    dplyr::mutate(
      date_lag=dplyr::lead(date,n = !!x@fn@lag_n)
      ,!!x@value@new_column_name_vec:=!!x@value@value_quo
      # ,days_in_current_period=sql("day(last_day(date))")
      # ,days_in_previous_period=sql("day(last_day(date_lag))")
      ,.by=c(!!!x@datum@group_quo)
    ) |>
    dplyr::select(-c(date,!!x@value@value_quo,missing_date_indicator))



  # bring tables together
  out_dbi <-   dplyr::left_join(
    full_dbi
    ,lag_dbi
    ,by=dplyr::join_by(date==date_lag,!!!x@datum@group_quo)
  ) |>
    dplyr::relocate(date,year,month) |>
    dplyr::relocate(dplyr::any_of("missing_date_indicator"),.after=dplyr::last_col())

  return(out_dbi)

}

#' Month-over-month vs. prior full momth execution function
#' @name mtdopm_fn
#' @param x ti object
#' @description
#' [mtdopm_fn()] is the function that is called by [mtdopm()] when passed through to [calculate]
#' @seealso [mtdopm()] for the function's intent
#' @details
#' This is internal non exported function that is nested in ti class and is called upon when the underlying function is called
#' by [calculate]
#' This will return a dbi object that can converted to a tibble object with [dplyr::collect()]
#' @returns dbi object
#' @keywords internal
mtdopm_fn <- function(x){


  # year-to-date table
  mtd_dbi <-
    x@datum@data |>
    dplyr::group_by(!!!x@datum@group_quo) |>
    mtd(.data = _,.date = !!x@datum@date_quo,.value = !!x@value@value_quo,calendar_type = x@datum@calendar_type) |>
    calculate() |>
    dplyr::select(
      -c(missing_date_indicator,!!x@value@value_quo)
    )

  #aggregate to prior year

  pm_dbi <-
    x@datum@data |>
    dplyr::group_by(!!!x@datum@group_quo) |>
    mom(.data = _,.date = !!x@datum@date_quo,.value = !!x@value@value_quo,calendar_type = x@datum@calendar_type,lag_n = x@fn@lag_n) |>
    calculate() |>
    dplyr::select(-c(missing_date_indicator,date,!!x@value@value_quo))

  # join together

 out_dbi <-
   mtd_dbi |>
    dplyr::left_join(
      pm_dbi
      ,by=dplyr::join_by(year,month,!!!x@datum@group_quo)
    ) |>
   dplyr::relocate(date,year,month)

  return(out_dbi)


}




## week related functions-----------------

#' Week-to-date execution fucntion
#' @name wtd_fn
#' @param x ti object
#' @description
#' [wtd_fn()] is the function that is called by [wtd()] when passed through to [calculate]
#' @seealso [wtd()] for the function's intent
#' @details
#' This is internal non exported function that is nested in ti class and is called upon when the underlying function is called
#' by [calculate]
#' This will return a dbi object that can converted to a tibble object with [dplyr::collect()]
#' @returns dbi object
#' @keywords internal
wtd_fn <- function(x){

  # full_dbi <-  create_calendar(x) |>
  #   dplyr::mutate(
  #     year=lubridate::year(date)
  #     ,month=lubridate::month(date)
  #     ,week=dplyr::sql("DATE_PART('week',date)")
  #     ,.before = 1
  #   )

  full_dbi <- create_full_dbi(x)



  out_dbi <- full_dbi |>
    dbplyr::window_order(date) |>
    dplyr::mutate(
      !!x@value@new_column_name_vec:=cumsum(!!x@value@value_quo)
      ,.by=c(year,month,week,!!!x@datum@group_quo)
    ) |>
    dplyr::relocate(date,year,month,week) |>
    dplyr::relocate(dplyr::any_of("missing_date_indicator"),.after=dplyr::last_col())

  return(out_dbi)

}





#' Previous month-to-date for tibble objects
#' @name pwtd_fn
#' @param x ti object
#' @description
#' [pwtd_fn()] is the function that is called by [pwtd()] when passed through to [calculate]
#' @seealso [pwtd()] for the function's intent
#' @details
#' This is internal non exported function that is nested in ti class and is called upon when the underlying function is called
#' by [calculate]
#' This will return a dbi object that can converted to a tibble object with [dplyr::collect()]
#' @returns dbi object
#' @keywords internal
pwtd_fn <- function(x){

 lag_n_vec <-  x@fn@lag_n |> rlang::as_label()

  # create calendar table

  # full_dbi <-  create_calendar(x) |>
  #   dplyr::mutate(
  #     year=lubridate::year(date)
  #     ,month=lubridate::month(date)
  #     ,week=dplyr::sql("DATE_PART('week',date)")
  #     ,.before = 1
  #   )



  full_dbi <- create_full_dbi(x) |>
    dplyr::select(-c(missing_date_indicator))

  # create lag table
  lag_dbi <- full_dbi|>
    dbplyr::window_order(date) |>
    dplyr::mutate(
      date_lag=as.Date(dplyr::sql(glue::glue("date + INTERVAL '1 weeks' * {lag_n_vec}")))
      ,!!x@value@new_column_name_vec:=cumsum(!!x@value@value_quo)
      # ,week_lag=dplyr::sql("DATE_PART('week',date_lag)")
      ,.by=c(year,month,week,!!!x@datum@group_quo)
    ) |>
    dplyr::select(-c(date,month,year,week,!!x@value@value_quo))


  # join tables together
  out_dbi <-
    dplyr::full_join(
    full_dbi
    ,lag_dbi
    ,by=dplyr::join_by(date==date_lag,!!!x@datum@group_quo)
  ) |>
    dplyr::select(-c(!!x@value@value_quo)) |>
    dbplyr::window_order(date) |>
    dplyr::group_by(date,year,month,!!!x@datum@group_quo) |>
    tidyr::fill(date,.direction = "down") |>
    dplyr::ungroup() |>
    dplyr::summarise(
      dplyr::across(dplyr::contains(x@value@value_vec),\(x) sum(x,na.rm=TRUE))
      ,.by=c(date,year,month,!!!x@datum@group_quo)
    ) |>
    dplyr::relocate(date,year,month)

  return(out_dbi)

}


#' Current year to date over previous year-to-date for tibble objects
#' @name wowtd_fn
#' @param x ti object
#' @description
#' [wowtd_fn()] is the function that is called by [wowtd()] when passed through to [calculate]
#' @seealso [wowtd()] for the function's intent
#' @details
#' This is internal non exported function that is nested in ti class and is called upon when the underlying function is called
#' by [calculate]
#' This will return a dbi object that can converted to a tibble object with [dplyr::collect()]
#' @returns dbi object
#' @keywords internal
wowtd_fn <- function(x){



  # ytd table
  wtd_dbi <-
    x@datum@data |>
    dplyr::group_by(!!!x@datum@group_quo) |>
    wtd(.data = _,.date = !!x@datum@date_quo,.value = !!x@value@value_quo,calendar_type = x@datum@calendar_type) |>
    calculate()

  #pytd table


  pwtd_dbi <-
    x@datum@data |>
    dplyr::group_by(!!!x@datum@group_quo) |>
    pwtd(.data = _,.date = !!x@datum@date_quo,.value = !!x@value@value_quo,calendar_type = x@datum@calendar_type,lag_n=x@fn@lag_n) |>
    calculate()
    # dplyr::rename(
    #   !!x@value@second_column_name:=!!x@value@new_column_name_quo
    # )

  # join tables together

  out_tbl <-
    dplyr::left_join(
    wtd_dbi
    ,pwtd_dbi
    ,by=dplyr::join_by(date,year,month,!!!x@datum@group_quo)
  ) |>
    dplyr::relocate(date,year,month,week) |>
    dplyr::relocate(dplyr::any_of("missing_date_indicator"),.after=dplyr::last_col())

  return(out_tbl)

}


#' Week-over-week execution function
#' @name wow_fn
#' @param x ti object
#' @description
#' [wow_fn()] is the function that is called by [wow()] when passed through to [calculate]
#' @seealso [wow()] for the function's intent
#' @details
#' This is internal non exported function that is nested in ti class and is called upon when the underlying function is called
#' by [calculate]
#' This will return a dbi object that can converted to a tibble object with [dplyr::collect()]
#' @returns dbi object
#' @keywords internal
wow_fn <- function(x){


  # full_dbi <-  create_calendar(x)




  full_dbi <- create_full_dbi(x)

  lag_dbi <- full_dbi|>
    dplyr::select(-c(year,quarter,month,week)) |>
    dbplyr::window_order(date) |>
    dplyr::mutate(
      date_lag=dplyr::lead(date,n = !!x@fn@lag_n)
      ,!!x@value@new_column_name_vec:=!!x@value@value_quo
      ,.by=c(!!!x@datum@group_quo)
    ) |>
    dplyr::select(-c(date,!!x@value@value_quo,missing_date_indicator))


  out_dbi <-
    dplyr::left_join(
    full_dbi
    ,lag_dbi
    ,by=dplyr::join_by(date==date_lag,!!!x@datum@group_quo)
  ) |>
    dplyr::relocate(date,year,month,week) |>
    dplyr::relocate(dplyr::any_of("missing_date_indicator"),.after=dplyr::last_col())

  return(out_dbi)

}

#' Year-over-year
#' @name wtdopw_fn
#' @param x ti object
#' @description
#' [wtdopw_fn()] is the function that is called by [wtdopw()] when passed through to [calculate]
#' @seealso [wtdopw()] for the function's intent
#' @details
#' This is internal non exported function that is nested in ti class and is called upon when the underlying function is called
#' by [calculate]
#' This will return a dbi object that can converted to a tibble object with [dplyr::collect()]
#' @returns dbi object
#' @keywords internal
wtdopw_fn <- function(x){

  # year-to-date table
  wtd_dbi <-
    x@datum@data |>
    dplyr::group_by(!!!x@datum@group_quo) |>
    wtd(.data = _,.date = !!x@datum@date_quo,.value = !!x@value@value_quo,calendar_type = x@datum@calendar_type) |>
    calculate() |>
    dplyr::select(-c(missing_date_indicator,!!x@value@value_quo))

  #aggregate to prior year

  pw_dbi <-
    x@datum@data |>
    dplyr::group_by(!!!x@datum@group_quo) |>
    wow(.data = _,.date = !!x@datum@date_quo,.value = !!x@value@value_quo,calendar_type = x@datum@calendar_type,lag_n = x@fn@lag_n) |>
    calculate() |>
    dplyr::select(-c(missing_date_indicator,date,!!x@value@value_quo))

  # join together

  out_dbi <-
    wtd_dbi |>
    dplyr::left_join(
      pw_dbi
      ,by=dplyr::join_by(year,month,week,!!!x@datum@group_quo)
    ) |>
    dplyr::relocate(date,year,month,week)

  return(out_dbi)

}


## all to date related functions ----------------

#' All-to-date execution function
#' @name atd_fn
#' @param x ti object
#' @description
#' [atd_fn()] is the function that is called by [atd()] when passed through to [calculate]
#' @seealso [atd()] for the function's intent
#' @details
#' This is internal non exported function that is nested in ti class and is called upon when the underlying function is called
#' by [calculate]
#' This will return a dbi object that can converted to a tibble object with [dplyr::collect()]
#' @returns dbi object
#' @keywords internal
atd_fn <- function(x){

  # full_dbi <-  create_calendar(x)


  full_dbi <- create_full_dbi(x)

  out_dbi<- full_dbi |>
    dbplyr::window_order(date) |>
    dplyr::mutate(
      !!x@value@new_column_name_vec:=cumsum(!!x@value@value_quo)
      ,.by=c(!!!x@datum@group_quo)
    ) |>
    dplyr::relocate(date) |>
    dplyr::relocate(dplyr::any_of("missing_date_indicator"),.after=dplyr::last_col())
  return(out_dbi)
}


## day related functions --------------------------

#' Day-over-day execution function
#' @name dod_fn
#' @param x ti object
#' @description
#' [dod_fn()] is the function that is called by [dod()] when passed through to [calculate]
#' @seealso [dod()] for the function's intent
#' @details
#' This is internal non exported function that is nested in ti class and is called upon when the underlying function is called
#'by [calculate]
#' This will return a dbi object that can converted to a tibble object with [dplyr::collect()]
#' @returns dbi object
#' @keywords internal
dod_fn <- function(x){

  # full_dbi <-  create_calendar(x)
  full_dbi <- create_full_dbi(x)

  lag_dbi <- full_dbi |>
    dplyr::select(-c(year,quarter,month,week,day)) |>
    dbplyr::window_order(date) |>
    dplyr::mutate(
      date_lag=dplyr::lead(date,n=!!x@fn@lag_n)
      ,!!x@value@new_column_name_vec:=!!x@value@value_quo
      ,.by=c(!!!x@datum@group_quo)
    ) |>
    dplyr::select(-c(date,!!x@value@value_quo,missing_date_indicator))

  out_dbi <-   dplyr::left_join(
    full_dbi
    ,lag_dbi
    ,by=dplyr::join_by(date==date_lag,!!!x@datum@group_quo)
  ) |>
    dplyr::relocate(date) |>
    dplyr::relocate(dplyr::any_of("missing_date_indicator"),.after=dplyr::last_col())

  return(out_dbi)

}



utils::globalVariables(c("missing_date_indicator","pp_missing_dates_cnt","pp_extra_dates_cnt","days_in_comparison_period"))
