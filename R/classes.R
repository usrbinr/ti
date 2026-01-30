
# to register methods upon packag loading--------------
.onLoad <- function(...) {
  S7::methods_register()
}


# time unit class when aggregating a date column-----------

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
          valid_names <- c("standard", NA_character_)
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


category <- S7::new_class(
  name="category"
  ,package = "ti"
  ,properties = list(
    category_values=S7::new_property(
      class=S7::class_numeric
      ,default=c(.7,.96,1)
      ,validator = \(value){
        if(assertthat::assert_that(all(value<=1),msg = cli::format_error("Please ensure the category_values are less than or equal to 1"))){}
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
