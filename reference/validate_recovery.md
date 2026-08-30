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

  Tidy estimates with term and estimate columns.

- truth:

  Tidy truth with term and truth columns.

- term, estimate, true_value:

  Column names.

- tolerance:

  Absolute error tolerance for successful recovery.

## Value

A base `data.frame` with bias, absolute/relative error, and recovery.

## Examples

``` r
estimates <- data.frame(term = c("x1", "x2"), estimate = c(0.52, -0.28))
truth <- data.frame(term = c("x1", "x2"), truth = c(0.5, -0.3))
validate_recovery(estimates, truth, tolerance = 0.1)
#>   term estimate truth bias absolute_error relative_error recovered
#> 1   x1     0.52   0.5 0.02           0.02     0.04000000      TRUE
#> 2   x2    -0.28  -0.3 0.02           0.02    -0.06666667      TRUE
```
