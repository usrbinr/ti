# ti 4.3.0

## Bug fixes

These are wrong-value bugs: the functions ran without error but returned
incorrect numbers.

- `wow()` returned several rows per week (569 rows for 153 weeks on
  `contoso::sales`), and some rows compared a week with itself. A week that
  spanned two week numbers or two months was split into several rows. `wtdopw()`
  was affected through `wow()`.
- On the retail calendars (`"445"`, `"454"`, `"544"`), `yoy()`, `qoq()`, `mom()`
  and `mtdopm()` returned several rows per period. Periods were built from
  calendar months, quarters and years rather than fiscal ones.
- Grouped `pmtd()` and `momtd()` used values from other groups when a group had
  no data in the previous month.
- `pytd()`, `pqtd()` and `pmtd()` added two earlier days together when both
  mapped to the same date (for example 28 and 29 February 2024 both onto
  28 February 2025), and `pqtd()` returned `NA` on some month ends (30 and
  31 May). Each date now compares with exactly one point in the earlier period;
  on the last day of a month that is the end of the earlier month.
- `pytd()` and `yoytd()` failed with `argument "lag_n" is missing` unless
  `lag_n` was given. It now defaults to `1`, like the other functions.
- The compound functions (`yoytd()`, `qoqtd()`, `momtd()`, `wowtd()`,
  `ytdopy()`, `qtdopq()`, `mtdopm()`, `wtdopw()`) ignored `fiscal_year_start`.
- `mtdopm()` returned two quarter columns (`quarter.x` and `quarter.y`).
- On the retail calendars, data in the last days of the year could be dropped.
  The calendar only built a fiscal year once the next fiscal year's start was
  known, so when data ended a few days after a fiscal year began (for example
  29-31 December 2024 on a January 4-4-5 calendar) those days were missing.

## Changes

- New `week_start` argument on every time intelligence function (1 = Monday
  to 7 = Sunday, default 7). On the standard calendar, weeks start on that day
  and week 1 is the week containing 1 January, so only the weeks either side of
  1 January can be partial. Weeks no longer split at month ends. On retail
  calendars, `week_start` sets the weekday fiscal periods start on.
- `week_start` and `fiscal_year_start` are on every function because the retail
  calendars build every fiscal period from whole weeks. On the standard
  calendar `fiscal_year_start` has no effect and `week_start` only affects the
  week functions and the `week` column. Changing either where it has no effect
  now shows a message, and the printed summary says the same.
- The `week` column now follows `week_start`. It was previously the ISO week
  for day-level results.
- `wtd()`, `pwtd()` and `wowtd()` now reset at the start of each week. They
  previously reset at seven-day blocks counted from 1 January and at every
  month end.
- `pytd()`, `pmtd()` and `pwtd()` (and `yoytd()`) return one row per calendar
  date, like the other functions. They previously added rows after the last
  date in the data.
- The printed summary has a new **Assumptions** block that states the
  conventions behind the numbers: what one row is, how periods are compared
  (including the month-end rule), how weeks and fiscal years are defined, and
  that totals and comparisons stay within each group.
- The printed summary no longer says a function "was executed", since printing
  runs nothing. The Actions checklist now shows its details (for example
  "Shift 2 weeks") even when colour is turned off, and missing data is counted
  in the function's own periods ("6 of 14 weeks had no data") instead of
  always in days. Printing now sends a single query for the dates.
- `ti` no longer writes to the database. The retail calendars and the `abc()`
  threshold table were created with `copy_to()`; they are now built inside the
  query with `dbplyr::copy_inline()`, so read-only access is enough. This also
  fixes retail-calendar results that were created earlier being changed by a
  later call, because every call overwrote the same `retail_calendar` table.
- Database connections other than 'DuckDB' now stop with an error instead of
  silently using 'DuckDB' SQL. 'DuckDB' and data frames are tested; support for
  other databases will come in a later release.
