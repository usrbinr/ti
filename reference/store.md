# Store Master Dataset

This dataset contains information about stores, including their
identifiers, geographic details, operational status, and physical
attributes.

## Usage

``` r
store
```

## Format

A data frame with multiple rows and 11 columns:

- store_key:

  `integer`. Unique identifier for the store.

- store_code:

  `character`. Internal code assigned to the store.

- geo_area_key:

  `integer`. Unique identifier for the geographic area.

- country_code:

  `character`. ISO country code (e.g., "US", "DE").

- country_name:

  `character`. Full name of the country where the store is located.

- state:

  `character`. State or region where the store is located.

- open_date:

  `Date`. Date when the store was opened.

- close_date:

  `Date`. Date when the store was closed (if applicable).

- description:

  `character`. Additional details or notes about the store.

- square_meters:

  `numeric`. Store size in square meters.

- status:

  `character`. Current operational status of the store (e.g., "Open",
  "Closed").

## Source

Generated from `fpaR::store`

## Examples

``` r
if (FALSE) { # \dontrun{
data(store)
head(store)
summary(store)
} # }
```
