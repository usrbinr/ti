# Current period quarter-to-date over previous period quarter

- This calculates the quarterly cumulative sum of a targeted value and
  compares it with the previous full quarter's total value respecting
  any groups that are passed through with
  [`dplyr::group_by()`](https://dplyr.tidyverse.org/reference/group_by.html)

- Use
  [calculate](https://codeberg.org/usrbinr/ti/reference/calculate.md) to
  return the results

## Usage

``` r
qtdopq(.data, .date, .value, calendar_type = "standard", lag_n = 1)
```

## Arguments

- .data:

  tibble or dbi object (either grouped or ungrouped)

- .date:

  the date column to group by

- .value:

  the value column to summarize

- calendar_type:

  select either 'standard' or '5-5-4' calendar, see 'Details' for
  additional information

- lag_n:

  the number of periods to lag

## Value

ti object

## Details

- This function creates a complete calendar object that fills in any
  missing days, weeks, months, quarters, or years

- If you provide a grouped object with
  [`dplyr::group_by()`](https://dplyr.tidyverse.org/reference/group_by.html),
  it will generate a complete calendar for each group

- The function creates a `ti` object, which pre-processes the data and
  arguments for further downstream functions

**standard calendar**

- The standard calendar splits the year into 12 months (with 28–31 days
  each) and uses a 7-day week

- It automatically accounts for leap years every four years to match the
  Gregorian calendar

**5-5-4 calendar**

- The 5-5-4 calendar divides the fiscal year into 52 weeks (occasionally
  53), organizing each quarter into two 5-week periods and one 4-week
  period.

- This system is commonly used in retail and financial reporting

## See also

Other time_intelligence:
[`atd()`](https://codeberg.org/usrbinr/ti/reference/atd.md),
[`dod()`](https://codeberg.org/usrbinr/ti/reference/dod.md),
[`mom()`](https://codeberg.org/usrbinr/ti/reference/mom.md),
[`momtd()`](https://codeberg.org/usrbinr/ti/reference/momtd.md),
[`mtd()`](https://codeberg.org/usrbinr/ti/reference/mtd.md),
[`mtdopm()`](https://codeberg.org/usrbinr/ti/reference/mtdopm.md),
[`pmtd()`](https://codeberg.org/usrbinr/ti/reference/pmtd.md),
[`pqtd()`](https://codeberg.org/usrbinr/ti/reference/pqtd.md),
[`pwtd()`](https://codeberg.org/usrbinr/ti/reference/pwtd.md),
[`pytd()`](https://codeberg.org/usrbinr/ti/reference/pytd.md),
[`qoq()`](https://codeberg.org/usrbinr/ti/reference/qoq.md),
[`qoqtd()`](https://codeberg.org/usrbinr/ti/reference/qoqtd.md),
[`qtd()`](https://codeberg.org/usrbinr/ti/reference/qtd.md),
[`wow()`](https://codeberg.org/usrbinr/ti/reference/wow.md),
[`wowtd()`](https://codeberg.org/usrbinr/ti/reference/wowtd.md),
[`wtd()`](https://codeberg.org/usrbinr/ti/reference/wtd.md),
[`wtdopw()`](https://codeberg.org/usrbinr/ti/reference/wtdopw.md),
[`yoy()`](https://codeberg.org/usrbinr/ti/reference/yoy.md),
[`yoytd()`](https://codeberg.org/usrbinr/ti/reference/yoytd.md),
[`ytd()`](https://codeberg.org/usrbinr/ti/reference/ytd.md),
[`ytdopy()`](https://codeberg.org/usrbinr/ti/reference/ytdopy.md)

## Examples

``` r
library(contoso)
qtdopq(sales,.date=order_date,.value=quantity,calendar_type='standard',lag_n=1)
#> 
#> ── Quarter-to-date over full previous quarter ──────────────────────────────────
#> Function: `qtdopq` was executed
#> 
#> ── Description: ──
#> 
#> This creates a daily `cumsum()` of the current quarter quantity and compares it
#> with the full quarter `sum()` previous quarter quantity from the start of the
#> standard calendar quarter to the end of the quarter
#> 
#> ── Calendar: ──
#> 
#> • The calendar aggregated order_date to the day time unit
#> • A standard calendar is created with 0 groups
#> • Calendar ranges from 2021-05-18 to 2024-04-20
#> • 222 days were missing and replaced with 0
#> • New date column date, year and quarter was created from order_date
#> 
#> ── Actions: ──
#> 
#> ✔Aggregate quantity
#> ✔Shift 1 quarter
#> ✔Compare previous full quarter
#> ✖Proportion Of Total
#> ✖Count Distinct
#> 
#> 
#> ── Next Steps: ──
#> 
#> • Use `calculate()` to return the results
#> ────────────────────────────────────────────────────────────────────────────────
#> 
```
