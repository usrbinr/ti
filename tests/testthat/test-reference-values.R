# Checks every ti function's numbers against an independent reference.
#
# How one check works (the worked example below does this step by step):
#
#   1. fixture   ref_fixture(): small test data with two stores, gaps, a leap
#                day and data that starts mid-month (helper-reference.R).
#   2. daily     ref_daily(): the fixture as a complete daily table, missing
#                days filled with 0, each day labelled with its year, month,
#                week and the first day of each period it belongs to.
#   3. expected  A plain-R reference function (ref_td(), ref_xox(), ...)
#                computes the answer from `daily`, following the documented
#                definition. It shares no code with ti.
#   4. actual    ti_result(): the ti function on the same fixture,
#                calculate()d and collect()ed.
#   5. compare   expect_matches_reference(): joins expected and actual on store
#                and date. Every expected row must appear exactly once in ti's
#                output, and every value must match (NA and 0 count as
#                different).
#
# The `checks` table says, for each function, which reference to use, which
# period, and which reference column to compare with which ti column. The
# looped tests then run the same five steps for every function, grouped and
# ungrouped, and with different calendars and week starts.

fixture <- ref_fixture()


# Worked example: mom() for each store, written out without the table --------

describe("worked example", {
  it("mom() grouped by store matches the reference", {
    # 2. complete daily table, one per store
    daily <- ref_daily(fixture, grouped = TRUE)

    # 3. expected: each month's total, and the total one month earlier
    #    columns: store, date (first day of the month), total, prior
    expected <- ref_xox(daily, period = "month")

    # 4. actual: what ti returns
    #    columns include: store, date, value (this month), mom_value (last month)
    actual <- ti_result(ti::mom, fixture, grouped = TRUE)

    # 5. compare the reference's total with ti's value, and the reference's
    #    prior with ti's mom_value
    expect_matches_reference(actual, expected, actual_col = "value", expected_col = "total")
    expect_matches_reference(actual, expected, actual_col = "mom_value", expected_col = "prior")
  })
})


# What to compare for each function -------------------------------------------
#
# reference  which plain-R reference computes the expected answer:
#              "running_total"        ref_td(): running total that restarts
#                                     each period (ytd, mtd, ...)
#              "period_over_period"   ref_xox(): each period's total and the
#                                     total one period earlier (yoy, mom, ...)
#              "previous_to_date"     ref_ptd(): the earlier period's running
#                                     total at the same point (pytd, pmtd, ...)
#              "to_date_vs_previous"  running total and previous-to-date side
#                                     by side (yoytd, momtd, ...)
#              "to_date_vs_prior_total"
#                                     running total and the previous period's
#                                     full total (ytdopy, mtdopm, ...)
# period     the period the function works in
# compare    reference column = ti column

