# Simulate a multivariate longitudinal VAR process

Draws a person mean for each unit from `between_covariance` around
`grand_means`, then runs a first-order vector autoregression on the
deviations from that person mean:
`y_t = mu + intercept + transition %*% (y_{t-1} - mu) + e_t`, with `e_t`
drawn from `innovation_covariance`. The first `burn_in` occasions are
discarded so the retained occasions are near stationarity.

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

  Number of units. A single positive whole number.

- occasions:

  Number of occasions retained per unit. A single whole number of at
  least 2.

- transition:

  Lag-one coefficients as a square matrix, or as a tidy data frame with
  columns `from`, `to` and `coefficient` (`from` supplies the matrix row
  and `to` the column). Entry `[i, j]` multiplies variable `j` at the
  previous occasion when forming variable `i` at the current occasion,
  so rows index the *receiving* variable and columns the *predicting*
  variable. The spectral radius must be below one.

- intercept:

  Variable intercepts, a scalar recycled across variables (the default,
  `0`) or one value per variable. The intercept is added to the
  deviation from the person mean at every occasion, so a non-zero
  intercept shifts the stationary mean to
  `person_mean + solve(diag(p) - transition) %*% intercept` and the
  `person_means` component is then no longer the realized process mean.

- innovation_covariance:

  Innovation covariance matrix, or a tidy data frame with columns `row`,
  `column` and `covariance`. Must be symmetric and positive
  semidefinite. `NULL` (the default) uses the identity.

- initial_covariance:

  Initial-state covariance matrix, or a tidy data frame with columns
  `row`, `column` and `covariance`. `NULL` (the default) reuses
  `innovation_covariance`.

- between_covariance:

  Between-unit covariance of person means, or a tidy data frame with
  columns `row`, `column` and `covariance`. `NULL` (the default) is a
  zero matrix, giving every unit the same person mean, `grand_means`.

- grand_means:

  Population means, a scalar recycled across variables (the default,
  `0`) or one value per variable.

- beeps_per_day:

  Optional number of occasions per day; `occasions` must be divisible by
  it. Adds `day` and `beep` columns to the returned data. Temporal
  carryover resets at each day boundary.

- burn_in:

  Warm-up occasions generated and then discarded before output. A single
  non-negative whole number, defaulting to `50`.

- seed:

  Optional random seed.

## Value

A long-form `simulab_sim` base `data.frame` with one row per
unit-occasion (`n * occasions` rows) and columns `id`, `occasion` and
one per variable, plus `day` and `beep` when `beeps_per_day` is
supplied. Components: `wide` (one row per unit, one
`<variable>.<occasion>` column per measurement), `transition`,
`innovation_covariance` and `between_covariance` (tidy matrix tables
with columns `row`, `column` and `coefficient` or `covariance`), and
`person_means` (one row per unit with columns `id` and one per
variable).

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
