# Every function depends on create_full_dbi() returning a complete calendar:
# exactly one row per period (per group), no gaps, each period dated by its
# first day, and totals that match the raw data. These tests check that
# directly, so a calendar problem points here rather than at every function.

fixture <- ref_fixture()

# a ti object at each time unit
unit_fns <- list(day = ti::ytd, week = ti::wow, month = ti::mom, quarter = ti::qoq, year = ti::yoy)

check_calendar <- function(unit, calendar_type, grouped, week_start = 7) {
  data <- if (grouped) dplyr::group_by(fixture, store) else fixture
  x <- unit_fns[[unit]](data, .date = date, .value = value, calendar_type = calendar_type, week_start = week_start)
  cal <- ti:::create_full_dbi(x) |> dplyr::collect() |> dplyr::ungroup() |> dplyr::mutate(date = as.Date(date))
  if (!grouped) cal$store <- "all"

  # expected periods: from each group's first to its last period, dated by the
  # period's true first day
  daily <- ref_daily(fixture, grouped, calendar_type, week_start)
  expected <- daily |>
    dplyr::summarise(
      date = min(.data[[paste0("start_", unit)]]), total = sum(value),
      .by = c(store, dplyr::all_of(ref_key(unit)))
    ) |>
    dplyr::select(store, date, total) |>
    dplyr::arrange(store, date)

  # 1. one row per period
  expect_equal(anyDuplicated(cal[c("store", "date")]), 0L)
  # 2 and 3. no gaps, no extra periods, each dated by its first day
  expect_equal(
    cal |> dplyr::select(store, date) |> dplyr::arrange(store, date),
    expected |> dplyr::select(store, date)
  )
  # 4. period totals, and the overall total, match the raw data
  got <- cal |> dplyr::select(store, date, total = value) |> dplyr::arrange(store, date)
  expect_equal(got$total, expected$total)
  expect_equal(sum(cal$value), sum(fixture$value))
  # periods without data are filled with 0 and flagged
  expect_true(all(cal$missing_date_indicator[cal$value == 0] == 1))
}

describe("create_full_dbi returns a complete calendar", {
  purrr::walk(c("standard", "445", "454", "544"), \(calendar_type) {
    purrr::walk(names(unit_fns), \(unit) {
      it(paste(calendar_type, unit), {
        # standard and 445 run everywhere; 454 and 544 are skipped on CRAN
        if (calendar_type %in% c("454", "544")) skip_on_cran()
        check_calendar(unit, calendar_type, grouped = FALSE)
        check_calendar(unit, calendar_type, grouped = TRUE)
      })
    })
  })

  purrr::walk(c(1, 4), \(week_start) {
    purrr::walk(c("standard", "445"), \(calendar_type) {
      it(paste(calendar_type, "week with week_start", week_start), {
        skip_on_cran()
        check_calendar("week", calendar_type, grouped = TRUE, week_start = week_start)
      })
    })
  })
})
