# Compute a tidy Weibull survival curve

Evaluates the simstudy Weibull curve of
[`define_survival()`](https://mohsaqr.github.io/simulab/reference/define_survival.md),
`S(t) = exp(-exp(formula) * t^(1 / shape) / scale)`, at `n` survival
probabilities spread evenly from `1 - 1 / n` down to `1 / n`, inverting
it for the matching times. The points are therefore equally spaced in
survival probability, not in time.

## Usage

``` r
survival_curve(formula, shape, scale = 1, n = 100L, time_limits = NULL)
```

## Arguments

- formula:

  Intercept of the linear predictor on the log scale. A single finite
  number. `exp(formula)` multiplies the cumulative hazard, and equals
  the hazard only when `shape` and `scale` are both 1.

- shape:

  Positive Weibull shape in the simstudy parameterization, the exponent
  applied to the transformed time. A single positive number.

- scale:

  Positive Weibull scale, dividing the cumulative hazard. A single
  positive number, defaulting to `1`.

- n:

  Number of curve points. A single whole number of at least 2,
  defaulting to `100`.

- time_limits:

  Optional inclusive time range, as an increasing non-negative numeric
  vector of length 2, that the curve is restricted to. Defaults to
  `NULL`, the whole curve. Points outside the range are dropped, so
  fewer than `n` rows are returned.

## Value

A base `data.frame` with one row per retained curve point, in increasing
time order, and columns `time` and `survival`.

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
