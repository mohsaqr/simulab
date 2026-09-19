# Apply a missingness mask to complete data

Sets every cell the mask flags to `NA`, leaving the complete data
otherwise untouched, and keeps the mask alongside the result as a tidy
component.

## Usage

``` r
observed_data(data, missingness, id = NULL)
```

## Arguments

- data:

  Complete base `data.frame`, or a `simulab_sim`, with as many rows as
  `missingness` and in the same row order.

- missingness:

  A logical mask returned by
  [`missingness_matrix()`](https://mohsaqr.github.io/simulab/reference/missingness_matrix.md),
  with one row per row of `data`. Its columns that also name columns of
  `data`, other than those listed in `id`, are the targets, and each
  must be logical.

- id:

  Identifier columns the mask carries that are never made missing. A
  character vector, or `NULL` (the default). Name the identifier columns
  of the mask here, or they are treated as targets and rejected for not
  being logical.

## Value

A `simulab_sim` base `data.frame` with the columns and rows of `data`,
the flagged cells of the target variables replaced by `NA`. The
component `missingness`, reached with
`as.data.frame(x, what = "missingness")`, is the mask in long form, one
row per observation and target variable, with columns `observation`,
`variable` and the logical `missing`.

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
