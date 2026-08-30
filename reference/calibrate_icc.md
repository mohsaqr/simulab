# Calibrate random-effect variance for a target ICC

Calibrate random-effect variance for a target ICC

## Usage

``` r
calibrate_icc(
  icc,
  distribution = c("normal", "binary", "poisson", "gamma", "negative_binomial"),
  total_variance = NULL,
  within_variance = NULL,
  mean = NULL,
  dispersion = NULL
)
```

## Arguments

- icc:

  Target intraclass correlations.

- distribution:

  Outcome distribution.

- total_variance:

  Total normal-outcome variance.

- within_variance:

  Within-cluster normal-outcome variance.

- mean:

  Poisson or negative-binomial mean.

- dispersion:

  Gamma or negative-binomial dispersion.

## Value

A base `data.frame` with one row per target ICC and the required
random-effect variance.

## Examples

``` r
calibrate_icc(icc = 0.1, distribution = "normal", total_variance = 1)
#>   icc distribution random_effect_variance
#> 1 0.1       normal                    0.1
calibrate_icc(icc = c(0.05, 0.1), distribution = "binary")
#>    icc distribution random_effect_variance
#> 1 0.05       binary              0.1731510
#> 2 0.10       binary              0.3655409
```
