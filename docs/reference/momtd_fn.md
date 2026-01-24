# Current year to date over previous year-to-date for tibble objects

`momtd_fn()` is the function that is called by
[`momtd()`](https://codeberg.org/usrbinr/fpa/reference/momtd.md) when
passed through to
[calculate](https://codeberg.org/usrbinr/fpa/reference/calculate.md)

## Usage

``` r
momtd_fn(x)
```

## Arguments

- x:

  ti object

## Value

dbi object

## Details

This is internal non exported function that is nested in ti class and is
called upon when the underlying function is called by
[calculate](https://codeberg.org/usrbinr/fpa/reference/calculate.md)
This will return a dbi object that can converted to a tibble object with
[`dplyr::collect()`](https://dplyr.tidyverse.org/reference/compute.html)

## See also

[`momtd()`](https://codeberg.org/usrbinr/fpa/reference/momtd.md) for the
function's intent
