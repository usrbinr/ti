
#' @title Current period year-to-date
#' @name ytd
#' @param .data tibble or dbi object (either grouped or ungrouped)
#' @param .date the date column to group by
#' @param .value the value column to summarize
#' @param calendar_type select either 'standard' or '5-5-4' calendar, see 'Details' for additional information
#'
#' @description
#' -  For each group, [ytd()]  will create the running annual sum of a value based on the calendar type specified
#' -  The function returns a ti object which prints out the summary of steps and actions that will take to create the calendar table and calculations
#' -  Use [calculate] to return the results
#' @details
#' -  This function creates a complete calendar object that fills in any missing days, weeks, months, quarters, or years
#' -  If you provide a grouped object with [dplyr::group_by()], it will generate a complete calendar for each group
#' -  The function creates a `ti` object, which pre-processes the data and arguments for further downstream functions
#'
#' **standard calendar**
#' -  The standard calendar splits the year into 12 months (with 28–31 days each) and uses a 7-day week
#' -  It automatically accounts for leap years every four years to match the Gregorian calendar
#'
#' **5-5-4 calendar**
#' -  The 5-5-4 calendar divides the fiscal year into 52 weeks (occasionally 53), organizing each quarter into two 5-week periods and one 4-week period.
#' -  This system is commonly used in retail and financial reporting
#' @family time_intelligence
#' @returns ti object
#' @export
#'
#' @examples
#' library(contoso)
#' ytd(sales,.date=order_date,.value=quantity,calendar_type="standard")
ytd <- function(.data,.date,.value,calendar_type='standard'){



  # assigns inputs to ytd_tbl class

  x <- ti(
    datum(
      data                 = .data
      ,calendar_type       = calendar_type
      ,date_vec            = rlang::as_label(rlang::enquo(.date))
    )
    ,time_unit             = time_unit("day")
    ,action                = action(
      value                = c("aggregate")
      ,method              = "This creates a daily {.code cumsum()} of the {cli::col_cyan('current year')}
                             {.field {value_chr}} from the start of the {cli::col_yellow({calendar_type})} calendar
                              year to the end of the year"
        )
    ,value = value(
      value_vec            =  rlang::as_label(rlang::enquo(.value))
      ,new_column_name_vec     = "ytd"
      )
    ,fn=fn(
      new_date_column_name = c("date","year")
      ,lag_n               = NA_integer_
      ,fn_exec             = ytd_fn
      ,fn_name             = "ytd"
      ,fn_long_name        = "Year-to-date"
    )
  )

  return(x)

}


#' @title Previous period year-to-date
#' @name pytd
#' @inheritParams ytd
#' @param lag_n the number of periods to lag
#' @description
#' -  For each group, [pytd()]  will create the running annual sum of a value based on the calendar type for the previous year compared to the current year calendar date
#' -  If no period exists, it will return `NA`
#' -  The function returns a ti object which prints out the summary of steps and actions that will take to create the calendar table and calculations
#' -  Use [calculate] to return the results
#' @inherit ytd details
#' @family time_intelligence
#' @returns ti object
#' @export
#'
#' @examples
#' library(contoso)
#' pytd(sales,.date=order_date,.value=quantity,calendar_type="standard",lag_n=1)
pytd <- function(.data,.date,.value,calendar_type='standard',lag_n){


  # assigns inputs to ytd_tbl class
  out <- ti(
    datum(
      data                  = .data
      ,calendar_type        = calendar_type
      ,date_vec             = rlang::as_label(rlang::enquo(.date))
    )
    ,time_unit              = time_unit("day")
    ,action                 = action(
      value                 = c("aggregate","shift")
      ,method               = "This creates a daily {.code cumsum()} of the {cli::col_br_cyan('previous year')}
                             {.field {value_chr}} from the start of the {cli::col_yellow({calendar_type})} calendar
                             year to the end of the year"
        )
    ,value=value(
      value_vec             = rlang::as_label(rlang::enquo(.value))
      ,new_column_name_vec      = "pytd"
    )
    ,fn=fn(
      lag_n                 = lag_n
      ,new_date_column_name = c("date","year")
      ,fn_exec              = pytd_fn
      ,fn_name              = "pytd"
      ,fn_long_name         = "Previous year-to-date"
      ,shift                = "year"
    )
  )

  return(out)
}


