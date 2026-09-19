# Generate a missingness mask

Draws, for every row of `data` and every variable in `specification`,
whether that cell is missing, by comparing a uniform draw against the
row's probability. The mask is returned rather than applied, so the
complete data and the mask that hides part of it can both be kept;
[`observed_data()`](https://mohsaqr.github.io/simulab/reference/observed_data.md)
joins them.

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

  Complete base `data.frame`, or a `simulab_sim`, with at least one row.
  Every target variable of `specification` must be one of its columns.

- specification:

  Definitions from
  [`define_missingnesses()`](https://mohsaqr.github.io/simulab/reference/define_missingnesses.md),
  a `simulab_missing_spec` object.

- id:

  Optional unit identifier. A single string naming a column of `data`,
  or `NULL` (the default). It is required by the `baseline` and
  `monotone` rules and is carried into the mask.

- period:

  Optional period variable that orders a unit's rows. A single string
  naming a column of `data`, or `NULL` (the default). It is required by
  the `baseline` and `monotone` rules and is carried into the mask.

- seed:

  Optional random seed. A single number, or `NULL` (the default).

- envir:

  Environment the formulas are evaluated in after the data columns.
  Defaults to the caller's environment.

## Value

A base `data.frame` with one row per row of `data`, holding the `id` and
`period` columns when they are given, or a single `row` column numbering
the rows when neither is, followed by one logical column per target
variable of `specification`, named after that variable. Variables of
`data` that `specification` says nothing about get no column.

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
