# Cohort Analysis

Database-friendly cohort analysis function. A remake of
<https://github.com/PeerChristensen/cohorts>, combining
`cohort_table_month`, `cohort_table_year`, and `cohort_table_day` into a
single package. Rewritten for database compatibility and tested with
Snowflake and DuckDB.

## Usage

``` r
cohort(.data, .date, .value, time_unit = "month", period_label = FALSE)
```

## Arguments

- .data:

  tibble or dbi object

- .date:

  date column

- .value:

  id column

- time_unit:

  do you want summarize the date column to 'day', 'week',
  'month','quarter' or 'year'

- period_label:

  do you want period labels or the dates c(TRUE , FALSE)

## Value

segment object

## Details

- Groups your `.value` column by shared time attributes from the `.date`
  column.

- Assigns each member to a cohort based on their first entry in `.date`.

- Aggregates the cohort by the `time_unit` argument (`day`, `week`,
  `month`, `quarter`, or `year`).

- Computes the distinct count of each cohort member over time.
