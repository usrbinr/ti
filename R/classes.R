
# to register methods upon packag loading--------------
.onLoad <- function(...) {
  S7::methods_register()
}


# time unit class when aggregating a date column-----------

#' Time unit class
#'
#' @description
#' `time_unit` records the calendar granularity that a date column is floored to
#' before a time-intelligence calculation is run. The value is lower-cased on
#' assignment and must be one of `"day"`, `"week"`, `"month"`, `"quarter"` or
#' `"year"`.
#'
#' @param value A single string giving the time unit.
#' @returns A `time_unit` S7 object.
#' @keywords internal
time_unit <- S7::new_class(

  ,name="time_unit"
  ,package = "ti"
  ,properties = list(
    value=S7::new_property(
      class=S7::class_character
      ,default = "day"
      ,setter=function(self,value){

        value <- tolower(value)
        self@value <- value
        self
      }
      ,validator =function(value){

      if(length(value)!=1) cli::format_error("Please enter only one time unit")

      }
    )
  )
    ,validator =function(self){

    valid_units <- c("day","week","month","quarter","year")
    if(!any(self@value %in% valid_units))  return(cli::format_error("Please only enter {valid_units}"))

    }
)



# action class to help with printing methods--------------

#' Action class
#'
#' @description
#' `action` carries the human-readable narrative shown by the `print()` methods.
#' `value` is lower-cased and passed through `make_action_cli()` on assignment,
#' which stores a named logical vector saying which of the five standard steps
#' (aggregate, shift, compare, proportion of total, count distinct) the
#' calculation performs. `print_actions_steps()` draws the checklist from it.
#'
#' @param value The steps the calculation performs, e.g.
#'   `c("aggregate", "shift")`. Stored as a named logical vector.
#' @param method A string describing the method used by the calculation.
#' @returns An `action` S7 object.
#' @keywords internal
action <- S7::new_class(
  name="action"
  ,package = "ti"
  ,properties=list(
    value=S7::new_property(
      class=S7::class_any
      ,setter = function(self,value){

        value <- tolower(value)
        self@value <- make_action_cli(value)
        self
      }
    )
    ,method=S7::new_property(
      class=S7::class_any
      ,default = NA_character_
    )
  )
)


# create data class to capture metadata ---------------

