library(testthat)

describe("fpaR functions", {

  it("ytd works", {
    testthat::expect_no_error({
      contoso::sales |>
        dplyr::group_by(store_key) |>
        fpaR::ytd(order_date, margin, "standard") |>
        fpaR::calculate() |>
        dplyr::collect() |>
        dplyr::filter(store_key == "999999") |>
        dplyr::arrange(date)
    })
  })

  it("qtd works", {
    testthat::expect_no_error({
      contoso::sales |>
        dplyr::group_by(store_key) |>
        fpaR::qtd(order_date, margin, "standard") |>
        fpaR::calculate() |>
        dplyr::filter(store_key == "999999") |>
        dplyr::arrange(date)
    })
  })

  it("mtd works", {
    testthat::expect_no_error({
      contoso::sales |>
        dplyr::group_by(store_key) |>
        fpaR::mtd(order_date, margin, "standard") |>
        fpaR::calculate() |>
        dplyr::filter(store_key == "999999") |>
        dplyr::arrange(date)
    })
  })

  it("wtd works", {
    testthat::expect_no_error({
      contoso::sales |>
        dplyr::group_by(store_key) |>
        fpaR::wtd(order_date, margin, "standard") |>
        fpaR::calculate() |>
        dplyr::filter(store_key == "999999") |>
        dplyr::arrange(date)
    })
  })

  it("atd works", {
    testthat::expect_no_error({
      contoso::sales |>
        dplyr::group_by(store_key) |>
        fpaR::atd(order_date, margin, "standard") |>
        fpaR::calculate() |>
        dplyr::collect() |>
        dplyr::filter(store_key == "999999") |>
        dplyr::arrange(date)
    })
  })

  it("yoy works", {
    testthat::expect_no_error({
      contoso::sales |>
        dplyr::group_by(store_key) |>
        fpaR::yoy(order_date, margin, "standard", 1) |>
        fpaR::calculate() |>
        dplyr::arrange(date) |>
        dplyr::filter(store_key == "999999") |>
        dplyr::arrange(date)
    })
  })

  it("qoq works", {
    testthat::expect_no_error({
      contoso::sales |>
        dplyr::group_by(store_key) |>
        fpaR::qoq(order_date, margin, "standard") |>
        fpaR::calculate() |>
        dplyr::filter(store_key == "999999") |>
        dplyr::arrange(date)
    })
  })

  it("mom works", {
    testthat::expect_no_error({
      contoso::sales |>
        dplyr::group_by(store_key) |>
        fpaR::mom(order_date, margin, "standard") |>
        fpaR::calculate() |>
        dplyr::filter(store_key == "999999") |>
        dplyr::arrange(date)
    })
  })

  it("wow works", {
    testthat::expect_no_error({
      contoso::sales |>
        dplyr::group_by(store_key) |>
        fpaR::wow(order_date, margin, "standard") |>
        fpaR::calculate() |>
        dplyr::filter(store_key == "999999") |>
        dplyr::arrange(date)
    })
  })

  it("dod works", {
    testthat::expect_no_error({
      contoso::sales |>
        dplyr::group_by(store_key) |>
        fpaR::dod(order_date, margin, "standard") |>
        fpaR::calculate() |>
        dplyr::filter(store_key == "999999") |>
        dplyr::arrange(date)
    })
  })

  it("yoytd works", {
    testthat::expect_no_error({
      contoso::sales |>
        dplyr::group_by(store_key) |>
        fpaR::yoytd(order_date, margin, "standard", 1) |>
        fpaR::calculate() |>
        dplyr::filter(store_key == "999999") |>
        dplyr::arrange(date) |>
        dplyr::filter(!is.na(pytd_margin))
    })
  })

  it("qoqtd works", {
    testthat::expect_no_error({
      contoso::sales |>
        fpaR::qoqtd(order_date, margin, "standard", 1) |>
        fpaR::calculate() |>
        dplyr::arrange(date) |>
        dplyr::filter(!is.na(pqtd_margin))
    })
  })

  it("momtd works", {
    testthat::expect_no_error({
      contoso::sales |>
        fpaR::momtd(order_date, margin, "standard", 1) |>
        fpaR::calculate() |>
        dplyr::arrange(date) |>
        dplyr::filter(!is.na(pmtd_margin))
    })
  })

  it("wowtd works", {
    testthat::expect_no_error({
      contoso::sales |>
        fpaR::wowtd(.date = order_date, .value = margin, calendar_type = "standard", lag_n = 1) |>
        fpaR::calculate()
    })
  })

  it("pytd works", {
    testthat::expect_no_error({
      contoso::sales |>
        dplyr::group_by(store_key) |>
        fpaR::pytd(.date = order_date, .value = margin, calendar_type = "standard", lag_n = 1) |>
        fpaR::calculate() |>
        dplyr::filter(store_key == "999999") |>
        dplyr::filter(!is.na(pytd_margin))
    })
  })

  it("pqtd works", {
    testthat::expect_no_error({
      contoso::sales |>
        dplyr::group_by(store_key) |>
        fpaR::pqtd(.date = order_date, .value = margin, calendar_type = "standard", lag_n = 1) |>
        fpaR::calculate() |>
        dplyr::filter(store_key == "999999") |>
        dplyr::filter(!is.na(pqtd_margin))
    })
  })

  it("pmtd works", {
    testthat::expect_no_error({
      contoso::sales |>
        dplyr::group_by(store_key) |>
        fpaR::pmtd(.date = order_date, .value = margin, calendar_type = "standard", lag_n = 1) |>
        fpaR::calculate() |>
        dplyr::filter(store_key == "999999") |>
        dplyr::filter(!is.na(pmtd_margin)) |>
        dplyr::arrange(date)
    })
  })

  it("pwtd works", {
    testthat::expect_no_error({
      contoso::sales |>
        dplyr::group_by(store_key) |>
        fpaR::pwtd(.date = order_date, .value = margin, calendar_type = "standard", lag_n = 1) |>
        fpaR::calculate() |>
        dplyr::filter(store_key == "999999") |>
        dplyr::filter(!is.na(pwtd_margin))
    })
  })

  it("ytdopy works", {
    testthat::expect_no_error({
      contoso::sales |>
        dplyr::group_by(store_key) |>
        fpaR::ytdopy(order_date, margin, calendar_type = "standard", lag_n = 1) |>
        fpaR::calculate() |>
        dplyr::filter(store_key == "999999") |>
        dplyr::filter(!is.na(yoy_margin))
    })
  })

  it("mtdopm works", {
    testthat::expect_no_error({
      contoso::sales |>
        dplyr::group_by(store_key) |>
        fpaR::mtdopm(order_date, margin, calendar_type = "standard", lag_n = 1) |>
        fpaR::calculate() |>
        dplyr::filter(store_key == "999999") |>
        dplyr::filter(!is.na(mom_margin)) |>
        dplyr::arrange(date)
    })
  })

  it("qtdopq works", {
    testthat::expect_no_error({
      contoso::sales |>
        dplyr::group_by(store_key) |>
        fpaR::qtdopq(order_date, margin, calendar_type = "standard", lag_n = 1) |>
        fpaR::calculate() |>
        dplyr::filter(store_key == "999999")
    })
  })

  it("wtdopw works", {
    testthat::expect_no_error({
      contoso::sales |>
        dplyr::group_by(store_key) |>
        fpaR::wtdopw(order_date, margin, lag_n = 1, calendar_type = "standard") |>
        fpaR::calculate() |>
        dplyr::filter(store_key == "999999")
    })
  })

  it("abc works", {
    testthat::expect_no_error({
      contoso::sales |>
        dplyr::group_by(store_key) |>
        fpaR::abc(category_values = c(.3, .5, .7, .8), .value = margin) |>
        fpaR::calculate()
    })
  })

  it("cohort works", {
    testthat::expect_no_error({
      contoso::sales |>
        dplyr::group_by(store_key) |>
        fpaR::cohort(.date = order_date, .value = margin, time_unit = "month", period_label = FALSE) |>
        fpaR::calculate()
    })
  })
})
