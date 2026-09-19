# Inject MCAR, MAR, or MNAR missingness

Blanks cells of `data` under one of the three standard mechanisms.
`"MCAR"` gives every row the same probability `proportion`, so
missingness depends on nothing. `"MAR"` makes it depend on the fully
observed `predictor`, which is itself never made missing. `"MNAR"` makes
each target variable's missingness depend on its own value, so the
values that disappear are not a random sample of them. For MAR and MNAR
the probability increases with the driving variable's rank: its
ties-averaged rank mapped into `(0, 1)`, or `0.5` for a missing or
constant driver, scaled by the multiplier that makes the mean
probability equal `proportion`, and capped at 1. Each MAR target
therefore shares one probability vector, while each MNAR target gets its
own.

## Usage

``` r
inject_missingness(
  data,
  mechanism = c("MCAR", "MAR", "MNAR"),
  proportion = 0.1,
  variables = NULL,
  predictor = NULL,
  seed = NULL
)
```

## Arguments

- data:

  Complete base `data.frame`, or a `simulab_sim`, with at least one row.

- mechanism:

  Missingness mechanism, one of `"MCAR"` (the default), `"MAR"` or
  `"MNAR"`.

- proportion:

  Target missing fraction, the mean cell probability rather than a
  realized count. A single number between 0 and 1, defaulting to `0.1`;
  the realized fraction is random around it and is reported in the
  `missingness_summary` component.

- variables:

  Variables to make missing. A character vector of column names, or
  `NULL` (the default), which selects every column of `data`,
  identifiers included. Under `"MAR"` the `predictor` is removed from
  this set.

- predictor:

  Fully observed predictor that drives MAR missingness. A single string
  naming a column of `data`, required when `mechanism` is `"MAR"` and
  ignored otherwise. Defaults to `NULL`.

- seed:

  Optional random seed. A single number, or `NULL` (the default).

## Value

A `simulab_sim` base `data.frame` with the columns and rows of `data`,
the drawn cells of the target variables replaced by `NA`. Components:
`missingness`, the cell-level mask reached with
`as.data.frame(x, what = "missingness")`, one row per observation and
target variable with columns `observation`, `variable`, `probability`,
the logical `missing` and `mechanism`; and `missingness_summary`, one
row per target variable with columns `variable`, `realized_proportion`
and `target_proportion`.

## Examples

``` r
data <- data.frame(id = 1:200, x = stats::rnorm(200), y = stats::rnorm(200))

result <- inject_missingness(
  data, mechanism = "MCAR", proportion = 0.2, variables = "y", seed = 1
)
head(result)
#> <simulab_sim:missingness> 6 rows x 3 columns
#>   id          x          y
#> 1  1  1.0744410 -0.3410670
#> 2  2  1.8956548  1.5024245
#> 3  3 -0.6029973  0.5283077
#> 4  4 -0.3908678  0.5421914
#> 5  5 -0.4162220 -0.1366734
#> 6  6 -0.3756574 -1.1367339

# MAR missingness in `y` driven by the observed predictor `x`.
head(inject_missingness(
  data, mechanism = "MAR", proportion = 0.2,
  variables = "y", predictor = "x", seed = 1
))
#> <simulab_sim:missingness> 6 rows x 3 columns
#>   id          x          y
#> 1  1  1.0744410         NA
#> 2  2  1.8956548         NA
#> 3  3 -0.6029973  0.5283077
#> 4  4 -0.3908678  0.5421914
#> 5  5 -0.4162220 -0.1366734
#> 6  6 -0.3756574 -1.1367339
```
