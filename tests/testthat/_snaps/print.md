# print output / explains ytd

    Code
      print(x)
    Message
      
      -- Year-to-date ----------------------------------------------------------------
      Function: `ytd` (nothing has been calculated yet)
      
      -- Description: --
      
      This creates a daily `cumsum()` of the current year value from the start of the
      standard calendar year to the end of the year
      
      -- Calendar: --
      
    Output
      * The calendar aggregated date to the day time unit
      * A standard calendar is created with 0 groups
      * Calendar ranges from 2024-01-01 to 2024-04-02
      * 81 of 93 days had no data and are filled with 0
      * New date column date, year was created from date
      
    Message
      -- Assumptions: --
      
      * One row per day
      * Running total that restarts at the start of each year
      
      -- Actions: --
      
    Output
      v Aggregate value
      x Shift
      x Compare
      x Proportion of Total
      x Count Distinct
      
    Message
      -- Next Steps: --
      
      * Use `calculate()` to return the results
      --------------------------------------------------------------------------------

# print output / explains atd

    Code
      print(x)
    Message
      
      -- All-to-date -----------------------------------------------------------------
      Function: `atd` (nothing has been calculated yet)
      
      -- Description: --
      
      This creates a daily `cumsum()` value from the earliest date of the standard
      calendar until the last date
      
      -- Calendar: --
      
    Output
      * The calendar aggregated date to the day time unit
      * A standard calendar is created with 0 groups
      * Calendar ranges from 2024-01-01 to 2024-04-02
      * 81 of 93 days had no data and are filled with 0
      * New date column date was created from date
      
    Message
      -- Assumptions: --
      
      * One row per day
      * Running total from the first date, never reset
      
      -- Actions: --
      
    Output
      v Aggregate value
      x Shift
      x Compare
      x Proportion of Total
      x Count Distinct
      
    Message
      -- Next Steps: --
      
      * Use `calculate()` to return the results
      --------------------------------------------------------------------------------

# print output / explains wow_grouped

    Code
      print(x)
    Message
      
      -- week over week --------------------------------------------------------------
      Function: `wow` (nothing has been calculated yet)
      
      -- Description: --
      
      This creates a full week `sum()` of the previous week value and compares it
      with the full week `sum()` current week value from the start of the standard
      calendar week to the end of the week
      
      -- Calendar: --
      
    Output
      * The calendar aggregated date to the week time unit
      * A standard calendar is created with 1 groups
      * Calendar ranges from 2024-01-01 to 2024-04-02
      * 6 of 14 weeks had no data and are filled with 0
      * New date column date, week, year, month was created from date
      
    Message
      -- Assumptions: --
      
      * One row per week per store, dated by the first day of the week
      * Each week's total is shown next to the total 1 week earlier; the first week
        has no earlier week and shows NA
      * Weeks start on Sunday; week 1 contains 1 January, so the weeks either side of
        1 January can be partial
      * Running totals and comparisons stay within each store; each group's calendar
        runs from its first to its last week with data
      
      -- Actions: --
      
    Output
      v Aggregate value
      v Shift 1 week
      v Compare previous week
      x Proportion of Total
      x Count Distinct
      
    Message
      -- Next Steps: --
      
      * Use `calculate()` to return the results
      --------------------------------------------------------------------------------

# print output / explains wow_monday_lag2

    Code
      print(x)
    Message
      
      -- week over week --------------------------------------------------------------
      Function: `wow` (nothing has been calculated yet)
      
      -- Description: --
      
      This creates a full week `sum()` of the previous week value and compares it
      with the full week `sum()` current week value from the start of the standard
      calendar week to the end of the week
      
      -- Calendar: --
      
    Output
      * The calendar aggregated date to the week time unit
      * A standard calendar is created with 0 groups
      * Calendar ranges from 2024-01-01 to 2024-04-02
      * 6 of 14 weeks had no data and are filled with 0
      * New date column date, week, year, month was created from date
      
    Message
      -- Assumptions: --
      
      * One row per week, dated by the first day of the week
      * Each week's total is shown next to the total 2 weeks earlier; the first 2
        weeks have no earlier week and show NA
      * Weeks start on Monday; week 1 contains 1 January, so the weeks either side of
        1 January can be partial
      
      -- Actions: --
      
    Output
      v Aggregate value
      v Shift 2 weeks
      v Compare previous week
      x Proportion of Total
      x Count Distinct
      
    Message
      -- Next Steps: --
      
      * Use `calculate()` to return the results
      --------------------------------------------------------------------------------

