# Independent reference implementation used to validate every ti function.
#
# It works day by day in plain R on a small in-memory table and follows the
# documented definitions directly. It shares no code with the package except
# generate_retail_calendar() for fiscal labels, which has its own tests in
# test-retail-calendar.R.

# Fixture: two stores with gaps, different active ranges, a leap day, and
# month, quarter and year boundaries (including a partial week at 1 January).
ref_fixture <- function() {
  set.seed(20261031)
  days <- seq(as.Date("2023-11-15"), as.Date("2025-03-10"), by = "day")
  a <- dplyr::tibble(store = "a", date = days)
  b <- dplyr::tibble(store = "b", date = days[days >= as.Date("2024-01-20") & days <= as.Date("2025-01-25")])
  dplyr::bind_rows(a, b) |>
    dplyr::slice_sample(prop = 0.7) |>
    dplyr::bind_rows(
      # make sure the edges and the leap day are present
      dplyr::tibble(
        store = c("a", "a", "a", "b", "b"),
        date = as.Date(c("2023-11-15", "2024-02-29", "2025-03-10", "2024-01-20", "2025-01-25"))
      )
    ) |>
    dplyr::distinct(store, date) |>
    dplyr::mutate(value = sample(1:100, dplyr::n(), replace = TRUE)) |>
    # two rows on the same day must be summed
    dplyr::bind_rows(dplyr::tibble(store = "a", date = as.Date("2024-02-29"), value = 1000L)) |>
    dplyr::mutate(value = as.numeric(value)) |>
    dplyr::arrange(store, date)
}

# Week number where week 1 contains 1 January and weeks start on week_start
# (1 = Monday ... 7 = Sunday), as in Excel's WEEKNUM().
ref_weeknum <- function(date, week_start) {
  jan1 <- lubridate::floor_date(date, "year")
  offset <- (lubridate::wday(jan1, week_start = week_start) - 1)
  (lubridate::yday(date) - 1 + offset) %/% 7 + 1
}

# Complete daily table per group, with calendar labels and period keys
ref_daily <- function(data, grouped, calendar_type = "standard", week_start = 7) {
  data <- data |>
    dplyr::summarise(value = sum(value), .by = c(if (grouped) "store", "date"))
  if (!grouped) data$store <- "all"

  full <- data |>
    dplyr::summarise(from = min(date), to = max(date), .by = store) |>
    purrr::pmap(\(store, from, to) dplyr::tibble(store = store, date = seq(from, to, by = "day"))) |>
    purrr::list_rbind() |>
    dplyr::left_join(data, by = c("store", "date")) |>
    dplyr::mutate(value = dplyr::coalesce(value, 0))

  # Labels on a calendar that extends well past the data, so every period's
  # true first day is known even when the data starts mid-period
  cal <- ref_calendar(min(full$date) - 400, max(full$date) + 400, calendar_type, week_start)
  starts <- purrr::map(c("year", "quarter", "month", "week", "day", "all"), \(period) {
    key <- ref_key(period)
    cal |>
      dplyr::summarise(start = min(date), .by = dplyr::all_of(key)) |>
      dplyr::rename_with(\(x) paste0("start_", period), "start")
  })

  full <- dplyr::inner_join(full, cal, by = "date")
  purrr::reduce2(starts, c("year", "quarter", "month", "week", "day", "all"), \(acc, s, period) {
    dplyr::left_join(acc, s, by = ref_key(period))
  }, .init = full)
}

ref_calendar <- function(from, to, calendar_type, week_start) {
  if (calendar_type == "standard") {
    cal <- dplyr::tibble(date = seq(from, to, by = "day")) |>
      dplyr::mutate(
        year = lubridate::year(date),
        quarter = lubridate::quarter(date),
        month = lubridate::month(date),
        week = ref_weeknum(date, week_start)
      )
  } else {
    cal <- ti:::generate_retail_calendar(from, to, calendar_type, week_start = week_start)
  }
  cal |>
    dplyr::mutate(
      key_year = year,
      key_quarter = paste(year, quarter),
      key_month = paste(year, month),
      key_week = paste(year, week),
      key_day = as.character(date),
      key_all = "all"
    )
}

# Column in `daily` that identifies a period, e.g. "key_month" holds "2024 2"
ref_key <- function(period) paste0("key_", period)

