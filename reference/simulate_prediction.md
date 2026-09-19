# Simulate a prediction design with continuous and categorical predictors

Draws the continuous predictors independently from normal distributions
and each categorical predictor by sampling its levels with replacement,
then forms the outcome as the intercept plus the continuous linear
predictor plus the level effects plus normal residual noise. With no
categorical predictor the call is simply
[`simulate_regression()`](https://mohsaqr.github.io/simulab/reference/simulate_regression.md).

## Usage

``` r
simulate_prediction(
  n,
  coefficients,
  categorical_levels = NULL,
  categorical_effects = NULL,
  category_probabilities = NULL,
  predictor_means = 0,
  predictor_sds = 1,
  error_sd = 1,
  outcome = "outcome",
  seed = NULL
)
```

## Arguments

- n:

  Sample size. A single whole number of at least 2.

- coefficients:

  Named numeric vector of continuous-predictor coefficients, with an
  optional `(Intercept)` entry that defaults to `0` when absent. The
  remaining names become the continuous predictor columns.

- categorical_levels:

  Named list of levels for categorical predictors, or a tidy data frame
  with columns `variable` and `level`. Optional `effect` and
  `probability` columns in that table supply `categorical_effects` and
  `category_probabilities`, so one table replaces all three arguments.
  Defaults to `NULL`, no categorical predictor.

- categorical_effects:

  Named list of level effects matching `categorical_levels` by name and
  length, one number per level, added to the outcome for the level a
  unit is assigned. Required whenever `categorical_levels` is given.

- category_probabilities:

  Optional named list of sampling probabilities, one non-negative value
  per level summing to one within each predictor. Defaults to `NULL`,
  equal probabilities across a predictor's levels.

- predictor_means, predictor_sds:

  Mean and standard deviation of each normally distributed continuous
  predictor, a scalar recycled across them (the defaults, `0` and `1`)
  or one value per continuous coefficient.

- error_sd:

  Residual standard deviation. A single positive number, defaulting to
  `1`.

- outcome:

  Outcome-column name. A single non-empty string, defaulting to
  `"outcome"`.

- seed:

  Optional random seed. A single number, or `NULL` (the default).

## Value

When `categorical_levels` is `NULL`, whatever
[`simulate_regression()`](https://mohsaqr.github.io/simulab/reference/simulate_regression.md)
returns. Otherwise a `simulab_sim` base `data.frame` with one row per
unit and columns `id`, one column per continuous coefficient name, one
character column per categorical predictor, and the outcome named by
`outcome`. Components: `coefficients` (one row per fixed term, columns
`term` and `coefficient`, always including `(Intercept)`),
`categorical_effects` (one row per predictor level, columns `variable`,
`level`, `effect` and `probability`), and `effects` (one row, columns
`signal_variance`, `residual_variance` and `r_squared`).
`signal_variance` is the *realized* variance of the simulated linear
predictor, so `r_squared` is the realized proportion of outcome variance
it explains, not a population value.

## Examples

``` r
result <- simulate_prediction(
  n = 200,
  coefficients = c("(Intercept)" = 0.5, x1 = 1, x2 = -1),
  seed = 1
)
head(result)
#> <simulab_sim:regression> 6 rows x 4 columns
#>   id         x1         x2    outcome
#> 1  1 -0.6264538  0.4094018  0.5385853
#> 2  2  0.1836433  1.6888733  0.8904248
#> 3  3 -0.8356286  1.5865884 -2.5252143
#> 4  4  1.5952808 -0.3309078  2.0353208
#> 5  5  0.3295078 -2.2852355  2.6985213
#> 6  6 -0.8204684  2.4976616 -3.1937874
as.data.frame(result, what = "coefficients")
#>          term coefficient
#> 1 (Intercept)         0.5
#> 2          x1         1.0
#> 3          x2        -1.0
```