#' Datum class
#'
#' @description
#' `datum` wraps the user's table together with the metadata every
#' time-intelligence function needs: which column holds the date, what calendar
#' the dates should be interpreted against, and how the table is grouped. Most
#' of its properties are read-only and computed on access from `data` and
#' `date_vec`, so they always reflect the current table.
#'
#' @param data A `data.frame` or `tbl_dbi`. Converted to a lazy table with
#'   [make_db_tbl()] on assignment.
#' @param calendar_type One of `"standard"`, `"445"`, `"454"` or `"544"`.
#'   Lower-cased on assignment.
#' @param fiscal_year_start Integer between 1 and 12 giving the month the fiscal
#'   year starts in.
#' @param week_start Integer between 1 (Monday) and 7 (Sunday) giving the day
#'   weeks start on.
#' @param date_vec The name of the date column, as a string.
#'
#' @prop class_name `"dbi"` if `data` is a database table, otherwise `"tbl"`.
#' @prop date_quo `date_vec` parsed to a symbol for tidy evaluation.
#' @prop min_date The earliest value of the date column.
#' @prop max_date The latest value of the date column.
#' @prop date_range Number of days between `min_date` and `max_date`.
#' @prop date_count Number of distinct dates present in the date column.
#' @prop date_missing `date_range` minus `date_count`, i.e. gaps in the calendar.
#' @prop group_indicator `TRUE` if `data` carries grouping variables.
#' @prop group_quo The grouping variables as a list of symbols.
#' @prop group_vec The grouping variables as a character vector.
#' @prop group_count Number of grouping variables.
#'
#' @returns A `datum` S7 object.
#' @keywords internal
datum <- S7::new_class(
  name="datum"
  ,package = "ti"
  ,properties =
    list(
      data=S7::new_property(
        class=S7::class_any
        ,setter = function(self,value){

          self@data <- make_db_tbl(value)
          return(self)
        }
      )
      ,class_name=S7::new_property(
        class=S7::class_any
        ,getter =  function(self){

          class <- class(self@data)

          x <- dplyr::if_else(
  any(grepl("tbl_dbi", class))
  , "dbi"
  , "tbl"
)

          return(x)
        }

        ,validator =  function(value){

          if(!any(class(value) %in% c("tbl_dbi","data.frame"))) return(cli::format_error("Please pass a 'dbi' or 'data.frame' object"))
        }
      )
      ,calendar_type=S7::new_property(
        class=S7::class_character
        ,default = "standard"
        ,validator =function(value){
          valid_names <- c("standard", "445", "454", "544", NA_character_)
          if (!all(value %in% valid_names)) {
            return(paste0("Must be one of: ", paste(valid_names, collapse = ", ")))
          }
          NULL

        }
        ,setter=function(self,value){

          value <- tolower(value)
          self@calendar_type <- value
          return(self)
        }
      )
      ,fiscal_year_start=S7::new_property(
        class=S7::class_numeric
        ,default = 1
        ,validator = function(value){
          if(length(value) != 1 || !value %in% 1:12){
            return("fiscal_year_start must be an integer between 1 and 12")
          }
          NULL
        }
      )
      ,week_start=S7::new_property(
        class=S7::class_numeric
        ,default = 7
        ,validator = function(value){
          if(length(value) != 1 || !value %in% 1:7){
            return("week_start must be an integer between 1 (Monday) and 7 (Sunday)")
          }
          NULL
        }
      )
      ,date_vec=S7::new_property(
        class=S7::class_any
      )
      ,date_quo=S7::new_property(
        class=S7::class_any
        ,getter=\(self){

        if(!is.na(self@date_vec)){

           x <- rlang::parse_expr(self@date_vec)

         }else{

         x  <-  NA_character_

         }

          x
        }
      )
      ,min_date=S7::new_property(
        class=S7::class_numeric
        ,getter=\(self){

          if(!is.na(self@date_vec)){

          x <-  self@data |>
            dplyr::pull(dplyr::any_of(self@date_vec)) |>
            min(na.rm=TRUE)

          }else{

            x <- 0

          }

          x
        }
      )
      ,max_date=S7::new_property(
        class=S7::class_numeric
        ,getter=\(self){

          if(!is.na(self@date_vec)){

          x <-  self@data |>
            dplyr::pull(dplyr::any_of(self@date_vec)) |>
            max(na.rm=TRUE)

          }else{
            x <- 0
          }
          x
        }
      )
      ,date_range=S7::new_property(
        class=S7::class_numeric
        ,getter =\(self){

          x <- as.numeric(self@max_date-self@min_date)
          x
        }
      )
      ,date_count=S7::new_property(
        class=S7::class_numeric
        ,getter=\(self){

          if(!is.na(self@date_vec)){

          x <- self@data |>
            dplyr::pull(self@date_quo) |>
            unique() |>
            length()

          }else{

            x <- 0

          }
          x
        }
      )
      ,date_missing=S7::new_property(
        class=S7::class_numeric
        ,getter=\(self){
          x <- as.numeric(self@date_range-self@date_count)
          x
        }
      )
      ,group_indicator=S7::new_property(
        class=S7::class_logical
        ,getter=\(self){
          x <- dplyr::if_else(length(dplyr::groups(self@data)) != 0L,TRUE,FALSE)
          x
        }
      )
      ,group_quo=S7::new_property(
        class=S7::class_any
        ,getter = \(self){
          x <- dplyr::groups(self@data)
          x
        }
      )
      ,group_vec=S7::new_property(
        class=S7::class_any
        ,getter = \(self){
          x <-  as.character(unlist(dplyr::groups(self@data)))
          x
        }
      )
      ,group_count=S7::new_property(
        class=S7::class_numeric
        ,getter=\(self){
          if(!self@group_indicator){

            x <- 0
            x

          }else{
            x <-   length(self@group_vec)
            x
          }
        }
      )
    )
)

