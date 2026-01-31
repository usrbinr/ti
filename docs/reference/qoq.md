# Current full period quarter over previous full period quarter

- This calculates the full quarter value compared to the previous
  quarter value respecting any groups that are passed through with
  [`dplyr::group_by()`](https://dplyr.tidyverse.org/reference/group_by.html)

- Use
  [calculate](https://codeberg.org/usrbinr/ti/reference/calculate.md) to
  return the results

## Usage

``` r
qoq(
  .data,
  .date,
  .value,
  calendar_type = "standard",
  lag_n = 1,
  fiscal_year_start = 1
)
```

## Arguments

- .data:

  tibble or dbi object (either grouped or ungrouped)

- .date:

  the date column to group by

- .value:

  the value column to summarize

- calendar_type:

  select either 'standard', '445', '454', or '544' calendar, see
  'Details' for additional information

- lag_n:

  the number of periods to lag

- fiscal_year_start:

  integer 1-12, the month the fiscal year starts nearest to (default 1 =
  January). Only used with retail calendars ('445', '454', '544').

## Value

ti object

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
[`qoqtd()`](https://codeberg.org/usrbinr/ti/reference/qoqtd.md),
[`qtd()`](https://codeberg.org/usrbinr/ti/reference/qtd.md),
[`qtdopq()`](https://codeberg.org/usrbinr/ti/reference/qtdopq.md),
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
if (FALSE) { # \dontrun{
library(contoso)
qoq(sales,.date=order_date,.value=quantity,calendar_type='standard',lag_n=1)
} # }
```
