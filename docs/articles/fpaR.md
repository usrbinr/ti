# Getting started

## Introduction

Simply pass your data in either a tibble or a lazy DBI object to the
time intelligence function and input the required arguments.

We will use [`mtd()`](https://codeberg.org/usrbinr/ti/reference/mtd.md)
function to calculate the month-to-date sum of contoso’s company’ margin
from their sales dataset
([`contoso::sales`](https://usrbinr.github.io/contoso/reference/sales.html)).

Most time intelligence functions follow the same structure:

- Specify the date column to index the time intelligence functions (eg.
  `order_date`, `deliver_date`, etc)
- Specify the value column to aggregate (eg. `margin`, `net_margin`,
  `cogs`, `etc`)
- If there is a period rollback / rollforward then clarify the number of
  periods to roll
- Clarify if we are using a “standard” calendar or non-standard
  variation (currently supports 5-4-4, 4-4-5 and 4-5-4 calendars) see
  [standard vs. non standard calendar
  article](https://usrbinr.github.io/fpaR/articles/calendar_types.html)
  for more information

> Non standard calendars are currently not supported in this release

When you execute
[`mtd()`](https://codeberg.org/usrbinr/ti/reference/mtd.md), your
console will return a `ti` object displaying a custom print message:

- A summary of the function’s actions
- Details the calendar’s attributes used to support the calculation
- Describes the main transformation steps and columns that are
  referenced
- Lists out possible next actions

``` r
contoso::sales |> 
   fpaR::mtd(.date=order_date,.value = margin,calendar_type = "standard")
```

``` fansi
── Month-to-date ───────────────────────────────────────────────────────────────
```

    Function: `mtd` was executed

``` fansi
── Description: ──
```

``` fansi
This creates a daily `cumsum()` of the current month margin from the start of
the standard calendar month to the end of the month
```

``` fansi
── Calendar: ──
```

``` fansi
• The calendar aggregated order_date to the day time unit
• A standard calendar is created with 0 groups
• Calendar ranges from 2021-05-18 to 2024-04-20
• 222 days were missing and replaced with 0
• New date column date, year and month was created from order_date
```

``` fansi
── Actions: ──
```

``` fansi
✔Aggregate margin
```

``` fansi
✖Shift
```

``` fansi
✖Compare
```

``` fansi
✖Proportion Of Total
```

``` fansi
✖Count Distinct
```

``` fansi
── Next Steps: ──
```

    • Use `calculate()` to return the results

    ────────────────────────────────────────────────────────────────────────────────

To return the results to a lazy DBI object, pass the `ti` object through
to
[`calculate()`](https://codeberg.org/usrbinr/ti/reference/calculate.md).

``` r
contoso::sales |>                                                          
   fpaR::mtd(.date=order_date,.value = margin,calendar_type = "standard") |>  
   fpaR::calculate()                                                          
```

If you using a tibble, under the hood, fpa is converting your data to a
[duckdb](https://github.com/duckdb/duckdb-r) database

If your data is in a database, the package will leverage
[dbplyr](https://dbplyr.tidyverse.org/) to execute all the calculations

Either case use
[`dplyr::collect()`](https://dplyr.tidyverse.org/reference/compute.html)
to return your results to a local tibble

``` r
contoso::sales |>                                                                
   fpaR::mtd(.date=order_date,.value = margin,calendar_type = "standard") |>  
   fpaR::calculate() |>                                                       
   dplyr::collect()
```

``` fansi
# A tibble: 10 × 7
    year month date        margin missing_date_indicator mtd_margin
   <dbl> <dbl> <date>       <dbl>                  <dbl>      <dbl>
 1  2021     5 2021-05-18   407.                       0       407.
 2  2021     5 2021-05-19   711.                       0      1118.
 3  2021     5 2021-05-20  1424.                       0      2542.
 4  2021     5 2021-05-21 11339.                       0     13881.
 5  2021     5 2021-05-22  5359.                       0     19240.
 6  2021     5 2021-05-23     0                        1     19240.
 7  2021     5 2021-05-24     0                        1     19240.
 8  2021     5 2021-05-25   793.                       0     20033.
 9  2021     5 2021-05-26    74.6                      0     20107.
10  2021     5 2021-05-27  1433.                       0     21540.
# ℹ 1 more variable: days_in_current_period <dbl>
```

### What if you need the analysis at the group level?

Simply pass the groups that you want to
[`dplyr::group_by()`](https://dplyr.tidyverse.org/reference/group_by.html)
and time intelligence function will create a custom calendar for each
group level.

This ensures that each group will have a complete calendar ensuring no
group member has any missing dates.

``` r
contoso::sales |>   
   dplyr::group_by(customer_key,store_key) |>  
   fpaR::yoy(.date=order_date,.value = margin,calendar_type = "standard") 
```

## Why do we need this package when we have lubridate?

[Lubridate](https://lubridate.tidyverse.org/) is an excellent package
and is is at the core of many of fpaR’s functions. The issue isn’t
lubridate but rather the challenges and issues in your dataset that
typically don’t allow you to directly use lubridate.

The advantage of this package is that it will perform all the of the
required pre-processing steps for you.

- Issue 1: Many datasets **do not have continuous dates**, especially if
  data is recorded only on business days or for active transactions

- Issue 2: Period imbalances between periods (Eg. the different number
  of days between February vs. January) can create misleading
  analysis/trends or you analysis requires non-standard calendar types

- Issue 3: Calculating time intelligence for groups can lead to larger
  than memory issues even with smaller datasets

### Issue 1: Continuous Dates

Referencing the [Table 1](#tbl-missing-dates-issues-1) below, if we were
use
[`dplyr::lag()`](https://dplyr.tidyverse.org/reference/lead-lag.html) to
compare **Day-over-Day (DoD)** margin, we would be missing `2024-01-02`,
`2024-01-04`, and `2024-01-05` which would lead to incorrect answers or
trends.

| date       | margin |
|------------|--------|
| 2024-01-01 | 1200   |
| 2024-01-03 | 1100   |
| 2024-01-06 | 1300   |
| 2024-01-07 | 900    |
| 2024-01-08 | 1200   |
| 2024-01-09 | 850    |
| 2024-01-11 | 1450   |

Table 1: Incomplete calendar table can lead to wrong conclusions or
trends

To correct this, `fpaR` will automatically complete your calendar for
each group for the missing periods to ensure there are no missing
periods when calculating trends.

In [Table 2](#tbl-missing-dates-issue-1-fix-no-echo) we see a complete
calendar set and a new column, “missing_date_indicator” to indicate how
many dates were missing.

| date | margin | missing_date_indicator.x | missing_date_indicator.y | dod_margin |
|----|----|----|----|----|
| 2024-01-01 | 1200 | 0 | NA | NA |
| 2024-01-02 | 0 | 1 | 0 | 1200 |
| 2024-01-03 | 1100 | 0 | 1 | 0 |
| 2024-01-04 | 0 | 1 | 0 | 1100 |
| 2024-01-05 | 0 | 1 | 1 | 0 |
| 2024-01-06 | 1300 | 0 | 1 | 0 |
| 2024-01-07 | 900 | 0 | 0 | 1300 |
| 2024-01-08 | 1200 | 0 | 0 | 900 |
| 2024-01-09 | 850 | 0 | 0 | 1200 |
| 2024-01-10 | 0 | 1 | 0 | 850 |
| 2024-01-11 | 1450 | 0 | 1 | 0 |

Table 2: Original table now complete with missing dates and a missing
date indicator

### Issue 2: Period imbalances

When comparing two performance periods with a standard calendar, you can
often compare periods with unequal number of days or periods.

For example if you want to compare January sales to February you can get
misleading conclusions due to the unequal number of weekends and days in
those periods.

> In practice you have two choices:
>
> - compare periods with similar days (eg. the 28th of February compares
>   should only compare up to the 28th of January) and you omit three
>   days of January sales all together
>
> - compare have an imbalanced comparison (eg. the 28th of February
>   compares to the 31st of January so that no days are lost).

This package does the second option to ensure we don’t loose any of
January’s sales but to help flag for imbalance, fpaR will add a column
to let you know how many periods (eg. days) are in your comparison
period to increase transparency to this dynamic.

To create this example, we will use the
[`pmtd()`](https://codeberg.org/usrbinr/ti/reference/pmtd.md) function
to calculate the prior month to date cumulative margin in the current
month.

``` r
contoso::sales |>
   fpaR::pmtd(order_date,margin,"standard",lag_n = 1)
```

When we pass the ti object through to
[`calculate()`](https://codeberg.org/usrbinr/ti/reference/calculate.md)
and filter the results for February 2022, we would see the below
[Table 3](#tbl-issue2-example-no-echo).

On 2022-02-28, we see that is comparing 31 days of the previous period
to the 28 days in the current period.

| date       | year | month | pmtd_margin | days_in_comparison_period |
|------------|------|-------|-------------|---------------------------|
| 2022-02-26 | 2022 | 2     | 129436.2    | 26                        |
| 2022-02-27 | 2022 | 2     | 132202.3    | 27                        |
| 2022-02-28 | 2022 | 2     | 142668.5    | 31                        |

Table 3

### Issues 3: larger than memory

If your data isn’t already in a database then fpaR will leverage duckdb
to convert your data to enable larger than memory calculation.

This is necessary for time intelligence functions because when you have
grouped data, you need to complete calendar for each group combination.
For even modest datasets, this can quickly multiple and grow you data to
be larger than memory.

If your data is already in database, then fpaR will use
[dbplyr](https://dbplyr.tidyverse.org/) and will convert the functions
to SQL to write the queries.

In either scenario, you can use
[`dplyr::collect()`](https://dplyr.tidyverse.org/reference/compute.html)
to execute your SQL query and return a tibble to your local computer.

``` r
# quickly load contoso package to a database via the contoso package
db <- contoso::create_contoso_duckdb()

# pass through to the same function mtd()
db$sales |> mtd(order_date,margin,"standard")

# same syntax even though data source is now a tibble

contoso::sales |> mtd(order_date,margin,"standard")
```
