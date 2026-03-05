library(testthat)

# =============================================================================
# Error Path Tests - Validate helpful error messages for invalid inputs
# =============================================================================

describe("column validation", {
  it("errors when date column doesn't exist", {
    data <- dplyr::tibble(
      wrong_name = as.Date("2024-01-01"),
      value = 10
    )

    expect_error(
      ti::ytd(data, date, value, "standard"),
      "not found in data"
    )
  })

  it("errors when value column doesn't exist", {
    data <- dplyr::tibble(
      date = as.Date("2024-01-01"),
      wrong_name = 10
    )

    expect_error(
      ti::ytd(data, date, value, "standard"),
      "not found in data"
    )
  })

  it("errors when date column is not Date type", {
    data <- dplyr::tibble(
      date = "2024-01-01",  # character, not Date
      value = 10
    )

    expect_error(
      ti::ytd(data, date, value, "standard"),
      "must be a Date"
    )
  })

  it("errors when value column is not numeric", {
    data <- dplyr::tibble(
      date = as.Date("2024-01-01"),
      value = "ten"  # character, not numeric
    )

    expect_error(
      ti::ytd(data, date, value, "standard"),
      "must be numeric"
    )
  })
})

describe("calendar_type validation", {
  it("errors with invalid calendar type", {
    data <- dplyr::tibble(
      date = as.Date("2024-01-01"),
      value = 10
    )

    expect_error(
      ti::ytd(data, date, value, "invalid_calendar"),
      "Must be one of"
    )
  })
})

describe("abc validation", {
  it("errors when data is not grouped", {
    data <- dplyr::tibble(
      product = c("A", "B", "C"),
      sales = c(100, 200, 300)
    )

    expect_error(
      ti::abc(data, c(0.2, 0.5, 1), sales),
      "grouped"
    )
  })

  it("errors when value column doesn't exist", {
    data <- dplyr::tibble(
      product = c("A", "B", "C"),
      sales = c(100, 200, 300)
    ) |>
      dplyr::group_by(product)

    expect_error(
      ti::abc(data, c(0.2, 0.5, 1), nonexistent),
      "not found in data"
    )
  })

  it("errors when value column is not numeric", {
    data <- dplyr::tibble(
      product = c("A", "B", "C"),
      sales = c("high", "medium", "low")  # character
    ) |>
      dplyr::group_by(product)

    expect_error(
      ti::abc(data, c(0.2, 0.5, 1), sales),
      "must be numeric"
    )
  })

  it("errors when category values exceed 1", {
    data <- dplyr::tibble(
      product = c("A", "B", "C"),
      sales = c(100, 200, 300)
    ) |>
      dplyr::group_by(product)

    expect_error(
      ti::abc(data, c(0.2, 0.5, 1.5), sales),
      "less than or equal to 1"
    )
  })
})

describe("empty data handling", {
  it("handles empty tibble gracefully", {
    data <- dplyr::tibble(
      date = as.Date(character()),
      value = numeric()
    )

    # Should not error during construction
    result <- ti::ytd(data, date, value, "standard")
    expect_true(inherits(result, "ti::ti") || inherits(result, "S7_object"))
  })
})

describe("NA handling in data", {
  it("handles NA values in value column", {
    data <- dplyr::tibble(
      date = as.Date(c("2024-01-01", "2024-01-02", "2024-01-03")),
      value = c(10, NA, 30)
    )

    # Should complete without error - NAs propagate through cumsum
    expect_no_error({
      result <- data |>
        ti::ytd(date, value, "standard") |>
        ti::calculate() |>
        dplyr::collect()
    })
  })

  it("handles NA values in date column", {
    data <- dplyr::tibble(
      date = as.Date(c("2024-01-01", NA, "2024-01-03")),
      value = c(10, 20, 30)
    )

    # This may error or handle gracefully - document the behavior
    # For now, we expect it to complete (NA dates filtered by calendar join)
    expect_no_error({
      result <- data |>
        ti::ytd(date, value, "standard") |>
        ti::calculate() |>
        dplyr::collect()
    })
  })
})

describe("fiscal_year_start validation", {
  it("errors with invalid fiscal year start", {
    data <- dplyr::tibble(
      date = as.Date("2024-01-01"),
      value = 10
    )

    expect_error(
      ti::ytd(data, date, value, "standard", fiscal_year_start = 13),
      "1 and 12"
    )

    expect_error(
      ti::ytd(data, date, value, "standard", fiscal_year_start = 0),
      "1 and 12"
    )
  })
})

describe("lag_n validation", {
  it("works with valid lag values", {
    data <- dplyr::tibble(
      date = as.Date(c("2023-01-01", "2024-01-01")),
      value = c(100, 200)
    )

    expect_no_error({
      ti::pytd(data, date, value, "standard", lag_n = 1)
    })

    expect_no_error({
      ti::yoy(data, date, value, "standard", lag_n = 2)
    })
  })
})