# print output / explains pmtd_grouped

    Code
      print(x)
    Message
      
      -- Previous month-to-date ------------------------------------------------------
      Function: `pmtd` (nothing has been calculated yet)
      
      -- Description: --
      
      This creates a daily `cumsum()` of the previous month value from the start of
      the standard calendar month to the end of the month
      
      -- Calendar: --
      
    Output
      * The calendar aggregated date to the day time unit
      * A standard calendar is created with 1 groups
      * Calendar ranges from 2024-01-01 to 2024-04-02
      * 81 of 93 days had no data and are filled with 0
      * New date column date, year, quarter, month was created from date
      
    Message
      -- Assumptions: --
      
      * One row per day per store
      * Each day is compared with the same day 1 month earlier; on the last day of a
        month, with the end of the earlier month
      * Days whose earlier date is before the data starts show NA
      * Running totals and comparisons stay within each store; each group's calendar
        runs from its first to its last day with data
      
      -- Actions: --
      
    Output
      v Aggregate value
      v Shift 1 month
      x Compare
      x Proportion of Total
      x Count Distinct
      
    Message
      -- Next Steps: --
      
      * Use `calculate()` to return the results
      --------------------------------------------------------------------------------

# print output / explains pwtd

    Code
      print(x)
    Message
      
      -- Previous Week-to-date -------------------------------------------------------
      Function: `pwtd` (nothing has been calculated yet)
      
      -- Description: --
      
      This creates a daily `cumsum()` of the previous week value from the start of
      the standard calendar week to the end of the week
      
      -- Calendar: --
      
    Output
      * The calendar aggregated date to the day time unit
      * A standard calendar is created with 0 groups
      * Calendar ranges from 2024-01-01 to 2024-04-02
      * 81 of 93 days had no data and are filled with 0
      * New date column date, year, month, week was created from date
      
    Message
      -- Assumptions: --
      
      * One row per day
      * Each day is compared with the same weekday 1 week earlier
      * Days whose earlier date is before the data starts show NA
      * Weeks start on Sunday; week 1 contains 1 January, so the weeks either side of
        1 January can be partial
      
      -- Actions: --
      
    Output
      v Aggregate value
      v Shift 1 week
      x Compare
      x Proportion of Total
      x Count Distinct
      
    Message
      -- Next Steps: --
      
      * Use `calculate()` to return the results
      --------------------------------------------------------------------------------

# print output / explains yoytd

    Code
      print(x)
    Message
      
      -- Year-to-date over previous year-to-date -------------------------------------
      Function: `yoytd` (nothing has been calculated yet)
      
      -- Description: --
      
      This creates a daily `cumsum()` of the previous year value and compares it with
      the daily `cumsum()` current year value from the start of the standard calendar
      year to the end of the year
      
      -- Calendar: --
      
    Output
      * The calendar aggregated date to the day time unit
      * A standard calendar is created with 0 groups
      * Calendar ranges from 2024-01-01 to 2024-04-02
      * 81 of 93 days had no data and are filled with 0
      * New date column date, year was created from date
      
    Message
      -- Assumptions: --
      
      * One row per day
      * Each day is compared with the same day 1 year earlier; on the last day of a
        month, with the end of the earlier month
      * Days whose earlier date is before the data starts show NA
      
      -- Actions: --
      
    Output
      v Aggregate value
      v Shift 1 year
      v Compare Previous year-to-date
      x Proportion of Total
      x Count Distinct
      
    Message
      -- Next Steps: --
      
      * Use `calculate()` to return the results
      --------------------------------------------------------------------------------

# print output / explains ytdopy

    Code
      print(x)
    Message
      
      -- Year-to-date over full previous year ----------------------------------------
      Function: `ytdopy` (nothing has been calculated yet)
      
      -- Description: --
      
      This creates a daily `cumsum()` of the current year value and compares it with
      the full year `sum()` previous year value from the start of the standard
      calendar year to the end of the year
      
      -- Calendar: --
      
    Output
      * The calendar aggregated date to the day time unit
      * A standard calendar is created with 0 groups
      * Calendar ranges from 2024-01-01 to 2024-04-02
      * 81 of 93 days had no data and are filled with 0
      * New date column date, year was created from date
      
    Message
      -- Assumptions: --
      
      * One row per day
      * Each day's running total is shown next to the previous year's full total; NA
        when there is no earlier year
      
      -- Actions: --
      
    Output
      v Aggregate value
      v Shift 1 year
      v Compare previous year
      x Proportion of Total
      x Count Distinct
      
    Message
      -- Next Steps: --
      
      * Use `calculate()` to return the results
      --------------------------------------------------------------------------------

