# Simulate correlated Gaussian variables

Simulate correlated Gaussian variables

## Usage

``` r
simulate_correlated(
  n,
  means,
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

- means:

  Variable means.

- sds:

  Variable standard deviations.

- rho:

  Correlation used when `correlation` is not supplied.

- structure:

  Correlation structure: one of `"independent"`, `"exchangeable"`,
  `"ar1"`, or `"custom"`. If left unset it is chosen from the other
  arguments: `"custom"` when `correlation` is supplied, `"exchangeable"`
  when a non-zero `rho` (or `tau`) is supplied, and `"independent"`
  otherwise. Passing `"independent"` together with a non-zero `rho` is a
  contradiction and raises an error.

- correlation:

  A custom correlation matrix or tidy table returned by
  [`correlation_structure()`](https://mohsaqr.github.io/simulab/reference/correlation_structure.md).

- variable_names:

  Optional variable names.

- seed:

  Optional random seed.

## Value

A `simulab_sim` base `data.frame`. The requested correlation and
covariance structures are available through
[`as.data.frame()`](https://rdrr.io/r/base/as.data.frame.html) using
`what = "correlation"` or `what = "covariance"`.

## Examples

``` r
simulate_correlated(
  n = 100,
  means = c(0, 1, 2),
  sds = c(1, 2, 1),
  rho = 0.4,
  structure = "exchangeable",
  seed = 1
)
#> <simulab_sim:correlated> 100 rows x 4 columns
#>    id         V1         V2         V3
#> 1   1 -0.6838367 -0.2759531  2.1185336
#> 2   2  0.4813996  1.5673797  3.6473458
#> 3   3 -0.7513606 -0.5967492  3.1248806
#> 4   4  1.4982380  1.6379158  2.0062187
#> 5   5 -0.2569962 -0.7931684 -0.2823676
#> 6   6  0.1158181  4.9089199  4.6860305
#> 7   7  0.7654131  2.7079731  2.9045594
#> 8   8  1.0317614  3.1207616  2.8791678
#> 9   9  0.6440032  1.9009305  2.1876256
#> 10 10  0.2346483  4.3605248  2.8663294
#> ... 90 more rows
```