# Running total that restarts at the start of each period (ytd, mtd, wtd, ...).
# Adds `running_total` to every row of `daily`. For period = "month":
#
#   store date       value  running_total
#   a     2024-01-30    10             10 + earlier January days
#   a     2024-01-31     5             ... + 5
#   a     2024-02-01     7              7  <- new month, restarts
ref_td <- function(daily, period) {
  daily |>
    dplyr::arrange(store, date) |>
    dplyr::mutate(running_total = cumsum(value), .by = c(store, dplyr::all_of(ref_key(period))))
}

# One row per period: the period's first day, its total, and the total lag_n
# periods earlier (yoy, mom, wow, ...). For period = "month":
#
#   store date       total  prior
#   a     2023-11-01   874     NA  <- no earlier month
#   a     2023-12-01  1018    874
ref_xox <- function(daily, period, lag_n = 1) {
  daily |>
    dplyr::summarise(
      date = min(.data[[paste0("start_", period)]]), total = sum(value),
      .by = c(store, dplyr::all_of(ref_key(period)))
    ) |>
    dplyr::arrange(store, date) |>
    dplyr::mutate(prior = dplyr::lag(total, lag_n), .by = store)
}

# The same point in time lag_n periods earlier. Months roll back to the end of
# a shorter month, and when `date` is the last day of its month the cutoff is
# the last day of the earlier month. For period = "month":
#
#   2024-03-15 -> 2024-02-15
#   2024-03-30 -> 2024-02-29   (30 February does not exist)
#   2024-03-31 -> 2024-02-29   (month end -> month end)
#   2024-02-29 -> 2024-01-31   (month end -> month end)
ref_cutoff <- function(date, period, lag_n) {
  if (period == "week") return(date - 7 * lag_n)
  months_back <- lag_n * c(year = 12, quarter = 3, month = 1)[[period]]
  shifted <- lubridate::add_with_rollback(date, -months(months_back))
  is_eom <- date == lubridate::ceiling_date(date, "month") - 1
  dplyr::if_else(is_eom, lubridate::ceiling_date(shifted, "month") - 1, shifted)
}

# Previous period to date (pytd, pmtd, ...): for each day, the earlier period's
# running total on the cutoff date. Adds `cutoff` and `previous_to_date`:
#
#   store date       cutoff     previous_to_date
#   a     2024-03-15 2024-02-15 February 1-15 running total
#   a     2024-03-31 2024-02-29 all of February
ref_ptd <- function(daily, period, lag_n = 1) {
  running <- ref_td(daily, period) |>
    dplyr::select(store, cutoff = date, previous_to_date = running_total)
  daily |>
    dplyr::mutate(cutoff = ref_cutoff(date, period, lag_n)) |>
    dplyr::left_join(running, by = c("store", "cutoff"))
}

# The previous period's full total on every day of the period (ytdopy,
# mtdopm, ...). Adds `prior` to every row of `daily`:
#
#   store date       prior
#   a     2024-02-10 1034   <- all of January
#   a     2024-02-11 1034
ref_prior_total <- function(daily, period, lag_n = 1) {
  totals <- ref_xox(daily, period, lag_n) |> dplyr::select(store, dplyr::all_of(ref_key(period)), prior)
  dplyr::left_join(daily, totals, by = c("store", ref_key(period)))
}

# Run a ti function on the fixture and return a tibble keyed by store and date
ti_result <- function(fn, data, grouped, ...) {
  if (grouped) data <- dplyr::group_by(data, store)
  out <- fn(data, .date = date, .value = value, ...) |>
    ti::calculate() |>
    dplyr::collect() |>
    dplyr::ungroup() |>
    dplyr::mutate(date = as.Date(date))
  if (!grouped) out$store <- "all"
  out
}

# Compare expected and actual on (store, date); NA and 0 are treated as different
expect_matches_reference <- function(actual, expected, actual_col, expected_col) {
  joined <- dplyr::inner_join(
    expected |> dplyr::select(store, date, expected = dplyr::all_of(expected_col)),
    actual |> dplyr::select(store, date, actual = dplyr::all_of(actual_col)),
    by = c("store", "date")
  )
  # every expected row must be present exactly once
  testthat::expect_equal(nrow(joined), nrow(expected))
  testthat::expect_equal(anyDuplicated(actual[c("store", "date")]), 0L)
  bad <- joined |>
    dplyr::filter(!(is.na(expected) & is.na(actual)) & (is.na(expected) != is.na(actual) | abs(expected - actual) > 1e-8))
  testthat::expect(
    nrow(bad) == 0,
    paste0(
      nrow(bad), " of ", nrow(joined), " rows differ from the reference for `", actual_col, "`. First rows:\n",
      paste(utils::capture.output(print(utils::head(as.data.frame(bad), 6))), collapse = "\n")
    )
  )
  invisible(bad)
}
