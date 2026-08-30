# Apply a missingness mask to complete data

Apply a missingness mask to complete data

## Usage

``` r
observed_data(data, missingness, id = NULL)
```

## Arguments

- data:

  Complete base `data.frame`.

- missingness:

  A logical mask returned by
  [`missingness_matrix()`](https://mohsaqr.github.io/simulab/reference/missingness_matrix.md).

- id:

  Identifier columns present in both inputs and never made missing.

## Value

A `simulab_sim` base `data.frame` containing observed data.

## Examples

``` r
data <- data.frame(id = 1:100, outcome = stats::rnorm(100))
mask <- missingness_matrix(
  data,
  specification = define_missingnesses(define_missingness("outcome", formula = "0.3")),
  seed = 1
)

result <- observed_data(data, missingness = mask, id = "id")
head(result)
#> <simulab_sim:observed_data> 6 rows x 2 columns
#>   id    outcome
#> 1  1         NA
#> 2  2 -1.1327594
#> 3  3  1.4899074
#> 4  4 -0.2482471
#> 5  5         NA
#> 6  6  0.4048710
```
