

<img src="man/figures/ti_logo.png" align="right" width="120" />

## A Business Intelligence Toolkit for Financial Planning & Analysis (FP&A)

`ti` package is a collection of business intelligence tools designed to
simplify common **financial planning and analysis (FP&A)** tasks such as
time intelligence calculations and group member segmentation.

The package is inspired by best practices from a collection of blogs,
books, industry research, and hands-on work experience, consolidating
frequently performed business analyses into a fast, efficient, and
reusable framework.

In particular, the time intelligence functions are heavily inspired by
[PowerBI DAX](https://www.sqlbi.com/) functions.

Under the hood, these functions are built upon the great foundations of:

- [dbplyr](https://dbplyr.tidyverse.org/)
- [duckdb](https://github.com/duckdb/duckdb-r)
- [lubridate](https://lubridate.tidyverse.org/)

All functions are designed to work with either tibbles or a database
backend with a unified syntax. Dialect-specific date arithmetic is
generated for DuckDB, Snowflake and Postgres; other `dbplyr` backends
fall back to the DuckDB dialect and may need testing.

Even if you are working with tibbles, all functions are optimized to
leverage [DuckDB](https://github.com/duckdb/duckdb-r) for increased
speed and performance[^1]

By default, all functions return a lazy DBI object which you can return
as a tibble with `dplyr::collect()`

## Key features & benefits

- **Unified syntax** regardless if your data is in a tibble or a
  database
- **Scale** your data with [duckdb](https://github.com/duckdb/duckdb-r)
  to optimize your calculations
- **Instant clarity** as every function summarizes its transformation
  actions so that you can understand and validate the results

## Installation

Install the development version from Codeberg:

``` r
# Install using pak or remotes

remotes::install_git("https://codeberg.org/usrbinr/ti")

# to install from CRAN
pak::pak("ti")
```

## What is in ti?

> We recommend using the [Contoso](https://usrbinr.github.io/contoso/)
> package for any practice analysis. The contoso datasets are fictional
> business transactions of the Contoso toy company which are helpful for
> business intelligence related analysis

There are 2 main categories of functions:

- Time intelligence related functions
  (<a href="#tbl-ti-fn" class="quarto-xref">Table 1</a>)
- Categorization strategies
  (<a href="#tbl-abc-fn" class="quarto-xref">Table 2</a>)

### Time intelligence

This is a collection of the most commonly used time intelligence
analysis such as **Year-over-Year**(`yoy()`),
**Month-to-Date**(`mtd()`), and **Current Year-to-Date over Previous
Year-to-Date** (`ytdopy()`) analysis.

These functions are designed to quickly answer questions in a
consistent, fast and transparent way.

**Key benefits:**

- **Auto-fill missing dates**: Ensures no missing periods in your
  datasets so that correct period comparisons are performed

- **Flexible calendar options**: Handle comparisons based on a
  **standard** or **non-standard** fiscal calendar to accommodate
  different reporting frameworks

- **Clear definition**: Full transparency into the calculations that are
  performed, with visibility to any missing or incomplete date periods

Below is the full list of time intelligence functions:

<div id="tbl-ti-fn">

Table 1

<div class="cell-output-display">

<div id="zzeebxppdt" style="padding-left:0px;padding-right:0px;padding-top:10px;padding-bottom:10px;overflow-x:auto;overflow-y:auto;width:auto;height:auto;">
<style>@import url("https://fonts.googleapis.com/css2?family=Fira+Code:ital,wght@0,100;0,200;0,300;0,400;0,500;0,600;0,700;0,800;0,900;1,100;1,200;1,300;1,400;1,500;1,600;1,700;1,800;1,900&display=swap");
#zzeebxppdt table {
  font-family: system-ui, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif, 'Apple Color Emoji', 'Segoe UI Emoji', 'Segoe UI Symbol', 'Noto Color Emoji';
  -webkit-font-smoothing: antialiased;
  -moz-osx-font-smoothing: grayscale;
}
&#10;#zzeebxppdt thead, #zzeebxppdt tbody, #zzeebxppdt tfoot, #zzeebxppdt tr, #zzeebxppdt td, #zzeebxppdt th {
  border-style: none;
}
&#10;#zzeebxppdt p {
  margin: 0;
  padding: 0;
}
&#10;#zzeebxppdt .gt_table {
  display: table;
  border-collapse: collapse;
  line-height: normal;
  margin-left: auto;
  margin-right: auto;
  color: #333333;
  font-size: 16px;
  font-weight: normal;
  font-style: normal;
  background-color: #FFFFFF;
  width: auto;
  border-top-style: solid;
  border-top-width: 2px;
  border-top-color: #A8A8A8;
  border-right-style: none;
  border-right-width: 2px;
  border-right-color: #D3D3D3;
  border-bottom-style: solid;
  border-bottom-width: 2px;
  border-bottom-color: #A8A8A8;
  border-left-style: none;
  border-left-width: 2px;
  border-left-color: #D3D3D3;
}
&#10;#zzeebxppdt .gt_caption {
  padding-top: 4px;
  padding-bottom: 4px;
}
&#10;#zzeebxppdt .gt_title {
  color: #333333;
  font-size: 125%;
  font-weight: initial;
  padding-top: 4px;
  padding-bottom: 4px;
  padding-left: 5px;
  padding-right: 5px;
  border-bottom-color: #FFFFFF;
  border-bottom-width: 0;
}
&#10;#zzeebxppdt .gt_subtitle {
  color: #333333;
  font-size: 85%;
  font-weight: initial;
  padding-top: 3px;
  padding-bottom: 5px;
  padding-left: 5px;
  padding-right: 5px;
  border-top-color: #FFFFFF;
  border-top-width: 0;
}
&#10;#zzeebxppdt .gt_heading {
  background-color: #FFFFFF;
  text-align: center;
  border-bottom-color: #FFFFFF;
  border-left-style: none;
  border-left-width: 1px;
  border-left-color: #D3D3D3;
  border-right-style: none;
  border-right-width: 1px;
  border-right-color: #D3D3D3;
}
&#10;#zzeebxppdt .gt_bottom_border {
  border-bottom-style: solid;
  border-bottom-width: 2px;
  border-bottom-color: #D3D3D3;
}
&#10;#zzeebxppdt .gt_col_headings {
  border-top-style: solid;
  border-top-width: 2px;
  border-top-color: #D3D3D3;
  border-bottom-style: solid;
  border-bottom-width: 2px;
  border-bottom-color: #D3D3D3;
  border-left-style: none;
  border-left-width: 1px;
  border-left-color: #D3D3D3;
  border-right-style: none;
  border-right-width: 1px;
  border-right-color: #D3D3D3;
}
&#10;#zzeebxppdt .gt_col_heading {
  color: #333333;
  background-color: #FFFFFF;
  font-size: 100%;
  font-weight: normal;
  text-transform: inherit;
  border-left-style: none;
  border-left-width: 1px;
  border-left-color: #D3D3D3;
  border-right-style: none;
  border-right-width: 1px;
  border-right-color: #D3D3D3;
  vertical-align: bottom;
  padding-top: 5px;
  padding-bottom: 6px;
  padding-left: 5px;
  padding-right: 5px;
  overflow-x: hidden;
}
&#10;#zzeebxppdt .gt_column_spanner_outer {
  color: #333333;
  background-color: #FFFFFF;
  font-size: 100%;
  font-weight: normal;
  text-transform: inherit;
  padding-top: 0;
  padding-bottom: 0;
  padding-left: 4px;
  padding-right: 4px;
}
&#10;#zzeebxppdt .gt_column_spanner_outer:first-child {
  padding-left: 0;
}
&#10;#zzeebxppdt .gt_column_spanner_outer:last-child {
  padding-right: 0;
}
&#10;#zzeebxppdt .gt_column_spanner {
  border-bottom-style: solid;
  border-bottom-width: 2px;
  border-bottom-color: #D3D3D3;
  vertical-align: bottom;
  padding-top: 5px;
  padding-bottom: 5px;
  overflow-x: hidden;
  display: inline-block;
  width: 100%;
}
&#10;#zzeebxppdt .gt_spanner_row {
  border-bottom-style: hidden;
}
&#10;#zzeebxppdt .gt_group_heading {
  padding-top: 8px;
  padding-bottom: 8px;
  padding-left: 5px;
  padding-right: 5px;
  color: #333333;
  background-color: #FFFFFF;
  font-size: 100%;
  font-weight: initial;
  text-transform: inherit;
  border-top-style: solid;
  border-top-width: 2px;
  border-top-color: #D3D3D3;
  border-bottom-style: solid;
  border-bottom-width: 2px;
  border-bottom-color: #D3D3D3;
  border-left-style: none;
  border-left-width: 1px;
  border-left-color: #D3D3D3;
  border-right-style: none;
  border-right-width: 1px;
  border-right-color: #D3D3D3;
  vertical-align: middle;
  text-align: left;
}
&#10;#zzeebxppdt .gt_empty_group_heading {
  padding: 0.5px;
  color: #333333;
  background-color: #FFFFFF;
  font-size: 100%;
  font-weight: initial;
  border-top-style: solid;
  border-top-width: 2px;
  border-top-color: #D3D3D3;
  border-bottom-style: solid;
  border-bottom-width: 2px;
  border-bottom-color: #D3D3D3;
  vertical-align: middle;
}
&#10;#zzeebxppdt .gt_from_md > :first-child {
  margin-top: 0;
}
&#10;#zzeebxppdt .gt_from_md > :last-child {
  margin-bottom: 0;
}
&#10;#zzeebxppdt .gt_row {
  padding-top: 8px;
  padding-bottom: 8px;
  padding-left: 5px;
  padding-right: 5px;
  margin: 10px;
  border-top-style: solid;
  border-top-width: 1px;
  border-top-color: #D3D3D3;
  border-left-style: none;
  border-left-width: 1px;
  border-left-color: #D3D3D3;
  border-right-style: none;
  border-right-width: 1px;
  border-right-color: #D3D3D3;
  vertical-align: middle;
  overflow-x: hidden;
}
&#10;#zzeebxppdt .gt_stub {
  color: #333333;
  background-color: #FFFFFF;
  font-size: 100%;
  font-weight: initial;
  text-transform: inherit;
  border-right-style: solid;
  border-right-width: 2px;
  border-right-color: #D3D3D3;
  padding-left: 5px;
  padding-right: 5px;
}
&#10;#zzeebxppdt .gt_stub_row_group {
  color: #333333;
  background-color: #FFFFFF;
  font-size: 100%;
  font-weight: initial;
  text-transform: inherit;
  border-right-style: solid;
  border-right-width: 2px;
  border-right-color: #D3D3D3;
  padding-left: 5px;
  padding-right: 5px;
  vertical-align: top;
}
&#10;#zzeebxppdt .gt_row_group_first td {
  border-top-width: 2px;
}
&#10;#zzeebxppdt .gt_row_group_first th {
  border-top-width: 2px;
}
&#10;#zzeebxppdt .gt_summary_row {
  color: #333333;
  background-color: #FFFFFF;
  text-transform: inherit;
  padding-top: 8px;
  padding-bottom: 8px;
  padding-left: 5px;
  padding-right: 5px;
}
&#10;#zzeebxppdt .gt_first_summary_row {
  border-top-style: solid;
  border-top-color: #D3D3D3;
}
&#10;#zzeebxppdt .gt_first_summary_row.thick {
  border-top-width: 2px;
}
&#10;#zzeebxppdt .gt_last_summary_row {
  padding-top: 8px;
  padding-bottom: 8px;
  padding-left: 5px;
  padding-right: 5px;
  border-bottom-style: solid;
  border-bottom-width: 2px;
  border-bottom-color: #D3D3D3;
}
&#10;#zzeebxppdt .gt_grand_summary_row {
  color: #333333;
  background-color: #FFFFFF;
  text-transform: inherit;
  padding-top: 8px;
  padding-bottom: 8px;
  padding-left: 5px;
  padding-right: 5px;
}
&#10;#zzeebxppdt .gt_first_grand_summary_row {
  padding-top: 8px;
  padding-bottom: 8px;
  padding-left: 5px;
  padding-right: 5px;
  border-top-style: double;
  border-top-width: 6px;
  border-top-color: #D3D3D3;
}
&#10;#zzeebxppdt .gt_last_grand_summary_row_top {
  padding-top: 8px;
  padding-bottom: 8px;
  padding-left: 5px;
  padding-right: 5px;
  border-bottom-style: double;
  border-bottom-width: 6px;
  border-bottom-color: #D3D3D3;
}
&#10;#zzeebxppdt .gt_striped {
  background-color: rgba(128, 128, 128, 0.05);
}
&#10;#zzeebxppdt .gt_table_body {
  border-top-style: solid;
  border-top-width: 2px;
  border-top-color: #D3D3D3;
  border-bottom-style: solid;
  border-bottom-width: 2px;
  border-bottom-color: #D3D3D3;
}
&#10;#zzeebxppdt .gt_footnotes {
  color: #333333;
  background-color: #FFFFFF;
  border-bottom-style: none;
  border-bottom-width: 2px;
  border-bottom-color: #D3D3D3;
  border-left-style: none;
  border-left-width: 2px;
  border-left-color: #D3D3D3;
  border-right-style: none;
  border-right-width: 2px;
  border-right-color: #D3D3D3;
}
&#10;#zzeebxppdt .gt_footnote {
  margin: 0px;
  font-size: 90%;
  padding-top: 4px;
  padding-bottom: 4px;
  padding-left: 5px;
  padding-right: 5px;
}
&#10;#zzeebxppdt .gt_sourcenotes {
  color: #333333;
  background-color: #FFFFFF;
  border-bottom-style: none;
  border-bottom-width: 2px;
  border-bottom-color: #D3D3D3;
  border-left-style: none;
  border-left-width: 2px;
  border-left-color: #D3D3D3;
  border-right-style: none;
  border-right-width: 2px;
  border-right-color: #D3D3D3;
}
&#10;#zzeebxppdt .gt_sourcenote {
  font-size: 90%;
  padding-top: 4px;
  padding-bottom: 4px;
  padding-left: 5px;
  padding-right: 5px;
}
&#10;#zzeebxppdt .gt_left {
  text-align: left;
}
&#10;#zzeebxppdt .gt_center {
  text-align: center;
}
&#10;#zzeebxppdt .gt_right {
  text-align: right;
  font-variant-numeric: tabular-nums;
}
&#10;#zzeebxppdt .gt_font_normal {
  font-weight: normal;
}
&#10;#zzeebxppdt .gt_font_bold {
  font-weight: bold;
}
&#10;#zzeebxppdt .gt_font_italic {
  font-style: italic;
}
&#10;#zzeebxppdt .gt_super {
  font-size: 65%;
}
&#10;#zzeebxppdt .gt_footnote_marks {
  font-size: 75%;
  vertical-align: 0.4em;
  position: initial;
}
&#10;#zzeebxppdt .gt_asterisk {
  font-size: 100%;
  vertical-align: 0;
}
&#10;#zzeebxppdt .gt_indent_1 {
  text-indent: 5px;
}
&#10;#zzeebxppdt .gt_indent_2 {
  text-indent: 10px;
}
&#10;#zzeebxppdt .gt_indent_3 {
  text-indent: 15px;
}
&#10;#zzeebxppdt .gt_indent_4 {
  text-indent: 20px;
}
&#10;#zzeebxppdt .gt_indent_5 {
  text-indent: 25px;
}
&#10;#zzeebxppdt .katex-display {
  display: inline-flex !important;
  margin-bottom: 0.75em !important;
}
&#10;#zzeebxppdt div.Reactable > div.rt-table > div.rt-thead > div.rt-tr.rt-tr-group-header > div.rt-th-group:after {
  height: 0px !important;
}
</style>

