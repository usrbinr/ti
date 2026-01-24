# Year-to-date over full prior period year

`ytdopy_fn()` is the function that is called by
[`ytdopy()`](https://codeberg.org/usrbinr/fpa/reference/ytdopy.md) when
passed through to
[calculate](https://codeberg.org/usrbinr/fpa/reference/calculate.md)

## Usage

``` r
ytdopy_fn(x)
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
This will return a dbi object that can converted to a tibble object
with[`dplyr::collect()`](https://dplyr.tidyverse.org/reference/compute.html)

## See also

[`ytdopy()`](https://codeberg.org/usrbinr/fpa/reference/ytdopy.md) for
the function's intent
