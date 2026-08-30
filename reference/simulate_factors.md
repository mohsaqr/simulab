# Simulate a common-factor model

Simulate a common-factor model

## Usage

``` r
simulate_factors(
  n,
  loadings,
  uniquenesses = NULL,
  factor_correlation = NULL,
  intercepts = 0,
  include_scores = FALSE,
  seed = NULL
)
```

## Arguments

- n:

  Number of observations.

- loadings:

  Variable-by-factor loading matrix, or a tidy data frame with columns
  `item`, `factor` and `loading`.

- uniquenesses:

  Residual variances.

- factor_correlation:

  Optional factor correlation matrix, or a tidy data frame with columns
  `row`, `column` and `correlation`.

- intercepts:

  Variable intercepts.

- include_scores:

  Include true factor scores in primary data.

- seed:

  Optional random seed.

## Value

A `simulab_sim` base `data.frame` with population covariance and
parameter tables.

## Examples

``` r
# `loadings` is one row per item and one column per factor.
loadings <- matrix(
  c(0.8, 0.7, 0.6, 0, 0, 0,
    0, 0, 0, 0.8, 0.7, 0.6),
  ncol = 2
)
result <- simulate_factors(n = 300, loadings = loadings, seed = 1)
head(result)
#> <simulab_sim:factor_model> 6 rows x 7 columns
#>   id     item_1     item_2     item_3     item_4     item_5     item_6
#> 1  1 -0.7058032 -1.5392993 -1.6215009  1.2249650  1.1355307 -0.5366365
#> 2  2  1.0483694  0.2673233  1.6487169 -1.3930263 -0.3179170 -0.6649447
#> 3  3 -0.3515183 -0.3961046 -1.9868409  2.1132186  1.2751543  2.9331953
#> 4  4  1.6015395  0.3177598 -0.7277263 -0.8715115  0.8076578  0.9074974
#> 5  5  0.1816022  0.6955288  0.7558235  1.6466875  0.9582755  1.1390848
#> 6  6 -1.3384150 -1.3119662  0.2336745  1.1005855  2.5066440  0.3849813
as.data.frame(result, what = "parameters")
#>    variable   factor loading uniqueness intercept
#> 1    item_1 factor_1     0.8       0.36         0
#> 2    item_2 factor_1     0.7       0.51         0
#> 3    item_3 factor_1     0.6       0.64         0
#> 4    item_4 factor_1     0.0       0.36         0
#> 5    item_5 factor_1     0.0       0.51         0
#> 6    item_6 factor_1     0.0       0.64         0
#> 7    item_1 factor_2     0.0       0.36         0
#> 8    item_2 factor_2     0.0       0.51         0
#> 9    item_3 factor_2     0.0       0.64         0
#> 10   item_4 factor_2     0.8       0.36         0
#> 11   item_5 factor_2     0.7       0.51         0
#> 12   item_6 factor_2     0.6       0.64         0
```