# print output / explains mom_retail

    Code
      print(x)
    Message
      
      -- Month over month ------------------------------------------------------------
      Function: `mom` (nothing has been calculated yet)
      
      -- Description: --
      
      This creates a full month `sum()` of the previous month value and compares it
      with the full month `sum()` current month value from the start of the 445
      calendar month to the end of the month
      
      -- Calendar: --
      
    Output
      * The calendar aggregated date to the month time unit
      * A 445 calendar is created with 0 groups
      * Calendar ranges from 2024-01-01 to 2024-04-02
      * 0 of 4 months had no data and are filled with 0
      * New date column date, year, quarter, month was created from date
      
    Message
      -- Assumptions: --
      
      * One row per month, dated by the first day of the month
      * Each month's total is shown next to the total 1 month earlier; the first
        month has no earlier month and shows NA
      * 445 fiscal calendar: the fiscal year starts on the Monday nearest to 1 July,
        and fiscal weeks start on Monday
      
      -- Actions: --
      
    Output
      v Aggregate value
      v Shift 1 month
      v Compare previous full month
      x Proportion of Total
      x Count Distinct
      
    Message
      -- Next Steps: --
      
      * Use `calculate()` to return the results
      --------------------------------------------------------------------------------

# print output / explains mom_ignored_settings

    Code
      print(x)
    Message
      
      -- Month over month ------------------------------------------------------------
      Function: `mom` (nothing has been calculated yet)
      
      -- Description: --
      
      This creates a full month `sum()` of the previous month value and compares it
      with the full month `sum()` current month value from the start of the standard
      calendar month to the end of the month
      
      -- Calendar: --
      
    Output
      * The calendar aggregated date to the month time unit
      * A standard calendar is created with 0 groups
      * Calendar ranges from 2024-01-01 to 2024-04-02
      * 0 of 4 months had no data and are filled with 0
      * New date column date, year, quarter, month was created from date
      
    Message
      
      -- Assumptions: --
      
      * One row per month, dated by the first day of the month
      * Each month's total is shown next to the total 1 month earlier; the first
        month has no earlier month and shows NA
      * `week_start = 1` (Monday) has no effect on `mom()` with the standard
        calendar. It changes the week functions and the retail calendars.
      * `fiscal_year_start = 7` (July) has no effect on the standard calendar, which
        uses calendar years. It only applies to the retail calendars ("445", "454",
        "544").
      
      -- Actions: --
      
    Output
      v Aggregate value
      v Shift 1 month
      v Compare previous full month
      x Proportion of Total
      x Count Distinct
      
    Message
      -- Next Steps: --
      
      * Use `calculate()` to return the results
      --------------------------------------------------------------------------------

# print output / explains abc

    Code
      print(x)
    Message
      
      -- ABC Classification ----------------------------------------------------------
      Function: `ABC` (nothing has been calculated yet)
      
      -- Description: --
      
      This calculates a rolling cumulative distribution of variable and segments each
      group member's contribution by the break points provided. Helpful to know which
      group member's proportional contribution to the total.
      
      -- Category Information --
      
    Output
      * The data set is summarized by store and then sums each group member's value contribution of the total value and then finally calculates each groups rolling cumulative proportion of the total
      * Then cumulative distribution was then arranged from lowest to highest and finally classified into 3 break points 50%, 80%, 100%  and labelled into the following categories a, b, c
      
    Message
      -- Actions: --
      
    Output
      v Aggregate value
      x Shift
      x Compare
      v Proportion of Total
      x Count Distinct
    Message
      -- Next Steps: --
      
      * Use `calculate()` to return the results
      --------------------------------------------------------------------------------

# print output / explains cohort

    Code
      print(x)
    Message
      
      -- Time Based Cohort -----------------------------------------------------------
      Function: `cohort` (nothing has been calculated yet)
      
      -- Description: --
      
      This segments groups based on a shared time related dimension so you can track
      a cohort's trend over time
      
      -- Category Information --
      
    Output
      
      * The data set is grouped by the store and segments each group member by their first date entry to define their cohort store
      * This creates cohort ID that each member is assigned to eg; January 2020, February 2020, etc
      * The distinct count of each store member in the cohort is then tracked over time
    Message
      -- Calendar: --
      
    Output
      * The calendar aggregated date to the month time unit
      * A standard calendar is created with 0 groups
      * Calendar ranges from 2024-01-01 to 2024-04-02
      * 0 of 4 months had no data
      * New date column cohort_date was created from date
      
      
    Message
      -- Actions: --
      
    Output
      x Aggregate
      x Shift
      x Compare
      x Proportion of Total
      v Count Distinct store
    Message
      -- Next Steps: --
      
      * Use `calculate()` to return the results
      --------------------------------------------------------------------------------

