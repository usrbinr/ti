# Year-over-year

`wtdopw_fn()` is the function that is called by
[`wtdopw()`](https://codeberg.org/usrbinr/ti/reference/wtdopw.md) when
passed through to
[calculate](https://codeberg.org/usrbinr/ti/reference/calculate.md)

## Usage

``` r
wtdopw_fn(x)
```

## Arguments

- x:

  ti object

## Value

dbi object

## Details

This is internal non exported function that is nested in ti class and is
called upon when the underlying function is called by
[calculate](https://codeberg.org/usrbinr/ti/reference/calculate.md) This
will return a dbi object that can converted to a tibble object with
[`dplyr::collect()`](https://dplyr.tidyverse.org/reference/compute.html)

## See also

[`wtdopw()`](https://codeberg.org/usrbinr/ti/reference/wtdopw.md) for
the function's intent
