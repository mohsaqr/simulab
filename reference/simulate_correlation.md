# Simulate a correlation design

A thin wrapper around
[`simulate_correlated()`](https://mohsaqr.github.io/simulab/reference/simulate_correlated.md)
that supplies defaults for `means` and `sds`, so
`simulate_correlation(n)` generates a single standard normal variable.
`structure` is forwarded only when it is supplied, which keeps
[`simulate_correlated()`](https://mohsaqr.github.io/simulab/reference/simulate_correlated.md)'s
own default resolution intact: `"custom"` when `correlation` is given,
`"exchangeable"` when a non-zero `rho` is given, and `"independent"`
otherwise.

## Usage

``` r
simulate_correlation(
  n,
  means = 0,
  sds = 1,
  rho = 0,
  structure = c("independent", "exchangeable", "ar1", "custom"),
  correlation = NULL,
  variable_names = NULL,
  seed = NULL
)
```

## Arguments

- n:

  Number of observations.

- means, sds, rho, structure, correlation, variable_names, seed:

  Arguments passed to
  [`simulate_correlated()`](https://mohsaqr.github.io/simulab/reference/simulate_correlated.md).
  Unlike that function, `means` defaults to `0`. One variable is
  generated per element of `means`; `sds` must be a single value, which
  is recycled, or one value per mean.

## Value

A `simulab_sim` base `data.frame` with one row per observation and an
`id` column followed by one column per variable. The `parameters`,
`correlation` and `covariance` components hold the requested means and
standard deviations and the tidy correlation and covariance matrices;
use
[`components()`](https://mohsaqr.github.io/simulab/reference/components.md)
to list them.

## Examples

``` r
result <- simulate_correlation(n = 200, means = c(0, 0), sds = c(1, 1), rho = 0.6,
                               seed = 1)
head(result)
#> <simulab_sim:correlated> 6 rows x 3 columns
#>   id          V1         V2
#> 1  1 -0.46484204  0.1902906
#> 2  2  0.70828798  1.6602790
#> 3  3 -0.29102359  1.2409210
#> 4  4  1.40877402  0.1905454
#> 5  5 -0.41005641 -2.0637653
#> 6  6  0.01146529  2.1100350
as.data.frame(result, what = "correlation")
#>   row column correlation
#> 1  V1     V1         1.0
#> 2  V2     V1         0.6
#> 3  V1     V2         0.6
#> 4  V2     V2         1.0
```
