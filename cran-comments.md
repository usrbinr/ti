## Resubmission of an archived package

'ti' was archived on 2026-04-06 because the check ERRORs reported for version
4.0.0 were not corrected in time. This submission fixes them.

### Why 4.0.0 failed

All failures came from a single cause. 'ti' uses the 'contoso' package (Suggests)
for sample data in its tests and examples. 'contoso' 2.1.0 renamed the `margin`
column of its `sales` dataset to `gross_margin`, so every test that measured that
column failed with `Object 'margin' not found` (55 failures across
`test-retail-calendar.R` and `test-ti_fn.R`).

This is also why only some flavours reported ERROR: the macOS flavours, where
'contoso' was not installed, skipped the affected tests and returned OK.

### Fixes in this version

* All tests and examples now use `gross_margin`, matching 'contoso' >= 2.1.0.
  'contoso' is pinned to `(>= 2.1.0)` in Suggests so the mismatch cannot recur.
* Restored `calculate()` and `create_calendar()` to NAMESPACE. roxygen2 8.0.0
  added S7 support and no longer emits an export from `@export` on an
  `S7::method()<-` block, so both generics were silently dropped and every call
  failed with "'calculate' is not an exported object from 'namespace:ti'". The
  generics are now documented and exported on their `S7::new_generic()`
  definitions, following `vignette("rd-S7", package = "roxygen2")`.
* Removed the incorrect `export(print)` directive. S7 registers the `print()`
  methods at load time via `S7::methods_register()`, so re-exporting `base::print`
  was never needed.
* Documented all S7 classes, using `@prop` for read-only computed properties.
* Merged two roxygen blocks in `R/utils-misc.R` that had run together, which
  produced a malformed `@keywords` entry.

* Removed empty list items from the inherited "NA Handling" details section,
  which caused the "trimming empty <li>" HTML manual NOTE on the 4.2.1
  pretest.

### Also in this version

4.3.0 also fixes several functions that returned incorrect values (duplicate
rows in week-over-week results, retail-calendar period comparisons, days
missing from the retail calendar at the end of a year, and
previous-period-to-date values on month ends and in grouped data), and adds a
`week_start` argument. The package no longer writes temporary tables to the
user's database, and the printed summary now states the assumptions behind
each calculation. Every function is now tested against an independent
reference implementation.

'tibble' moved from Suggests to Imports and 'purrr' was added to Imports; the
unused 'cohorts' and 'crayon' were removed from Suggests.

Versions 4.2.0, 4.2.1 and 4.2.2 were never published; 4.3.0 is the version
being submitted. See NEWS.md for the full list of changes since 4.0.0.

## R CMD check results

0 errors | 0 warnings | 1 note

The NOTE is expected for this submission:

* "New submission" and "Package was archived on CRAN" — this resubmission is
  addressed above.
* "Possibly misspelled words in DESCRIPTION: MTD, QTD, YTD, backends" — these
  are correct. MTD, QTD and YTD are the standard financial abbreviations for
  month-, quarter- and year-to-date, and "backends" is the usual spelling for
  database backends.

## Test environments

* local: Pop!_OS 24.04 LTS, R 4.6.1

Checked with `devtools::check(remote = TRUE, manual = TRUE)`. Tests were run
against 'contoso' 2.4.0, the version currently on CRAN.

The full test suite takes about 6 minutes locally; the exhaustive variations
are skipped on CRAN with `skip_on_cran()`, which brings it to about
2.5 minutes.

## Downstream dependencies

There are no reverse dependencies.
