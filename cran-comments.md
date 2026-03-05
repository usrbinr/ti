## R CMD check results

0 errors | 0 warnings | 1 note

* The NOTE about "unable to verify current time" is a local system issue
  and not related to the package.

## Changes in this version (4.2.0)

### Bug Fixes
- Fixed test compatibility with contoso >= 2.1.0 (column renamed)
- Fixed ABC temp table naming to prevent collisions in parallel usage
- Fixed example in `abc()` documentation

### Improvements
- Added input validation for date/value column types with helpful error messages
- Added comprehensive error handling tests (16 new tests, 102 total)
- Replaced `assertthat` dependency with `cli::cli_abort` for consistent error handling
- Removed `scales` dependency (inlined percent formatting)
- Documented NA handling behavior in function documentation

### Dependencies Reduced
- Removed: `assertthat`, `scales`
- Current Imports: cli, DBI, dbplyr, dplyr, duckdb, glue, janitor, lubridate, rlang, S7, tidyr

## Test environments

* local: Pop!_OS 22.04 LTS, R 4.5.2
* GitHub Actions: ubuntu-latest, R release
* R-hub: Windows, macOS, Linux

## Previous CRAN feedback addressed

1. **Package names in single quotes**: DESCRIPTION uses 'ti' and 'dbplyr' in single quotes.

2. **Removed "Tools for" from description**: Description begins with the package's purpose directly.

3. **References**: This package implements standard time intelligence calculations
   commonly used in financial planning tools (YTD, MTD, QTD, YoY, etc.).

4. **Examples**: All examples use `\donttest{}` as they depend on the suggested
   package 'contoso' for sample data.
