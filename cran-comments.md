## R CMD check results

0 errors | 0 warnings | 1 note

* This is a new submission.

* The flagged words (YTD, MTD, QTD) are standard financial acronyms
  for Year-to-date, Month-to-date, and Quarter-to-date respectively.
  "backends" refers to database backends and is intentional.

## Resubmission

This is a resubmission addressing the following reviewer feedback:

1. **Package names in single quotes**: Updated DESCRIPTION to use 'ti' and
   'dbplyr' in single quotes as required.

2. **Removed "Tools for" from description**: Rewrote the Description field
   to begin with the package's purpose directly.

3. **References**: This package implements time intelligence calculations
   commonly used in financial planning tools. The methodology is based on
   standard period-over-period and period-to-date calculations; there are
   no specific academic references to cite.

4. **Examples for unexported function**: Removed examples from the internal
   function `seq_date_sql()` which is marked with `@keywords internal`.

5. **Replaced \\dontrun{} with \\donttest{}**: All examples now use
   `\donttest{}` instead of `\dontrun{}` as the examples depend on the
   suggested package 'contoso' for sample data.
