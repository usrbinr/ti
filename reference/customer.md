# Customer dataset

A comprehensive dataset containing customer information including
personal details, geographic information, demographics, and other
relevant customer attributes.

## Usage

``` r
customer
```

## Format

A data frame with rows of customer data and 24 columns:

- customer_key:

  Unique identifier for each customer

- geo_area_key:

  Geographic area identifier

- start_dt:

  Start date of customer relationship

- end_dt:

  End date of customer relationship (if applicable)

- continent:

  Continent where the customer is located

- gender:

  Customer's gender

- title:

  Customer's title (Mr., Mrs., Ms., etc.)

- given_name:

  Customer's first name

- middle_initial:

  Customer's middle initial

- surname:

  Customer's last name

- street_address:

  Customer's street address

- city:

  City where the customer resides

- state:

  State abbreviation

- state_full:

  Full state name

- zip_code:

  Postal/ZIP code

- country:

  Country code

- country_full:

  Full country name

- birthday:

  Customer's date of birth

- age:

  Customer's age in years

- occupation:

  Customer's occupation or profession

- company:

  Company where the customer is employed

- vehicle:

  Customer's vehicle information

- latitude:

  Geographic latitude of customer's location

- longitude:

  Geographic longitude of customer's location

## Source

Internal customer database Generated from
[`fpaR::sales`](https://codeberg.org/usrbinr/ti/reference/sales.md)
