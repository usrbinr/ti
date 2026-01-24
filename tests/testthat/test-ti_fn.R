library(testthat)

describe("fpa functions", {

  it("ytd works", {
    testthat::expect_no_error({
      contoso::sales |>
        dplyr::group_by(store_key) |>
        fpa::ytd(order_date, margin, "standard") |>
        fpa::calculate() |>
        dplyr::collect() |>
        dplyr::filter(store_key == "999999") |>
        dplyr::arrange(date)
    })
  })

  it("qtd works", {
    testthat::expect_no_error({
      contoso::sales |>
        dplyr::group_by(store_key) |>
        fpa::qtd(order_date, margin, "standard") |>
        fpa::calculate() |>
        dplyr::filter(store_key == "999999") |>
        dplyr::arrange(date)
    })
  })

  it("mtd works", {
    testthat::expect_no_error({
      contoso::sales |>
        dplyr::group_by(store_key) |>
        fpa::mtd(order_date, margin, "standard") |>
        fpa::calculate() |>
        dplyr::filter(store_key == "999999") |>
        dplyr::arrange(date)
    })
  })

  it("wtd works", {
    testthat::expect_no_error({
      contoso::sales |>
        dplyr::group_by(store_key) |>
        fpa::wtd(order_date, margin, "standard") |>
        fpa::calculate() |>
        dplyr::filter(store_key == "999999") |>
        dplyr::arrange(date)
    })
  })

  it("atd works", {
    testthat::expect_no_error({
      contoso::sales |>
        dplyr::group_by(store_key) |>
        fpa::atd(order_date, margin, "standard") |>
        fpa::calculate() |>
        dplyr::collect() |>
        dplyr::filter(store_key == "999999") |>
        dplyr::arrange(date)
    })
  })

  it("yoy works", {
    testthat::expect_no_error({
      contoso::sales |>
        dplyr::group_by(store_key) |>
        fpa::yoy(order_date, margin, "standard", 1) |>
        fpa::calculate() |>
        dplyr::arrange(date) |>
        dplyr::filter(store_key == "999999") |>
        dplyr::arrange(date)
    })
  })

  it("qoq works", {
    testthat::expect_no_error({
      contoso::sales |>
        dplyr::group_by(store_key) |>
        fpa::qoq(order_date, margin, "standard") |>
        fpa::calculate() |>
        dplyr::filter(store_key == "999999") |>
        dplyr::arrange(date)
    })
  })

  it("mom works", {
    testthat::expect_no_error({
      contoso::sales |>
        dplyr::group_by(store_key) |>
        fpa::mom(order_date, margin, "standard") |>
        fpa::calculate() |>
        dplyr::filter(store_key == "999999") |>
        dplyr::arrange(date)
    })
  })

  it("wow works", {
    testthat::expect_no_error({
      contoso::sales |>
        dplyr::group_by(store_key) |>
        fpa::wow(order_date, margin, "standard") |>
        fpa::calculate() |>
        dplyr::filter(store_key == "999999") |>
        dplyr::arrange(date)
    })
  })

  it("dod works", {
    testthat::expect_no_error({
      contoso::sales |>
        dplyr::group_by(store_key) |>
        fpa::dod(order_date, margin, "standard") |>
        fpa::calculate() |>
        dplyr::filter(store_key == "999999") |>
        dplyr::arrange(date)
    })
  })

  it("yoytd works", {
    testthat::expect_no_error({
      contoso::sales |>
        dplyr::group_by(store_key) |>
        fpa::yoytd(order_date, margin, "standard", 1) |>
        fpa::calculate() |>
        dplyr::filter(store_key == "999999") |>
        dplyr::arrange(date) |>
        dplyr::filter(!is.na(pytd_margin))
    })
  })

  it("qoqtd works", {
    testthat::expect_no_error({
      contoso::sales |>
        fpa::qoqtd(order_date, margin, "standard", 1) |>
        fpa::calculate() |>
        dplyr::arrange(date) |>
        dplyr::filter(!is.na(pqtd_margin))
    })
  })

  it("momtd works", {
    testthat::expect_no_error({
      contoso::sales |>
        fpa::momtd(order_date, margin, "standard", 1) |>
        fpa::calculate() |>
        dplyr::arrange(date) |>
        dplyr::filter(!is.na(pmtd_margin))
    })
  })

  it("wowtd works", {
    testthat::expect_no_error({
      contoso::sales |>
        fpa::wowtd(.date = order_date, .value = margin, calendar_type = "standard", lag_n = 1) |>
        fpa::calculate()
    })
  })

  it("pytd works", {
    testthat::expect_no_error({
      contoso::sales |>
        dplyr::group_by(store_key) |>
        fpa::pytd(.date = order_date, .value = margin, calendar_type = "standard", lag_n = 1) |>
        fpa::calculate() |>
        dplyr::filter(store_key == "999999") |>
        dplyr::filter(!is.na(pytd_margin))
    })
  })

  it("pqtd works", {
    testthat::expect_no_error({
      contoso::sales |>
        dplyr::group_by(store_key) |>
        fpa::pqtd(.date = order_date, .value = margin, calendar_type = "standard", lag_n = 1) |>
        fpa::calculate() |>
        dplyr::filter(store_key == "999999") |>
        dplyr::filter(!is.na(pqtd_margin))
    })
  })

  it("pmtd works", {
    testthat::expect_no_error({
      contoso::sales |>
        dplyr::group_by(store_key) |>
        fpa::pmtd(.date = order_date, .value = margin, calendar_type = "standard", lag_n = 1) |>
        fpa::calculate() |>
        dplyr::filter(store_key == "999999") |>
        dplyr::filter(!is.na(pmtd_margin)) |>
        dplyr::arrange(date)
    })
  })

  it("pwtd works", {
    testthat::expect_no_error({
      contoso::sales |>
        dplyr::group_by(store_key) |>
        fpa::pwtd(.date = order_date, .value = margin, calendar_type = "standard", lag_n = 1) |>
        fpa::calculate() |>
        dplyr::filter(store_key == "999999") |>
        dplyr::filter(!is.na(pwtd_margin))
    })
  })

  it("ytdopy works", {
    testthat::expect_no_error({
      contoso::sales |>
        dplyr::group_by(store_key) |>
        fpa::ytdopy(order_date, margin, calendar_type = "standard", lag_n = 1) |>
        fpa::calculate() |>
        dplyr::filter(store_key == "999999") |>
        dplyr::filter(!is.na(yoy_margin))
    })
  })

  it("mtdopm works", {
    testthat::expect_no_error({
      contoso::sales |>
        dplyr::group_by(store_key) |>
        fpa::mtdopm(order_date, margin, calendar_type = "standard", lag_n = 1) |>
        fpa::calculate() |>
        dplyr::filter(store_key == "999999") |>
        dplyr::filter(!is.na(mom_margin)) |>
        dplyr::arrange(date)
    })
  })

  it("qtdopq works", {
    testthat::expect_no_error({
      contoso::sales |>
        dplyr::group_by(store_key) |>
        fpa::qtdopq(order_date, margin, calendar_type = "standard", lag_n = 1) |>
        fpa::calculate() |>
        dplyr::filter(store_key == "999999")
    })
  })

  it("wtdopw works", {
    testthat::expect_no_error({
      contoso::sales |>
        dplyr::group_by(store_key) |>
        fpa::wtdopw(order_date, margin, lag_n = 1, calendar_type = "standard") |>
        fpa::calculate() |>
        dplyr::filter(store_key == "999999")
    })
  })

  it("abc works", {
    testthat::expect_no_error({
      contoso::sales |>
        dplyr::group_by(store_key) |>
        fpa::abc(category_values = c(.3, .5, .7, .8), .value = margin) |>
        fpa::calculate()
    })
  })

  it("cohort works", {
    testthat::expect_no_error({
      contoso::sales |>
        dplyr::group_by(store_key) |>
        fpa::cohort(.date = order_date, .value = margin, time_unit = "month", period_label = FALSE) |>
        fpa::calculate()
    })
  })
})
