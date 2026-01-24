# Foreign Exchange Rates Dataset

This dataset contains foreign exchange rates between different
currencies for specific dates.

## Usage

``` r
fx
```

## Format

A data frame with multiple rows and 4 columns:

- date:

  `Date`. The date for which the exchange rate is recorded.

- from_currency:

  `character`. The source currency code (e.g., "USD").

- to_currency:

  `character`. The target currency code (e.g., "EUR").

- exchange:

  `numeric`. The exchange rate from `from_currency` to `to_currency`.

## Source

Generated from `fpaR::fx`

## Examples

``` r
if (FALSE) { # \dontrun{
data(fx)
head(fx)
summary(fx)
} # }
```
