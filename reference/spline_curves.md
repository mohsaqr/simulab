# Compute one or more tidy spline curves

Compute one or more tidy spline curves

## Usage

``` r
spline_curves(coefficients, knots = c(0.25, 0.5, 0.75), degree = 3L, n = 1000L)
```

## Arguments

- coefficients:

  Numeric vector or matrix with one coefficient column per curve.

- knots, degree, n:

  Spline-basis arguments.

## Value

A base `data.frame` with one row per x/curve combination and columns
`x`, `curve`, and `value`.

## Examples

``` r
head(spline_curves(coefficients = c(0.1, 0.2, 0.5, 0.4, 0.7, 0.6, 0.9),
                   knots = c(0.25, 0.5, 0.75), degree = 3, n = 20))
#>            x   curve     value
#> 1 0.00000000 curve_1 0.1000000
#> 2 0.05263158 curve_1 0.1684842
#> 3 0.10526316 curve_1 0.2423337
#> 4 0.15789474 curve_1 0.3136171
#> 5 0.21052632 curve_1 0.3744035
#> 6 0.26315789 curve_1 0.4168052
```