checks <- list(
  ytd    = list(reference = "running_total",          period = "year",    compare = c(running_total = "ytd_value")),
  qtd    = list(reference = "running_total",          period = "quarter", compare = c(running_total = "qtd_value")),
  mtd    = list(reference = "running_total",          period = "month",   compare = c(running_total = "mtd_value")),
  wtd    = list(reference = "running_total",          period = "week",    compare = c(running_total = "wtd_value")),
  atd    = list(reference = "running_total",          period = "all",     compare = c(running_total = "atd_value")),
  yoy    = list(reference = "period_over_period",     period = "year",    compare = c(total = "value", prior = "yoy_value")),
  qoq    = list(reference = "period_over_period",     period = "quarter", compare = c(total = "value", prior = "qoq_value")),
  mom    = list(reference = "period_over_period",     period = "month",   compare = c(total = "value", prior = "mom_value")),
  wow    = list(reference = "period_over_period",     period = "week",    compare = c(total = "value", prior = "wow_value")),
  dod    = list(reference = "period_over_period",     period = "day",     compare = c(total = "value", prior = "dod_value")),
  pytd   = list(reference = "previous_to_date",       period = "year",    compare = c(previous_to_date = "pytd_value")),
  pqtd   = list(reference = "previous_to_date",       period = "quarter", compare = c(previous_to_date = "pqtd_value")),
  pmtd   = list(reference = "previous_to_date",       period = "month",   compare = c(previous_to_date = "pmtd_value")),
  pwtd   = list(reference = "previous_to_date",       period = "week",    compare = c(previous_to_date = "pwtd_value")),
  yoytd  = list(reference = "to_date_vs_previous",    period = "year",    compare = c(running_total = "ytd_value", previous_to_date = "pytd_value")),
  qoqtd  = list(reference = "to_date_vs_previous",    period = "quarter", compare = c(running_total = "qtd_value", previous_to_date = "pqtd_value")),
  momtd  = list(reference = "to_date_vs_previous",    period = "month",   compare = c(running_total = "mtd_value", previous_to_date = "pmtd_value")),
  wowtd  = list(reference = "to_date_vs_previous",    period = "week",    compare = c(running_total = "wtd_value", previous_to_date = "pwtd_value")),
  ytdopy = list(reference = "to_date_vs_prior_total", period = "year",    compare = c(running_total = "ytd_value", prior = "yoy_value")),
  qtdopq = list(reference = "to_date_vs_prior_total", period = "quarter", compare = c(running_total = "qtd_value", prior = "qoq_value")),
  mtdopm = list(reference = "to_date_vs_prior_total", period = "month",   compare = c(running_total = "mtd_value", prior = "mom_value")),
  wtdopw = list(reference = "to_date_vs_prior_total", period = "week",    compare = c(running_total = "wtd_value", prior = "wow_value"))
)

# Step 3: the expected answer for one function. Returns one row per store and
# date (or per store and period) with the reference columns named in `compare`.
expected_for <- function(check, daily) {
  switch(check$reference,
    running_total      = ref_td(daily, check$period),
    period_over_period = ref_xox(daily, check$period),
    previous_to_date   = ref_ptd(daily, check$period),
    to_date_vs_previous = dplyr::left_join(
      ref_td(daily, check$period),
      ref_ptd(daily, check$period) |> dplyr::select(store, date, previous_to_date),
      by = c("store", "date")
    ),
    to_date_vs_prior_total = dplyr::left_join(
      ref_td(daily, check$period),
      ref_prior_total(daily, check$period) |> dplyr::select(store, date, prior),
      by = c("store", "date")
    )
  )
}

# Steps 2-5 for one function
check_against_reference <- function(fn_name, grouped, calendar_type = "standard", week_start = 7) {
  check <- checks[[fn_name]]
  daily <- ref_daily(fixture, grouped, calendar_type, week_start)                # 2
  expected <- expected_for(check, daily)                                         # 3
  actual <- ti_result(                                                           # 4
    getExportedValue("ti", fn_name), fixture, grouped,
    calendar_type = calendar_type, week_start = week_start
  )
  purrr::iwalk(check$compare, \(actual_col, expected_col) {                      # 5
    expect_matches_reference(actual, expected, actual_col, expected_col)
  })
}


# The same check for every function -------------------------------------------

describe("standard calendar values match the reference", {
  purrr::walk(names(checks), \(fn_name) {
    it(paste(fn_name, "ungrouped"), check_against_reference(fn_name, grouped = FALSE))
    it(paste(fn_name, "grouped"), check_against_reference(fn_name, grouped = TRUE))
  })
})

