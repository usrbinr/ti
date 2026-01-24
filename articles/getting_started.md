# Getting started

### How to use fpaR?

#### Time Intelligence

When you execute a time intelligence function, it will return a “ti”
class object with a custom print method that explains what the function
is doing and a summary of transformation steps and the calendar
attributes.

Simply pass your data in either tibble or a lazy DBI object to the time
intelligence function and input the required arguments.

> Regardless if you pass a tibble or lazy DBI object, all time
> intelligence functions will return a lazy DBI object for performance
> reasons

We will use [`mtd()`](https://codeberg.org/usrbinr/ti/reference/mtd.md)
function to calculate the month-to-date sum of contoso’s company’
revenue
([`contoso::sales`](https://usrbinr.github.io/contoso/reference/sales.html)).

Most time intelligence functions follow the same structure:

- specify the date column to index the time intelligence functions
- specify the value column to aggregate
- if there is a period rollback / rollforward then clarify the number of
  periods
- clarify if we are using a “standard” calendar or non-standard
  variation (currently supports 5-5-4)

When you execute
[`mtd()`](https://codeberg.org/usrbinr/ti/reference/mtd.md), your
console return a `ti` object and will print a summary of the function’s
actions, details the calendar’s attributes, describes the main
transformation steps and lists out possible next actions.

``` r
contoso::sales |> 
   fpaR::mtd(.date=order_date,.value = revenue,calendar_type = "standard") 
```

``` fansi
── Month-to-date ───────────────────────────────────────────────────────────────
```

    Function: `mtd` was executed

``` fansi
── Description: ──
```

``` fansi
This creates a daily `cumsum()` of the current month revenue from the start of
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
✔Aggregate revenue
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

To return the results to a lazy tibble of results, pass the ti object
through to
[`calculate()`](https://codeberg.org/usrbinr/ti/reference/calculate.md).

``` r
contoso::sales |>                                                                
   fpaR::mtd(.date=order_date,.value = margin,calendar_type = "standard") |>  
   fpaR::calculate()                                                          
```

If you using a tibble, under the hood, `fpaR` is converting your data to
a [duckdb](https://github.com/duckdb/duckdb-r) database.

If your data is in a database, the package will leverage
[dbplyr](https://dbplyr.tidyverse.org/) to execute all the calculations.

Either case use
[`dplyr::collect()`](https://dplyr.tidyverse.org/reference/compute.html)
to return your results to a local tibble.

``` r
contoso::sales |>                                                                
   fpaR::mtd(.date=order_date,.value = margin,calendar_type = "standard") |>  
   fpaR::calculate() |>                                                       
   dplyr::collect() |>                                               
   head(10)
```

``` fansi
# A tibble: 10 × 7
    year month date       margin missing_date_indicator mtd_margin
   <dbl> <dbl> <date>      <dbl>                  <dbl>      <dbl>
 1  2022     7 2022-07-01 10656.                      0     10656.
 2  2022     7 2022-07-02  2567.                      0     13223.
 3  2022     7 2022-07-03     0                       1     13223.
 4  2022     7 2022-07-04  2537.                      0     15760.
 5  2022     7 2022-07-05  9302.                      0     25062.
 6  2022     7 2022-07-06  4139.                      0     29202.
 7  2022     7 2022-07-07  9383.                      0     38584.
 8  2022     7 2022-07-08  3343.                      0     41927.
 9  2022     7 2022-07-09  7865.                      0     49792.
10  2022     7 2022-07-10     0                       1     49792.
# ℹ 1 more variable: days_in_current_period <dbl>
```

#### What if you need the analysis at the group level?

Simply pass through the groups that you want with
[`dplyr::group_by()`](https://dplyr.tidyverse.org/reference/group_by.html)
and time intelligence function will create a custom calendar for each
group level.

This will calculate a complete calendar ensuring each group has a
complete calendar with no missing dates.

``` r
contoso::sales |>   
   dplyr::group_by(customer_key,store_key) |>  
   fpaR::yoy(.date=order_date,.value = margin,calendar_type = "standard") 
```

The functions will work with your database even if you don’t have write
permission by creatively leveraging CTEs to create interim tables.

### Why do we need this package when we have lubridate?

[Lubridate](https://lubridate.tidyverse.org/) is an excellent package
and is heavily used by the package. The issue isn’t lubridate but rather
issues you may not be aware of in your package.

Time-based comparisons, such as Year-over-Year (YoY),
Quarter-over-Quarter (QoQ), and Month-to-Date (MTD), are common for
tracking business performance. However, they come with challenges:

- Many datasets **do not have continuous dates**, especially if data is
  recorded only on business days or for active transactions

- Period imbalances between periods (Eg. the different number of days
  between February vs. January) can create misleading analysis or trends

- Your analysis may need to reference a non-standard calendar such as a
  5-5-4, 4-4-5, or 13 month calendar

- Your data may be in excel sheets, csv or databases and you need to
  inter-operable framework to switch between all your data types

#### Issue 1: Continuous Dates

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

| date       | margin | missing_date_indicator |
|------------|--------|------------------------|
| 2024-01-01 | 1200   | 0                      |
| 2024-01-02 | 0      | 1                      |
| 2024-01-03 | 1100   | 0                      |
| 2024-01-04 | 0      | 1                      |
| 2024-01-05 | 0      | 1                      |
| 2024-01-06 | 1300   | 0                      |
| 2024-01-07 | 900    | 0                      |
| 2024-01-08 | 1200   | 0                      |
| 2024-01-09 | 850    | 0                      |
| 2024-01-10 | 0      | 1                      |
| 2024-01-11 | 1450   | 0                      |

Table 2: Original table now complete with missing dates and a missing
date indicator

### Issue 2: Period imbalances

When comparing two performance periods with a standard calendar, you
often will compare a period with unequal number of days or periods. For
example if you want to compare January sales to February you can get
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

this package does the second option which is ensure we don’t loose any
of January’s sales but to help flag for imbalance, fpaR will add a
column to let you know how many periods (eg. days) are in your
comparison period to increase transparency to this dynamic.

To create this example, we will use the
[`pmtd()`](https://codeberg.org/usrbinr/ti/reference/pmtd.md) function
to calculate the prior month to date cumulative margin in the current
month.

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

### what is going on under the hood

In financial planning and analysis, it is common to compare
**year-to-date (YTD)** metrics against the **previous year’s YTD** to
understand performance trends.

The function
[`yoytd_fn()`](https://codeberg.org/usrbinr/ti/reference/yoytd_fn.md)
provides this functionality. While it is an **internal, non-exported
function**, it is called by \[yoytd()\] and executed through
\[calculate()\].

This vignette explains what the function does, how it works, and how to
work with its output.

## Function Purpose

[`yoytd_fn()`](https://codeberg.org/usrbinr/ti/reference/yoytd_fn.md)
performs the following:

1.  Computes **current year-to-date (YTD)** values.
2.  Computes **previous year-to-date (PYTD)** values, optionally
    applying a lag.
3.  Joins YTD and PYTD tables together on `date`, `year`, and grouping
    variables.
4.  Fills missing dates downward for consistency.
5.  Summarizes the data by summing the YTD and PYTD values by group.

The output is a **DBI object** that can be converted into a **tibble**
using
[`dplyr::collect()`](https://dplyr.tidyverse.org/reference/compute.html)
for further analysis.
