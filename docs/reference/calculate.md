# Execute time-intelligence or segments class objects to return the underlying transformed table

The `calculate()` function takes an object created by a time function
(like [`ytd()`](https://codeberg.org/usrbinr/ti/reference/ytd.md),
[`mtd()`](https://codeberg.org/usrbinr/ti/reference/mtd.md), or
[`qtd()`](https://codeberg.org/usrbinr/ti/reference/qtd.md)) or a
segment function (like
[`cohort()`](https://codeberg.org/usrbinr/ti/reference/cohort.md) or
[`abc()`](https://codeberg.org/usrbinr/ti/reference/abc.md)) and
executes the underlying transformation logic. It translates the function
blueprint into an actionable query, returning the final data table.

## Arguments

- x:

  ti object

## Value

dbi object

## Details

The TI and segment functions in **fpaR**—such as
[`ytd()`](https://codeberg.org/usrbinr/ti/reference/ytd.md) or
[`cohort()`](https://codeberg.org/usrbinr/ti/reference/cohort.md) and
others—are designed to be **lazy and database-friendly**. They do not
perform the heavy data transformation immediately. Instead, they return
a blueprint object (of class `ti`,`segment_abc` or `segment_cohort`)
that contains all the parameters and logic needed for the calculation.

**`calculate()`** serves as the **execution engine**.

When called, it interprets the blueprint and generates optimized R code
or SQL code (using the `dbplyr` package) that is then executed
efficiently on the data source, whether it's an in-memory `tibble` or a
remote database backend (like `duckdb` or `snowflake`). This approach
minimizes data transfer and improves performance for large datasets.

The resulting table will be sorted by the relevant date column to ensure
the correct temporal ordering of the calculated metrics.

## Examples

``` r
if (FALSE) { # \dontrun{
x <- ytd(sales,.date=order_date,.value=quantity,calendar_type="standard")
calculate(x)
} # }
```
