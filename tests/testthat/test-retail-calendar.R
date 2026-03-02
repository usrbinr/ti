library(testthat)

describe("generate_retail_calendar", {

  it("produces 13 weeks per quarter for a 52-week year", {
    cal <- ti:::generate_retail_calendar(
      start_date = "2024-02-04",
      end_date = "2025-02-01",
      calendar_type = "445",
      fiscal_year_start = 2,
      week_start = 7
    )

    weeks_per_quarter <- cal |>
      dplyr::distinct(year, quarter, week) |>
      dplyr::count(year, quarter)

    # Each quarter should have 13 weeks (or 14 for 53-week year last quarter)
    expect_true(all(weeks_per_quarter$n >= 13))
  })

  it("assigns correct month week counts for 445 pattern", {
    cal <- ti:::generate_retail_calendar(
      start_date = "2024-01-01",
      end_date = "2025-12-31",
      calendar_type = "445",
      fiscal_year_start = 2,
      week_start = 7
    )

    # Use a complete fiscal year (2024 has all 12 months in range)
    weeks_per_month <- cal |>
      dplyr::distinct(year, month, week) |>
      dplyr::count(year, month) |>
      dplyr::filter(year == 2024)

    # 445 pattern: first quarter months should be 4, 4, 5
    pattern_months <- weeks_per_month$n[1:3]
    expect_equal(pattern_months, c(4L, 4L, 5L))
  })

  it("assigns correct month week counts for 454 pattern", {
    cal <- ti:::generate_retail_calendar(
      start_date = "2024-01-01",
      end_date = "2025-12-31",
      calendar_type = "454",
      fiscal_year_start = 2,
      week_start = 7
    )

    weeks_per_month <- cal |>
      dplyr::distinct(year, month, week) |>
      dplyr::count(year, month) |>
      dplyr::filter(year == 2024)

    pattern_months <- weeks_per_month$n[1:3]
    expect_equal(pattern_months, c(4L, 5L, 4L))
  })

  it("assigns correct month week counts for 544 pattern", {
    cal <- ti:::generate_retail_calendar(
      start_date = "2024-01-01",
      end_date = "2025-12-31",
      calendar_type = "544",
      fiscal_year_start = 2,
      week_start = 7
    )

    weeks_per_month <- cal |>
      dplyr::distinct(year, month, week) |>
      dplyr::count(year, month) |>
      dplyr::filter(year == 2024)

    pattern_months <- weeks_per_month$n[1:3]
    expect_equal(pattern_months, c(5L, 4L, 4L))
  })

  it("covers all dates without gaps", {
    cal <- ti:::generate_retail_calendar(
      start_date = "2024-06-01",
      end_date = "2024-12-31",
      calendar_type = "445",
      fiscal_year_start = 2,
      week_start = 7
    )

    expected_dates <- seq(as.Date("2024-06-01"), as.Date("2024-12-31"), by = "day")
    expect_equal(cal$date, expected_dates)
  })

  it("has no duplicate dates", {
    cal <- ti:::generate_retail_calendar(
      start_date = "2023-01-01",
      end_date = "2025-12-31",
      calendar_type = "445",
      fiscal_year_start = 2,
      week_start = 7
    )

    expect_equal(nrow(cal), length(unique(cal$date)))
  })
})