# value tbl class

#' Value class
#'
#' @description
#' `value` records which column is being measured and what the resulting column
#' should be called. Assigning `new_column_name_vec` prefixes the supplied
#' string onto `value_vec`, so setting it to `"ytd"` for a value column of
#' `sales` gives `ytd_sales`.
#'
#' @param value_vec The name of the value column, as a string.
#' @param new_column_name_vec A prefix for the output column; stored as
#'   `paste0(prefix, "_", value_vec)`.
#'
#' @prop value_quo `value_vec` parsed to a symbol for tidy evaluation.
#' @prop new_column_name_quo `new_column_name_vec` parsed to a symbol.
#'
#' @returns A `value` S7 object.
#' @keywords internal
value <- S7::new_class(
  "value"
  ,properties = list(

    value_vec=S7::new_property(
      class=S7::class_character
      ,default = NA_character_
    )
    ,value_quo=S7::new_property(
      class=S7::class_any
      ,getter=\(self){
        x <- rlang::parse_expr(self@value_vec)
        x
      }
    )
    ,new_column_name_vec=S7::new_property(
      class=S7::class_character
      ,setter = \(self,value){
        self@new_column_name_vec <- paste0(value,"_",self@value_vec)
        self
      }
    )
    ,new_column_name_quo=S7::new_property(
      class=S7::class_any
      ,getter= \(self){
       x <- rlang::parse_expr(self@new_column_name_vec)
       x
      }
    )
  )
)


# function tbl class-----------------------

#' Function class
#'
#' @description
#' `fn` is the blueprint half of a lazy time-intelligence object. It holds the
#' transformation to run ([fn_exec][fn]) plus the metadata that describes it,
#' which is what lets [ytd()] and friends return an object cheaply and defer the
#' real work to [calculate()].
#'
#' @param fn_exec A function taking a `ti` object and returning the transformed
#'   table.
#' @param fn_name Short name of the calculation, e.g. `"ytd"`.
#' @param fn_long_name Human-readable name, e.g. `"year to date"`.
#' @param shift The period the calculation shifts by, e.g. `"year"`.
#' @param compare The period the calculation compares against.
#' @param label Whether the calculation adds a period label column.
#' @param new_date_column_name Name of the date column the calculation creates.
#' @param lag_n Number of periods to lag by.
#'
#' @returns An `fn` S7 object.
#' @keywords internal
fn <- S7::new_class(
  "fn"
  ,package = "ti"
  ,properties = list(
    fn_exec=S7::class_function
    ,fn_name=S7::new_property(
      class=S7::class_character
      ,default=NA_character_
    )
    ,fn_long_name=S7::new_property(
      class=S7::class_character
      ,default = NA_character_
    )
    ,shift=S7::new_property(
      class=S7::class_character
      ,default = NA_character_
    )
    ,compare=S7::new_property(
      class=S7::class_character
      ,default = NA_character_
    )
    ,label=S7::new_property(
      class=S7::class_logical
      ,default = FALSE
    )
    ,new_date_column_name=S7::new_property(
      class=S7::class_any
      ,default = NA_character_
    )
    ,lag_n=S7::new_property(
      class=S7::class_numeric
      ,default = 0
    )
  )
)

# ti class to bring everything together ----------------