#' @title Current period year-to-date compared to previous period year-to-date
#' @name yoytd
#' @inheritParams pytd
#' @description
#' -  This calculates the annual cumulative sum of targeted value and compares it with the previous period's annual cumulative to date sum using a standard or 5-5-4 calendar respecting
#' any groups that are passed through with [dplyr::group_by()]
#' -  Use [calculate] to return the results
#' @inherit ytd details
#' @family time_intelligence
#' @returns ti object
#' @export
#'
#' @examples
#' library(contoso)
#' yoytd(sales,.date=order_date,.value=quantity,calendar_type="standard",lag_n=1)
yoytd <- function(.data,.date,.value,calendar_type='standard',lag_n){


  # Vali.date inputs

  # assigns inputs to yoytd class

  x <- ti(
    datum(
      data                 = .data
      ,calendar_type       = calendar_type
      ,date_vec            =  rlang::as_label(rlang::enquo(.date))
    )
    ,time_unit             = time_unit("day")
    ,action                = action(
      value                = c("aggregate","shift","compare")
      ,method              = "This creates a daily {.code cumsum()} of the {cli::col_br_cyan('previous year')}
                             {.field {value_chr}} and {.strong compares} it with the daily {.code cumsum()}
                             {cli::col_cyan('current year')} {.field {value_chr}} from the start of the
                             {cli::col_yellow({calendar_type})} calendar year to the end of the year"
    )
    ,value=value(
      value_vec             = rlang::as_label(rlang::enquo(.value))
      ,new_column_name_vec      = "ytd"
    )
    ,fn=fn(
      lag_n                 = lag_n
      ,new_date_column_name = c("date","year")
      ,fn_exec              = yoytd_fn
      ,fn_name              = "yoytd"
      ,fn_long_name         = "Year-to-date over previous year-to-date"
      ,shift                = "year"
      ,compare              = "Previous year-to-date"
    )
  )

  return(x)
}


#' @title Current full period year over previous full period year
#' @name yoy
#' @inheritParams pytd
#' @description
#' -  This calculates the full year value compared to the previous year value respecting
#' any groups that are passed through with [dplyr::group_by()]
#'
#' -  Use [calculate] to return the results
#' @inherit ytd details
#' @family time_intelligence
#'
#' @returns ti object
#' @export
#'
#' @examples
#' library(contoso)
#' yoy(sales,.date=order_date,.value=quantity,calendar_type='standard',lag_n=1)
yoy <- function(.data,.date,.value,calendar_type='standard',lag_n=1){

  out <- ti(
    datum(
      data                 = .data
      ,calendar_type       = calendar_type
      ,date_vec            = rlang::as_label(rlang::enquo(.date))
    )
    ,time_unit             = time_unit("year")
    ,action                = action(
      value                = c("aggregate","shift","compare")
      ,method              = "This creates a full year {.code sum()} of the {cli::col_br_cyan('previous year')}
                             {.field {value_chr}} and {.strong compares} it with the full year {.code sum()}
                             {cli::col_cyan('current year')} {.field {value_chr}} from the start of the
                             {cli::col_yellow({calendar_type})} calendar year to the end of the year"
    )

    ,value=value(
      value_vec             = rlang::as_label(rlang::enquo(.value))
      ,new_column_name_vec      = "yoy"
    )
    ,fn=fn(
      new_date_column_name  = c("date","year")
      ,lag_n                = lag_n
      ,fn_exec              = yoy_fn
      ,fn_name              = "yoy"
      ,fn_long_name         = "Year over year"
      ,shift                = "year"
      ,compare              = "previous year"
    )
  )

  return(out)

}

#' @title Current period year-to-date compared to full previous period
#' @name ytdopy
#' @inheritParams pytd
#' @description
#' -  This calculates the full year value compared to the previous year value using a standard or 5-5-4 calendar respecting
#' any groups that are passed through with [dplyr::group_by()]
#'
#' -  Use [calculate] to return the results
#' @inherit ytd details
#' @family time_intelligence
#' @returns ti object
#' @export
#' @examples
#' library(contoso)
#' ytdopy(sales,.date=order_date,.value=quantity,calendar_type='standard',lag_n=1)
ytdopy <- function(.data,.date,.value,calendar_type='standard',lag_n=1){

  out <- ti(
    datum(
      data                 = .data
      ,calendar_type       = calendar_type
      ,date_vec            = rlang::as_label(rlang::enquo(.date))
    )
    ,time_unit             = time_unit("day")
    ,action                = action(
      value                = c("aggregate","shift","compare")
      ,method              = "This creates a daily {.code cumsum()} of the {cli::col_cyan('current year')}
                             {.field {value_chr}} and {.strong compares} it with the full year {.code sum()}
                             {cli::col_br_cyan('previous year')} {.field {value_chr}} from the start of the
                             {cli::col_yellow({calendar_type})} calendar year to the end of the year"
    )


    ,value=value(
      value_vec             = rlang::as_label(rlang::enquo(.value))
      ,new_column_name_vec      = "ytd"
    )

    ,fn=fn(
      new_date_column_name  = c("date","year")
      ,lag_n                = lag_n
      ,fn_exec              = ytdopy_fn
      ,fn_name              = "ytdopy"
      ,fn_long_name         = "Year-to-date over full previous year"
      ,compare              = "previous year"
      ,shift                = "year"
    )
  )

  return(out)

}

