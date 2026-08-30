# Encode categorical variables

Encode categorical variables

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

  Base `data.frame`.

- variables:

  Categorical variables to encode.

- coding:

  Factor, dummy, or effect coding.

- labels:

  Optional labels for factor coding, as a named list per variable or a
  tidy data frame with columns `variable`, `level` and `label`.

- prefix:

  Prefix for generated variables.

- replace:

  Remove source variables after encoding.

## Value

A `simulab_sim` base `data.frame` with encoded variables.

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