- Requires 'dbplyr' >= 2.3.0.
- 'tibble' moved from Suggests to Imports, since the retail calendar uses it,
  and 'purrr' was added to Imports. The unused 'cohorts' and 'crayon' were
  removed from Suggests.

## Documentation

- New article, "How ti Works: A Developer Guide": the design principles, the
  S7 classes, how a call becomes SQL, how the calendar is built, the five
  calculation templates, the tests, and known rough edges.
- The README and "Working with Databases" article now state that 'DuckDB' is
  tested and that support for other databases will come in a later release.

## Tests

- Every function is now checked row by row against an independent reference
  implementation (`tests/testthat/helper-reference.R`), ungrouped and grouped,
  with every `week_start` day, and on the retail calendars, plus hand-computed
  examples. Previously most functions were only tested for running without
  error.
- New tests that check the calendar directly (one row per period, no gaps,
  periods dated by their first day, totals that match the data), and that no
  function writes to the database.
- Snapshot tests of the printed summary for one function per calculation
  type, a retail calendar, `abc()` and `cohort()`.
- Tests that the retail calendar covers every day of the requested range,
  including the last days of the year.
- The exhaustive variations (all seven `week_start` days, the 4-5-4 and 5-4-4
  calendars, and tests that duplicate the reference checks) are skipped on
  CRAN to keep check time down. Every function is still checked against the
  reference on CRAN, on the standard and 4-4-5 calendars.

# ti 4.2.2

## Documentation
- Removed empty bullets from the "NA Handling" section of `ytd()` details,
  inherited by 21 help pages, which produced "trimming empty <li>" HTML
  validation NOTEs

# ti 4.2.1

## Bug Fixes
- Restored `calculate()` and `create_calendar()` to NAMESPACE. roxygen2 8.0.0 no
  longer emits an export from `@export` on an `S7::method()<-` block, so both
  generics were silently dropped and every call failed with "'calculate' is not
  an exported object from 'namespace:ti'"
- Removed the incorrect `export(print)` directive; the `print()` methods are
  registered at load time by `S7::methods_register()`

## Documentation
- Documented the S7 generics on their `new_generic()` definitions, per
  `vignette("rd-S7", package = "roxygen2")`
- Documented all S7 classes, using `@prop` for read-only computed properties
- Merged two roxygen blocks in `R/utils-misc.R` that had run together

# ti 4.2.0

This release fixes the check ERRORs that led to 'ti' being archived on CRAN on
2026-04-06. It was never published to CRAN; its changes reach users in 4.2.1.

## Bug Fixes
- Fixed test compatibility with contoso >= 2.1.0 (`margin` renamed to `gross_margin`).
  This was the cause of the CRAN check ERRORs in 4.0.0.
- Fixed ABC temp table naming to prevent collisions in parallel usage
- Fixed example in `abc()` documentation using old column name

## Improvements
- Added input validation for date/value column types with helpful error messages
- Added comprehensive error handling tests (16 new tests)
- Standardized internal `*_fn` functions to use template pattern
- Added value-based test assertions for calculation verification
- Replaced `assertthat` dependency with `cli::cli_abort` for consistent error handling
- Removed `scales` dependency (inlined percent formatting)
- Replaced magic numbers with named constants
- Documented NA handling behavior in function documentation
- Pinned contoso dependency to >= 2.1.0 in Suggests

## Dependencies
- Removed: `assertthat`, `scales`
- Total test count: 102 (up from 62)

# ti 4.1.0

- Internal release (not submitted to CRAN)

# ti 4.0.0

- Fixed Snowflake SQL dialect date arithmetic
- Addressed CRAN submission feedback
- Updated documentation with qrtdown

# ti 3.0.0
- refactor code based to make easier to maintain

# ti 2.0.0
- non-standard calendar support including 4-4-5, 5-4-4 and 4-5-4 calendars

# ti 1.0.0
- new package name
- removed non-standard calendar support for now
- CRAN release
