# Construct a categorical probability formula

Supply exactly one of `probabilities` and `categories`; supplying both,
or neither, is an error. Probabilities are normalized to sum to one.

## Usage

``` r
categorical_formula(probabilities = NULL, categories = NULL)
```

## Arguments

- probabilities:

  Category probabilities, at least two of them.

- categories:

  Number of equal-probability categories, used instead of
  `probabilities`.

## Value

A one-row `simulab_formula` base `data.frame`.

## Examples

``` r
categorical_formula(probabilities = c(0.2, 0.5, 0.3))
#>          type                                     formula
#> 1 categorical 0.20000000000000001;0.5;0.29999999999999999
```
