# Sales Transactions Dataset

This dataset contains sales transaction data, including order details,
customer information, pricing, and revenue metrics.

## Usage

``` r
sales
```

## Format

A data frame with multiple rows and 17 columns:

- order_key:

  `integer`. Unique identifier for each order.

- line_number:

  `integer`. Line number within an order, representing individual items.

- order_date:

  `Date`. Date when the order was placed.

- delivery_date:

  `Date`. Date when the order was delivered.

- customer_key:

  `integer`. Unique identifier for the customer.

- store_key:

  `integer`. Unique identifier for the store where the transaction
  occurred.

- product_key:

  `integer`. Unique identifier for the product.

- quantity:

  `numeric`. Number of units sold in the transaction.

- unit_price:

  `numeric`. Price per unit of the product in the original currency.

- net_price:

  `numeric`. Final price per unit after discounts.

- unit_cost:

  `numeric`. Cost per unit of the product.

- currency_code:

  `character`. Currency code (e.g., "USD", "EUR").

- exchange_rate:

  `numeric`. Exchange rate applied to the transaction currency.

- gross_revenue:

  `numeric`. Total revenue before any deductions.

- net_revenue:

  `numeric`. Revenue after deductions such as discounts and taxes.

- cogs:

  `numeric`. Cost of goods sold (COGS).

- margin:

  `numeric`. Profit margin calculated as `net_revenue - cogs`.

## Source

Generated from `fpaR::sales`

## Examples

``` r
data(sales)
head(sales)
#> # A tibble: 6 × 17
#>   order_key line_number order_date delivery_date customer_key store_key
#>       <dbl>       <dbl> <date>     <date>               <dbl>     <dbl>
#> 1    233000           0 2021-05-18 2021-05-18         1855811       585
#> 2    233100           0 2021-05-19 2021-05-19         1345436       550
#> 3    233100           1 2021-05-19 2021-05-19         1345436       550
#> 4    233100           2 2021-05-19 2021-05-19         1345436       550
#> 5    233200           0 2021-05-20 2021-05-20          926315       370
#> 6    233200           1 2021-05-20 2021-05-20          926315       370
#> # ℹ 11 more variables: product_key <dbl>, quantity <dbl>, unit_price <dbl>,
#> #   net_price <dbl>, unit_cost <dbl>, currency_code <chr>, exchange_rate <dbl>,
#> #   gross_revenue <dbl>, net_revenue <dbl>, cogs <dbl>, margin <dbl>
summary(sales)
#>    order_key       line_number      order_date         delivery_date       
#>  Min.   :233000   Min.   :0.000   Min.   :2021-05-18   Min.   :2021-05-18  
#>  1st Qu.:268901   1st Qu.:0.000   1st Qu.:2022-05-12   1st Qu.:2022-05-12  
#>  Median :287603   Median :1.000   Median :2022-11-15   Median :2022-11-17  
#>  Mean   :288707   Mean   :1.173   Mean   :2022-11-26   Mean   :2022-11-27  
#>  3rd Qu.:311000   3rd Qu.:2.000   3rd Qu.:2023-07-07   3rd Qu.:2023-07-08  
#>  Max.   :339801   Max.   :6.000   Max.   :2024-04-20   Max.   :2024-04-23  
#>   customer_key       store_key       product_key      quantity     
#>  Min.   :   1401   Min.   :    10   Min.   :   1   Min.   : 1.000  
#>  1st Qu.: 539021   1st Qu.:   450   1st Qu.: 504   1st Qu.: 1.000  
#>  Median :1224765   Median :999999   Median :1446   Median : 2.000  
#>  Mean   :1122913   Mean   :538154   Mean   :1214   Mean   : 3.147  
#>  3rd Qu.:1669633   3rd Qu.:999999   3rd Qu.:1642   3rd Qu.: 4.000  
#>  Max.   :2099336   Max.   :999999   Max.   :2517   Max.   :10.000  
#>    unit_price        net_price          unit_cost       currency_code     
#>  Min.   :   0.95   Min.   :   0.855   Min.   :   0.48   Length:7794       
#>  1st Qu.:  47.95   1st Qu.:  46.008   1st Qu.:  22.05   Class :character  
#>  Median : 208.50   Median : 197.800   Median :  86.91   Mode  :character  
#>  Mean   : 311.36   Mean   : 292.896   Mean   : 128.42                     
#>  3rd Qu.: 369.00   3rd Qu.: 342.015   3rd Qu.: 164.18                     
#>  Max.   :3748.50   Max.   :3748.500   Max.   :1241.95                     
#>  exchange_rate    gross_revenue      net_revenue            cogs        
#>  Min.   :0.7056   Min.   :    1.9   Min.   :    1.71   Min.   :   0.96  
#>  1st Qu.:0.9461   1st Qu.:  115.8   1st Qu.:  107.74   1st Qu.:  52.00  
#>  Median :1.0000   Median :  409.3   Median :  387.00   Median : 183.88  
#>  Mean   :1.0284   Mean   :  997.1   Mean   :  937.38   Mean   : 411.63  
#>  3rd Qu.:1.0000   3rd Qu.: 1136.2   3rd Qu.: 1064.14   3rd Qu.: 490.76  
#>  Max.   :1.6080   Max.   :29988.0   Max.   :25789.68   Max.   :9935.64  
#>      margin         
#>  Min.   :7.213e-01  
#>  1st Qu.:5.280e+01  
#>  Median :1.990e+02  
#>  Mean   :5.258e+02  
#>  3rd Qu.:5.613e+02  
#>  Max.   :1.622e+04  
```
