
# Time Intelligence Execution Functions
# ======================================
# Template-based execution functions that eliminate duplication across periods.
# Each *_fn() is a thin wrapper calling one of 5 parameterized templates.


# Template 1: Simple cumsum (td) ----------------------------------------------
# Used by: ytd_fn, qtd_fn, mtd_fn, wtd_fn, atd_fn

#' @noRd
td_template <- function(x, by_cols, relocate_cols) {

  # Follow along with a dummy example: run devtools::load_all(), then the line(s)
  # below, then the body one step at a time.
  # x <- contoso::sales |>
  #   dplyr::group_by(store_key) |>
  #   wtd(.date = order_date, .value = net_revenue)
  # by_cols <- c("year", "week")                       # as wtd_fn() passes
  # relocate_cols <- c("date", "year", "month", "week")

  full_dbi <- create_full_dbi(x)

  out_dbi <- full_dbi |>
    dbplyr::window_order(date) |>
    dplyr::mutate(
      !!x@value@new_column_name_vec := base::cumsum(!!x@value@value_quo)
      ,.by = c(!!!rlang::syms(by_cols), !!!x@datum@group_quo)
    ) |>
    dplyr::relocate(!!!rlang::syms(relocate_cols)) |>
    dplyr::relocate(
      dplyr::any_of("missing_date_indicator")
      ,.after = dplyr::last_col()
    )

  return(out_dbi)
}


# Template 2: Previous period to date (ptd) -----------------------------------
# Used by: pytd_fn, pqtd_fn, pmtd_fn, pwtd_fn
#
# For each calendar date, works out the same point in the earlier period (the
# cutoff, see sql_period_cutoff()) and looks up the earlier period's running
# total on that date. Looking up one cutoff per date means each date gets
# exactly one value, and the lookup is by group.

#' @noRd
ptd_template <- function(x, unit, by_cols, out_cols, days_in_period = FALSE) {

  # Follow along with a dummy example: run devtools::load_all(), then the line(s)
  # below, then the body one step at a time.
  # x <- contoso::sales |>
  #   dplyr::group_by(store_key) |>
  #   pmtd(.date = order_date, .value = net_revenue)
  # unit <- "month"                                    # as pmtd_fn() passes
  # by_cols <- c("year", "month")
  # out_cols <- c("date", "year", "month")
  # days_in_period <- TRUE

  full_dbi <- create_full_dbi(x)
  .con <- dbplyr::remote_con(full_dbi)

  td_dbi <- full_dbi |>
    dbplyr::window_order(date) |>
    dplyr::mutate(
      .ti_td = cumsum(!!x@value@value_quo)
      ,.by = c(!!!rlang::syms(by_cols), !!!x@datum@group_quo)
    ) |>
    dplyr::select(.ti_cutoff = date, !!!x@datum@group_quo, .ti_td)

  cutoff_sql <- sql_period_cutoff(.con, unit = unit, lag_n = x@fn@lag_n)

  out_dbi <- full_dbi |>
    dplyr::mutate(.ti_cutoff = as.Date(!!cutoff_sql)) |>
    dplyr::left_join(td_dbi, by = dplyr::join_by(.ti_cutoff, !!!x@datum@group_quo)) |>
    dplyr::mutate(!!x@value@new_column_name_vec := .ti_td)

  if (isTRUE(days_in_period)) {
    out_dbi <- out_dbi |>
      dplyr::mutate(
        days_in_comparison_period = dplyr::if_else(is.na(.ti_td), NA, lubridate::day(.ti_cutoff))
      )
  }

  out_dbi |>
    dplyr::select(
      dplyr::all_of(out_cols)
      ,!!!x@datum@group_quo
      ,!!x@value@new_column_name_vec
      ,dplyr::any_of("days_in_comparison_period")
    )
}


# Template 3: Compare cumsums (xoxtd) -----------------------------------------
# Used by: yoytd_fn, qoqtd_fn, momtd_fn, wowtd_fn
#
# Calls the td + ptd functions, joins them together.

