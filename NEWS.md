# ti 4.2.0

## Bug Fixes
- Fixed test compatibility with contoso >= 2.1.0 (`margin` renamed to `gross_margin`)
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
