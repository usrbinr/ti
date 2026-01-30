
# Time Intelligence Execution Functions
# ======================================
# Template-based execution functions that eliminate duplication across periods.
# Each *_fn() is a thin wrapper calling one of 5 parameterized templates.


# Template 1: Simple cumsum (td) ----------------------------------------------
# Used by: ytd_fn, qtd_fn, mtd_fn, wtd_fn, atd_fn

#' @noRd
td_template <- function(x, by_cols, relocate_cols) {

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


# Template 2: Lagged cumsum (ptd) ---------------------------------------------
# Used by: pytd_fn, pqtd_fn, pmtd_fn, pwtd_fn
#
# The year variant uses lubridate::years() for the lag, while quarter/month/week
# variants use sql_date_add(). This split is necessary because the SQL date
# arithmetic differs by period.

#' @noRd
ptd_year_template <- function(x, by_cols, drop_cols, join_by_cols, relocate_cols) {

  full_dbi <- create_full_dbi(x)

  lag_dbi <- full_dbi |>
    dbplyr::window_order(date) |>
    dplyr::mutate(
      date_lag = as.Date(date + lubridate::years(!!x@fn@lag_n))
      ,!!x@value@new_column_name_vec := cumsum(!!x@value@value_quo)
      ,.by = c(!!!rlang::syms(by_cols), !!!x@datum@group_quo)
    ) |>
    dplyr::select(-c(!!!rlang::syms(drop_cols), !!x@value@value_quo))

  out_dbi <- dplyr::full_join(
    full_dbi
    ,lag_dbi
    ,by = dplyr::join_by(date == date_lag, !!!x@datum@group_quo)
  ) |>
    dplyr::select(-c(!!x@value@value_quo)) |>
    dbplyr::window_order(date) |>
    dplyr::group_by(!!!rlang::syms(join_by_cols), !!!x@datum@group_quo) |>
    tidyr::fill(date, .direction = "down") |>
    dplyr::ungroup() |>
    dplyr::summarise(
      dplyr::across(dplyr::contains(x@value@value_vec), \(x) sum(x, na.rm = TRUE))
      ,.by = c(!!!rlang::syms(join_by_cols), !!!x@datum@group_quo)
    ) |>
    dplyr::relocate(!!!rlang::syms(relocate_cols)) |>
    dplyr::relocate(dplyr::any_of("missing_date_indicator"), .after = dplyr::last_col())

  return(out_dbi)
}

#' @noRd
ptd_sql_template <- function(x, sql_unit, sql_expr, by_cols, drop_cols, join_by_cols, relocate_cols, filter_na_col = NULL) {

  lag_n_vec <- x@fn@lag_n |> rlang::as_label()

  full_dbi <- create_full_dbi(x)

  if (!is.null(filter_na_col)) {
    # pmtd and pwtd remove missing_date_indicator before lag
    full_dbi_for_lag <- full_dbi |> dplyr::select(-c(missing_date_indicator))
  } else {
    full_dbi_for_lag <- full_dbi
  }

  .con <- dbplyr::remote_con(full_dbi_for_lag)
  date_lag_sql <- sql_date_add(.con, sql_unit, sql_expr(lag_n_vec))

  lag_dbi <- full_dbi_for_lag |>
    dbplyr::window_order(date) |>
    dplyr::mutate(
      date_lag = as.Date(!!date_lag_sql)
      ,!!x@value@new_column_name_vec := cumsum(!!x@value@value_quo)
      ,.by = c(!!!rlang::syms(by_cols), !!!x@datum@group_quo)
    ) |>
    dplyr::select(-c(!!!rlang::syms(drop_cols), !!x@value@value_quo))

  # pmtd has extra month/year extraction and days_in_comparison_period logic
  if (sql_unit == "month" && !is.null(filter_na_col)) {
    lag_dbi <- lag_dbi |>
      dplyr::mutate(
        month = lubridate::month(date_lag)
        ,year = lubridate::year(date_lag)
      ) |>
      dplyr::mutate(
        days_in_comparison_period = lubridate::day(date)
      ) |>
      dplyr::select(-c(year, month, date))
  }

  if (!is.null(filter_na_col)) {
    # pmtd/pwtd: use full_dbi_for_lag (without missing_date_indicator) for join
    join_result <- dplyr::full_join(
      full_dbi_for_lag
      ,lag_dbi
      ,by = dplyr::join_by(date == date_lag, !!!x@datum@group_quo)
    ) |>
      dplyr::select(-c(!!x@value@value_quo)) |>
      dbplyr::window_order(date, !!!x@datum@group_quo)

    if (sql_unit == "month") {
      # pmtd: fill both days_in_comparison_period and the value column
      join_result <- join_result |>
        tidyr::fill(c(days_in_comparison_period, !!x@value@new_column_name_quo), .direction = "down") |>
        dplyr::summarise(
          !!x@value@new_column_name_vec := max(!!x@value@new_column_name_quo, na.rm = TRUE)
          ,days_in_comparison_period = max(days_in_comparison_period, na.rm = TRUE)
          ,.by = c(!!!rlang::syms(join_by_cols), !!!x@datum@group_quo)
        )
    } else {
      # pwtd
      join_result <- join_result |>
        dplyr::group_by(!!!rlang::syms(join_by_cols), !!!x@datum@group_quo) |>
        tidyr::fill(date, .direction = "down") |>
        dplyr::ungroup() |>
        dplyr::summarise(
          dplyr::across(dplyr::contains(x@value@value_vec), \(x) sum(x, na.rm = TRUE))
          ,.by = c(!!!rlang::syms(join_by_cols), !!!x@datum@group_quo)
        )
    }

    out_dbi <- join_result |>
      dplyr::relocate(!!!rlang::syms(relocate_cols)) |>
      dplyr::relocate(dplyr::any_of("missing_date_indicator"), .after = dplyr::last_col())

  } else {
    # pqtd path
    out_dbi <- dplyr::full_join(
      full_dbi
      ,lag_dbi
      ,by = dplyr::join_by(date == date_lag, !!!x@datum@group_quo)
    ) |>
      dplyr::select(-c(!!x@value@value_quo)) |>
      dbplyr::window_order(date, !!!rlang::syms(join_by_cols), !!!x@datum@group_quo) |>
      dplyr::group_by(!!!rlang::syms(join_by_cols), !!!x@datum@group_quo) |>
      tidyr::fill(date, .direction = "down") |>
      dplyr::ungroup() |>
      dplyr::summarise(
        dplyr::across(dplyr::contains(x@value@value_vec), \(x) sum(x, na.rm = TRUE))
        ,.by = c(!!!rlang::syms(join_by_cols), !!!x@datum@group_quo)
      ) |>
      dplyr::filter(!is.na(year)) |>
      dplyr::relocate(!!!rlang::syms(relocate_cols)) |>
      dplyr::relocate(dplyr::any_of("missing_date_indicator"), .after = dplyr::last_col())
  }

  return(out_dbi)
}


# Template 3: Compare cumsums (xoxtd) -----------------------------------------
# Used by: yoytd_fn, qoqtd_fn, momtd_fn, wowtd_fn
#
# Calls the td + ptd functions, joins them together.

#' @noRd
xoxtd_template <- function(x, td_fn_call, ptd_fn_call, join_by_cols, relocate_cols, add_year = FALSE) {

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

  # Current period to-date
  td_dbi <-
    x@datum@data |>
    dplyr::group_by(!!!x@datum@group_quo) |>
    td_class_fn(.data = _, .date = !!x@datum@date_quo, .value = !!x@value@value_quo, calendar_type = x@datum@calendar_type) |>
    calculate() |>
    dplyr::select(-c(missing_date_indicator, !!x@value@value_quo))

  # Previous full period
  px_dbi <-
    x@datum@data |>
    dplyr::group_by(!!!x@datum@group_quo) |>
    xox_class_fn(.data = _, .date = !!x@datum@date_quo, .value = !!x@value@value_quo, calendar_type = x@datum@calendar_type, lag_n = x@fn@lag_n) |>
    calculate() |>
    dplyr::select(-c(missing_date_indicator, date, !!x@value@value_quo))

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
  ptd_year_template(
    x,
    by_cols = "year",
    drop_cols = c("date", "year"),
    join_by_cols = c("date", "year"),
    relocate_cols = c("date", "year")
  )
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
      ytd(.data = x@datum@data, .date = !!x@datum@date_quo, .value = !!x@value@value_quo, calendar_type = x@datum@calendar_type) |>
        ytd_fn()
    },
    ptd_fn_call = function(x) {
      pytd(.data = x@datum@data, .date = !!x@datum@date_quo, .value = !!x@value@value_quo, calendar_type = x@datum@calendar_type, lag_n = x@fn@lag_n) |>
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
  full_dbi <- create_full_dbi(x)

  out_dbi <- full_dbi |>
    dbplyr::window_order(date) |>
    dplyr::mutate(
      !!x@value@new_column_name_vec := base::cumsum(!!x@value@value_quo)
      ,.by = c(year, quarter, !!!x@datum@group_quo)
    ) |>
    dplyr::ungroup() |>
    dplyr::relocate(date, year) |>
    dplyr::relocate(dplyr::any_of("missing_date_indicator"), .after = dplyr::last_col())

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
pqtd_fn <- function(x) {
  ptd_sql_template(
    x,
    sql_unit = "month",
    sql_expr = function(lag_n_vec) glue::glue("3 * {lag_n_vec}"),
    by_cols = c("year", "quarter"),
    drop_cols = c("date", "year", "quarter"),
    join_by_cols = c("date", "year", "quarter"),
    relocate_cols = c("date", "year")
  )
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
      qtd(.data = x@datum@data, .date = !!x@datum@date_quo, .value = !!x@value@value_quo, calendar_type = x@datum@calendar_type) |>
        qtd_fn()
    },
    ptd_fn_call = function(x) {
      pqtd(.data = x@datum@data, .date = !!x@datum@date_quo, .value = !!x@value@value_quo, calendar_type = x@datum@calendar_type, lag_n = x@fn@lag_n) |>
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
  ptd_sql_template(
    x,
    sql_unit = "month",
    sql_expr = function(lag_n_vec) lag_n_vec,
    by_cols = c("year", "month"),
    drop_cols = c("month", "year"),
    join_by_cols = c("date", "year", "month"),
    relocate_cols = c("date", "year", "month"),
    filter_na_col = "year"
  )
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

  mtd_dbi <- mtd(.data = x@datum@data, .date = !!x@datum@date_quo, .value = !!x@value@value_quo, calendar_type = x@datum@calendar_type) |>
    calculate()

  pmtd_dbi <- pmtd(.data = x@datum@data, .date = !!x@datum@date_quo, .value = !!x@value@value_quo, calendar_type = x@datum@calendar_type, lag_n = x@fn@lag_n) |>
    calculate()

  out_dbi <-
    dplyr::full_join(
      mtd_dbi
      ,pmtd_dbi
      ,by = dplyr::join_by(date == date, year, month, !!!x@datum@group_quo)
    ) |>
    dplyr::summarise(
      dplyr::across(dplyr::contains(x@value@value_vec), \(x) sum(x, na.rm = TRUE))
      ,.by = c(date, year, month, !!!x@datum@group_quo)
    ) |>
    dplyr::relocate(date, year, month)

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
  td_template(x, by_cols = c("year", "month", "week"), relocate_cols = c("date", "year", "month", "week"))
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
  ptd_sql_template(
    x,
    sql_unit = "week",
    sql_expr = function(lag_n_vec) lag_n_vec,
    by_cols = c("year", "month", "week"),
    drop_cols = c("date", "month", "year", "week"),
    join_by_cols = c("date", "year", "month"),
    relocate_cols = c("date", "year", "month"),
    filter_na_col = "year"
  )
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

  wtd_dbi <-
    x@datum@data |>
    dplyr::group_by(!!!x@datum@group_quo) |>
    wtd(.data = _, .date = !!x@datum@date_quo, .value = !!x@value@value_quo, calendar_type = x@datum@calendar_type) |>
    calculate()

  pwtd_dbi <-
    x@datum@data |>
    dplyr::group_by(!!!x@datum@group_quo) |>
    pwtd(.data = _, .date = !!x@datum@date_quo, .value = !!x@value@value_quo, calendar_type = x@datum@calendar_type, lag_n = x@fn@lag_n) |>
    calculate()

  out_tbl <-
    dplyr::left_join(
      wtd_dbi
      ,pwtd_dbi
      ,by = dplyr::join_by(date, year, month, !!!x@datum@group_quo)
    ) |>
    dplyr::relocate(date, year, month, week) |>
    dplyr::relocate(dplyr::any_of("missing_date_indicator"), .after = dplyr::last_col())

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
    join_by_cols = c("year", "month", "week"),
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
