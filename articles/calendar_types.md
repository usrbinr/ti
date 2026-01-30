# Standard vs. Non-Standard Calendars

## Introduction: Beyond the Gregorian Calendar

In many **Financial Planning & Analysis (FP&A)** functions, you’ll
encounter a `calendar_type` argument. This might be confusing, as most
people assume there is only one type of calendar!

To accommodate the unique operational and analytical needs of certain
industries (particularly retail and manufacturing), `ti` often involves
two primary calendar systems:

1.  **Standard Calendar** (Gregorian)
2.  **Non-Standard Calendars** (e.g., *5-4-4, 4-4-5, 4-5-4*)

This guide explains the differences between these calendars and their
typical use cases in business analysis.

------------------------------------------------------------------------

### 1. The Standard (Gregorian) Calendar

This is the **conventional calendar** used for general financial
reporting, scheduling, and external communication.

#### Structure & Use

- **Period Structure:** 12 months of **varying lengths** (28–31 days).
- **Days/Weeks:** 365 days per year (366 in a leap year).
- **Advantage:** It matches external reporting deadlines, regulatory
  timelines, and standard corporate schedules.

#### Disadvantage: Inconsistent Comparisons

The primary drawback is that comparing operational metrics (like sales
or margin) month-over-month (MoM) or quarter-over-quarter (QoQ) is
challenging. The varying number of days or weekends leads to
**misleading conclusions**.

> For example, comparing sales from a 31-day month to a 28-day month
> will inherently show a “drop” in total revenue, even if the daily
> performance was identical. This makes true performance comparison
> difficult.

------------------------------------------------------------------------

### 2. Non-Standard (Retail/Fiscal) Calendars

Non-standard calendars are explicitly designed to **control for
period-to-period variance**. They achieve this by ensuring every
comparable period has an identical number of weeks and, critically, an
identical number of **weekends**. This allows for a **cleaner
“apples-to-apples” comparison** of operational performance.

The most common types are the **Retail Calendars** (used in retail,
restaurant, and manufacturing), such as **5-4-4**, **4-4-5**, and
**4-5-4**.

#### Example: The 5-4-4 Calendar Structure

The 5-4-4 structure ensures that every quarter is exactly **13 weeks**
long, and the month structure repeats perfectly:

- **Basis:** Weeks in a period, not days in a month.
- **Total Year:** 52 weeks (364 days).

| Quarter Structure | Weeks | Days | Purpose |
|:--:|:--:|:--:|:---|
| **Period 1** | 5 Weeks | 35 days | Captures seasonal spikes or month-end activity. |
| **Period 2** | 4 Weeks | 28 days | Standard monthly period. |
| **Period 3** | 4 Weeks | 28 days | Standard monthly period. |
| **Total Quarter** | 13 Weeks | 91 days | Ensures exact period alignment QoQ. |

#### The 53rd Week Challenge

Since a 52-week year is 364 days, and the solar year is
$`\approx 365.25`$ days, a **53rd week** must be added every 5 to 6
years to keep the fiscal year aligned with the actual calendar year.
This **53-week year** is a crucial planning consideration for businesses
using non-standard calendars.

------------------------------------------------------------------------

### Calendar Comparison

| Feature | Standard (Gregorian) Calendar | Non-Standard (e.g., 5-4-4) Calendar |
|:---|:---|:---|
| **Basis of Period** | Days in month | Weeks in period |
| **Month/Period Length** | Varies (28–31 days) | Fixed (4 or 5 weeks) |
| **Consistency MoM/QoQ** | Low: Days/weekends vary | High: Weeks/weekends are identical |
| **Best For** | General reporting, external financial statements (GAAP/IFRS) | **Operational Analysis:** Retail sales, inventory, labor costs, and year-over-year comparisons. |

------------------------------------------------------------------------

### How to reference in `ti` functions?

The `calendar_type` argument is how you instruct the function on which
system to use for its internal calculations and indexing.

- To use a traditional calendar, pass: `"standard"`
- To use a retail calendar, pass the respective structure: `"544"`,
  `"454"`, or `"445"`

Under the hood, `ti` handles the complexities: it generates the
appropriate date keys and ensures that all your metrics are indexed
correctly to the start and end of the chosen calendar’s periods.

------------------------------------------------------------------------

### Fiscal Year Start

By default, the retail calendar’s fiscal year starts nearest to
**January** (`fiscal_year_start = 1`). Many retailers operate on a
fiscal year that begins in **February** (e.g., NRF convention). You can
control this with the `fiscal_year_start` parameter:

- `fiscal_year_start = 1` – fiscal year starts nearest to January 1st
  (default)
- `fiscal_year_start = 2` – fiscal year starts nearest to February 1st
  (common in US retail)
