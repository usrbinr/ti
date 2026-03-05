library(testthat)

# Internal test fixtures with consecutive dates
# Package fills missing dates with 0, so use consecutive days for predictable results

describe("ytd value calculations", {
  it("computes cumulative sum correctly within year", {
    data <- dplyr::tibble(
      date = as.Date(c("2024-01-01", "2024-01-02", "2024-01-03")),
      value = c(10, 20, 30)
    )

    result <- data |>
      ti::ytd(date, value, "standard") |>
      ti::calculate() |>
      dplyr::collect() |>
      dplyr::arrange(date)

    # YTD cumsum: 10, 30, 60
    expect_equal(result$ytd_value[1], 10)
    expect_equal(result$ytd_value[2], 30)
    expect_equal(result$ytd_value[3], 60)
  })

  it("resets cumsum at year boundary", {
    data <- dplyr::tibble(
      date = as.Date(c("2023-12-31", "2024-01-01", "2024-01-02")),
      value = c(100, 10, 20)
    )

    result <- data |>
      ti::ytd(date, value, "standard") |>
      ti::calculate() |>
      dplyr::collect() |>
      dplyr::arrange(date)

    # 2023: 100
    # 2024: 10, 30 (reset)
    expect_equal(result$ytd_value[result$date == as.Date("2023-12-31")], 100)
    expect_equal(result$ytd_value[result$date == as.Date("2024-01-01")], 10)
    expect_equal(result$ytd_value[result$date == as.Date("2024-01-02")], 30)
  })
})

describe("qtd value calculations", {
  it("computes cumulative sum correctly within quarter", {
    data <- dplyr::tibble(
      date = as.Date(c("2024-03-31", "2024-04-01", "2024-04-02")),
      value = c(50, 10, 20)
    )

    result <- data |>
      ti::qtd(date, value, "standard") |>
      ti::calculate() |>
      dplyr::collect() |>
      dplyr::arrange(date)

    # Q1: 50
    # Q2: 10, 30 (reset at quarter boundary)
    expect_equal(result$qtd_value[result$date == as.Date("2024-03-31")], 50)
    expect_equal(result$qtd_value[result$date == as.Date("2024-04-01")], 10)
    expect_equal(result$qtd_value[result$date == as.Date("2024-04-02")], 30)
  })
})

describe("mtd value calculations", {
  it("computes cumulative sum correctly within month", {
    data <- dplyr::tibble(
      date = as.Date(c("2024-01-31", "2024-02-01", "2024-02-02")),
      value = c(50, 10, 20)
    )

    result <- data |>
      ti::mtd(date, value, "standard") |>
      ti::calculate() |>
      dplyr::collect() |>
      dplyr::arrange(date)

    # Jan: 50
    # Feb: 10, 30 (reset at month boundary)
    expect_equal(result$mtd_value[result$date == as.Date("2024-01-31")], 50)
    expect_equal(result$mtd_value[result$date == as.Date("2024-02-01")], 10)
    expect_equal(result$mtd_value[result$date == as.Date("2024-02-02")], 30)
  })
})

describe("atd value calculations", {
  it("computes all-time cumulative sum without reset", {
    data <- dplyr::tibble(
      date = as.Date(c("2023-12-31", "2024-01-01", "2024-01-02")),
      value = c(100, 10, 20)
    )

    result <- data |>
      ti::atd(date, value, "standard") |>
      ti::calculate() |>
      dplyr::collect() |>
      dplyr::arrange(date)

    # ATD never resets - running total across years
    expect_equal(result$atd_value[1], 100)
    expect_equal(result$atd_value[2], 110)
    expect_equal(result$atd_value[3], 130)
  })
})

describe("grouped calculations", {
  it("maintains separate cumsum per group", {
    data <- dplyr::tibble(
      date = as.Date(c(
        "2024-01-01", "2024-01-02",
        "2024-01-01", "2024-01-02"
      )),
      value = c(10, 20, 100, 200),
      group = c("A", "A", "B", "B")
    )

    result <- data |>
      dplyr::group_by(group) |>
      ti::ytd(date, value, "standard") |>
      ti::calculate() |>
      dplyr::collect() |>
      dplyr::arrange(group, date)

    # Group A: 10, 30
    # Group B: 100, 300
    a_results <- result |> dplyr::filter(group == "A")
    b_results <- result |> dplyr::filter(group == "B")

    expect_equal(a_results$ytd_value[1], 10)
    expect_equal(a_results$ytd_value[2], 30)
    expect_equal(b_results$ytd_value[1], 100)
    expect_equal(b_results$ytd_value[2], 300)
  })
})

describe("missing date filling", {
  it("fills missing dates with zero values", {
    data <- dplyr::tibble(
      date = as.Date(c("2024-01-01", "2024-01-03")),  # Gap on Jan 2
      value = c(10, 30)
    )

    result <- data |>
      ti::ytd(date, value, "standard") |>
      ti::calculate() |>
      dplyr::collect() |>
      dplyr::arrange(date)

    # Should have 3 rows (filled Jan 2 with 0)
    expect_equal(nrow(result), 3)

    # Jan 1: 10, Jan 2: 10 (0 added), Jan 3: 40
    expect_equal(result$ytd_value[1], 10)
    expect_equal(result$ytd_value[2], 10)  # Filled date, cumsum unchanged
    expect_equal(result$ytd_value[3], 40)
    expect_equal(result$value[2], 0)       # Filled with 0
  })
})
