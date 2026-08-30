# Simulate proportional-hazards survival data with calibrated censoring

Simulate proportional-hazards survival data with calibrated censoring

## Usage

``` r
simulate_proportional_survival(
  n,
  coefficients,
  baseline = c("weibull", "exponential", "gompertz"),
  rate = 0.1,
  shape = 1,
  censoring = 0.3,
  covariate_distribution = c("normal", "binary"),
  seed = NULL
)
```

## Arguments

- n:

  Sample size.

- coefficients:

  Covariate log-hazard coefficients.

- baseline:

  Weibull, exponential, or Gompertz baseline.

- rate:

  Positive baseline rate.

- shape:

  Positive Weibull/Gompertz shape.

- censoring:

  Target censoring fraction.

- covariate_distribution:

  Normal or binary covariates.

- seed:

  Optional random seed.

## Value

A `simulab_sim` base `data.frame` with observed time, status,
covariates, and tidy parameters.

## Examples

``` r
result <- simulate_proportional_survival(
  n = 200,
  coefficients = c(x1 = 0.7),
  shape = 1.5,
  censoring = 0.2,
  seed = 1
)
head(result)
#> <simulab_sim:proportional_survival> 6 rows x 4 columns
#>   id      time status         x1
#> 1  1 3.4716735      1 -0.6264538
#> 2  2 1.8516781      0  0.1836433
#> 3  3 0.8889412      1 -0.8356286
#> 4  4 0.4992354      1  1.5952808
#> 5  5 0.5960112      1  0.3295078
#> 6  6 1.1976905      0 -0.8204684
as.data.frame(result, what = "parameters")
#>             term      value
#> 1             x1 0.70000000
#> 2  baseline_rate 0.10000000
#> 3          shape 1.50000000
#> 4 censoring_rate 0.05520726
```
