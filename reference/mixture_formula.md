# Construct a mixture simulation formula

Construct a mixture simulation formula

## Usage

``` r
mixture_formula(variables, probabilities = NULL)
```

## Arguments

- variables:

  Variable names or expressions.

- probabilities:

  Optional probabilities. Equal probabilities are used by default.

## Value

A one-row `simulab_formula` base `data.frame`.

## Examples

``` r
mixture_formula(variables = c("a", "b"), probabilities = c(0.3, 0.7))
#>      type                                           formula
#> 1 mixture a | 0.29999999999999999 + b | 0.69999999999999996
```
