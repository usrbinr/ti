# ti must run as read-only queries: nothing is written to the database, so it
# works with read-only access and separate results never share a table.

local_sales_db <- function(env = parent.frame(), read_only = FALSE) {
  path <- withr::local_tempfile(fileext = ".duckdb", .local_envir = env)
  con <- DBI::dbConnect(duckdb::duckdb(), path)
  DBI::dbWriteTable(con, "sales", contoso::sales)
  if (read_only) {
    DBI::dbDisconnect(con, shutdown = TRUE)
    con <- DBI::dbConnect(duckdb::duckdb(), path, read_only = TRUE)
  }
  withr::defer(DBI::dbDisconnect(con, shutdown = TRUE), envir = env)
  con
}

run_all <- function(sales) {
  grouped <- dplyr::group_by(sales, store_key)
  list(
    standard = ti::ytd(sales, order_date, net_revenue),
    week     = ti::wowtd(grouped, order_date, net_revenue),
    retail   = ti::mom(grouped, order_date, net_revenue, calendar_type = "445"),
    retail_c = ti::ytdopy(sales, order_date, net_revenue, calendar_type = "544"),
    ptd      = ti::pmtd(grouped, order_date, net_revenue),
    abc      = ti::abc(grouped, category_values = c(0.5, 0.8, 1), .value = net_revenue)
  ) |>
    purrr::map(\(x) x |> ti::calculate() |> dplyr::collect())
}

describe("database access", {
  it("writes no tables", {
    con <- local_sales_db()
    before <- DBI::dbListTables(con)
    results <- run_all(dplyr::tbl(con, "sales"))
    expect_equal(DBI::dbListTables(con), before)
    purrr::walk(results, \(r) expect_gt(nrow(r), 0))
  })

  # DuckDB still allows temporary tables on a read-only connection, so this
  # only checks nothing needs to write to the database file itself; the test
  # above is the one that catches temporary tables
  it("works with a read-only connection", {
    skip_on_cran()
    con <- local_sales_db(read_only = TRUE)
    results <- run_all(dplyr::tbl(con, "sales"))
    purrr::walk(results, \(r) expect_gt(nrow(r), 0))
  })

  it("gives the same results from a database table as from a data frame", {
    con <- local_sales_db()
    from_db <- ti::mom(dplyr::tbl(con, "sales"), order_date, net_revenue, calendar_type = "445") |>
      ti::calculate() |> dplyr::collect() |> dplyr::arrange(date)
    from_df <- ti::mom(contoso::sales, order_date, net_revenue, calendar_type = "445") |>
      ti::calculate() |> dplyr::collect() |> dplyr::arrange(date)
    expect_equal(as.data.frame(from_db), as.data.frame(from_df))
  })

  it("keeps each retail result's own calendar", {
    con <- local_sales_db()
    sales <- dplyr::tbl(con, "sales")
    early <- dplyr::filter(sales, order_date < as.Date("2022-01-01"))
    late <- dplyr::filter(sales, order_date >= as.Date("2024-01-01"))

    a <- ti::ytd(early, order_date, net_revenue, calendar_type = "445") |> ti::calculate()
    expected_a <- a |> dplyr::collect() |> dplyr::arrange(date)

    # building a second retail result must not change the first
    b <- ti::ytd(late, order_date, net_revenue, calendar_type = "445") |> ti::calculate()
    b_rows <- b |> dplyr::collect()

    expect_equal(as.data.frame(a |> dplyr::collect() |> dplyr::arrange(date)), as.data.frame(expected_a))
    expect_true(max(as.Date(expected_a$date)) < as.Date("2022-01-01"))
    expect_true(min(as.Date(b_rows$date)) >= as.Date("2024-01-01"))
  })
})

describe("database detection", {
  it("accepts DuckDB", {
    con <- DBI::dbConnect(duckdb::duckdb())
    withr::defer(DBI::dbDisconnect(con, shutdown = TRUE))
    expect_equal(ti:::detect_sql_dialect(con), "duckdb")
  })

  it("stops with a clear error for databases it does not support", {
    fake <- structure(list(), class = "Microsoft SQL Server")
    expect_error(ti:::detect_sql_dialect(fake), "does not support this database")
  })

  it("warns that untested databases are untested", {
    rlang::local_options(rlib_warning_verbosity = "verbose")
    fake <- structure(list(), class = "Snowflake")
    expect_warning(dialect <- ti:::detect_sql_dialect(fake), "not been tested")
    expect_equal(dialect, "snowflake")
  })
})
