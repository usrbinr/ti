# Detect SQL dialect from a DBI connection

Detect SQL dialect from a DBI connection

## Usage

``` r
detect_sql_dialect(.con)
```

## Arguments

- .con:

  A DBI connection object

## Value

A character string: "snowflake", "duckdb", or "postgres"
