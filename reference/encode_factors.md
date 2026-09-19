# Encode categorical variables

Turns categorical columns into the numeric columns a model needs. Dummy
coding is one indicator per level, with no reference level dropped;
effect coding drops the last level's indicator and codes that level `-1`
across the remaining columns; factor coding leaves one factor column.

## Usage

``` r
encode_factors(
  data,
  variables,
  coding = c("factor", "dummy", "effect"),
  labels = NULL,
  prefix = "f_",
  replace = FALSE
)
```

## Arguments

- data:

  Base `data.frame`, or a `simulab_sim`.

- variables:

  Categorical variables to encode. A character vector of at least one
  column name of `data`. Levels are taken in the order
  [`factor()`](https://rdrr.io/r/base/factor.html) sorts them.

- coding:

  Encoding to apply, one of `"factor"` (the default), one factor column
  named `<prefix><variable>`, `"dummy"`, one 0/1 indicator per level
  named `<prefix><variable>_<level>`, or `"effect"`, the same indicators
  without the last level's column and with `-1` in every column for that
  level.

- labels:

  Optional replacement level labels, as a named list per variable, one
  atomic vector shared by every variable, or a tidy data frame with
  columns `variable`, `level` and `label`. Defaults to `NULL`, the
  values as they stand. The labels are passed to
  [`factor()`](https://rdrr.io/r/base/factor.html), so they rename the
  levels in sorted order and also feed the generated column names.

- prefix:

  Prefix for generated variables. A single string, defaulting to `"f_"`.

- replace:

  Remove the source variables after encoding. A single flag, defaulting
  to `FALSE`.

## Value

A `simulab_sim` base `data.frame` with the columns of `data`, minus the
source variables when `replace` is `TRUE`, followed by the generated
columns, one row per input row. The component `encoding`, reached with
`as.data.frame(x, what = "encoding")`, holds one row per generated
column with columns `source`, `encoded` and `coding`.

## Examples

``` r
data <- data.frame(id = 1:6, arm = rep(c("a", "b", "c"), each = 2))
encode_factors(data, variables = "arm", coding = "dummy")
#> <simulab_sim:encoded_factors> 6 rows x 5 columns
#>   id arm f_arm_a f_arm_b f_arm_c
#> 1  1   a       1       0       0
#> 2  2   a       1       0       0
#> 3  3   b       0       1       0
#> 4  4   b       0       1       0
#> 5  5   c       0       0       1
#> 6  6   c       0       0       1
```
