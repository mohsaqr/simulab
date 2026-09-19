# Simulate longitudinal growth trajectories

Draws per-unit random growth coefficients, then forms the outcome at
each measurement occasion as
`(intercept + b0) + (slope + b1) * time + (quadratic + b2) * time^2`
plus normal residual noise, where `b2` is present only when `random_sd`
has three elements. Every unit is observed at every occasion (balanced
design).

## Usage

``` r
simulate_growth(
  n,
  times,
  intercept = 0,
  slope = 1,
  quadratic = 0,
  random_sd = c(1, 0.25),
  random_correlation = NULL,
  residual_sd = 1,
  seed = NULL
)
```

## Arguments

- n:

  Number of units. A single whole number of at least 2.

- times:

  Measurement occasions: a finite numeric vector of at least two unique
  values, used verbatim as the `time` predictor (so `0:4` puts the
  intercept at the first occasion).

- intercept, slope, quadratic:

  Fixed growth coefficients, each a single number; they default to `0`,
  `1` and `0`.

- random_sd:

  Standard deviations for the random intercept, slope, and optional
  quadratic term. A non-negative numeric vector of length 2 (the
  default, `c(1, 0.25)`) or 3.

- random_correlation:

  Correlation matrix for the random effects, matching the length of
  `random_sd`, or a tidy data frame with columns `row`, `column` and
  `correlation`. `NULL` (the default) makes the random effects
  uncorrelated.

- residual_sd:

  Residual standard deviation. A single positive number, defaulting to
  `1`.

- seed:

  Optional random seed.

## Value

A long-form `simulab_sim` base `data.frame` with one row per
unit-occasion (`n * length(times)` rows) and columns `id`, `time` and
`outcome`. Rows are ordered by occasion first and unit second. A
`parameters` component holds one row for each of `intercept`, `slope`,
`quadratic` and `residual_sd`, with columns `term` and `value` (note
that `residual_sd` is a standard deviation, and that the random-effect
standard deviations are not repeated there). A `random_effects`
component holds one row per unit with columns `id`, `intercept`, `slope`
and, when `random_sd` has three elements, `quadratic`, giving each
unit's deviation from the fixed coefficients.

## Examples

``` r
result <- simulate_growth(
  n = 100, times = 0:4, intercept = 10, slope = 0.5, seed = 1
)
head(result)
#> <simulab_sim:growth> 6 rows x 3 columns
#>   id time   outcome
#> 1  1    0  9.782948
#> 2  2    0 11.872517
#> 3  3    0 10.750960
#> 4  4    0 11.264373
#> 5  5    0  8.044272
#> 6  6    0 11.677193
as.data.frame(result, what = "parameters")
#>          term value
#> 1   intercept  10.0
#> 2       slope   0.5
#> 3   quadratic   0.0
#> 4 residual_sd   1.0
```