## quarter related ti_tbl-----------------------------

#' @title  Current period quarter-to-date
#' @name qtd
#' @inheritParams ytd
#' @description
#' This calculates the full year value compared to the previous year value using a standard or 5-5-4 calendar respecting
#' any groups that are passed through with [dplyr::group_by()]
#'
#' Use [calculate] to return the results
#' @inherit ytd details
#' @family time_intelligence
#' @returns ti object
#' @export
#'
#' @examples
#' library(contoso)
#' qtd(sales,.date=order_date,.value=quantity,calendar_type="standard")
qtd <- function(.data,.date,.value,calendar_type='standard'){


  # Aggregate data based on provided time unit

  out <- ti(
    datum(
      data                       = .data
      ,calendar_type             = calendar_type
      ,date_vec                  =  rlang::as_label(rlang::enquo(.date))
    )
    ,time_unit                   = time_unit("day")
    ,action = action(
      value                      = c("aggregate")
      ,method                    = "This creates a daily {.code cumsum()} of the {cli::col_cyan('current quarter')}
                                   {.field {value_chr}} from the start of the {cli::col_yellow({calendar_type})} calendar
                                   quarter to the end of the quarter"
        )
    ,value = value(
      value_vec                  = rlang::as_label(rlang::enquo(.value))
      ,new_column_name_vec           = "qtd"
    )
    ,fn=fn(
      new_date_column_name       = c("year","quarter")
      ,lag_n                     = NA_integer_
      ,fn_exec                   = qtd_fn
      ,fn_name                   = "qtd"
      ,fn_long_name              = "Quarter-to-date"
    )
  )


  return(out)
}


#' @title Prior period quarter-to-date
#' @name pqtd
#' @inheritParams pytd
#' @description
#' -  This calculates the quarterly cumulative sum of targeted value using a standard or 5-5-4 calendar respecting
#' any groups that are passed through with [dplyr::group_by()]
#'
#' use [calculate] to return the results
#' @inherit ytd details
#' @family time_intelligence
#' @returns ti object
#' @export
#'
#' @examples
#' library(contoso)
#' pqtd(sales,.date=order_date,.value=quantity,calendar_type="standard",lag_n=1)
pqtd <- function(.data,.date,.value,calendar_type='standard',lag_n=1){

  # Aggregate data based on provided time unit

  out <- ti(
    datum(
      data                        = .data
      ,calendar_type              = calendar_type
      ,date_vec                   =  rlang::as_label(rlang::enquo(.date))
    )
    ,time_unit                    = time_unit("day")
    ,action = action(
      value                       = c("aggregate","shift")
      ,method                     = "This creates a daily {.code cumsum()} of the {cli::col_br_cyan('previous quarter')}
                                    {.field {value_chr}} from the start of the {cli::col_yellow({calendar_type})} calendar
                                    quarter to the end of the quarter"
        )
    ,value = value(
      value_vec                  = rlang::as_label(rlang::enquo(.value))
      ,new_column_name_vec           = "pqtd"
    )
    ,fn=fn(
      new_date_column_name       = c("date","year","quarter")
      ,lag_n                     = lag_n
      ,fn_exec                   = pqtd_fn
      ,fn_name                   = "pqtd"
      ,fn_long_name              = "Prior quarter-to-date"
      ,shift                     = "quarter"
    )
  )


  return(out)
}


#' @title Current period quarter-to-date compared to previous period quarter-to-date
#' @name qoqtd
#' @inheritParams pytd
#' @description
#' -  This calculates the annual cumulative sum of targeted value using a standard or 5-5-4 calendar respecting
#' any groups that are passed through with [dplyr::group_by()]
#'
#' -  Use [calculate] to return the results
#' @inherit ytd details
#' @family time_intelligence
#' @returns ti object
#' @export
#'
#' @examples
#' library(contoso)
#' qoqtd(sales,.date=order_date,.value=quantity,calendar_type="standard",lag_n=1)
qoqtd <- function(.data,.date,.value,calendar_type='standard',lag_n=1){

  # assigns inputs to yoytd class

  out <- ti(
    datum(
      data                 = .data
      ,calendar_type       = calendar_type
      ,date_vec            = rlang::as_label(rlang::enquo(.date))
    )
    ,time_unit             = time_unit("day")
    ,action                = action(
      value                = c("aggregate","shift","compare")
      ,method              = "This creates a daily {.code cumsum()} of the {cli::col_br_cyan('previous quarter')}
                             {.field {value_chr}} and {.strong compares} it with the daily {.code cumsum()}
                             {cli::col_cyan('current quarter')} {.field {value_chr}} from the start of the
                             {cli::col_yellow({calendar_type})} calendar quarter to the end of the quarter"
    )
    ,value=value(
      value_vec             = rlang::as_label(rlang::enquo(.value))
      ,new_column_name_vec      = "pqtd"
    )
    ,fn=fn(
      lag_n                 = lag_n
      ,new_date_column_name = c("date","year","quarter")
      ,fn_exec              = qoqtd_fn
      ,fn_name              = "qoqtd"
      ,fn_long_name         = "Current period quarter-to-date compared to previous period quarter-to-date"
      ,shift                = "quarter"
      ,compare              = "pqtd"
    )
  )

  return(out)
}


