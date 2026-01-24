# Month-over-month vs. prior full momth execution function

`mtdopm_fn()` is the function that is called by
[`mtdopm()`](https://codeberg.org/usrbinr/fpa/reference/mtdopm.md) when
passed through to
[calculate](https://codeberg.org/usrbinr/fpa/reference/calculate.md)

## Usage

``` r
mtdopm_fn(x)
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

[`mtdopm()`](https://codeberg.org/usrbinr/fpa/reference/mtdopm.md) for
the function's intent
