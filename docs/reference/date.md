# Date Dimension Table

This dataset provides a comprehensive date dimension table, including
various calendar attributes such as year, quarter, month, and
day-related information.

## Usage

``` r
date
```

## Format

A data frame with multiple rows and 18 columns:

- date:

  `Date`. The actual calendar date.

- date_key:

  `integer`. Unique identifier for the date (often used in data
  warehouses).

- year:

  `integer`. The calendar year (e.g., 2024).

- year_quarter:

  `character`. Year and quarter combination (e.g., "2024-Q1").

- year_quarter_number:

  `integer`. Numeric representation of year and quarter (e.g., 202401
  for Q1 of 2024).

- quarter:

  `integer`. The quarter of the year (1 to 4).

- year_month:

  `character`. Year and month combination (e.g., "2024-01").

- year_month_short:

  `character`. Abbreviated year and month (e.g., "Jan 2024").

- year_month_number:

  `integer`. Numeric representation of year and month (e.g., 202401 for
  January 2024).

- month:

  `character`. Full month name (e.g., "January").

- month_short:

  `character`. Abbreviated month name (e.g., "Jan").

- month_number:

  `integer`. Numeric representation of the month (1 to 12).

- dayof_week:

  `character`. Full name of the day of the week (e.g., "Monday").

- dayof_week_short:

  `character`. Abbreviated day of the week (e.g., "Mon").

- dayof_week_number:

  `integer`. Numeric representation of the day of the week (1 for Monday
  to 7 for Sunday).

- working_day:

  `logical`. Indicates if the date is a working day (TRUE/FALSE).

- working_day_number:

  `integer`. Sequential working day number within the year.

## Source

Generated from `fpaR::date`

## Examples

``` r
if (FALSE) { # \dontrun{
data(date)
head(date)
summary(date)
} # }
```