#' @title Current period quarter-to-date over previous period quarter
#' @name qtdopq
#' @inheritParams pytd
#' @description
#' -  This calculates the quarterly cumulative sum of a targeted value and compares it with the previous full quarter's total value respecting
#' any groups that are passed through with [dplyr::group_by()]
#' -  Use [calculate] to return the results
#' @inherit ytd details
#' @family time_intelligence
#' @returns ti object
#' @export
#'
#' @examples
#' library(contoso)
#' qtdopq(sales,.date=order_date,.value=quantity,calendar_type='standard',lag_n=1)
qtdopq <- function(.data,.date,.value,calendar_type='standard',lag_n=1){

  out <- ti(
    datum(
      data                 = .data
      ,calendar_type       = calendar_type
      ,date_vec            = rlang::as_label(rlang::enquo(.date))
    )
    ,time_unit             = time_unit("day")
    ,action                = action(
      value                = c("aggregate","shift","compare")
      ,method              = "This creates a daily {.code cumsum()} of the {cli::col_cyan('current quarter')}
                             {.field {value_chr}} and {.strong compares} it with the full quarter {.code sum()}
                             {cli::col_br_cyan('previous quarter')} {.field {value_chr}} from the start of the
                             {cli::col_yellow({calendar_type})} calendar quarter to the end of the quarter"
    )

    ,value=value(
      value_vec            = rlang::as_label(rlang::enquo(.value))
      ,new_column_name_vec     = "qtd"
    )
    ,fn=fn(
      new_date_column_name = c("date","year","quarter")
      ,lag_n               = lag_n
      ,fn_exec             = qtdopq_fn
      ,fn_name             = "qtdopq"
      ,fn_long_name        = "Quarter-to-date over full previous quarter"
      ,shift               = "quarter"
      ,compare             = "previous full quarter"
    )
  )
  return(out)
}


#' @title Current full period quarter over previous full period quarter
#' @name qoq
#' @description
#' -  This calculates the full quarter value compared to the previous quarter value respecting
#' any groups that are passed through with [dplyr::group_by()]
#' -  Use [calculate] to return the results
#'
#' @inheritParams pytd
#' @family time_intelligence
#' @returns ti object
#' @export
#'
#' @examples
#' library(contoso)
#' qoq(sales,.date=order_date,.value=quantity,calendar_type='standard',lag_n=1)
qoq <- function(.data,.date,.value,calendar_type='standard',lag_n=1){

  out <- ti(
    datum(
      data                 = .data
      ,calendar_type       = calendar_type
      ,date_vec            = rlang::as_label(rlang::enquo(.date))
    )
    ,time_unit             = time_unit("quarter")
    ,action                = action(
      value                = c("aggregate","shift","compare")
      ,method              = "This creates a full quarter {.code sum()} of the {cli::col_br_cyan('previous quarter')}
                             {.field {value_chr}} and {.strong compares} it with the full quarter {.code sum()}
                             {cli::col_cyan('current quarter')} {.field {value_chr}} from the start of the
                             {cli::col_yellow({calendar_type})} calendar quarter to the end of the quarter"
    )
    ,value=value(
      value_vec             = rlang::as_label(rlang::enquo(.value))
      ,new_column_name_vec      = "qoq"
    )
    ,fn=fn(
      lag_n                 = lag_n
      ,new_date_column_name = c("date","year","quarter")
      ,fn_exec              = qoq_fn
      ,fn_name              = "qoq"
      ,fn_long_name         = "Quarter over quarter"
      ,shift                = "quarter"
      ,compare              = "previous full quarter"
    )
  )



  return(out)
}



## month related ti_tbl-------------------

