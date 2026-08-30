# Compute a tidy Weibull survival curve

Compute a tidy Weibull survival curve

## Usage

``` r
survival_curve(formula, shape, scale = 1, n = 100L, time_limits = NULL)
```

## Arguments

- formula:

  Log-hazard intercept.

- shape:

  Positive shape parameter.

- scale:

  Positive scale parameter.

- n:

  Number of curve points.

- time_limits:

  Optional time range.

## Value

A base `data.frame` with one row per curve point and columns `time` and
`survival`.

## Examples

``` r
curve <- survival_curve(formula = -8, shape = 0.3, n = 10)
head(curve)
#>        time  survival
#> 1  5.611903 0.9000000
#> 2  6.895548 0.8111111
#> 3  7.871201 0.7222222
#> 4  8.713903 0.6333333
#> 5  9.494576 0.5444444
#> 6 10.255879 0.4555556
```
