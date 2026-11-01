# The printed summary explains what a calculation will do and the conventions
# behind its numbers. Snapshots lock that text, so changing a convention
# without updating its explanation shows up as a snapshot diff in review.

sales <- dplyr::tibble(
  store = rep(c("a", "b"), each = 6),
  date = as.Date(c(
    "2024-01-01", "2024-01-15", "2024-02-10", "2024-02-29", "2024-03-31", "2024-04-02",
    "2024-01-20", "2024-02-01", "2024-02-28", "2024-03-15", "2024-03-30", "2024-04-01"
  )),
  value = c(10, 20, 30, 40, 50, 60, 5, 15, 25, 35, 45, 55)
)
grouped <- dplyr::group_by(sales, store)

# build objects outside the snapshot; only print() is recorded
objects <- list(
  ytd = ti::ytd(sales, date, value),
  atd = ti::atd(sales, date, value),
  wow_grouped = ti::wow(grouped, date, value),
  wow_monday_lag2 = ti::wow(sales, date, value, lag_n = 2, week_start = 1),
  pmtd_grouped = ti::pmtd(grouped, date, value),
  pwtd = ti::pwtd(sales, date, value),
  yoytd = ti::yoytd(sales, date, value),
  ytdopy = ti::ytdopy(sales, date, value),
  mom_retail = ti::mom(sales, date, value, calendar_type = "445", fiscal_year_start = 7, week_start = 1),
  abc = ti::abc(grouped, category_values = c(0.5, 0.8, 1), .value = value),
  cohort = ti::cohort(sales, date, store)
)

describe("print output", {
  purrr::iwalk(objects, \(x, nm) {
    it(paste("explains", nm), expect_snapshot(print(x)))
  })
})

# print() writes some lines as cli messages and some to stdout; keep both
print_lines <- function(x) {
  msgs <- character()
  out <- utils::capture.output(msgs <- cli::cli_fmt(print(x)))
  c(out, msgs)
}

describe("print details", {
  it("does not say anything was executed", {
    out <- print_lines(objects$ytd)
    expect_false(any(grepl("executed", out)))
    expect_true(any(grepl("nothing has been calculated yet", out)))
  })

  it("shows ticked steps with their details when colour is off", {
    withr::local_options(cli.num_colors = 1)
    out <- print_lines(objects$wow_monday_lag2)
    expect_true(any(grepl("Aggregate value", out)))
    expect_true(any(grepl("Shift 2 weeks", out)))
    expect_true(any(grepl("Compare previous week", out)))
  })

  it("counts missing periods at the function's grain", {
    out <- print_lines(objects$wow_grouped)
    # 2024-01-01 to 2024-04-02 spans 14 Sunday-start weeks (the first is cut
    # at 1 January); data falls in weeks 1, 3, 5, 6, 9, 11, 13 and 14
    expect_true(any(grepl("6 of 14 weeks had no data", out)))
  })

  it("stores steps as TRUE/FALSE", {
    steps <- objects$pmtd_grouped@action@value
    expect_type(steps, "logical")
    expect_equal(names(steps), c("aggregate", "shift", "compare", "proportion of total", "count distinct"))
    expect_equal(unname(steps), c(TRUE, TRUE, FALSE, FALSE, FALSE))
  })
})