#' @title Current period month-to-date
#' @name mtd
#' @inheritParams ytd
#' @description
#' This calculates the monthly cumulative sum of targeted value using a standard or 5-5-4 calendar respecting
#' any groups that are passed through with [dplyr::group_by()]
#'
#' Use [calculate] to return the results
#' @inherit ytd details
#' @family time_intelligence
#' @returns ti object
#' @export
#' @examples
#' library(contoso)
#' mtd(sales,.date=order_date,.value=quantity,calendar_type="standard")
mtd <- function(.data,.date,.value,calendar_type='standard'){

    out <- ti(
      datum(
        data                 = .data
        ,calendar_type       = calendar_type
        ,date_vec            = rlang::as_label(rlang::enquo(.date))
      )
      ,time_unit             = time_unit("day")
      ,action                = action(
      value                  = c("aggregate")
      ,method                = "This creates a daily {.code cumsum()} of the {cli::col_cyan('current month')}
                             {.field {value_chr}} from the start of the {cli::col_yellow({calendar_type})} calendar
                              month to the end of the month"
        )
      ,value=value(
        value_vec            = rlang::as_label(rlang::enquo(.value))
        ,new_column_name_vec     = "mtd"
      )
      ,fn=fn(
        new_date_column_name = c("date","year","month")
       ,lag_n                = NA_integer_
       ,fn_exec              = mtd_fn
       ,fn_name              = "mtd"
      ,fn_long_name          = "Month-to-date"
      )
    )

  return(out)

}



#' @title Previous period month-to-date
#' @name pmtd
#' @inheritParams pytd
#' @description
#' This calculates the monthly cumulative sum of targeted value using a standard or 5-5-4 calendar respecting
#' any groups that are passed through with [dplyr::group_by()]
#'
#' Use [calculate] to return the results
#' @inherit ytd details
#' @family time_intelligence
#' @returns ti object
#' @export
#' @examples
#' library(contoso)
#' pmtd(sales,.date=order_date,.value=quantity,calendar_type="standard",lag_n=1)
pmtd <- function(.data,.date,.value,calendar_type='standard',lag_n=1){

  out <- ti(
    datum(
      data                 = .data
      ,calendar_type       = calendar_type
      ,date_vec            = rlang::as_label(rlang::enquo(.date))
    )
    ,time_unit             = time_unit("day")
    ,action                = action(
      value                = c("aggregate","shift")
      ,method              = "This creates a daily {.code cumsum()} of the {cli::col_br_cyan('previous month')}
                             {.field {value_chr}} from the start of the {cli::col_yellow({calendar_type})} calendar
                             month to the end of the month"
        )
    ,value=value(
      value_vec            = rlang::as_label(rlang::enquo(.value))
      ,new_column_name_vec     = "pmtd"
    )
    ,fn=fn(
      new_date_column_name = c("date","year","month")
      ,lag_n               = lag_n
      ,fn_exec             = pmtd_fn
      ,fn_name             = "pmtd"
      ,fn_long_name        = "Previous month-to-date"
      ,shift               = "month"
    )
  )

  return(out)
}

#' @title Current period month to date compared to previous period month-to-date
#' @name momtd
#' @inheritParams pytd
#' @description
#' This calculates the monthly cumulative sum of targeted value using a standard or 5-5-4 calendar respecting
#' any groups that are passed through with [dplyr::group_by()]
#'
#' Use [calculate] to return the results
#' @inherit ytd details
#' @family time_intelligence
#' @returns ti object
#' @export
#' @examples
#' library(contoso)
#' momtd(sales,.date=order_date,.value=quantity,calendar_type="standard", lag_n=1)
momtd <- function(.data,.date,.value,calendar_type='standard',lag_n=1){


  out <- ti(
    datum(
      data                 = .data
      ,calendar_type       = calendar_type
      ,date_vec            = rlang::as_label(rlang::enquo(.date))
    )
    ,time_unit             = time_unit("day")
    ,action                = action(
      value                = c("aggregate","shift","compare")
      ,method              = "This creates a daily {.code cumsum()} of the {cli::col_br_cyan('previous month')}
                             {.field {value_chr}} and {.strong compares} it with the daily {.code cumsum()}
                             {cli::col_cyan('current month')} {.field {value_chr}} from the start of the
                             {cli::col_yellow({calendar_type})} calendar month to the end of the month"
    )
    ,value=value(
      value_vec            = rlang::as_label(rlang::enquo(.value))
      ,new_column_name_vec     = "momtd"
    )
    ,fn=fn(
      new_date_column_name = c("date","year","month")
      ,lag_n               = lag_n
      ,fn_exec             = momtd_fn
      ,fn_name             = "momtd"
      ,fn_long_name        = "Month-to-date over previous month-to-date"
      ,compare             = "Previous month-to-date"
      ,shift               = "month"
    )
  )

  return(out)
}



