# ABC classification function

- For your group variable, `abc()` will categorize which groups make up
  what proportion of the totals according to the category_values that
  you have entered

- The function returns a segment object which prints out the execution
  steps and actions that it will take to categorize your data

- Use
  [calculate](https://codeberg.org/usrbinr/ti/reference/calculate.md) to
  return the results

## Usage

``` r
abc(.data, category_values, .value)
```

## Arguments

- .data:

  tibble or dbi object (either grouped or ungrouped)

- category_values:

  vector of break points between 0 and 1

- .value:

  optional: if left blank,`abc()` will use the number of rows per group
  to categorize, alternatively you can pass a column name to categorize

## Value

abc object

## Details

- This function is helpful to understand which groups of make up what
  proportion of the cumulative contribution

- If you do not provide a `.value` then it will count the transactions
  per group, if you provide `.value` then it will
  [`sum()`](https://rdrr.io/r/base/sum.html) the `.value` per group

- The function creates a `segment` object, which pre-processes the data
  into its components

## Examples

``` r
if (FALSE) { # \dontrun{
abc(contoso::sales,c(.1,.5,.7,.96,1),.value=margin)
} # }
```
