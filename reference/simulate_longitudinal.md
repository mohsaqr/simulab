# Simulate a multivariate longitudinal VAR process

Simulate a multivariate longitudinal VAR process

## Usage

``` r
simulate_longitudinal(
  n,
  occasions,
  transition,
  intercept = 0,
  innovation_covariance = NULL,
  initial_covariance = NULL,
  between_covariance = NULL,
  grand_means = 0,
  beeps_per_day = NULL,
  burn_in = 50L,
  seed = NULL
)
```

## Arguments

- n:

  Number of units.

- occasions:

  Number of occasions.

- transition:

  Lag-one coefficients as a square matrix, or as a tidy data frame with
  columns `from`, `to` and `coefficient`.

- intercept:

  Variable intercepts.

- innovation_covariance:

  Innovation covariance matrix, or a tidy data frame with columns `row`,
  `column` and `covariance`.

- initial_covariance:

  Initial-state covariance matrix, or a tidy data frame with columns
  `row`, `column` and `covariance`.

- between_covariance:

  Between-unit covariance of person means, or a tidy data frame with
  columns `row`, `column` and `covariance`.

- grand_means:

  Population means.

- beeps_per_day:

  Optional number of occasions per day. Temporal carryover resets at
  each day boundary.

- burn_in:

  Warm-up occasions discarded before output.

- seed:

  Optional random seed.

## Value

A long-form `simulab_sim` base `data.frame`; wide observations and
transition/covariance tables are available as components.

## Examples

``` r
# `transition` is the lag-one coefficient matrix of the VAR process.
result <- simulate_longitudinal(
  n = 20,
  occasions = 30,
  transition = matrix(c(0.5, 0.1, 0.0, 0.4), nrow = 2, byrow = TRUE),
  seed = 1
)
head(result)
#> <simulab_sim:longitudinal_var> 6 rows x 4 columns
#>   id occasion  variable_1 variable_2
#> 1  1        1 -0.77084247 -2.1925817
#> 2  1        2 -0.14114900 -2.5420051
#> 3  1        3  0.42604399 -2.1327222
#> 4  1        4 -0.01764584  1.2340777
#> 5  1        5  1.75519038 -0.7926695
#> 6  1        6  0.81688808  0.1331193
components(result)
#>                   table rows columns
#> 1                  data  600       4
#> 2                  wide   20      61
#> 3            transition    4       3
#> 4 innovation_covariance    4       3
#> 5    between_covariance    4       3
#> 6          person_means   20       3
```