describe("retail calendar integration with ti functions", {

  it("ytd works with 445 calendar", {
    testthat::expect_no_error({
      contoso::sales |>
        ti::ytd(order_date, gross_margin, calendar_type = "445", fiscal_year_start = 2) |>
        ti::calculate() |>
        dplyr::collect() |>
        dplyr::arrange(date)
    })
  })

  it("qtd works with 445 calendar", {
    testthat::expect_no_error({
      contoso::sales |>
        ti::qtd(order_date, gross_margin, calendar_type = "445", fiscal_year_start = 2) |>
        ti::calculate() |>
        dplyr::collect() |>
        dplyr::arrange(date)
    })
  })

  it("mtd works with 445 calendar", {
    testthat::expect_no_error({
      contoso::sales |>
        ti::mtd(order_date, gross_margin, calendar_type = "445", fiscal_year_start = 2) |>
        ti::calculate() |>
        dplyr::collect() |>
        dplyr::arrange(date)
    })
  })

  it("ytd with 445 returns fiscal year values", {
    result <- contoso::sales |>
      ti::ytd(order_date, gross_margin, calendar_type = "445", fiscal_year_start = 2) |>
      ti::calculate() |>
      dplyr::collect() |>
      dplyr::arrange(date)

    # Should have year column with fiscal year values
    expect_true("year" %in% names(result))
    # Fiscal year values should exist
    expect_true(all(!is.na(result$year)))
  })

  it("grouped ytd works with 454 calendar", {
    testthat::expect_no_error({
      contoso::sales |>
        dplyr::group_by(store_key) |>
        ti::ytd(order_date, gross_margin, calendar_type = "454", fiscal_year_start = 2) |>
        ti::calculate() |>
        dplyr::collect() |>
        dplyr::filter(store_key == "999999") |>
        dplyr::arrange(date)
    })
  })

  it("wtd works with 445 calendar", {
    testthat::expect_no_error({
      contoso::sales |>
        ti::wtd(order_date, gross_margin, calendar_type = "445", fiscal_year_start = 2) |>
        ti::calculate() |>
        dplyr::collect() |>
        dplyr::arrange(date)
    })
  })

  it("atd works with 445 calendar", {
    testthat::expect_no_error({
      contoso::sales |>
        ti::atd(order_date, gross_margin, calendar_type = "445", fiscal_year_start = 2) |>
        ti::calculate() |>
        dplyr::collect() |>
        dplyr::arrange(date)
    })
  })

  it("pytd works with 445 calendar", {
    testthat::expect_no_error({
      contoso::sales |>
        ti::pytd(order_date, gross_margin, calendar_type = "445", fiscal_year_start = 2, lag_n = 1) |>
        ti::calculate() |>
        dplyr::collect() |>
        dplyr::arrange(date)
    })
  })

  it("pqtd works with 445 calendar", {
    testthat::expect_no_error({
      contoso::sales |>
        ti::pqtd(order_date, gross_margin, calendar_type = "445", fiscal_year_start = 2, lag_n = 1) |>
        ti::calculate() |>
        dplyr::collect() |>
        dplyr::arrange(date)
    })
  })

  it("pmtd works with 445 calendar", {

    testthat::expect_no_error({
      contoso::sales |>
        ti::pmtd(order_date, gross_margin, calendar_type = "445", fiscal_year_start = 2, lag_n = 1) |>
        ti::calculate() |>
        dplyr::collect() |>
        dplyr::arrange(date)
    })
  })

  it("pwtd works with 445 calendar", {

    testthat::expect_no_error({
      contoso::sales |>
        ti::pwtd(order_date, gross_margin, calendar_type = "445", fiscal_year_start = 2, lag_n = 1) |>
        ti::calculate() |>
        dplyr::collect() |>
        dplyr::arrange(date)
    })
  })

  it("yoy works with 445 calendar", {
    testthat::expect_no_error({
      contoso::sales |>
        ti::yoy(order_date, gross_margin, calendar_type = "445", fiscal_year_start = 2, lag_n = 1) |>
        ti::calculate() |>
        dplyr::collect() |>
        dplyr::arrange(date)
    })
  })

  it("qoq works with 445 calendar", {
    testthat::expect_no_error({
      contoso::sales |>
        ti::qoq(order_date, gross_margin, calendar_type = "445", fiscal_year_start = 2, lag_n = 1) |>
        ti::calculate() |>
        dplyr::collect() |>
        dplyr::arrange(date)
    })
  })

  it("mom works with 445 calendar", {
    testthat::expect_no_error({
      contoso::sales |>
        ti::mom(order_date, gross_margin, calendar_type = "445", fiscal_year_start = 2, lag_n = 1) |>
        ti::calculate() |>
        dplyr::collect() |>
        dplyr::arrange(date)
    })
  })

  it("wow works with 445 calendar", {
    testthat::expect_no_error({
      contoso::sales |>
        ti::wow(order_date, gross_margin, calendar_type = "445", fiscal_year_start = 2, lag_n = 1) |>
        ti::calculate() |>
        dplyr::collect() |>
        dplyr::arrange(date)
    })
  })

  it("dod works with 445 calendar", {
    testthat::expect_no_error({
      contoso::sales |>
        ti::dod(order_date, gross_margin, calendar_type = "445", fiscal_year_start = 2, lag_n = 1) |>
        ti::calculate() |>
        dplyr::collect() |>
        dplyr::arrange(date)
    })
  })

  it("yoytd works with 445 calendar", {
    testthat::expect_no_error({
      contoso::sales |>
        ti::yoytd(order_date, gross_margin, calendar_type = "445", fiscal_year_start = 2, lag_n = 1) |>
        ti::calculate() |>
        dplyr::collect() |>
        dplyr::arrange(date)
    })
  })

  it("qoqtd works with 445 calendar", {

    testthat::expect_no_error({
      contoso::sales |>
        ti::qoqtd(order_date, gross_margin, calendar_type = "445", fiscal_year_start = 2, lag_n = 1) |>
        ti::calculate() |>
        dplyr::collect() |>
        dplyr::arrange(date)
    })
  })

  it("momtd works with 445 calendar", {

    testthat::expect_no_error({
      contoso::sales |>
        ti::momtd(order_date, gross_margin, calendar_type = "445", fiscal_year_start = 2, lag_n = 1) |>
        ti::calculate() |>
        dplyr::collect() |>
        dplyr::arrange(date)
    })
  })

  it("wowtd works with 445 calendar", {

    testthat::expect_no_error({
      contoso::sales |>
        ti::wowtd(order_date, gross_margin, calendar_type = "445", fiscal_year_start = 2, lag_n = 1) |>
        ti::calculate() |>
        dplyr::collect()
    })
  })

  it("ytdopy works with 445 calendar", {
    testthat::expect_no_error({
      contoso::sales |>
        ti::ytdopy(order_date, gross_margin, calendar_type = "445", fiscal_year_start = 2, lag_n = 1) |>
        ti::calculate() |>
        dplyr::collect() |>
        dplyr::arrange(date)
    })
  })

  it("qtdopq works with 445 calendar", {
    testthat::expect_no_error({
      contoso::sales |>
        ti::qtdopq(order_date, gross_margin, calendar_type = "445", fiscal_year_start = 2, lag_n = 1) |>
        ti::calculate() |>
        dplyr::collect() |>
        dplyr::arrange(date)
    })
  })

  it("mtdopm works with 445 calendar", {
    testthat::expect_no_error({
      contoso::sales |>
        ti::mtdopm(order_date, gross_margin, calendar_type = "445", fiscal_year_start = 2, lag_n = 1) |>
        ti::calculate() |>
        dplyr::collect() |>
        dplyr::arrange(date)
    })
  })

  it("wtdopw works with 445 calendar", {
    testthat::expect_no_error({
      contoso::sales |>
        ti::wtdopw(order_date, gross_margin, calendar_type = "445", fiscal_year_start = 2, lag_n = 1) |>
        ti::calculate() |>
        dplyr::collect() |>
        dplyr::arrange(date)
    })
  })
})


