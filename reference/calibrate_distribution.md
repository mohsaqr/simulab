# Convert mean/dispersion parameterizations

`calibrate_distribution()` inverts the mean and dispersion
parameterization used by the `formula`/`variance` specification columns
into the shape parameters base R's samplers take. For a mean and a
*variance*, and for the wider catalogue, use
[`calibrate_moments()`](https://mohsaqr.github.io/simulab/reference/calibrate_moments.md).

## Usage

``` r
calibrate_distribution(
  distribution = c("beta", "gamma", "negative_binomial"),
  mean,
  dispersion
)
```

## Arguments

- distribution:

  Beta, gamma, or negative-binomial distribution.

- mean:

  Distribution mean.

- dispersion:

  Beta precision or gamma/negative-binomial dispersion.

## Value

A base `data.frame` with one row per input value and parameter, and
columns `distribution`, `mean`, `dispersion`, `parameter` and `value`.

## Examples

``` r
calibrate_distribution("beta", mean = 0.4, dispersion = 8)
#>   distribution mean dispersion parameter value
#> 1         beta  0.4          8    shape1   3.2
#> 2         beta  0.4          8    shape2   4.8
calibrate_distribution("gamma", mean = 10, dispersion = 0.5)
#>   distribution mean dispersion parameter value
#> 1        gamma   10        0.5     shape   2.0
#> 2        gamma   10        0.5      rate   0.2
calibrate_distribution("negative_binomial", mean = 5, dispersion = 0.4)
#>        distribution mean dispersion parameter     value
#> 1 negative_binomial    5        0.4      size 2.5000000
#> 2 negative_binomial    5        0.4      prob 0.3333333
```
