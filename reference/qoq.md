# Current full period quarter over previous full period quarter

- This calculates the full quarter value compared to the previous
  quarter value respecting any groups that are passed through with
  [`dplyr::group_by()`](https://dplyr.tidyverse.org/reference/group_by.html)

- Use
  [calculate](https://codeberg.org/usrbinr/fpa/reference/calculate.md)
  to return the results

## Usage

``` r
qoq(.data, .date, .value, calendar_type = "standard", lag_n = 1)
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

## See also

Other time_intelligence:
[`atd()`](https://codeberg.org/usrbinr/fpa/reference/atd.md),
[`dod()`](https://codeberg.org/usrbinr/fpa/reference/dod.md),
[`mom()`](https://codeberg.org/usrbinr/fpa/reference/mom.md),
[`momtd()`](https://codeberg.org/usrbinr/fpa/reference/momtd.md),
[`mtd()`](https://codeberg.org/usrbinr/fpa/reference/mtd.md),
[`mtdopm()`](https://codeberg.org/usrbinr/fpa/reference/mtdopm.md),
[`pmtd()`](https://codeberg.org/usrbinr/fpa/reference/pmtd.md),
[`pqtd()`](https://codeberg.org/usrbinr/fpa/reference/pqtd.md),
[`pwtd()`](https://codeberg.org/usrbinr/fpa/reference/pwtd.md),
[`pytd()`](https://codeberg.org/usrbinr/fpa/reference/pytd.md),
[`qoqtd()`](https://codeberg.org/usrbinr/fpa/reference/qoqtd.md),
[`qtd()`](https://codeberg.org/usrbinr/fpa/reference/qtd.md),
[`qtdopq()`](https://codeberg.org/usrbinr/fpa/reference/qtdopq.md),
[`wow()`](https://codeberg.org/usrbinr/fpa/reference/wow.md),
[`wowtd()`](https://codeberg.org/usrbinr/fpa/reference/wowtd.md),
[`wtd()`](https://codeberg.org/usrbinr/fpa/reference/wtd.md),
[`wtdopw()`](https://codeberg.org/usrbinr/fpa/reference/wtdopw.md),
[`yoy()`](https://codeberg.org/usrbinr/fpa/reference/yoy.md),
[`yoytd()`](https://codeberg.org/usrbinr/fpa/reference/yoytd.md),
[`ytd()`](https://codeberg.org/usrbinr/fpa/reference/ytd.md),
[`ytdopy()`](https://codeberg.org/usrbinr/fpa/reference/ytdopy.md)

## Examples

``` r
library(contoso)
qoq(sales,.date=order_date,.value=quantity,calendar_type='standard',lag_n=1)
#> 
#> ── Quarter over quarter ────────────────────────────────────────────────────────
#> Function: `qoq` was executed
#> 
#> ── Description: ──
#> 
#> This creates a full quarter `sum()` of the previous quarter quantity and
#> compares it with the full quarter `sum()` current quarter quantity from the
#> start of the standard calendar quarter to the end of the quarter
#> 
#> ── Calendar: ──
#> 
#> • The calendar aggregated order_date to the quarter time unit
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
