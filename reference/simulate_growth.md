# Simulate longitudinal growth trajectories

Simulate longitudinal growth trajectories

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

  Number of units.

- times:

  Measurement occasions.

- intercept, slope, quadratic:

  Fixed growth coefficients.

- random_sd:

  Standard deviations for random intercept, slope, and optional
  quadratic term.

- random_correlation:

  Correlation matrix for random effects, or a tidy data frame with
  columns `row`, `column` and `correlation`.

- residual_sd:

  Residual standard deviation.

- seed:

  Optional random seed.

## Value

A long-form `simulab_sim` base `data.frame`.

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
