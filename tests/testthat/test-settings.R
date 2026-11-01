# week_start and fiscal_year_start are on every function because the retail
# calendars build every fiscal period from whole weeks. Where a changed setting
# has no effect, ti says so when the object is built and when it is printed.

sales <- dplyr::tibble(
  date = seq(as.Date("2024-01-01"), as.Date("2024-03-31"), "day"),
  value = seq_along(date)
)

describe("messages for settings that have no effect", {
  it("says week_start has no effect on mom() with the standard calendar", {
    expect_message(ti::mom(sales, date, value, week_start = 1), "has no effect on `mom\\(\\)`")
  })

  it("says week_start only relabels the week column of ytd()", {
    expect_message(ti::ytd(sales, date, value, week_start = 3), "only changes the week column")
  })

  it("says fiscal_year_start has no effect on the standard calendar", {
    expect_message(ti::ytd(sales, date, value, fiscal_year_start = 7), "fiscal_year_start = 7")
  })

  # DuckDB prints its own message on new connections, so only ti's setting
  # messages are checked
  settings_msg <- "week_start|fiscal_year_start"

  it("is silent where the setting matters or is left at its default", {
    expect_no_message(ti::wow(sales, date, value, week_start = 1), message = settings_msg)
    expect_no_message(ti::wtd(sales, date, value, week_start = 1), message = settings_msg)
    expect_no_message(ti::mom(sales, date, value, calendar_type = "445", week_start = 1, fiscal_year_start = 7), message = settings_msg)
    expect_no_message(ti::mom(sales, date, value, week_start = 7, fiscal_year_start = 1), message = settings_msg)
    expect_no_message(ti::mom(sales, date, value), message = settings_msg)
  })

  it("does not repeat the message when calculate() builds inner objects", {
    x <- suppressMessages(ti::yoytd(sales, date, value, week_start = 2))
    expect_no_message(ti::calculate(x) |> dplyr::collect(), message = settings_msg)
  })

  it("prints the same explanation in the Assumptions block", {
    x <- suppressMessages(ti::mom(sales, date, value, week_start = 1, fiscal_year_start = 7))
    out <- c(utils::capture.output(msgs <- cli::cli_fmt(print(x))), msgs)
    expect_true(any(grepl("has no effect on `mom\\(\\)`", out)))
    expect_true(any(grepl("fiscal_year_start = 7", out)))
  })
})

describe("the settings really have no effect where the message says so", {
  run <- function(fn, ...) {
    suppressMessages(fn(sales, date, value, ...)) |>
      ti::calculate() |>
      dplyr::collect() |>
      dplyr::arrange(date) |>
      as.data.frame()
  }

  it("week_start does not change mom() at all", {
    expect_equal(run(ti::mom, week_start = 1), run(ti::mom))
  })

  it("week_start changes only the week column of ytd()", {
    a <- run(ti::ytd, week_start = 3)
    b <- run(ti::ytd)
    expect_equal(a[setdiff(names(a), "week")], b[setdiff(names(b), "week")])
    expect_false(identical(a$week, b$week))
  })

  it("fiscal_year_start does not change the standard calendar", {
    expect_equal(run(ti::ytd, fiscal_year_start = 7), run(ti::ytd))
    expect_equal(run(ti::qoq, fiscal_year_start = 4), run(ti::qoq))
  })
})