describe("week functions follow week_start", {
  week_fns <- c("wtd", "wow", "pwtd", "wowtd", "wtdopw")
  day_names <- c("Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday")
  # every start day, standard calendar, ungrouped and grouped
  # Monday runs everywhere; the other start days are skipped on CRAN to keep
  # check time down
  purrr::walk(1:7, \(week_start) {
    purrr::walk(week_fns, \(fn_name) {
      it(paste(fn_name, "with weeks starting", day_names[week_start]), {
        if (week_start != 1) skip_on_cran()
        check_against_reference(fn_name, grouped = FALSE, week_start = week_start)
        check_against_reference(fn_name, grouped = TRUE, week_start = week_start)
      })
    })
  })
  # on retail calendars week_start moves every fiscal period, not only weeks
  purrr::walk(c(1, 3), \(week_start) {
    purrr::walk(c("wtd", "wow", "mtd", "mom", "ytd", "yoy"), \(fn_name) {
      it(paste("445", fn_name, "with weeks starting", day_names[week_start]), {
        skip_on_cran()
        check_against_reference(fn_name, grouped = TRUE, calendar_type = "445", week_start = week_start)
      })
    })
  })
})

describe("week_start hand-computed values", {
  # 2024-01-01 is a Monday; value = day of the month
  data <- dplyr::tibble(date = seq(as.Date("2024-01-01"), as.Date("2024-01-14"), "day"), value = 1:14)

  it("wtd with Wednesday weeks resets every Wednesday", {
    out <- ti::wtd(data, date, value, week_start = 3) |> ti::calculate() |> dplyr::collect() |> dplyr::arrange(date)
    # week 1: Mon Jan 1 - Tue Jan 2 (cut at 1 January)
    # week 2: Wed Jan 3 - Tue Jan 9
    # week 3: Wed Jan 10 - Sun Jan 14
    expect_equal(out$wtd_value, c(cumsum(1:2), cumsum(3:9), cumsum(10:14)))
    expect_equal(out$week, c(1, 1, rep(2, 7), rep(3, 5)))
  })

  it("wow with Wednesday weeks compares whole Wednesday-start weeks", {
    out <- ti::wow(data, date, value, week_start = 3) |> ti::calculate() |> dplyr::collect() |> dplyr::arrange(date)
    expect_equal(as.Date(out$date), as.Date(c("2024-01-01", "2024-01-03", "2024-01-10")))
    expect_equal(out$value, c(1 + 2, sum(3:9), sum(10:14)))
    expect_equal(out$wow_value, c(NA, 1 + 2, sum(3:9)))
  })

  it("the same data gives different weeks for different start days", {
    totals <- purrr::map(c(monday = 1, wednesday = 3, sunday = 7), \(ws) {
      ti::wow(data, date, value, week_start = ws) |> ti::calculate() |> dplyr::collect() |>
        dplyr::arrange(date) |> dplyr::pull(value)
    })
    # Monday: Jan 1-7, Jan 8-14
    expect_equal(totals$monday, c(sum(1:7), sum(8:14)))
    # Sunday: Jan 1-6 (Mon-Sat), Jan 7-13, Jan 14
    expect_equal(totals$sunday, c(sum(1:6), sum(7:13), 14))
    expect_equal(totals$wednesday, c(1 + 2, sum(3:9), sum(10:14)))
    # every version still adds up to the same total
    purrr::walk(totals, \(x) expect_equal(sum(x), sum(1:14)))
  })

  it("rejects an invalid week_start", {
    expect_error(ti::wow(data, date, value, week_start = 0), "week_start")
    expect_error(ti::wow(data, date, value, week_start = 8), "week_start")
  })
})

describe("retail calendar values match the reference", {
  # fiscal periods come from the calendar labels; the previous-period-to-date
  # functions shift by calendar months and are not covered here
  retail_fns <- c("ytd", "qtd", "mtd", "wtd", "yoy", "qoq", "mom", "wow", "ytdopy", "qtdopq", "mtdopm", "wtdopw")
  purrr::walk(c("445", "454", "544"), \(calendar_type) {
    purrr::walk(retail_fns, \(fn_name) {
      it(paste(calendar_type, fn_name), {
        # 445 runs everywhere; 454 and 544 use the same code and are skipped on CRAN
        if (calendar_type != "445") skip_on_cran()
        check_against_reference(fn_name, grouped = TRUE, calendar_type = calendar_type)
      })
    })
  })
})

