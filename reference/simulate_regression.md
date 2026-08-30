# Simulate a linear regression design

Simulate a linear regression design

## Usage

``` r
simulate_regression(
  n,
  coefficients,
  predictor_means = 0,
  predictor_sds = 1,
  correlation = NULL,
  error_sd = 1,
  outcome = "outcome",
  seed = NULL
)
```

## Arguments

- n:

  Sample size.

- coefficients:

  Named coefficients including optional `(Intercept)`.

- predictor_means, predictor_sds:

  Predictor means and standard deviations.

- correlation:

  Optional predictor correlation matrix or tidy table.

- error_sd:

  Positive residual standard deviation.

- outcome:

  Name of the outcome variable.

- seed:

  Optional random seed.

## Value

A `simulab_sim` base `data.frame` with coefficient, predictor, and
population R-squared tables.

## Examples

``` r
# `coefficients` must be named; "(Intercept)" is optional.
result <- simulate_regression(
  n = 200,
  coefficients = c("(Intercept)" = 1, x1 = 0.5, x2 = -0.3),
  seed = 1
)
head(result)
#> <simulab_sim:regression> 6 rows x 4 columns
#>   id         x1         x2    outcome
#> 1  1 -0.6264538  0.4094018  1.6383935
#> 2  2  0.1836433  1.6888733  2.4808145
#> 3  3 -0.8356286  1.5865884 -0.4967881
#> 4  4  1.5952808 -0.3309078  1.5060449
#> 5  5  0.3295078 -2.2852355  1.4341025
#> 6  6 -0.8204684  2.4976616 -0.5351901
as.data.frame(result, what = "coefficients")
#>          term coefficient
#> 1 (Intercept)         1.0
#> 2          x1         0.5
#> 3          x2        -0.3
as.data.frame(result, what = "effects")
#>   signal_variance residual_variance r_squared
#> 1            0.34                 1 0.2537313
```
