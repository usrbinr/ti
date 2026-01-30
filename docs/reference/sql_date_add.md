# Generate dialect-appropriate date addition SQL

Generate dialect-appropriate date addition SQL

## Usage

``` r
sql_date_add(.con, unit, n_expr, date_col = "date")
```

## Arguments

- .con:

  A DBI connection object

- unit:

  A character string: "month", "week", etc.

- n_expr:

  An expression string for the number of units

- date_col:

  A character string for the date column name

## Value

A [`dplyr::sql`](https://dplyr.tidyverse.org/reference/sql.html) object
