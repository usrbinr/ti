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
