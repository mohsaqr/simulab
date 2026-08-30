# Generate a missingness mask

Generate a missingness mask

## Usage

``` r
missingness_matrix(
  data,
  specification,
  id = NULL,
  period = NULL,
  seed = NULL,
  envir = parent.frame()
)
```

## Arguments

- data:

  Complete base `data.frame`.

- specification:

  Definitions from
  [`define_missingnesses()`](https://mohsaqr.github.io/simulab/reference/define_missingnesses.md).

- id:

  Optional unit identifier for longitudinal rules.

- period:

  Optional period variable for longitudinal rules.

- seed:

  Optional random seed.

- envir:

  Formula evaluation environment.

## Value

A base `data.frame` containing identifier columns followed by one
logical missingness indicator per data variable.

## Examples

``` r
data <- data.frame(id = 1:100, baseline = stats::rnorm(100), outcome = stats::rnorm(100))
specification <- define_missingnesses(
  define_missingness("outcome", formula = "0.2")
)

mask <- missingness_matrix(data, specification = specification, seed = 1)
head(mask)
#>   row outcome
#> 1   1   FALSE
#> 2   2   FALSE
#> 3   3   FALSE
#> 4   4   FALSE
#> 5   5   FALSE
#> 6   6   FALSE
```
