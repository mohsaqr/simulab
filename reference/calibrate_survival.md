# Calibrate a Weibull survival curve to target points

Finds the `formula` and `shape` whose simstudy Weibull curve,
`S(t) = exp(-exp(formula) * t^(1 / shape))` with `scale` fixed at 1,
passes as closely as possible through the supplied points. The fit is a
least-squares fit of `log(time)` on `log(-log(survival))`, run with
`L-BFGS-B`, and the returned `formula` and `shape` can be handed
straight to
[`define_survival()`](https://mohsaqr.github.io/simulab/reference/define_survival.md)
or
[`survival_curve()`](https://mohsaqr.github.io/simulab/reference/survival_curve.md).

## Usage

``` r
calibrate_survival(time, survival)
```

## Arguments

- time:

  Increasing positive times. A finite numeric vector of at least two
  strictly increasing values, the same length as `survival`.

- survival:

  Survival probabilities at those times. A finite numeric vector
  strictly inside `(0, 1)` and strictly decreasing.

## Value

A one-row base `data.frame` with the calibrated numeric `formula` and
`shape`, the [`optim()`](https://rdrr.io/r/stats/optim.html)
`convergence` code (always `0`, since a non-converged fit raises an
error), and `rmse`, the root mean squared residual **on the log-time
scale**.

## Examples

``` r
calibrate_survival(time = c(50, 100, 150), survival = c(0.9, 0.7, 0.4))
#>     formula    shape convergence       rmse
#> 1 -9.950622 0.510809           0 0.03467959
```
