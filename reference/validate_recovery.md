# Compare recovered estimates with known simulation truth

Compare recovered estimates with known simulation truth

## Usage

``` r
validate_recovery(
  estimates,
  truth,
  term = "term",
  estimate = "estimate",
  true_value = NULL,
  tolerance = 0.1
)
```

## Arguments

- estimates:

  Tidy base `data.frame` with a term column and an estimate column, or a
  fitted model with named coefficients, such as the result of
  [`lm()`](https://rdrr.io/r/stats/lm.html), whose coefficients become
  the `term` and `estimate` columns.

- truth:

  The generating values. A tidy base `data.frame` with a term column and
  a true-value column; a `simulab_sim` result, whose table of generating
  values (the one its print method shows under `Truth`) is used; or a
  batch of results from `batch = n`, whose tables are stacked with a
  `batch_id` column numbered as
  [`apply_batch()`](https://pak.dynasite.org/simulab/reference/apply_batch.md)
  numbers the data sets, so each estimate is compared with the truth of
  its own data set.

- term:

  Name of the term column in both frames, default `"term"`. The frames
  are merged on it and on every other column the two share, such as
  `batch_id`.

- estimate:

  Name of the estimate column in `estimates`, default `"estimate"`.

- true_value:

  Name of the true-value column in `truth`. `NULL` (the default) uses a
  column named `truth` when there is one, and otherwise the only numeric
  column of `truth` other than the shared identifiers; it is an error
  when there are several.

- tolerance:

  Single non-negative absolute-error tolerance for successful recovery,
  default `0.1`.

## Value

A base `data.frame` with one row per row of `estimates`, in the same
order, plus one row for each term found only in `truth`. Every column of
`estimates` other than `term` and `estimate` (for example the `batch_id`
of
[`apply_batch()`](https://pak.dynasite.org/simulab/reference/apply_batch.md))
comes first, then the columns `term`, `estimate`, `truth`, `bias`
(estimate minus truth), `absolute_error`, `relative_error` (`NA` where
truth is zero) and `recovered`, a logical that is `TRUE` when
`absolute_error` is at most `tolerance`.

## Examples

``` r
estimates <- data.frame(term = c("x1", "x2"), estimate = c(0.52, -0.28))
truth <- data.frame(term = c("x1", "x2"), truth = c(0.5, -0.3))
validate_recovery(estimates, truth, tolerance = 0.1)
#>   term estimate truth bias absolute_error relative_error recovered
#> 1   x1     0.52   0.5 0.02           0.02     0.04000000      TRUE
#> 2   x2    -0.28  -0.3 0.02           0.02    -0.06666667      TRUE

# One data set: the fitted model against the result's own truth.
data_set <- simulate_regression(seed = 1)
validate_recovery(lm(outcome ~ x1 + x2, data = data_set), data_set)
#>          term   estimate truth         bias absolute_error relative_error
#> 1 (Intercept) -0.6252180 -0.63  0.004782022    0.004782022   -0.007590511
#> 2          x1  0.1652958  0.15  0.015295795    0.015295795    0.101971968
#> 3          x2  0.7541006  0.82 -0.065899429    0.065899429   -0.080365157
#>   recovered
#> 1      TRUE
#> 2      TRUE
#> 3      TRUE

# A batch with drawn coefficients: each data set is compared with its own.
datasets <- simulate_regression(seed = 1, batch = 20)
fit_coefficients <- function(data) {
  fit <- lm(outcome ~ x1 + x2, data = data)
  data.frame(term = names(coef(fit)), estimate = unname(coef(fit)))
}
estimates <- apply_batch(datasets, fit_coefficients)
head(validate_recovery(estimates, datasets))
#>   batch_id        term   estimate truth        bias absolute_error
#> 1        1 (Intercept)  0.4871271  0.52 -0.03287288     0.03287288
#> 2        1          x1  0.4291198  0.46 -0.03088022     0.03088022
#> 3        1          x2 -0.4881249 -0.34 -0.14812486     0.14812486
#> 4        2 (Intercept) -0.5419140 -0.53 -0.01191397     0.01191397
#> 5        2          x1  0.4818146  0.45  0.03181463     0.03181463
#> 6        2          x2  0.5997644  0.76 -0.16023560     0.16023560
#>   relative_error recovered
#> 1    -0.06321708      TRUE
#> 2    -0.06713092      TRUE
#> 3     0.43566136     FALSE
#> 4     0.02247919      TRUE
#> 5     0.07069917      TRUE
#> 6    -0.21083632     FALSE
```