#' @noRd
xoxtd_template <- function(x, td_fn_call, ptd_fn_call, join_by_cols, relocate_cols, add_year = FALSE) {

  # Follow along with a dummy example: run devtools::load_all(), then the line(s)
  # below, then the body one step at a time.
  # x <- momtd(contoso::sales, .date = order_date, .value = net_revenue)
  # td_fn_call  <- \(x) mtd(x@datum@data, .date = !!x@datum@date_quo, .value = !!x@value@value_quo) |> mtd_fn()
  # ptd_fn_call <- \(x) pmtd(x@datum@data, .date = !!x@datum@date_quo, .value = !!x@value@value_quo) |> pmtd_fn()
  # join_by_cols <- c("year", "month")                 # as momtd_fn() passes
  # relocate_cols <- c("date", "year", "month")
  # add_year <- FALSE

  td_dbi <- td_fn_call(x)
  ptd_dbi <- ptd_fn_call(x)

  out_dbi <- dplyr::full_join(
    td_dbi
    ,ptd_dbi
    ,by = dplyr::join_by(date == date, !!!rlang::syms(join_by_cols), !!!x@datum@group_quo)
  ) |>
    dplyr::group_by(date, !!!rlang::syms(join_by_cols), !!!x@datum@group_quo) |>
    tidyr::fill(date, .direction = "down") |>
    dplyr::ungroup() |>
    dplyr::summarise(
      dplyr::across(dplyr::contains(x@value@value_vec), \(x) sum(x, na.rm = TRUE))
      ,.by = c(date, !!!rlang::syms(join_by_cols), !!!x@datum@group_quo)
    )

  if (isTRUE(add_year)) {
    out_dbi <- out_dbi |>
      dplyr::mutate(year = lubridate::year(date))
  }

  if (!is.null(join_by_cols) && "year" %in% join_by_cols) {
    out_dbi <- out_dbi |>
      dplyr::filter(!is.na(year))
  }

  out_dbi <- out_dbi |>
    dplyr::relocate(!!!rlang::syms(relocate_cols)) |>
    dplyr::relocate(dplyr::any_of("missing_date_indicator"), .after = dplyr::last_col())

  return(out_dbi)
}


# Template 4: Full period compare (xox) ---------------------------------------
# Used by: yoy_fn, qoq_fn, mom_fn, wow_fn, dod_fn

#' @noRd
xox_template <- function(x, drop_cols, relocate_cols) {

  # Follow along with a dummy example: run devtools::load_all(), then the line(s)
  # below, then the body one step at a time.
  # x <- contoso::sales |>
  #   dplyr::group_by(store_key) |>
  #   wow(.date = order_date, .value = net_revenue)
  # drop_cols <- c("year", "quarter", "month", "week")  # as wow_fn() passes
  # relocate_cols <- c("date", "year", "month", "week")

  full_dbi <- create_full_dbi(x)

  lag_dbi <- full_dbi |>
    dplyr::select(-c(!!!rlang::syms(drop_cols))) |>
    dbplyr::window_order(date, !!!x@datum@group_quo) |>
    dplyr::mutate(
      date_lag = dplyr::lead(date, n = !!x@fn@lag_n)
      ,!!x@value@new_column_name_vec := !!x@value@value_quo
      ,.by = c(!!!x@datum@group_quo)
    ) |>
    dplyr::select(-c(date, !!x@value@value_quo, missing_date_indicator))

  out_dbi <- dplyr::left_join(
    full_dbi
    ,lag_dbi
    ,by = dplyr::join_by(date == date_lag, !!!x@datum@group_quo)
  ) |>
    dplyr::relocate(!!!rlang::syms(relocate_cols)) |>
    dplyr::relocate(dplyr::any_of("missing_date_indicator"), .after = dplyr::last_col())

  return(out_dbi)
}


# Template 5: TD over previous full period (tdopx) ----------------------------
# Used by: ytdopy_fn, qtdopq_fn, mtdopm_fn, wtdopw_fn