<table class="gt_table" data-quarto-postprocess="true"
data-quarto-disable-processing="false" data-quarto-bootstrap="false">
<thead>
<tr class="gt_heading">
<th colspan="5"
class="gt_heading gt_title gt_font_normal gt_bottom_border"><strong>Time
Intelligence Functions</strong></th>
</tr>
<tr class="gt_col_headings">
<th id="Function"
class="gt_col_heading gt_columns_bottom_border gt_left"
data-quarto-table-cell-role="th"
style="background-color: #F0F0F0; font-weight: bold"
scope="col">Function</th>
<th id="Description"
class="gt_col_heading gt_columns_bottom_border gt_left"
data-quarto-table-cell-role="th"
style="background-color: #F0F0F0; font-weight: bold"
scope="col">Description</th>
<th id="Shift" class="gt_col_heading gt_columns_bottom_border gt_center"
data-quarto-table-cell-role="th"
style="background-color: #F0F0F0; font-weight: bold"
scope="col">Shift</th>
<th id="Aggregate"
class="gt_col_heading gt_columns_bottom_border gt_center"
data-quarto-table-cell-role="th"
style="background-color: #F0F0F0; font-weight: bold"
scope="col">Aggregate</th>
<th id="Compare"
class="gt_col_heading gt_columns_bottom_border gt_center"
data-quarto-table-cell-role="th"
style="background-color: #F0F0F0; font-weight: bold"
scope="col">Compare</th>
</tr>
</thead>
<tbody class="gt_table_body">
<tr>
<td class="gt_row gt_left" headers="Function"
style="font-family: &#39;Fira Code&#39;; font-weight: bold">YoY</td>
<td class="gt_row gt_left" headers="Description">Full Year over
Year</td>
<td class="gt_row gt_center" headers="Shift"></td>
<td class="gt_row gt_center" headers="Aggregate">X</td>
<td class="gt_row gt_center" headers="Compare">X</td>
</tr>
<tr>
<td class="gt_row gt_left gt_striped" headers="Function"
style="font-family: &#39;Fira Code&#39;; font-weight: bold">YTD</td>
<td class="gt_row gt_left gt_striped"
headers="Description">Year-to-Date</td>
<td class="gt_row gt_center gt_striped" headers="Shift"></td>
<td class="gt_row gt_center gt_striped" headers="Aggregate">X</td>
<td class="gt_row gt_center gt_striped" headers="Compare"></td>
</tr>
<tr>
<td class="gt_row gt_left" headers="Function"
style="font-family: &#39;Fira Code&#39;; font-weight: bold">PYTD</td>
<td class="gt_row gt_left" headers="Description">Prior Year-to-Date
amount</td>
<td class="gt_row gt_center" headers="Shift">X</td>
<td class="gt_row gt_center" headers="Aggregate">X</td>
<td class="gt_row gt_center" headers="Compare"></td>
</tr>
<tr>
<td class="gt_row gt_left gt_striped" headers="Function"
style="font-family: &#39;Fira Code&#39;; font-weight: bold">YoYTD</td>
<td class="gt_row gt_left gt_striped" headers="Description">Current
Year-to-Date over Prior Year-to-Date</td>
<td class="gt_row gt_center gt_striped" headers="Shift">X</td>
<td class="gt_row gt_center gt_striped" headers="Aggregate">X</td>
<td class="gt_row gt_center gt_striped" headers="Compare">X</td>
</tr>
<tr>
<td class="gt_row gt_left" headers="Function"
style="font-family: &#39;Fira Code&#39;; font-weight: bold">YTDOPY</td>
<td class="gt_row gt_left" headers="Description">Year-to-Date over Full
Previous Year</td>
<td class="gt_row gt_center" headers="Shift">X</td>
<td class="gt_row gt_center" headers="Aggregate">X</td>
<td class="gt_row gt_center" headers="Compare">X</td>
</tr>
<tr>
<td class="gt_row gt_left gt_striped" headers="Function"
style="font-family: &#39;Fira Code&#39;; font-weight: bold">QoQ</td>
<td class="gt_row gt_left gt_striped" headers="Description">Full Quarter
over Quarter</td>
<td class="gt_row gt_center gt_striped" headers="Shift"></td>
<td class="gt_row gt_center gt_striped" headers="Aggregate">X</td>
<td class="gt_row gt_center gt_striped" headers="Compare">X</td>
</tr>
<tr>
<td class="gt_row gt_left" headers="Function"
style="font-family: &#39;Fira Code&#39;; font-weight: bold">QTD</td>
<td class="gt_row gt_left" headers="Description">Quarter-to-Date</td>
<td class="gt_row gt_center" headers="Shift"></td>
<td class="gt_row gt_center" headers="Aggregate">X</td>
<td class="gt_row gt_center" headers="Compare"></td>
</tr>
<tr>
<td class="gt_row gt_left gt_striped" headers="Function"
style="font-family: &#39;Fira Code&#39;; font-weight: bold">PQTD</td>
<td class="gt_row gt_left gt_striped" headers="Description">Prior
Quarter-to-Date</td>
<td class="gt_row gt_center gt_striped" headers="Shift">X</td>
<td class="gt_row gt_center gt_striped" headers="Aggregate">X</td>
<td class="gt_row gt_center gt_striped" headers="Compare"></td>
</tr>
<tr>
<td class="gt_row gt_left" headers="Function"
style="font-family: &#39;Fira Code&#39;; font-weight: bold">QOQTD</td>
<td class="gt_row gt_left"
headers="Description">Quarter-over-Quarter-to-Date</td>
<td class="gt_row gt_center" headers="Shift">X</td>
<td class="gt_row gt_center" headers="Aggregate">X</td>
<td class="gt_row gt_center" headers="Compare">X</td>
</tr>
<tr>
<td class="gt_row gt_left gt_striped" headers="Function"
style="font-family: &#39;Fira Code&#39;; font-weight: bold">QTDOPQ</td>
<td class="gt_row gt_left gt_striped"
headers="Description">Quarter-to-Date over Full Previous Quarter</td>
<td class="gt_row gt_center gt_striped" headers="Shift">X</td>
<td class="gt_row gt_center gt_striped" headers="Aggregate">X</td>
<td class="gt_row gt_center gt_striped" headers="Compare">X</td>
</tr>
<tr>
<td class="gt_row gt_left" headers="Function"
style="font-family: &#39;Fira Code&#39;; font-weight: bold">MTD</td>
<td class="gt_row gt_left" headers="Description">Month-to-Date</td>
<td class="gt_row gt_center" headers="Shift"></td>
<td class="gt_row gt_center" headers="Aggregate">X</td>
<td class="gt_row gt_center" headers="Compare"></td>
</tr>
<tr>
<td class="gt_row gt_left gt_striped" headers="Function"
style="font-family: &#39;Fira Code&#39;; font-weight: bold">MoM</td>
<td class="gt_row gt_left gt_striped" headers="Description">Full Month
over Full Month</td>
<td class="gt_row gt_center gt_striped" headers="Shift"></td>
<td class="gt_row gt_center gt_striped" headers="Aggregate">X</td>
<td class="gt_row gt_center gt_striped" headers="Compare">X</td>
</tr>
<tr>
<td class="gt_row gt_left" headers="Function"
style="font-family: &#39;Fira Code&#39;; font-weight: bold">MoMTD</td>
<td class="gt_row gt_left" headers="Description">Current Month-to-Date
over Prior Month-to-Date</td>
<td class="gt_row gt_center" headers="Shift">X</td>
<td class="gt_row gt_center" headers="Aggregate">X</td>
<td class="gt_row gt_center" headers="Compare">X</td>
</tr>
<tr>
<td class="gt_row gt_left gt_striped" headers="Function"
style="font-family: &#39;Fira Code&#39;; font-weight: bold">PMTD</td>
<td class="gt_row gt_left gt_striped" headers="Description">Prior
Month's MTD amount</td>
<td class="gt_row gt_center gt_striped" headers="Shift">X</td>
<td class="gt_row gt_center gt_striped" headers="Aggregate">X</td>
<td class="gt_row gt_center gt_striped" headers="Compare"></td>
</tr>
<tr>
<td class="gt_row gt_left" headers="Function"
style="font-family: &#39;Fira Code&#39;; font-weight: bold">MTDOPM</td>
<td class="gt_row gt_left" headers="Description">Month-to-Date over Full
Previous Month</td>
<td class="gt_row gt_center" headers="Shift">X</td>
<td class="gt_row gt_center" headers="Aggregate">X</td>
<td class="gt_row gt_center" headers="Compare">X</td>
</tr>
<tr>
<td class="gt_row gt_left gt_striped" headers="Function"
style="font-family: &#39;Fira Code&#39;; font-weight: bold">WTD</td>
<td class="gt_row gt_left gt_striped"
headers="Description">Week-to-Date</td>
<td class="gt_row gt_center gt_striped" headers="Shift"></td>
<td class="gt_row gt_center gt_striped" headers="Aggregate">X</td>
<td class="gt_row gt_center gt_striped" headers="Compare"></td>
</tr>
<tr>
<td class="gt_row gt_left" headers="Function"
style="font-family: &#39;Fira Code&#39;; font-weight: bold">WoW</td>
<td class="gt_row gt_left" headers="Description">Full Week over Full
Week</td>
<td class="gt_row gt_center" headers="Shift"></td>
<td class="gt_row gt_center" headers="Aggregate">X</td>
<td class="gt_row gt_center" headers="Compare">X</td>
</tr>
<tr>
<td class="gt_row gt_left gt_striped" headers="Function"
style="font-family: &#39;Fira Code&#39;; font-weight: bold">WoWTD</td>
<td class="gt_row gt_left gt_striped" headers="Description">Current
Week-to-Date over Prior Week-to-Date</td>
<td class="gt_row gt_center gt_striped" headers="Shift">X</td>
<td class="gt_row gt_center gt_striped" headers="Aggregate">X</td>
<td class="gt_row gt_center gt_striped" headers="Compare">X</td>
</tr>
<tr>
<td class="gt_row gt_left" headers="Function"
style="font-family: &#39;Fira Code&#39;; font-weight: bold">PWTD</td>
<td class="gt_row gt_left" headers="Description">Prior Week-to-Date</td>
<td class="gt_row gt_center" headers="Shift">X</td>
<td class="gt_row gt_center" headers="Aggregate">X</td>
<td class="gt_row gt_center" headers="Compare"></td>
</tr>
<tr>
<td class="gt_row gt_left gt_striped" headers="Function"
style="font-family: &#39;Fira Code&#39;; font-weight: bold">ATD</td>
<td class="gt_row gt_left gt_striped" headers="Description">Cumulative
total from inception to date</td>
<td class="gt_row gt_center gt_striped" headers="Shift"></td>
<td class="gt_row gt_center gt_striped" headers="Aggregate">X</td>
<td class="gt_row gt_center gt_striped" headers="Compare"></td>
</tr>
<tr>
<td class="gt_row gt_left" headers="Function"
style="font-family: &#39;Fira Code&#39;; font-weight: bold">DoD</td>
<td class="gt_row gt_left" headers="Description">Full Day over Full
Day</td>
<td class="gt_row gt_center" headers="Shift"></td>
<td class="gt_row gt_center" headers="Aggregate">X</td>
<td class="gt_row gt_center" headers="Compare">X</td>
</tr>
</tbody>
</table>

