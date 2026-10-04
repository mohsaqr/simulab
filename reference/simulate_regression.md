# Simulate a linear regression design

Simulate a linear regression design

## Usage

``` r
simulate_regression(
  n = 100L,
  coefficients = NULL,
  predictor_means = 0,
  predictor_sds = 1,
  correlation = NULL,
  error_sd = 1,
  outcome = "outcome",
  seed = NULL,
  batch = NULL,
  n_predictors = 2L
)
```

## Arguments

- n:

  Sample size, defaulting to `100`.

- coefficients:

  Named coefficients including optional `(Intercept)`. `NULL` (the
  default) draws an intercept from the standard normal distribution and
  `n_predictors` slopes, named `x1`, `x2`, ..., from the uniform
  distribution on \\\[-1, 1\]\\, each rounded to two decimals, inside
  the same seeded draw as the data. The drawn values are reported in the
  `coefficients` table.

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

- batch:

  Optional single positive whole number. When given, the simulator runs
  `batch` times and returns a plain `list` of `batch` results, each
  exactly what the same call without `batch` returns. With a `seed`,
  every dataset gets its own seed drawn from `seed`, so the whole batch
  is reproducible; without one the datasets are consecutive draws from
  the session's random-number stream. The default `NULL` returns a
  single result.

- n_predictors:

  Number of predictors when `coefficients` is `NULL`, a single positive
  whole number defaulting to `2`. Ignored otherwise.

## Value

A `simulab_sim` base `data.frame` with one row per observation and
columns `id`, one column per predictor, and `outcome` (renamed by
`outcome`). Three tidy tables come from
[`as.data.frame()`](https://rdrr.io/r/base/as.data.frame.html):
`what = "coefficients"` has one row per term with columns `term` and
`coefficient`, the intercept first; `what = "effects"` has a single row
with columns `signal_variance` (the quadratic form of the slopes in the
predictor covariance matrix), `residual_variance` (`error_sd^2`) and the
population `r_squared`
`signal_variance / (signal_variance + residual_variance)`;
`what = "predictor_correlation"` has one row per correlation-matrix cell
with columns `row`, `column` and `correlation`.

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
#> 
#> Truth (coefficients):
#>          term coefficient
#> 1 (Intercept)         1.0
#> 2          x1         0.5
#> 3          x2        -0.3
#> 
#> Other tables: effects, predictor_correlation. Read one with as.data.frame(x, what = "effects").
as.data.frame(result, what = "coefficients")
#>          term coefficient
#> 1 (Intercept)         1.0
#> 2          x1         0.5
#> 3          x2        -0.3
as.data.frame(result, what = "effects")
#>   signal_variance residual_variance r_squared
#> 1            0.34                 1 0.2537313

# With no coefficients, they are drawn and reported as the truth.
drawn <- simulate_regression(seed = 1)
as.data.frame(drawn, what = "coefficients")
#>          term coefficient
#> 1 (Intercept)       -0.63
#> 2          x1        0.15
#> 3          x2        0.82
```