#' @noRd
tdopx_template <- function(x, td_class_fn, xox_class_fn, join_by_cols, relocate_cols) {

  # Follow along with a dummy example: run devtools::load_all(), then the line(s)
  # below, then the body one step at a time.
  # x <- wtdopw(contoso::sales, .date = order_date, .value = net_revenue)
  # td_class_fn <- wtd                                  # as wtdopw_fn() passes
  # xox_class_fn <- wow
  # join_by_cols <- c("year", "week")
  # relocate_cols <- c("date", "year", "month", "week")

  # Current period to-date
  td_dbi <-
    x@datum@data |>
    dplyr::group_by(!!!x@datum@group_quo) |>
    td_class_fn(.data = _, .date = !!x@datum@date_quo, .value = !!x@value@value_quo, calendar_type = x@datum@calendar_type, fiscal_year_start = x@datum@fiscal_year_start, week_start = x@datum@week_start) |>
    calculate() |>
    dplyr::select(-c(missing_date_indicator, !!x@value@value_quo))

  # Previous full period
  px_dbi <-
    x@datum@data |>
    dplyr::group_by(!!!x@datum@group_quo) |>
    xox_class_fn(.data = _, .date = !!x@datum@date_quo, .value = !!x@value@value_quo, calendar_type = x@datum@calendar_type, fiscal_year_start = x@datum@fiscal_year_start, week_start = x@datum@week_start, lag_n = x@fn@lag_n) |>
    calculate() |>
    dplyr::select(-c(missing_date_indicator, date, !!x@value@value_quo)) |>
    # labels other than the join keys come from the current period
    dplyr::select(-dplyr::any_of(setdiff(c("year", "quarter", "month", "week"), join_by_cols)))

  out_dbi <- td_dbi |>
    dplyr::left_join(
      px_dbi
      ,by = dplyr::join_by(!!!rlang::syms(join_by_cols), !!!x@datum@group_quo)
    ) |>
    dplyr::relocate(!!!rlang::syms(relocate_cols))

  return(out_dbi)
}


# =============================================================================
# Public *_fn() wrappers - same API, delegates to templates
# =============================================================================

