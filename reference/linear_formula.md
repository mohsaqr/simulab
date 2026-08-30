# Construct a linear simulation formula

Construct a linear simulation formula

## Usage

``` r
linear_formula(coefficients, variables)
```

## Arguments

- coefficients:

  Coefficients with an optional intercept.

- variables:

  Variable names. When there is one additional coefficient, the first is
  the intercept.

## Value

A one-row `simulab_formula` base `data.frame`.

## Examples

``` r
linear_formula(coefficients = c(1, 0.5, -0.3), variables = c("x1", "x2"))
#>     type                  formula
#> 1 linear 1 + 0.5 * x1 + -0.3 * x2
```
