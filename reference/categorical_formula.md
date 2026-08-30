# Construct a categorical probability formula

Construct a categorical probability formula

## Usage

``` r
categorical_formula(probabilities = NULL, categories = NULL)
```

## Arguments

- probabilities:

  Category probabilities.

- categories:

  Number of equal-probability categories when probabilities are not
  supplied.

## Value

A one-row `simulab_formula` base `data.frame`.

## Examples

``` r
categorical_formula(probabilities = c(0.2, 0.5, 0.3))
#>          type                                     formula
#> 1 categorical 0.20000000000000001;0.5;0.29999999999999999
```
