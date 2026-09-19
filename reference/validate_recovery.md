# Compare recovered estimates with known simulation truth

Compare recovered estimates with known simulation truth

## Usage

``` r
validate_recovery(
  estimates,
  truth,
  term = "term",
  estimate = "estimate",
  true_value = "truth",
  tolerance = 0.1
)
```

## Arguments

- estimates:

  Tidy base `data.frame` with a term column and an estimate column.

- truth:

  Tidy base `data.frame` with a term column and a true-value column.

- term:

  Name of the term column in both frames, default `"term"`. It is the
  key the two frames are merged on.

- estimate:

  Name of the estimate column in `estimates`, default `"estimate"`.

- true_value:

  Name of the true-value column in `truth`, default `"truth"`.

- tolerance:

  Single non-negative absolute-error tolerance for successful recovery,
  default `0.1`.

## Value

A base `data.frame` with one row per term appearing in either frame (the
merge keeps unmatched terms) and the columns `term`, `estimate`,
`truth`, `bias` (estimate minus truth), `absolute_error`,
`relative_error` (`NA` where truth is zero) and `recovered`, a logical
that is `TRUE` when `absolute_error` is at most `tolerance`.

## Examples

``` r
estimates <- data.frame(term = c("x1", "x2"), estimate = c(0.52, -0.28))
truth <- data.frame(term = c("x1", "x2"), truth = c(0.5, -0.3))
validate_recovery(estimates, truth, tolerance = 0.1)
#>   term estimate truth bias absolute_error relative_error recovered
#> 1   x1     0.52   0.5 0.02           0.02     0.04000000      TRUE
#> 2   x2    -0.28  -0.3 0.02           0.02    -0.06666667      TRUE
```