</div>

</div>

</div>

------------------------------------------------------------------------

### Classification Strategies

#### ABC Classification

ABC classification is a business analysis technique that categorizes
items (like products, customers, or suppliers) based on their relative
contribution of a value. It expands upon the Pareto Principle (the 80/20
rule), allowing the user to determine which percentage of items or group
members contribute to the largest percentage of the total value.

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

<div class="cell-output-display column-screen">

<div id="kpshklwisp" style="padding-left:0px;padding-right:0px;padding-top:10px;padding-bottom:10px;overflow-x:auto;overflow-y:auto;width:auto;height:auto;">
<style>@import url("https://fonts.googleapis.com/css2?family=Fira+Code:ital,wght@0,100;0,200;0,300;0,400;0,500;0,600;0,700;0,800;0,900;1,100;1,200;1,300;1,400;1,500;1,600;1,700;1,800;1,900&display=swap");
#kpshklwisp table {
  font-family: system-ui, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif, 'Apple Color Emoji', 'Segoe UI Emoji', 'Segoe UI Symbol', 'Noto Color Emoji';
  -webkit-font-smoothing: antialiased;
  -moz-osx-font-smoothing: grayscale;
}
&#10;#kpshklwisp thead, #kpshklwisp tbody, #kpshklwisp tfoot, #kpshklwisp tr, #kpshklwisp td, #kpshklwisp th {
  border-style: none;
}
&#10;#kpshklwisp p {
  margin: 0;
  padding: 0;
}
&#10;#kpshklwisp .gt_table {
  display: table;
  border-collapse: collapse;
  line-height: normal;
  margin-left: auto;
  margin-right: auto;
  color: #333333;
  font-size: 16px;
  font-weight: normal;
  font-style: normal;
  background-color: #FFFFFF;
  width: auto;
  border-top-style: solid;
  border-top-width: 2px;
  border-top-color: #A8A8A8;
  border-right-style: none;
  border-right-width: 2px;
  border-right-color: #D3D3D3;
  border-bottom-style: solid;
  border-bottom-width: 2px;
  border-bottom-color: #A8A8A8;
  border-left-style: none;
  border-left-width: 2px;
  border-left-color: #D3D3D3;
}
&#10;#kpshklwisp .gt_caption {
  padding-top: 4px;
  padding-bottom: 4px;
}
&#10;#kpshklwisp .gt_title {
  color: #333333;
  font-size: 125%;
  font-weight: initial;
  padding-top: 4px;
  padding-bottom: 4px;
  padding-left: 5px;
  padding-right: 5px;
  border-bottom-color: #FFFFFF;
  border-bottom-width: 0;
}
&#10;#kpshklwisp .gt_subtitle {
  color: #333333;
  font-size: 85%;
  font-weight: initial;
  padding-top: 3px;
  padding-bottom: 5px;
  padding-left: 5px;
  padding-right: 5px;
  border-top-color: #FFFFFF;
  border-top-width: 0;
}
&#10;#kpshklwisp .gt_heading {
  background-color: #FFFFFF;
  text-align: center;
  border-bottom-color: #FFFFFF;
  border-left-style: none;
  border-left-width: 1px;
  border-left-color: #D3D3D3;
  border-right-style: none;
  border-right-width: 1px;
  border-right-color: #D3D3D3;
}
&#10;#kpshklwisp .gt_bottom_border {
  border-bottom-style: solid;
  border-bottom-width: 2px;
  border-bottom-color: #D3D3D3;
}
&#10;#kpshklwisp .gt_col_headings {
  border-top-style: solid;
  border-top-width: 2px;
  border-top-color: #D3D3D3;
  border-bottom-style: solid;
  border-bottom-width: 2px;
  border-bottom-color: #D3D3D3;
  border-left-style: none;
  border-left-width: 1px;
  border-left-color: #D3D3D3;
  border-right-style: none;
  border-right-width: 1px;
  border-right-color: #D3D3D3;
}
&#10;#kpshklwisp .gt_col_heading {
  color: #333333;
  background-color: #FFFFFF;
  font-size: 100%;
  font-weight: normal;
  text-transform: inherit;
  border-left-style: none;
  border-left-width: 1px;
  border-left-color: #D3D3D3;
  border-right-style: none;
  border-right-width: 1px;
  border-right-color: #D3D3D3;
  vertical-align: bottom;
  padding-top: 5px;
  padding-bottom: 6px;
  padding-left: 5px;
  padding-right: 5px;
  overflow-x: hidden;
}
&#10;#kpshklwisp .gt_column_spanner_outer {
  color: #333333;
  background-color: #FFFFFF;
  font-size: 100%;
  font-weight: normal;
  text-transform: inherit;
  padding-top: 0;
  padding-bottom: 0;
  padding-left: 4px;
  padding-right: 4px;
}
&#10;#kpshklwisp .gt_column_spanner_outer:first-child {
  padding-left: 0;
}
&#10;#kpshklwisp .gt_column_spanner_outer:last-child {
  padding-right: 0;
}
&#10;#kpshklwisp .gt_column_spanner {
  border-bottom-style: solid;
  border-bottom-width: 2px;
  border-bottom-color: #D3D3D3;
  vertical-align: bottom;
  padding-top: 5px;
  padding-bottom: 5px;
  overflow-x: hidden;
  display: inline-block;
  width: 100%;
}
&#10;#kpshklwisp .gt_spanner_row {
  border-bottom-style: hidden;
}
&#10;#kpshklwisp .gt_group_heading {
  padding-top: 8px;
  padding-bottom: 8px;
  padding-left: 5px;
  padding-right: 5px;
  color: #333333;
  background-color: #FFFFFF;
  font-size: 100%;
  font-weight: initial;
  text-transform: inherit;
  border-top-style: solid;
  border-top-width: 2px;
  border-top-color: #D3D3D3;
  border-bottom-style: solid;
  border-bottom-width: 2px;
  border-bottom-color: #D3D3D3;
  border-left-style: none;
  border-left-width: 1px;
  border-left-color: #D3D3D3;
  border-right-style: none;
  border-right-width: 1px;
  border-right-color: #D3D3D3;
  vertical-align: middle;
  text-align: left;
}
&#10;#kpshklwisp .gt_empty_group_heading {
  padding: 0.5px;
  color: #333333;
  background-color: #FFFFFF;
  font-size: 100%;
  font-weight: initial;
  border-top-style: solid;
  border-top-width: 2px;
  border-top-color: #D3D3D3;
  border-bottom-style: solid;
  border-bottom-width: 2px;
  border-bottom-color: #D3D3D3;
  vertical-align: middle;
}
&#10;#kpshklwisp .gt_from_md > :first-child {
  margin-top: 0;
}
&#10;#kpshklwisp .gt_from_md > :last-child {
  margin-bottom: 0;
}
&#10;#kpshklwisp .gt_row {
  padding-top: 8px;
  padding-bottom: 8px;
  padding-left: 5px;
  padding-right: 5px;
  margin: 10px;
  border-top-style: solid;
  border-top-width: 1px;
  border-top-color: #D3D3D3;
  border-left-style: none;
  border-left-width: 1px;
  border-left-color: #D3D3D3;
  border-right-style: none;
  border-right-width: 1px;
  border-right-color: #D3D3D3;
  vertical-align: middle;
  overflow-x: hidden;
}
&#10;#kpshklwisp .gt_stub {
  color: #333333;
  background-color: #FFFFFF;
  font-size: 100%;
  font-weight: initial;
  text-transform: inherit;
  border-right-style: solid;
  border-right-width: 2px;
  border-right-color: #D3D3D3;
  padding-left: 5px;
  padding-right: 5px;
}
&#10;#kpshklwisp .gt_stub_row_group {
  color: #333333;
  background-color: #FFFFFF;
  font-size: 100%;
  font-weight: initial;
  text-transform: inherit;
  border-right-style: solid;
  border-right-width: 2px;
  border-right-color: #D3D3D3;
  padding-left: 5px;
  padding-right: 5px;
  vertical-align: top;
}
&#10;#kpshklwisp .gt_row_group_first td {
  border-top-width: 2px;
}
&#10;#kpshklwisp .gt_row_group_first th {
  border-top-width: 2px;
}
&#10;#kpshklwisp .gt_summary_row {
  color: #333333;
  background-color: #FFFFFF;
  text-transform: inherit;
  padding-top: 8px;
  padding-bottom: 8px;
  padding-left: 5px;
  padding-right: 5px;
}
&#10;#kpshklwisp .gt_first_summary_row {
  border-top-style: solid;
  border-top-color: #D3D3D3;
}
&#10;#kpshklwisp .gt_first_summary_row.thick {
  border-top-width: 2px;
}
&#10;#kpshklwisp .gt_last_summary_row {
  padding-top: 8px;
  padding-bottom: 8px;
  padding-left: 5px;
  padding-right: 5px;
  border-bottom-style: solid;
  border-bottom-width: 2px;
  border-bottom-color: #D3D3D3;
}
&#10;#kpshklwisp .gt_grand_summary_row {
  color: #333333;
  background-color: #FFFFFF;
  text-transform: inherit;
  padding-top: 8px;
  padding-bottom: 8px;
  padding-left: 5px;
  padding-right: 5px;
}
&#10;#kpshklwisp .gt_first_grand_summary_row {
  padding-top: 8px;
  padding-bottom: 8px;
  padding-left: 5px;
  padding-right: 5px;
  border-top-style: double;
  border-top-width: 6px;
  border-top-color: #D3D3D3;
}
&#10;#kpshklwisp .gt_last_grand_summary_row_top {
  padding-top: 8px;
  padding-bottom: 8px;
  padding-left: 5px;
  padding-right: 5px;
  border-bottom-style: double;
  border-bottom-width: 6px;
  border-bottom-color: #D3D3D3;
}
&#10;#kpshklwisp .gt_striped {
  background-color: rgba(128, 128, 128, 0.05);
}
&#10;#kpshklwisp .gt_table_body {
  border-top-style: solid;
  border-top-width: 2px;
  border-top-color: #D3D3D3;
  border-bottom-style: solid;
  border-bottom-width: 2px;
  border-bottom-color: #D3D3D3;
}
&#10;#kpshklwisp .gt_footnotes {
  color: #333333;
  background-color: #FFFFFF;
  border-bottom-style: none;
  border-bottom-width: 2px;
  border-bottom-color: #D3D3D3;
  border-left-style: none;
  border-left-width: 2px;
  border-left-color: #D3D3D3;
  border-right-style: none;
  border-right-width: 2px;
  border-right-color: #D3D3D3;
}
&#10;#kpshklwisp .gt_footnote {
  margin: 0px;
  font-size: 90%;
  padding-top: 4px;
  padding-bottom: 4px;
  padding-left: 5px;
  padding-right: 5px;
}
&#10;#kpshklwisp .gt_sourcenotes {
  color: #333333;
  background-color: #FFFFFF;
  border-bottom-style: none;
  border-bottom-width: 2px;
  border-bottom-color: #D3D3D3;
  border-left-style: none;
  border-left-width: 2px;
  border-left-color: #D3D3D3;
  border-right-style: none;
  border-right-width: 2px;
  border-right-color: #D3D3D3;
}
&#10;#kpshklwisp .gt_sourcenote {
  font-size: 90%;
  padding-top: 4px;
  padding-bottom: 4px;
  padding-left: 5px;
  padding-right: 5px;
}
&#10;#kpshklwisp .gt_left {
  text-align: left;
}
&#10;#kpshklwisp .gt_center {
  text-align: center;
}
&#10;#kpshklwisp .gt_right {
  text-align: right;
  font-variant-numeric: tabular-nums;
}
&#10;#kpshklwisp .gt_font_normal {
  font-weight: normal;
}
&#10;#kpshklwisp .gt_font_bold {
  font-weight: bold;
}
&#10;#kpshklwisp .gt_font_italic {
  font-style: italic;
}
&#10;#kpshklwisp .gt_super {
  font-size: 65%;
}
&#10;#kpshklwisp .gt_footnote_marks {
  font-size: 75%;
  vertical-align: 0.4em;
  position: initial;
}
&#10;#kpshklwisp .gt_asterisk {
  font-size: 100%;
  vertical-align: 0;
}
&#10;#kpshklwisp .gt_indent_1 {
  text-indent: 5px;
}
&#10;#kpshklwisp .gt_indent_2 {
  text-indent: 10px;
}
&#10;#kpshklwisp .gt_indent_3 {
  text-indent: 15px;
}
&#10;#kpshklwisp .gt_indent_4 {
  text-indent: 20px;
}
&#10;#kpshklwisp .gt_indent_5 {
  text-indent: 25px;
}
&#10;#kpshklwisp .katex-display {
  display: inline-flex !important;
  margin-bottom: 0.75em !important;
}
&#10;#kpshklwisp div.Reactable > div.rt-table > div.rt-thead > div.rt-tr.rt-tr-group-header > div.rt-th-group:after {
  height: 0px !important;
}
</style>