#' Time-intelligence class
#'
#' @description
#' `ti` is the object returned by every time-intelligence function ([ytd()],
#' [yoy()], [mtd()] and so on). It composes the data ([datum][datum]), the
#' granularity ([time_unit][time_unit]), the measure ([value][value]), the
#' calculation blueprint ([fn][fn]) and the print narrative ([action][action])
#' into a single lazy object. Nothing is computed until it is passed to
#' [calculate()].
#'
#' @param datum A [datum][datum] object holding the table and its date metadata.
#' @param time_unit A [time_unit][time_unit] object giving the granularity.
#' @param value A [value][value] object naming the measure and output column.
#' @param fn An [fn][fn] object holding the transformation to execute.
#' @param action An [action][action] object describing the calculation for
#'   printing.
#'
#' @returns A `ti` S7 object.
#' @keywords internal
ti <- S7::new_class(

  name="ti"
  ,package = "ti"

  #properties
  ,properties = list(

    #see calendar class
    datum=datum
    # see time unit class
    ,time_unit=time_unit

    # properties on the target variable
    ,value=value

    # properties of function
    ,fn=fn
    # properties to help with printing method
    ,action=action

  )
  # validator to check if date column is in date format
  #   ,validator = \(self){
  #
  #   if(!any(self@data@data |>  dplyr::pull(self@data@date_vec) |> class() %in% c("Date"))){
  #
  #     return(cli::format_error("'{self@data@date_vec}' is not in Date format"))
  #   }
  # }
)



## abc class---------

#' Category class
#'
#' @description
#' `category` holds the cumulative cut-points used by [abc()] to bucket group
#' members. Assigning `category_names` derives one letter per cut-point from
#' `category_values`, so the default three cut-points become `a`, `b` and `c`.
#'
#' @param category_values Numeric cumulative cut-points, all `<= 1`. Defaults to
#'   `c(0.7, 0.96, 1)`.
#' @param category_names Bucket labels; derived from the length of
#'   `category_values` on assignment.
#'
#' @returns A `category` S7 object.
#' @keywords internal
category <- S7::new_class(
  name="category"
  ,package = "ti"
  ,properties = list(
    category_values=S7::new_property(
      class=S7::class_numeric
      ,default=c(.7,.96,1)
      ,validator = \(value){
        if (!all(value <= 1)) {
          return("Please ensure the category_values are less than or equal to 1")
        }
        NULL
      }
    )
    ,category_names=S7::new_property(
      class=S7::class_any
      ,setter = \(self,value){
        self@category_names <- letters[1:length(self@category_values)]
        self
      }
    )
  )
)


#' ABC segmentation class
#'
#' @description
#' `segment_abc` is the lazy object returned by [abc()]. It mirrors [ti][ti] but
#' swaps the time-shift metadata for a [category][category] object holding the
#' bucket cut-points. Pass it to [calculate()] to run the segmentation.
#'
#' @param datum A [datum][datum] object holding the table and its date metadata.
#' @param category A [category][category] object giving the bucket cut-points.
#' @param time_unit A [time_unit][time_unit] object giving the granularity.
#' @param fn An [fn][fn] object holding the transformation to execute.
#' @param action An [action][action] object describing the calculation for
#'   printing.
#' @param value A [value][value] object naming the measure and output column.
#'
#' @returns A `segment_abc` S7 object.
#' @keywords internal
segment_abc <- S7::new_class(

  ,name="segment_abc"
  ,package = "ti"
  ,properties = list(
    datum=datum
    ,category=category
    ,time_unit=time_unit
    ,fn=fn
    ,action=action
    ,value=value
  )
)



#' Cohort segmentation class
#'
#' @description
#' `segment_cohort` is the lazy object returned by [cohort()]. It groups records
#' by the period in which each group member first appears, then measures each
#' cohort forward through time. Pass it to [calculate()] to run the
#' segmentation.
#'
#' @param datum A [datum][datum] object holding the table and its date metadata.
#' @param time_unit A [time_unit][time_unit] object giving the cohort period.
#' @param fn An [fn][fn] object holding the transformation to execute.
#' @param action An [action][action] object describing the calculation for
#'   printing.
#' @param value A [value][value] object naming the measure and output column.
#'
#' @returns A `segment_cohort` S7 object.
#' @keywords internal
segment_cohort <- S7::new_class(

  ,name="segment_cohort"
  ,package = "ti"
  ,properties = list(
    datum=datum
    ,time_unit=time_unit
    ,fn=fn
    ,action=action
    ,value=value
  )
)