describe("544 calendar integration", {

  it("ytd works with 544 calendar", {
    testthat::expect_no_error({
      contoso::sales |>
        ti::ytd(order_date, gross_margin, calendar_type = "544", fiscal_year_start = 2) |>
        ti::calculate() |>
        dplyr::collect() |>
        dplyr::arrange(date)
    })
  })

  it("qoq works with 544 calendar", {
    testthat::expect_no_error({
      contoso::sales |>
        ti::qoq(order_date, gross_margin, calendar_type = "544", fiscal_year_start = 2, lag_n = 1) |>
        ti::calculate() |>
        dplyr::collect() |>
        dplyr::arrange(date)
    })
  })

  it("momtd works with 544 calendar", {

    testthat::expect_no_error({
      contoso::sales |>
        ti::momtd(order_date, gross_margin, calendar_type = "544", fiscal_year_start = 2, lag_n = 1) |>
        ti::calculate() |>
        dplyr::collect() |>
        dplyr::arrange(date)
    })
  })

  it("wtdopw works with 544 calendar", {
    testthat::expect_no_error({
      contoso::sales |>
        ti::wtdopw(order_date, gross_margin, calendar_type = "544", fiscal_year_start = 2, lag_n = 1) |>
        ti::calculate() |>
        dplyr::collect() |>
        dplyr::arrange(date)
    })
  })
})


describe("fiscal_year_start variations", {

  it("ytd works with fiscal_year_start = 7", {
    testthat::expect_no_error({
      contoso::sales |>
        ti::ytd(order_date, gross_margin, calendar_type = "445", fiscal_year_start = 7) |>
        ti::calculate() |>
        dplyr::collect() |>
        dplyr::arrange(date)
    })
  })

  it("qoq works with fiscal_year_start = 10", {
    testthat::expect_no_error({
      contoso::sales |>
        ti::qoq(order_date, gross_margin, calendar_type = "454", fiscal_year_start = 10, lag_n = 1) |>
        ti::calculate() |>
        dplyr::collect() |>
        dplyr::arrange(date)
    })
  })

  it("mtd works with fiscal_year_start = 4", {
    testthat::expect_no_error({
      contoso::sales |>
        ti::mtd(order_date, gross_margin, calendar_type = "544", fiscal_year_start = 4) |>
        ti::calculate() |>
        dplyr::collect() |>
        dplyr::arrange(date)
    })
  })
})
