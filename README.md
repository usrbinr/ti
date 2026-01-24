

<!-- badges: start -->

[![CRAN
status](https://www.r-pkg.org/badges/version/fpaR?svg=1.png)](https://CRAN.R-project.org/package=fpaR)
[![Binder](https://mybinder.org/badge_logo.svg)](https://mybinder.org/v2/gh/usrbinr/fpaR/HEAD)
[![](https://cranlogs.r-pkg.org/badges/fpaR.png)](https://cran.r-project.org/package=fpaR)
<!-- badges: end -->

## A Business Intelligence Toolkit for Financial Planning & Analysis (FP&A)

This package is a collection of business intelligence tools designed to
simplify common **financial planning and analysis (FP&A)** tasks such as
time intelligence calculations, group members segmentation and
factor/variance analysis.

The package is inspired by best practices from a collection of blogs,
books, industry research, and hands-on work experience, consolidating
frequently performed business analyses into a fast, efficient, and
reusable framework.

In particular, the time intelligence functions are heavily inspired by
[PowerBI DAX](https://www.sqlbi.com/) functions

Under the hood, these functions are built upon the great foundations of:

- [dbplyr](https://dbplyr.tidyverse.org/)  
- [duckdb](https://github.com/duckdb/duckdb-r)
- [lubridate](https://lubridate.tidyverse.org/)

All functions are designed to work with either tibbles or modern
databases (DuckDB, Snowflake, SQLite, etc) with a unified syntax.

Even if you are working with tibbles, all functions are optimized to
leverage [DuckDB](https://github.com/duckdb/duckdb-r) for increased
speed and performance[^1]

By default, all functions returns a lazy DBI object which you can return
as a tibble with `dplyr::collect()`

## Key features & benefits

- **Unified syntax** regardless if your data is in a tibble or a
  database
- **Scale** your data with [duckdb](https://github.com/duckdb/duckdb-r)
  to optimize your calculations
- **Instant clarity** as every function summarizes its transformation
  actions so that you can understand and validate the results

## Installation

Install the development from GitHub:

``` r
# Install using pak or install.package()

pak::pak("usrbinr/fpaR")
```

## What is in fpa?

> We recommend using the [Contoso](https://usrbinr.github.io/contoso/)
> package for any practice analysis. The contoso datasets are fictional
> business transaction of the Contoso toy company which are helpful for
> business intelligence related analysis

There are 3 main categories of functions:

- Time intelligence related functions
  (<a href="#tbl-ti-fn" class="quarto-xref">Table 1</a>)
- Categorization strategies
  (<a href="#tbl-abc-fn" class="quarto-xref">Table 2</a>)
- Factor analysis (work in progress)

### Time intelligence

This is a collection of the most commonly used time intelligence
analysis such as **Year-over-Year**(`yoy()`),
**Month-to-Date**(`mtd()`), and **Current Year-to-Date over Previous
Year-to-Date** (`ytdopy()`) analysis.

These functions are designed to quickly answer questions in a
consistent, fast and transparent way.

**Key benefits:**

- **Auto-fill missing dates**: Ensures no missing periods in your
  datasets so that right period comparisons are performed

- **Flexible calendar options**: Handle comparisons based on a
  **standard** or **non-standard** fiscal calendar to accommodate
  different reporting frameworks

- **Clear definition**: Full transparency to the calculations that are
  performed with visibilty to any missing or incomplete date periods

Below is the full list of time intelligence functions:

<div id="tbl-ti-fn">

Table 1

<div class="cell-output-display">

| Function | Description | Shift | Aggregate | Compare |
|----|----|----|----|----|
| YoY | Full Year over Year |  |  | X |
| YTD | Year-to-Date |  | X |  |
| PYTD | Prior Year-to-Date amount | X | X |  |
| YoYTD | Current Year-to-Date over Prior Year-to-Date | X | X | X |
| YTDOPY | Year-to-Date over Full Previous Year | X | X | X |
| QoQ | Full Quarter over Quarter |  |  | X |
| QTD | Quarter-to-Date |  | X |  |
| PQTD | Prior Quarter-to-Date | X | X |  |
| QOQTD | Quarter-over-Quarter-to-Date | X | X | X |
| QTDOPQ | Quarter-to-Date over Full Previous Quarter | X | X | X |
| MTD | Month-to-Date |  | X |  |
| MoM | Full Month over Full Month |  |  | X |
| MoMTD | Current Month-to-Date over Prior Month-to-Date | X | X | X |
| PMTD | Prior Month’s MTD amount | X | X |  |
| MTDOPM | Month-to-Date over Full Previous Month | X | X | X |
| WTD | Week-to-Date |  | X |  |
| WoW | Full Week over Full Week |  |  | X |
| WoWTD | Current Week-to-Date over Prior Week-to-Date | X | X | X |
| PWTD | Prior Week-to-Date | X | X |  |
| ATD | cumlaitve total from inception to date |  | x |  |
| DoD | Full Day over Full Day |  |  | X |

</div>

</div>

------------------------------------------------------------------------

### **Classification Strategies**

#### ABC Classification

ABC classification is a business analysis technique that categorizes
items (like products, customers, or suppliers) based on their relative
contribution of a value. It expands upon the the Pareto Principle (the
80/20 rule), allowing the user to determine which percentage of items or
group members contribute to the largest percentage of the total value.

You assign the break points for the categorization and the function will
label each category with a letter value.

#### Cohort

Cohort analysis is a type of behavioral analytics that takes data from a
given group of users (called a cohort) and tracks their activity over
time. A cohort is typically defined by a shared starting characteristic,
most commonly the time period in which the entities first interacted
with the product or service.

This allows you to understand retention, turnover and other cohort
attributes more clearly.

<div id="tbl-abc-fn">

Table 2

<div class="cell-output-display">

| Function | Description | Categorizes | Time-Based | Tracks Over Time |
|----|----|----|----|----|
| abc() | ABC Classification groups items by relative contribution (Pareto analysis). | X |  |  |
| cohort() | Cohort analysis groups entities by a shared start point and analyzes behavior over time. |  | X | X |

</div>

</div>

## Additional references and inspirations

- [PeerChristensen’s Cohort
  Package](https://github.com/PeerChristensen/cohorts)

[^1]: I plan to use
    [duckplyr](https://duckplyr.tidyverse.org/index.html) once it
    expands support for lubricate functions
