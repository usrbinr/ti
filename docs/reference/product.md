# Product Master Dataset

This dataset contains detailed information about products, including
their identifiers, attributes, pricing, and categorization.

## Usage

``` r
product
```

## Format

A data frame with multiple rows and 14 columns:

- product_key:

  `integer`. Unique identifier for the product.

- product_code:

  `character`. Internal or SKU code for the product.

- product_name:

  `character`. Name of the product.

- manufacturer:

  `character`. Name of the product manufacturer.

- brand:

  `character`. Brand associated with the product.

- color:

  `character`. Color of the product.

- weight_unit:

  `character`. Unit of measurement for weight (e.g., "kg", "lb").

- weight:

  `numeric`. Weight of the product in specified units.

- cost:

  `numeric`. Cost price of the product.

- price:

  `numeric`. Selling price of the product.

- category_key:

  `integer`. Unique identifier for the product category.

- category_name:

  `character`. Name of the product category.

- sub_category_key:

  `integer`. Unique identifier for the product sub-category.

- sub_category_name:

  `character`. Name of the product sub-category.

## Source

Generated from `fpaR::product`

## Examples

``` r
if (FALSE) { # \dontrun{
data(product)
head(product)
summary(product)
} # }
```
