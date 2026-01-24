# Generate a Cross-Dialect SQL Date Series

Creates a lazy `dbplyr` table containing a continuous sequence of dates.
The function automatically detects the SQL dialect of the connection and
dispatches the most efficient native series generator (e.g.,
`GENERATE_SERIES` for DuckDB/Postgres or `GENERATOR` for Snowflake).

## Usage

``` r
seq_date_sql(
  .con,
  start_date,
  end_date,
  calendar_type = "standard",
  time_unit = "day",
  week_start = 7
)
```

## Arguments

- .con:

  A valid DBI connection object (e.g., DuckDB, Postgres, Snowflake) or a
  `dbplyr` simulated connection.

- start_date:

  A character string in 'YYYY-MM-DD' format or a Date object
  representing the start of the series.

- end_date:

  A character string in 'YYYY-MM-DD' format or a Date object
  representing the end of the series.

- time_unit:

  A character string specifying the interval. Must be one of: `"day"`,
  `"week"`, `"month"`, `"quarter"`, or `"year"`.

- week_start:

  description

## Value

A `tbl_lazy` (SQL) object with a single column `date`.

## Details

This function is designed to be "nestable," meaning the resulting SQL
can be used safely inside larger `dplyr` pipelines. It avoids `WITH`
clauses in dialects like DuckDB to prevent parser errors when `dbplyr`
wraps the query in a subquery (e.g., `SELECT * FROM (...) AS q01`).

For unit testing, the function supports `dbplyr` simulation objects. If
a `TestConnection` is detected, it returns a `lazy_frame` to avoid
metadata field queries that would otherwise fail on a mock connection.

## Examples

``` r
if (FALSE) { # \dontrun{
con <- DBI::dbConnect(duckdb::duckdb())
# Generates a daily sequence for the year 2025
calendar <- seq_date_sql("2025-01-01", "2025-12-31", "day", con)
} # }
```
