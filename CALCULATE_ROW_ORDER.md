# `calculate()` does not return rows in date order

Status: open
Found: 2026-10-02, ti 4.2.1, while building a gross margin report on `contoso::sales`

## Summary

The `calculate()` docs say:

> The resulting table will be sorted by the relevant date column to ensure the
> correct temporal ordering of the calculated metrics.

That is not what happens. After `collect()`, rows come back in arbitrary order,
both ungrouped and within groups. **The calculated values are correct**: YTD,
PYTD and MoM figures all reconciled to hand-computed totals. Only the row order
is wrong.

This matters because users naturally follow `calculate()` with order-dependent
code (`lag()`, `lead()`, `cumsum()`, `first()`, `last()`, `diff()`). Those give
silently wrong answers. In my case, a month-by-month `lag()` on `yoytd()` output
attributed -$309K of a -$327K YTD gap to August instead of -$96K.

## Reproduction

```r
library(ti)
library(dplyr)

x <- ytd(contoso::sales, .date = order_date, .value = quantity)
res <- calculate(x) |> collect()

is.unsorted(res$date)
#> TRUE
head(res$date, 3)
#> "2024-01-01 UTC" "2024-01-02 UTC" "2024-01-03 UTC"   # data starts 2021-05-18

# No ORDER BY on the outermost query, only inside window functions
sql <- dbplyr::sql_render(calculate(x))
grepl("ORDER BY", sql)             #> TRUE  (window functions)
grepl("ORDER BY[^()]*$", sql)      #> FALSE (no final ORDER BY)

# Grouped: unsorted within every group
xg <- ytd(group_by(contoso::sales, currency_code), .date = order_date, .value = quantity)
calculate(xg) |>
  collect() |>
  summarise(unsorted = is.unsorted(date), .by = currency_code)
#> TRUE for all 5 currencies
```

I saw the same behaviour from `mom()` and `yoytd()`, grouped and ungrouped, with
plain tibble input (not only remote tables).

## Cause

`R/methods.R`:

```r
S7::method(calculate, ti) <- function(x, ...) {
  out <- x@fn@fn_exec(x) |>
    dbplyr::window_order(date)
  return(out)
}
```

`dbplyr::window_order()` only sets the `ORDER BY` used *inside* window functions
(`OVER (... ORDER BY ...)`). It does not add an `ORDER BY` to the final query.
Without one, SQL makes no guarantee about row order, and DuckDB returns rows in
whatever order its parallel execution produces. Here that is blocks of dates out
of sequence.

`segment_abc` is fine because it ends with `dplyr::arrange(row_id)`.
`segment_cohort` has no final ordering either.

## Proposed fix

End the `ti` method with `arrange()`, which dbplyr renders as an outer
`ORDER BY`. Keep `window_order()` in case downstream window functions rely on it.

```r
S7::method(calculate, ti) <- function(x, ...) {
  out <- x@fn@fn_exec(x) |>
    dbplyr::window_order(date) |>
    dplyr::arrange(!!!x@datum@group_quo, date)
  return(out)
}
```

I checked the downstream equivalent: `calculate(xg) |> arrange(currency_code, date) |> collect()`
returns every group sorted.

Decisions to make:

- **Sort key order.** `group, date` keeps each series contiguous, which suits
  `lag()` and plotting. `date, group` matches the current docs' wording literally.
  I'd go with `group, date` and update the docs to say "sorted by group, then date".
- **Sorting must be the last step.** If a user adds more dbplyr verbs after
  `calculate()`, dbplyr can drop the `ORDER BY` from the subquery (it warns
  "ORDER BY is ignored in subqueries"). Worth one sentence in the docs: re-apply
  `arrange()` after further lazy verbs, or sort after `collect()`.
- **Cost.** An outer sort over large remote tables isn't free, but it is small
  next to the window functions already in the query. If that is a concern, add an
  `ordered = TRUE` argument.
- **`segment_cohort`.** Decide whether it should sort as well, for consistency.

## Tests to add

```r
test_that("calculate() returns rows sorted by date", {
  x <- ytd(contoso::sales, .date = order_date, .value = quantity)
  res <- dplyr::collect(calculate(x))
  expect_false(is.unsorted(res$date))
})

test_that("calculate() returns rows sorted by date within groups", {
  x <- ytd(dplyr::group_by(contoso::sales, currency_code),
           .date = order_date, .value = quantity)
  res <- dplyr::collect(calculate(x))
  per_group <- tapply(res$date, res$currency_code, is.unsorted)
  expect_false(any(per_group))
})
```

These may pass by luck on small data or a single thread. Repeating the test, or
setting DuckDB `threads` above 1 if the internal connection allows it, makes the
failure reliable.

## Follow-ups

- [ ] Apply the fix in `R/methods.R`
- [ ] Update the `calculate()` `@details` sort wording and re-document
- [ ] Add the tests above
- [ ] Decide on `segment_cohort`
- [ ] Add a `NEWS.md` entry (bug fix: `calculate()` now returns rows in date order)
