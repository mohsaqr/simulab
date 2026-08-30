# Calibrate a Weibull survival curve to target points

Calibrate a Weibull survival curve to target points

## Usage

``` r
calibrate_survival(time, survival)
```

## Arguments

- time:

  Increasing positive times.

- survival:

  Decreasing survival probabilities.

## Value

A one-row base `data.frame` with calibrated `formula`, `shape`,
convergence code, and root mean squared error.

## Examples

``` r
calibrate_survival(time = c(50, 100, 150), survival = c(0.9, 0.7, 0.4))
#>     formula    shape convergence       rmse
#> 1 -9.950622 0.510809           0 0.03467959
```