<table class="gt_table do-not-create-environment"
data-quarto-postprocess="true" data-quarto-disable-processing="false"
data-quarto-bootstrap="false">
<thead>
<tr class="gt_heading">
<th colspan="5"
class="gt_heading gt_title gt_font_normal gt_bottom_border"><strong>Classification
Functions</strong></th>
</tr>
<tr class="gt_col_headings">
<th id="Function"
class="gt_col_heading gt_columns_bottom_border gt_left"
data-quarto-table-cell-role="th"
style="background-color: #F0F0F0; font-weight: bold"
scope="col">Function</th>
<th id="Description"
class="gt_col_heading gt_columns_bottom_border gt_left"
data-quarto-table-cell-role="th"
style="background-color: #F0F0F0; font-weight: bold"
scope="col">Description</th>
<th id="Categorizes"
class="gt_col_heading gt_columns_bottom_border gt_center"
data-quarto-table-cell-role="th"
style="background-color: #F0F0F0; font-weight: bold"
scope="col">Categorizes</th>
<th id="Time-Based"
class="gt_col_heading gt_columns_bottom_border gt_center"
data-quarto-table-cell-role="th"
style="background-color: #F0F0F0; font-weight: bold"
scope="col">Time-Based</th>
<th id="Tracks-Over-Time"
class="gt_col_heading gt_columns_bottom_border gt_center"
data-quarto-table-cell-role="th"
style="background-color: #F0F0F0; font-weight: bold" scope="col">Tracks
Over Time</th>
</tr>
</thead>
<tbody class="gt_table_body">
<tr>
<td class="gt_row gt_left" headers="Function"
style="font-family: &#39;Fira Code&#39;; font-weight: bold">abc()</td>
<td class="gt_row gt_left" headers="Description">ABC Classification
groups items by relative contribution (Pareto analysis).</td>
<td class="gt_row gt_center" headers="Categorizes">X</td>
<td class="gt_row gt_center" headers="Time-Based"></td>
<td class="gt_row gt_center" headers="Tracks Over Time"></td>
</tr>
<tr>
<td class="gt_row gt_left gt_striped" headers="Function"
style="font-family: &#39;Fira Code&#39;; font-weight: bold">cohort()</td>
<td class="gt_row gt_left gt_striped" headers="Description">Cohort
analysis groups entities by a shared start point and analyzes behavior
over time.</td>
<td class="gt_row gt_center gt_striped" headers="Categorizes"></td>
<td class="gt_row gt_center gt_striped" headers="Time-Based">X</td>
<td class="gt_row gt_center gt_striped"
headers="Tracks Over Time">X</td>
</tr>
</tbody>
</table>

</div>

</div>

</div>

## Additional references and inspirations

- [PeerChristensen’s Cohort
  Package](https://github.com/PeerChristensen/cohorts)

[^1]: I plan to use
    [duckplyr](https://duckplyr.tidyverse.org/index.html) once it
    expands support for lubridate functions
