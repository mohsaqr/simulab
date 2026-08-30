# Compute tidy B-spline basis functions

Compute tidy B-spline basis functions

## Usage

``` r
spline_basis(knots = c(0.25, 0.5, 0.75), degree = 3L, n = 1000L)
```

## Arguments

- knots:

  Interior knots between zero and one.

- degree:

  Polynomial degree.

- n:

  Number of evaluation points.

## Value

A base `data.frame` with one row per x/basis combination and columns
`x`, `basis`, and `value`.

## Examples

``` r
head(spline_basis(knots = c(0.25, 0.5, 0.75), degree = 3, n = 20))
#>            x   basis       value
#> 1 0.00000000 basis_1 1.000000000
#> 2 0.05263158 basis_1 0.492054235
#> 3 0.10526316 basis_1 0.194051611
#> 4 0.15789474 basis_1 0.050007290
#> 5 0.21052632 basis_1 0.003936434
#> 6 0.26315789 basis_1 0.000000000
```
