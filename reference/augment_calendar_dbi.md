# Add Comprehensive Date-Based Attributes to a DBI lazy frame

This function takes a data frame and a date column and generates a wide
set of derived date attributes. These include start/end dates for year,
quarter, month, and week; day-of-week indicators; completed and
remaining days in each time unit; and additional convenience variables
such as weekend indicators.

It is designed for time-based feature engineering and is useful in
reporting, forecasting, time-series modeling, and data enrichment
workflows.

## Usage

``` r
augment_calendar_dbi(.data, .date)
```

## Arguments

- .data:

  A data frame or tibble containing at least one date column.

- .date:

  A column containing `Date` values, passed using tidy-eval (e.g.,
  `{{ date_col }}`).

## Value

A dbi containing the original data along with all generated date-based
attributes.

## Details

The function creates the following groups of attributes:

**1. Start and end dates**

- `year_start_date`, `year_end_date`

- `quarter_start_date`, `quarter_end_date`

- `month_start_date`, `month_end_date`

- `week_start_date`, `week_end_date`

**2. Day-of-week fields**

- `day_of_week` – numeric day of the week (1–7)

- `day_of_week_label` – ordered factor label (e.g., Mon, Tue, …)

**3. Duration fields**

- `days_in_year` – total days in the year interval

- `days_in_quarter` – total days in the quarter interval

- `days_in_month` – total days in the month

**4. Completed/remaining days**

- `days_complete_in_week`, `days_remaining_in_week`

- `days_complete_in_month`, `days_remaining_in_month`

- `days_complete_in_quarter`, `days_remaining_in_quarter`

- `days_complete_in_year`, `days_remaining_in_year`

**5. Miscellaneous**

- `weekend_indicator` – equals 1 if Saturday or Sunday; otherwise 0

All date-derived fields ending in `_date` are coerced to class `Date`.