#' Current month-to-date over full previous period month
#' @name mtdopm
#' @inheritParams pytd
#' @description
#' This calculates the monthly cumulative sum of targeted value using a standard or 5-5-4 calendar respecting
#' any groups that are passed through with [dplyr::group_by()]
#'
#' Use [calculate] to return the results
#' @inherit ytd details
#' @family time_intelligence
#' @returns ti object
#' @export
#'
#' @examples
#' library(contoso)
#' mtdopm(sales,.date=order_date,.value=quantity,calendar_type="standard",lag_n=1)
mtdopm <- function(.data,.date,.value,calendar_type='standard',lag_n=1){
  out <- ti(
    datum(
      data                 = .data
      ,calendar_type       = calendar_type
      ,date_vec            = rlang::as_label(rlang::enquo(.date))
    )
    ,time_unit             = time_unit("day")
    ,action                = action(
      value                = c("aggregate","shift","compare")
      ,method              = "This creates a daily {.code cumsum()} of the {cli::col_cyan('current month')}
                             {.field {value_chr}} and {.strong compares} it with the full month {.code sum()}
                             {cli::col_br_cyan('previous month')} {.field {value_chr}} from the start of the
                             {cli::col_yellow({calendar_type})} calendar month to the end of the month"
    )
    ,value=value(
      value_vec            = rlang::as_label(rlang::enquo(.value))
      ,new_column_name_vec     = "mtdopm"
    )
    ,fn=fn(
      new_date_column_name = c("date","year","month")
      ,lag_n               = lag_n
      ,fn_exec             = mtdopm_fn
      ,fn_name             = "mtdopm"
      ,fn_long_name        = "Month-to-date over full previous month"
      ,shift               = "month"
      ,compare             = "previous full month"
    )
  )

  return(out)
}

#' @title Current full period month over previous full period month
#' @name mom
#' @inheritParams pytd
#' @description
#' This calculates the monthly cumulative sum of targeted value using a standard or 5-5-4 calendar respecting
#' any groups that are passed through with [dplyr::group_by()]
#'
#' Use [calculate] to return the results
#' @inherit ytd details
#' @family time_intelligence
#' @returns ti object
#' @export
#' @examples
#' library(contoso)
#' mom(sales,.date=order_date,.value=quantity,calendar_type='standard',lag_n=1)
mom <- function(.data,.date,.value,calendar_type='standard',lag_n=1){

  out <- ti(
    datum(
      data                 = .data
      ,calendar_type       = calendar_type
      ,date_vec            = rlang::as_label(rlang::enquo(.date))
    )
    ,time_unit             = time_unit("month")
    ,action                = action(
      value                = c("aggregate","shift","compare")
      ,method              = "This creates a full month {.code sum()} of the {cli::col_br_cyan('previous month')}
                             {.field {value_chr}} and {.strong compares} it with the full month {.code sum()}
                             {cli::col_cyan('current month')} {.field {value_chr}} from the start of the
                             {cli::col_yellow({calendar_type})} calendar month to the end of the month"
    )
    ,value=value(
      value_vec            = rlang::as_label(rlang::enquo(.value))
      ,new_column_name_vec     = "mom"
    )
    ,fn=fn(
      new_date_column_name = c("date","year","month")
      ,lag_n               = lag_n
      ,fn_exec             = mom_fn
      ,fn_name             = "mom"
      ,fn_long_name        = "Month over month"
      ,compare             = "previous full month"
      ,shift               = "month"
    )
  )
    return(out)

}


## week related ti_tbl-------------


#' @title Current period week-to-date
#' @name wtd
#' @inheritParams ytd
#' @description
#' This calculates the monthly cumulative sum of targeted value using a standard or 5-5-4 calendar respecting
#' any groups that are passed through with [dplyr::group_by()]
#'
#' Use [calculate] to return the results
#' @inherit ytd details
#' @family time_intelligence
#' @returns ti object
#' @export
#' @examples
#' \dontrun{
#' wtd(sales,.date=order_date,.value=quantity,calendar_type="standard")
#' }

wtd <- function(.data,.date,.value,calendar_type='standard'){

  # Validate inputs

  out <- ti(
    datum(
      data                 = .data
      ,calendar_type       = calendar_type
      ,date_vec            = rlang::as_label(rlang::enquo(.date))
    )
    ,time_unit             = time_unit("day")
    ,action                = action(
      value                = c("aggregate")
      ,method              = "This creates a daily {.code cumsum()} of the {cli::col_cyan('current week')}
                             {.field {value_chr}} from the start of the {cli::col_yellow({calendar_type})} calendar
                              week to the end of the week"
        )
    ,value=value(
      value_vec            = rlang::as_label(rlang::enquo(.value))
      ,new_column_name_vec     = "wtd"
    )
    ,fn=fn(
      new_date_column_name = c("date","year","month","week")
      ,lag_n               = NA_integer_
      ,fn_exec             = wtd_fn
      ,fn_name             = "wtd"
      ,fn_long_name        = "Week-to-date"
    )
  )

  return(out)

}

