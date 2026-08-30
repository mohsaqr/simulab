# Create a tidy correlation structure

Create a tidy correlation structure

## Usage

``` r
correlation_structure(
  n_variables,
  rho = 0,
  structure = c("independent", "exchangeable", "ar1", "custom"),
  correlation = NULL,
  variable_names = NULL
)
```

## Arguments

- n_variables:

  Number of variables.

- rho:

  Correlation coefficient used by exchangeable and AR(1) structures.

- structure:

  Correlation structure: one of `"independent"`, `"exchangeable"`,
  `"ar1"`, or `"custom"`. If left unset it is chosen from the other
  arguments: `"custom"` when `correlation` is supplied, `"exchangeable"`
  when a non-zero `rho` (or `tau`) is supplied, and `"independent"`
  otherwise. Passing `"independent"` together with a non-zero `rho` is a
  contradiction and raises an error.

- correlation:

  Custom correlation matrix.

- variable_names:

  Optional variable names.

## Value

A base `data.frame` with one row per matrix cell and columns `row`,
`column`, and `correlation`.

## Examples

``` r
correlation_structure(
  n_variables = 3,
  rho = 0.5,
  structure = "ar1"
)
#>   row column correlation
#> 1  V1     V1        1.00
#> 2  V2     V1        0.50
#> 3  V3     V1        0.25
#> 4  V1     V2        0.50
#> 5  V2     V2        1.00
#> 6  V3     V2        0.50
#> 7  V1     V3        0.25
#> 8  V2     V3        0.50
#> 9  V3     V3        1.00
```
