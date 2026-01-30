# Generate a retail (4-4-5, 4-5-4, or 5-4-4) calendar mapping table

Generate a retail (4-4-5, 4-5-4, or 5-4-4) calendar mapping table

## Usage

``` r
generate_retail_calendar(
  start_date,
  end_date,
  calendar_type,
  fiscal_year_start = 1,
  week_start = 7
)
```

## Arguments

- start_date:

  Start date (Date or character YYYY-MM-DD)

- end_date:

  End date (Date or character YYYY-MM-DD)

- calendar_type:

  One of "445", "454", "544"

- fiscal_year_start:

  Integer 1-12, month the fiscal year starts nearest to

- week_start:

  Integer 1-7, day of week (1=Monday, 7=Sunday)

## Value

A tibble with columns: date, year, quarter, month, week
