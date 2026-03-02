library(testthat)

describe("ti functions", {

  it("ytd works", {
    testthat::expect_no_error({
      contoso::sales |>
        dplyr::group_by(store_key) |>
        ti::ytd(order_date, gross_margin, "standard") |>
        ti::calculate() |>
        dplyr::collect() |>
        dplyr::filter(store_key == "999999") |>
        dplyr::arrange(date)
    })
  })

  it("qtd works", {
    testthat::expect_no_error({
      contoso::sales |>
        dplyr::group_by(store_key) |>
        ti::qtd(order_date, gross_margin, "standard") |>
        ti::calculate() |>
        dplyr::filter(store_key == "999999") |>
        dplyr::arrange(date)
    })
  })

  it("mtd works", {
    testthat::expect_no_error({
      contoso::sales |>
        dplyr::group_by(store_key) |>
        ti::mtd(order_date, gross_margin, "standard") |>
        ti::calculate() |>
        dplyr::filter(store_key == "999999") |>
        dplyr::arrange(date)
    })
  })

  it("wtd works", {
    testthat::expect_no_error({
      contoso::sales |>
        dplyr::group_by(store_key) |>
        ti::wtd(order_date, gross_margin, "standard") |>
        ti::calculate() |>
        dplyr::filter(store_key == "999999") |>
        dplyr::arrange(date)
    })
  })

  it("atd works", {
    testthat::expect_no_error({
      contoso::sales |>
        dplyr::group_by(store_key) |>
        ti::atd(order_date, gross_margin, "standard") |>
        ti::calculate() |>
        dplyr::collect() |>
        dplyr::filter(store_key == "999999") |>
        dplyr::arrange(date)
    })
  })

  it("yoy works", {
    testthat::expect_no_error({
      contoso::sales |>
        dplyr::group_by(store_key) |>
        ti::yoy(order_date, gross_margin, "standard", 1) |>
        ti::calculate() |>
        dplyr::arrange(date) |>
        dplyr::filter(store_key == "999999") |>
        dplyr::arrange(date)
    })
  })

  it("qoq works", {
    testthat::expect_no_error({
      contoso::sales |>
        dplyr::group_by(store_key) |>
        ti::qoq(order_date, gross_margin, "standard") |>
        ti::calculate() |>
        dplyr::filter(store_key == "999999") |>
        dplyr::arrange(date)
    })
  })

  it("mom works", {
    testthat::expect_no_error({
      contoso::sales |>
        dplyr::group_by(store_key) |>
        ti::mom(order_date, gross_margin, "standard") |>
        ti::calculate() |>
        dplyr::filter(store_key == "999999") |>
        dplyr::arrange(date)
    })
  })

  it("wow works", {
    testthat::expect_no_error({
      contoso::sales |>
        dplyr::group_by(store_key) |>
        ti::wow(order_date, gross_margin, "standard") |>
        ti::calculate() |>
        dplyr::filter(store_key == "999999") |>
        dplyr::arrange(date)
    })
  })

  it("dod works", {
    testthat::expect_no_error({
      contoso::sales |>
        dplyr::group_by(store_key) |>
        ti::dod(order_date, gross_margin, "standard") |>
        ti::calculate() |>
        dplyr::filter(store_key == "999999") |>
        dplyr::arrange(date)
    })
  })

  it("yoytd works", {
    testthat::expect_no_error({
      contoso::sales |>
        dplyr::group_by(store_key) |>
        ti::yoytd(order_date, gross_margin, "standard", 1) |>
        ti::calculate() |>
        dplyr::filter(store_key == "999999") |>
        dplyr::arrange(date) |>
        dplyr::filter(!is.na(pytd_gross_margin))
    })
  })

  it("qoqtd works", {
    testthat::expect_no_error({
      contoso::sales |>
        ti::qoqtd(order_date, gross_margin, "standard", 1) |>
        ti::calculate() |>
        dplyr::arrange(date) |>
        dplyr::filter(!is.na(pqtd_gross_margin))
    })
  })

  it("momtd works", {
    testthat::expect_no_error({
      contoso::sales |>
        ti::momtd(order_date, gross_margin, "standard", 1) |>
        ti::calculate() |>
        dplyr::arrange(date) |>
        dplyr::filter(!is.na(pmtd_gross_margin))
    })
  })

  it("wowtd works", {
    testthat::expect_no_error({
      contoso::sales |>
        ti::wowtd(.date = order_date, .value = gross_margin, calendar_type = "standard", lag_n = 1) |>
        ti::calculate()
    })
  })

  it("pytd works", {
    testthat::expect_no_error({
      contoso::sales |>
        dplyr::group_by(store_key) |>
        ti::pytd(.date = order_date, .value = gross_margin, calendar_type = "standard", lag_n = 1) |>
        ti::calculate() |>
        dplyr::filter(store_key == "999999") |>
        dplyr::filter(!is.na(pytd_gross_margin))
    })
  })

  it("pqtd works", {
    testthat::expect_no_error({
      contoso::sales |>
        dplyr::group_by(store_key) |>
        ti::pqtd(.date = order_date, .value = gross_margin, calendar_type = "standard", lag_n = 1) |>
        ti::calculate() |>
        dplyr::filter(store_key == "999999") |>
        dplyr::filter(!is.na(pqtd_gross_margin))
    })
  })

  it("pmtd works", {
    testthat::expect_no_error({
      contoso::sales |>
        dplyr::group_by(store_key) |>
        ti::pmtd(.date = order_date, .value = gross_margin, calendar_type = "standard", lag_n = 1) |>
        ti::calculate() |>
        dplyr::filter(store_key == "999999") |>
        dplyr::filter(!is.na(pmtd_gross_margin)) |>
        dplyr::arrange(date)
    })
  })

  it("pwtd works", {
    testthat::expect_no_error({
      contoso::sales |>
        dplyr::group_by(store_key) |>
        ti::pwtd(.date = order_date, .value = gross_margin, calendar_type = "standard", lag_n = 1) |>
        ti::calculate() |>
        dplyr::filter(store_key == "999999") |>
        dplyr::filter(!is.na(pwtd_gross_margin))
    })
  })

  it("ytdopy works", {
    testthat::expect_no_error({
      contoso::sales |>
        dplyr::group_by(store_key) |>
        ti::ytdopy(order_date, gross_margin, calendar_type = "standard", lag_n = 1) |>
        ti::calculate() |>
        dplyr::filter(store_key == "999999") |>
        dplyr::filter(!is.na(yoy_gross_margin))
    })
  })

  it("mtdopm works", {
    testthat::expect_no_error({
      contoso::sales |>
        dplyr::group_by(store_key) |>
        ti::mtdopm(order_date, gross_margin, calendar_type = "standard", lag_n = 1) |>
        ti::calculate() |>
        dplyr::filter(store_key == "999999") |>
        dplyr::filter(!is.na(mom_gross_margin)) |>
        dplyr::arrange(date)
    })
  })

  it("qtdopq works", {
    testthat::expect_no_error({
      contoso::sales |>
        dplyr::group_by(store_key) |>
        ti::qtdopq(order_date, gross_margin, calendar_type = "standard", lag_n = 1) |>
        ti::calculate() |>
        dplyr::filter(store_key == "999999")
    })
  })

  it("wtdopw works", {
    testthat::expect_no_error({
      contoso::sales |>
        dplyr::group_by(store_key) |>
        ti::wtdopw(order_date, gross_margin, lag_n = 1, calendar_type = "standard") |>
        ti::calculate() |>
        dplyr::filter(store_key == "999999")
    })
  })

  it("abc works", {
    testthat::expect_no_error({
      contoso::sales |>
        dplyr::group_by(store_key) |>
        ti::abc(category_values = c(.3, .5, .7, .8), .value = gross_margin) |>
        ti::calculate()
    })
  })

  it("cohort works", {
    testthat::expect_no_error({
      contoso::sales |>
        dplyr::group_by(store_key) |>
        ti::cohort(.date = order_date, .value = gross_margin, time_unit = "month", period_label = FALSE) |>
        ti::calculate()
    })
  })
})