#' @title Previous period week-to-date
#' @name pwtd
#' @inheritParams pytd
#' @description
#' This calculates the monthly cumulative sum of targeted value using a standard or 5-5-4 calendar respecting
#' any groups that are passed through with [dplyr::group_by()]
#'
#' Use [calculate] to return the results
#' @inherit ytd details
#' @family time_intelligence
#' @returns ti object
#' @export
#' @examples
#' library(contoso)
#' pwtd(sales,.date=order_date,.value=quantity,calendar_type="standard",lag_n=1)
pwtd <- function(.data,.date,.value,calendar_type='standard',lag_n=1){


  out <- ti(
    datum(
      data                 = .data
      ,calendar_type       = calendar_type
      ,date_vec            = rlang::as_label(rlang::enquo(.date))
    )
    ,time_unit             = time_unit("day")
    ,action                = action(
      value                = c("aggregate","shift")
      ,method              = "This creates a daily {.code cumsum()} of the {cli::col_br_cyan('previous week')}
                             {.field {value_chr}} from the start of the {cli::col_yellow({calendar_type})} calendar
                             week to the end of the week"
        )
    ,value=value(
      value_vec            = rlang::as_label(rlang::enquo(.value))
      ,new_column_name_vec     = "pwtd"
    )
    ,fn=fn(
      new_date_column_name = c("date","year","month","week")
      ,lag_n               = lag_n
      ,fn_exec             = pwtd_fn
      ,fn_name             = "pwtd"
      ,fn_long_name        = "Previous Week-to-date"
      ,shift               = "week"
    )
  )

  return(out)

}




#' @title Current period Week-to-date over previous period week-to-date
#' @name wowtd
#' @inheritParams pytd
#' @description
#' This calculates the monthly cumulative sum of targeted value using a standard or 5-5-4 calendar respecting
#' any groups that are passed through with [dplyr::group_by()]
#'
#' Use [calculate] to return the results
#' @inherit ytd details
#' @family time_intelligence
#' @returns ti object
#' @export
#' @examples
#' library(contoso)
#' wowtd(sales,.date=order_date,.value=quantity,calendar_type="standard",lag_n=1)
wowtd <- function(.data,.date,.value,calendar_type='standard',lag_n=1){

  # Vali.date inputs

  out <- ti(
    datum(
      data=.data
      ,calendar_type       = calendar_type
      ,date_vec            = rlang::as_label(rlang::enquo(.date))
    )
    ,time_unit             = time_unit("day")
    ,action                = action(
      value                = c("aggregate","shift","compare")
      ,method              = "This creates a daily {.code cumsum()} of the {cli::col_br_cyan('previous week')}
                             {.field {value_chr}} and {.strong compares} it with the daily {.code cumsum()}
                             {cli::col_cyan('current week')} {.field {value_chr}} from the start of the
                             {cli::col_yellow({calendar_type})} calendar week to the end of the week"
    )
    ,value=value(
      value_vec            = rlang::as_label(rlang::enquo(.value))
      ,new_column_name_vec     = "wowtd"
    )
    ,fn=fn(
      new_date_column_name = c("date","year","month","week")
      ,lag_n               = lag_n
      ,fn_exec             = wowtd_fn
      ,fn_name             = "wowtd"
      ,fn_long_name        = "Week-to-date over previous week-to-date"
      ,compare             = "pwtd"
      ,shift               = "week"

    )
  )
  return(out)
}


#' @title Current period week-to-date over full previous period week
#' @name wtdopw
#' @inheritParams pytd
#' @description
#' This calculates the monthly cumulative sum of targeted value using a standard or 5-5-4 calendar respecting
#' any groups that are passed through with [dplyr::group_by()]
#'
#' Use [calculate] to return the results
#' @inherit ytd details
#' @family time_intelligence
#' @returns ti object
#' @export
#' @examples
#' library(contoso)
#' wtdopw(sales,.date=order_date,.value=quantity,calendar_type="standard",lag_n=1)
wtdopw <- function(.data,.date,.value,calendar_type='standard',lag_n=1){

  out <- ti(
    datum(
      data=.data
      ,calendar_type=calendar_type
      ,date_vec = rlang::as_label(rlang::enquo(.date))
    )
    ,time_unit = time_unit("day")
    ,action                = action(
      value                = c("aggregate","shift","compare")
      ,method              = "This creates a daily {.code cumsum()} of the {cli::col_cyan('current week')}
                             {.field {value_chr}} and {.strong compares} it with the full week {.code sum()}
                             {cli::col_br_cyan('previous week')} {.field {value_chr}} from the start of the
                             {cli::col_yellow({calendar_type})} calendar week to the end of the week"
    )
    ,value=value(
      value_vec = rlang::as_label(rlang::enquo(.value))
      ,new_column_name_vec  = "wtwopw"
    )
    ,fn=fn(
      new_date_column_name = c("date","year","month","week")
      ,lag_n               = lag_n
      ,fn_exec             = wtdopw_fn
      ,fn_name             = "wtdopw"
      ,fn_long_name        = "Week-to-date over full previous week"
      ,compare             = "previous week"
      ,shift               = "week"
    )
  )


  return(out)
}