## year related functions ---------------

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
ytd_fn <- function(x) {
  td_template(x, by_cols = "year", relocate_cols = c("date", "year"))
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
pytd_fn <- function(x) {
  ptd_template(x, unit = "year", by_cols = "year", out_cols = c("date", "year"))
}

#' @title Current year to date over previous year-to-date execution function
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
yoytd_fn <- function(x) {
  xoxtd_template(
    x,
    td_fn_call = function(x) {
      ytd(.data = x@datum@data, .date = !!x@datum@date_quo, .value = !!x@value@value_quo, calendar_type = x@datum@calendar_type, fiscal_year_start = x@datum@fiscal_year_start, week_start = x@datum@week_start) |>
        ytd_fn()
    },
    ptd_fn_call = function(x) {
      pytd(.data = x@datum@data, .date = !!x@datum@date_quo, .value = !!x@value@value_quo, calendar_type = x@datum@calendar_type, fiscal_year_start = x@datum@fiscal_year_start, week_start = x@datum@week_start, lag_n = x@fn@lag_n) |>
        pytd_fn()
    },
    join_by_cols = "year",
    relocate_cols = c("date", "year"),
    add_year = TRUE
  )
}

#' @title Current year-to-date over previous period year-to-date execution function
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
yoy_fn <- function(x) {
  xox_template(x, drop_cols = "year", relocate_cols = c("date", "year"))
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
ytdopy_fn <- function(x) {
  tdopx_template(
    x,
    td_class_fn = ytd,
    xox_class_fn = yoy,
    join_by_cols = "year",
    relocate_cols = c("date", "year")
  )
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
qtd_fn <- function(x) {
  td_template(x, by_cols = c("year", "quarter"), relocate_cols = c("date", "year"))
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
pqtd_fn <- function(x) {
  ptd_template(x, unit = "quarter", by_cols = c("year", "quarter"), out_cols = c("date", "year", "quarter"))
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
qoqtd_fn <- function(x) {
  xoxtd_template(
    x,
    td_fn_call = function(x) {
      qtd(.data = x@datum@data, .date = !!x@datum@date_quo, .value = !!x@value@value_quo, calendar_type = x@datum@calendar_type, fiscal_year_start = x@datum@fiscal_year_start, week_start = x@datum@week_start) |>
        qtd_fn()
    },
    ptd_fn_call = function(x) {
      pqtd(.data = x@datum@data, .date = !!x@datum@date_quo, .value = !!x@value@value_quo, calendar_type = x@datum@calendar_type, fiscal_year_start = x@datum@fiscal_year_start, week_start = x@datum@week_start, lag_n = x@fn@lag_n) |>
        pqtd_fn()
    },
    join_by_cols = c("year", "quarter"),
    relocate_cols = c("date", "year")
  )
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
qoq_fn <- function(x) {
  xox_template(x, drop_cols = c("year", "quarter"), relocate_cols = c("date", "year", "quarter"))
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
qtdopq_fn <- function(x) {
  tdopx_template(
    x,
    td_class_fn = qtd,
    xox_class_fn = qoq,
    join_by_cols = c("year", "quarter"),
    relocate_cols = c("date", "year", "quarter")
  )
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
mtd_fn <- function(x) {
  td_template(x, by_cols = c("year", "month"), relocate_cols = c("date", "year", "month"))
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
pmtd_fn <- function(x) {
  ptd_template(x, unit = "month", by_cols = c("year", "month"), out_cols = c("date", "year", "month"), days_in_period = TRUE)
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
momtd_fn <- function(x) {
  xoxtd_template(
    x,
    td_fn_call = function(x) {
      mtd(.data = x@datum@data, .date = !!x@datum@date_quo, .value = !!x@value@value_quo, calendar_type = x@datum@calendar_type, fiscal_year_start = x@datum@fiscal_year_start, week_start = x@datum@week_start) |>
        mtd_fn()
    },
    ptd_fn_call = function(x) {
      pmtd(.data = x@datum@data, .date = !!x@datum@date_quo, .value = !!x@value@value_quo, calendar_type = x@datum@calendar_type, fiscal_year_start = x@datum@fiscal_year_start, week_start = x@datum@week_start, lag_n = x@fn@lag_n) |>
        pmtd_fn()
    },
    join_by_cols = c("year", "month"),
    relocate_cols = c("date", "year", "month")
  )
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
mom_fn <- function(x) {
  xox_template(x, drop_cols = c("year", "quarter", "month"), relocate_cols = c("date", "year", "month"))
}

#' Month-to-date over full previous month execution function
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
mtdopm_fn <- function(x) {
  tdopx_template(
    x,
    td_class_fn = mtd,
    xox_class_fn = mom,
    join_by_cols = c("year", "month"),
    relocate_cols = c("date", "year", "month")
  )
}


## week related functions-----------------

#' Week-to-date execution function
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
wtd_fn <- function(x) {
  td_template(x, by_cols = c("year", "week"), relocate_cols = c("date", "year", "month", "week"))
}

#' Previous week-to-date execution function
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
pwtd_fn <- function(x) {
  ptd_template(x, unit = "week", by_cols = c("year", "week"), out_cols = c("date", "year", "month"))
}

#' Week-to-date over previous week-to-date execution function
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
wowtd_fn <- function(x) {
  # Note: Cannot use xoxtd_template because pwtd_fn drops 'week' column,

  # and wowtd needs to preserve it via left_join without summarise.
  wtd_dbi <- wtd(.data = x@datum@data, .date = !!x@datum@date_quo, .value = !!x@value@value_quo, calendar_type = x@datum@calendar_type, fiscal_year_start = x@datum@fiscal_year_start, week_start = x@datum@week_start) |>
    wtd_fn()

  pwtd_dbi <- pwtd(.data = x@datum@data, .date = !!x@datum@date_quo, .value = !!x@value@value_quo, calendar_type = x@datum@calendar_type, fiscal_year_start = x@datum@fiscal_year_start, week_start = x@datum@week_start, lag_n = x@fn@lag_n) |>
    pwtd_fn()

  dplyr::left_join(wtd_dbi, pwtd_dbi, by = dplyr::join_by(date, year, month, !!!x@datum@group_quo)) |>
    dplyr::relocate(date, year, month, week) |>
    dplyr::relocate(dplyr::any_of("missing_date_indicator"), .after = dplyr::last_col())
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
wow_fn <- function(x) {
  xox_template(x, drop_cols = c("year", "quarter", "month", "week"), relocate_cols = c("date", "year", "month", "week"))
}

#' Week-to-date over full previous week execution function
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
wtdopw_fn <- function(x) {
  tdopx_template(
    x,
    td_class_fn = wtd,
    xox_class_fn = wow,
    join_by_cols = c("year", "week"),
    relocate_cols = c("date", "year", "month", "week")
  )
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
atd_fn <- function(x) {
  td_template(x, by_cols = character(0), relocate_cols = "date")
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
#' by [calculate]
#' This will return a dbi object that can converted to a tibble object with [dplyr::collect()]
#' @returns dbi object
#' @keywords internal
dod_fn <- function(x) {
  xox_template(x, drop_cols = c("year", "quarter", "month", "week", "day"), relocate_cols = "date")
}


utils::globalVariables(c("missing_date_indicator", "pp_missing_dates_cnt", "pp_extra_dates_cnt", "days_in_comparison_period"))
