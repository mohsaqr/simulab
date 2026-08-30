# Simulate a two-level Gaussian model

Simulate a two-level Gaussian model

## Usage

``` r
simulate_multilevel(
  clusters,
  cluster_size,
  intercept = 0,
  slopes = numeric(0L),
  predictor_means = 0,
  predictor_sds = 1,
  random_intercept_sd = 1,
  random_slope_sd = 0,
  random_effect_correlation = 0,
  residual_sd = 1,
  seed = NULL
)
```

## Arguments

- clusters:

  Number of clusters.

- cluster_size:

  Units per cluster, scalar or vector.

- intercept:

  Fixed intercept.

- slopes:

  Named fixed-effect slopes.

- predictor_means, predictor_sds:

  Predictor parameters.

- random_intercept_sd:

  Random-intercept standard deviation.

- random_slope_sd:

  Random-slope standard deviation for the first predictor.

- random_effect_correlation:

  Correlation between random intercept and slope.

- residual_sd:

  Residual standard deviation.

- seed:

  Optional random seed.

## Value

A `simulab_sim` base `data.frame` with fixed/random parameter tables.

## Examples

``` r
# `slopes` must be named; the names become the predictor columns.
result <- simulate_multilevel(
  clusters = 30,
  cluster_size = 10,
  intercept = 1,
  slopes = c(x1 = 0.5),
  random_intercept_sd = 0.8,
  seed = 1
)
head(result)
#> <simulab_sim:multilevel> 6 rows x 4 columns
#>   id cluster          x1     outcome
#> 1  1       1  2.40161776 -0.89268184
#> 2  2       1 -0.03924000  1.79321912
#> 3  3       1  0.68973936  0.20816363
#> 4  4       1  0.02800216  0.08285919
#> 5  5       1 -0.74327321 -0.04211799
#> 6  6       1  0.18879230  1.20545128
as.data.frame(result, what = "fixed_effects")
#>          term coefficient
#> 1 (Intercept)         1.0
#> 2          x1         0.5
as.data.frame(result, what = "variance_components")
#>          component variance
#> 1 random_intercept     0.64
#> 2     random_slope     0.00
#> 3         residual     1.00
```