#' @title Current full period week over full previous period week
#' @name wow
#' @inheritParams pytd
#' @description
#' This calculates the monthly cumulative sum of targeted value using a standard or 5-5-4 calendar respecting
#' any groups that are passed through with [dplyr::group_by()]
#'
#' Use [calculate] to return the results
#' @inherit ytd details
#' @family time_intelligence
#' @returns ti object
#' @export
#' @examples
#' library(contoso)
#' wow(sales,.date=order_date,.value=quantity,calendar_type='standard',lag_n=1)
wow <- function(.data,.date,.value,calendar_type='standard',lag_n=1){

  out <- ti(
    datum(
      data=.data
      ,calendar_type=calendar_type
      ,date_vec = rlang::as_label(rlang::enquo(.date))
    )
    ,time_unit = time_unit("week")
    ,action                = action(
      value                = c("aggregate","shift","compare")
      ,method              = "This creates a full week {.code sum()} of the {cli::col_br_cyan('previous week')}
                             {.field {value_chr}} and {.strong compares} it with the full week {.code sum()}
                             {cli::col_cyan('current week')} {.field {value_chr}} from the start of the
                             {cli::col_yellow({calendar_type})} calendar week to the end of the week"
    )
    ,value=value(
      value_vec           = rlang::as_label(rlang::enquo(.value))
      ,new_column_name_vec    = "wow"
    )
    ,fn=fn(
      new_date_column_name = c("date","week","year","month")
      ,lag_n               = lag_n
      ,fn_exec             = wow_fn
      ,fn_name             = "wow"
      ,fn_long_name        = "week over week"
      ,compare             = "previous week"
      ,shift               = "week"
    )
  )

    return(out)

}


## all related ti_tbl-------------------------

#' @title All period-to-date
#' @name atd
#' @inheritParams ytd
#' @description
#' This calculates the monthly cumulative sum of targeted value using a standard or 5-5-4 calendar respecting
#' any groups that are passed through with [dplyr::group_by()]
#'
#' Use [calculate] to return the results
#' @inherit ytd details
#' @family time_intelligence
#' @returns ti object
#' @export
#' @examples
#' \dontrun{
#' library(contoso)
#' atd(sales,.date=order_date,.value=quantity,calendar_type="standard")
#' }
atd <- function(.data,.date,.value,calendar_type='standard'){

  out <- ti(
    datum(
      data                 = .data
      ,calendar_type       = calendar_type
      ,date_vec            = rlang::as_label(rlang::enquo(.date))
    )
    ,time_unit             = time_unit("day")
    ,action                = action(
      value                = c("aggregate")
      ,method              = "This creates a daily {.code cumsum()}
                             {.field {value_chr}} from the earliest date of the {cli::col_yellow({calendar_type})} calendar
                              until the last date"
        )
    ,value=value(
      value_vec            = rlang::as_label(rlang::enquo(.value))
      ,new_column_name_vec     = "atd"
    )
    ,fn=fn(
      new_date_column_name = c("date")
      ,lag_n               = NA_integer_
      ,fn_exec             = atd_fn
      ,fn_name             = "atd"
      ,fn_long_name        = "All-to-date"
    )
  )

  return(out)

}


## Day related functions------------------

#' @title Current period day over previous period day
#' @name dod
#' @inheritParams pytd
#' @description
#' This calculates the monthly cumulative sum of targeted value using a standard or 5-5-4 calendar respecting
#' any groups that are passed through with [dplyr::group_by()]
#'
#' Use [calculate] to return the results
#' @inherit ytd details
#' @family time_intelligence
#' @returns ti object
#' @export
#' @examples
#' \dontrun{
#' library(contoso)
#' dod(sales,.date=order_date,.value=quantity,calendar_type='standard',lag_n=1)
#' }
dod <- function(.data,.date,.value,calendar_type='standard',lag_n=1){

  out <- ti(
    datum(
      data=.data
      ,calendar_type=calendar_type
      ,date_vec = rlang::as_label(rlang::enquo(.date))
    )
    ,time_unit = time_unit("day")
    ,action                = action(
      value                = c("aggregate","shift","compare")
      ,method              = "This creates a full day {.code sum()} of the {cli::col_br_cyan('previous day')}
                             {.field {value_chr}} and {.strong compares} it with the full day {.code sum()}
                             {cli::col_cyan('current day')} {.field {value_chr}} from the start of the
                             {cli::col_yellow({calendar_type})} calendar day to the end of the day"
    )
    ,value=value(
      value_vec             = rlang::as_label(rlang::enquo(.value))
      ,new_column_name_vec      = "dod"
    )
    ,fn=fn(
      new_date_column_name = c("date")
      ,lag_n               = lag_n
      ,fn_exec             = dod_fn
      ,fn_name             = "dod"
      ,fn_long_name        = "Day over day"
      ,compare             = "previous day"
      ,shift               = "day"
    )
  )
  return(out)
}