describe("hand-computed values", {
  # Small enough to check on paper: 2024-01-01 is a Monday
  data <- dplyr::tibble(
    date = as.Date(c("2023-12-30", "2023-12-31", "2024-01-01", "2024-01-03", "2024-01-07", "2024-01-08")),
    value = c(1, 2, 4, 8, 16, 32)
  )

  it("wow returns one row per Sunday-start week with the prior week's total", {
    out <- ti::wow(data, date, value) |> ti::calculate() |> dplyr::collect() |> dplyr::arrange(date)
    # Sun Dec 24 - Sat Dec 30: 1
    # Sun Dec 31: 2 (that week is cut at 1 January)
    # Mon Jan 1 - Sat Jan 6: 4 + 8 = 12
    # Sun Jan 7 - Sat Jan 13: 16 + 32 = 48
    expect_equal(as.Date(out$date), as.Date(c("2023-12-24", "2023-12-31", "2024-01-01", "2024-01-07")))
    expect_equal(out$value, c(1, 2, 12, 48))
    expect_equal(out$wow_value, c(NA, 1, 2, 12))
  })

  it("wow with Monday weeks", {
    out <- ti::wow(data, date, value, week_start = 1) |> ti::calculate() |> dplyr::collect() |> dplyr::arrange(date)
    # Mon Dec 25 - Sun Dec 31: 1 + 2 = 3; Mon Jan 1 - Sun Jan 7: 4 + 8 + 16 = 28; Jan 8: 32
    expect_equal(as.Date(out$date), as.Date(c("2023-12-25", "2024-01-01", "2024-01-08")))
    expect_equal(out$value, c(3, 28, 32))
    expect_equal(out$wow_value, c(NA, 3, 28))
  })

  it("wtd resets at each week start but not at month ends", {
    d <- dplyr::tibble(date = seq(as.Date("2024-01-28"), as.Date("2024-02-05"), "day"), value = 1)
    out <- ti::wtd(d, date, value) |> ti::calculate() |> dplyr::collect() |> dplyr::arrange(date)
    # Sun Jan 28 - Sat Feb 3 is one week; Sun Feb 4 starts the next
    expect_equal(out$wtd_value, c(1, 2, 3, 4, 5, 6, 7, 1, 2))
  })

  it("pytd and yoytd default to the previous year", {
    d <- dplyr::tibble(date = as.Date(c("2023-01-05", "2023-03-01", "2024-01-10", "2024-03-01")), value = c(10, 20, 1, 2))
    out <- ti::pytd(d, date, value) |> ti::calculate() |> dplyr::collect()
    expect_equal(out$pytd_value[as.Date(out$date) == as.Date("2024-01-10")], 10)
    expect_equal(out$pytd_value[as.Date(out$date) == as.Date("2024-03-01")], 30)
    out <- ti::yoytd(d, date, value) |> ti::calculate() |> dplyr::collect()
    expect_equal(out$ytd_value[as.Date(out$date) == as.Date("2024-03-01")], 3)
    expect_equal(out$pytd_value[as.Date(out$date) == as.Date("2024-03-01")], 30)
  })

  it("grouped pmtd does not use another group's values", {
    d <- dplyr::tibble(
      store = c("a", "a", "b"),
      date = as.Date(c("2024-01-10", "2024-02-10", "2024-02-15")),
      value = c(100, 1, 5)
    ) |> dplyr::group_by(store)
    out <- ti::pmtd(d, date, value) |> ti::calculate() |> dplyr::collect()
    # store b has no January data, so its previous-month-to-date is never 100
    b <- out[out$store == "b", ]
    expect_false(any(b$pmtd_value == 100, na.rm = TRUE))
    a <- out[out$store == "a" & as.Date(out$date) == as.Date("2024-02-10"), ]
    expect_equal(a$pmtd_value, 100)
  })
})
