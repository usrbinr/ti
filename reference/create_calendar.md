# Create Calendar Table

`create_calendar()` summarizes a tibble to target time unit and
completes the calendar to ensure no missing days, month, quarter or
years. If a grouped tibble is passed through it will complete the
calendar for each combination of the group

## Arguments

- x:

  ti object

## Value

dbi object

## Details

This is in internal function to make it easier to ensure data has no
missing dates to simplify the use of time intelligence functions
downstream of the application. If you want to summarize to a particular
group, simply pass the tibble through to the
[`dplyr::group_by()`](https://dplyr.tidyverse.org/reference/group_by.html)
argument prior to function and the function will make summarize and make
a complete calendar for each group item.