- `fiscal_year_start = 7` – fiscal year starts nearest to July 1st

The start date is determined by finding the `week_start` weekday
(default: Sunday) nearest to the 1st of the specified month.

------------------------------------------------------------------------

### Examples

#### Year-to-date with a 4-4-5 retail calendar

The fiscal year starts nearest to February. Each quarter has 13 weeks
split into 4-week, 4-week, and 5-week months.

``` r
contoso::sales |>
  ytd(
    .date = order_date,
    .value = margin,
    calendar_type = "445",
    fiscal_year_start = 2
  ) |>
  calculate() |>
  collect()
```

| date | year | quarter | month | week | day | margin | ytd_margin | missing_date_indicator |
|----|----|----|----|----|----|----|----|----|
| 2021-05-18 | 2021 | 2 | 4 | 16 | 18 | 406.840 | 406.840 | 0 |
| 2021-05-19 | 2021 | 2 | 4 | 16 | 19 | 711.351 | 1118.191 | 0 |
| 2021-05-20 | 2021 | 2 | 4 | 16 | 20 | 1424.101 | 2542.292 | 0 |
| 2021-05-21 | 2021 | 2 | 4 | 16 | 21 | 11338.631 | 13880.923 | 0 |
| 2021-05-22 | 2021 | 2 | 4 | 16 | 22 | 5358.767 | 19239.690 | 0 |
| 2021-05-23 | 2021 | 2 | 4 | 17 | 23 | 0.000 | 19239.690 | 1 |
| 2021-05-24 | 2021 | 2 | 4 | 17 | 24 | 0.000 | 19239.690 | 1 |
| 2021-05-25 | 2021 | 2 | 4 | 17 | 25 | 792.933 | 20032.623 | 0 |
| 2021-05-26 | 2021 | 2 | 4 | 17 | 26 | 74.550 | 20107.173 | 0 |
| 2021-05-27 | 2021 | 2 | 4 | 17 | 27 | 1432.710 | 21539.883 | 0 |

Notice that the `year`, `quarter`, `month`, and `week` columns now
reflect the **fiscal** periods from the 4-4-5 calendar rather than the
Gregorian calendar.

#### Month-to-date with a 5-4-4 retail calendar

``` r
contoso::sales |>
  mtd(
    .date = order_date,
    .value = margin,
    calendar_type = "544",
    fiscal_year_start = 2
  ) |>
  calculate() |>
  collect()
```

| date | year | month | quarter | week | day | margin | mtd_margin | missing_date_indicator |
|----|----|----|----|----|----|----|----|----|
| 2021-05-18 | 2021 | 4 | 2 | 16 | 18 | 406.840 | 406.840 | 0 |
| 2021-05-19 | 2021 | 4 | 2 | 16 | 19 | 711.351 | 1118.191 | 0 |
| 2021-05-20 | 2021 | 4 | 2 | 16 | 20 | 1424.101 | 2542.292 | 0 |
| 2021-05-21 | 2021 | 4 | 2 | 16 | 21 | 11338.631 | 13880.923 | 0 |
| 2021-05-22 | 2021 | 4 | 2 | 16 | 22 | 5358.767 | 19239.690 | 0 |
| 2021-05-23 | 2021 | 4 | 2 | 17 | 23 | 0.000 | 19239.690 | 1 |
| 2021-05-24 | 2021 | 4 | 2 | 17 | 24 | 0.000 | 19239.690 | 1 |
| 2021-05-25 | 2021 | 4 | 2 | 17 | 25 | 792.933 | 20032.623 | 0 |
| 2021-05-26 | 2021 | 4 | 2 | 17 | 26 | 74.550 | 20107.173 | 0 |
| 2021-05-27 | 2021 | 4 | 2 | 17 | 27 | 1432.710 | 21539.883 | 0 |

#### Grouped analysis with a retail calendar

Groups work exactly as they do with the standard calendar. Each group
gets a complete fiscal calendar.

``` r
contoso::sales |>
  group_by(store_key) |>
  qtd(
    .date = order_date,
    .value = margin,
    calendar_type = "445",
    fiscal_year_start = 2
  ) |>
  calculate() |>
  collect()
```

#### Comparing calendar types

Below is a side-by-side comparison of how the same date is classified
under a standard calendar vs. a 4-4-5 retail calendar:

| Feature | Standard (2024-03-15) | 4-4-5 FY starts Feb (2024-03-15) |
|---------|-----------------------|----------------------------------|
| Year    | 2024                  | 2024                             |
| Quarter | 1                     | 1                                |
| Month   | 3                     | 2                                |
| Week    | 11                    | 7                                |

Table 1

The retail calendar shifts the fiscal boundaries so that every
comparable period contains the same number of weeks, enabling cleaner
period-over-period comparisons.
