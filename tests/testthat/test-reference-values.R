# Every ti function is checked row by row against the independent reference in
# helper-reference.R, ungrouped and grouped, so a wrong number fails the tests
# rather than only a crash.

fixture <- ref_fixture()

# function, reference type, period, and the ti output column for each value
specs <- list(
  ytd    = list(type = "td",    unit = "year",    cols = c(td = "ytd_value")),
  qtd    = list(type = "td",    unit = "quarter", cols = c(td = "qtd_value")),
  mtd    = list(type = "td",    unit = "month",   cols = c(td = "mtd_value")),
  wtd    = list(type = "td",    unit = "week",    cols = c(td = "wtd_value")),
  atd    = list(type = "td",    unit = "all",     cols = c(td = "atd_value")),
  yoy    = list(type = "xox",   unit = "year",    cols = c(total = "value", prior = "yoy_value")),
  qoq    = list(type = "xox",   unit = "quarter", cols = c(total = "value", prior = "qoq_value")),
  mom    = list(type = "xox",   unit = "month",   cols = c(total = "value", prior = "mom_value")),
  wow    = list(type = "xox",   unit = "week",    cols = c(total = "value", prior = "wow_value")),
  dod    = list(type = "xox",   unit = "day",     cols = c(total = "value", prior = "dod_value")),
  pytd   = list(type = "ptd",   unit = "year",    cols = c(ptd = "pytd_value")),
  pqtd   = list(type = "ptd",   unit = "quarter", cols = c(ptd = "pqtd_value")),
  pmtd   = list(type = "ptd",   unit = "month",   cols = c(ptd = "pmtd_value")),
  pwtd   = list(type = "ptd",   unit = "week",    cols = c(ptd = "pwtd_value")),
  yoytd  = list(type = "xoxtd", unit = "year",    cols = c(td = "ytd_value", ptd = "pytd_value")),
  qoqtd  = list(type = "xoxtd", unit = "quarter", cols = c(td = "qtd_value", ptd = "pqtd_value")),
  momtd  = list(type = "xoxtd", unit = "month",   cols = c(td = "mtd_value", ptd = "pmtd_value")),
  wowtd  = list(type = "xoxtd", unit = "week",    cols = c(td = "wtd_value", ptd = "pwtd_value")),
  ytdopy = list(type = "tdopx", unit = "year",    cols = c(td = "ytd_value", prior = "yoy_value")),
  qtdopq = list(type = "tdopx", unit = "quarter", cols = c(td = "qtd_value", prior = "qoq_value")),
  mtdopm = list(type = "tdopx", unit = "month",   cols = c(td = "mtd_value", prior = "mom_value")),
  wtdopw = list(type = "tdopx", unit = "week",    cols = c(td = "wtd_value", prior = "wow_value"))
)

reference_for <- function(spec, daily) {
  switch(spec$type,
    td    = ref_td(daily, spec$unit),
    xox   = ref_xox(daily, spec$unit),
    ptd   = ref_ptd(daily, spec$unit),
    xoxtd = dplyr::left_join(
      ref_td(daily, spec$unit),
      ref_ptd(daily, spec$unit) |> dplyr::select(store, date, ptd),
      by = c("store", "date")
    ),
    tdopx = dplyr::left_join(
      ref_td(daily, spec$unit),
      ref_prior_total(daily, spec$unit) |> dplyr::select(store, date, prior),
      by = c("store", "date")
    )
  )
}

check_against_reference <- function(fn_name, grouped, calendar_type = "standard", week_start = 7) {
  spec <- specs[[fn_name]]
  daily <- ref_daily(fixture, grouped, calendar_type, week_start)
  expected <- reference_for(spec, daily)
  actual <- ti_result(
    getExportedValue("ti", fn_name), fixture, grouped,
    calendar_type = calendar_type, week_start = week_start
  )
  purrr::iwalk(spec$cols, \(actual_col, expected_col) {
    expect_matches_reference(actual, expected, actual_col, expected_col)
  })
}

describe("standard calendar values match the reference", {
  purrr::walk(names(specs), \(fn_name) {
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
