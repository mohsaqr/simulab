# Simulate a declaratively specified study

Simulate a declaratively specified study

## Usage

``` r
simulate_study(
  n,
  specification,
  id = "id",
  seed = NULL,
  envir = parent.frame()
)
```

## Arguments

- n:

  Number of observational units.

- specification:

  A tidy definition table created with
  [`define_variables()`](https://mohsaqr.github.io/simulab/reference/define_variables.md),
  in either the distribution-call form or the `formula`/`variance`
  column form.

- id:

  Name of the identifier column.

- seed:

  Optional random seed. The caller's random-number state is restored on
  exit.

- envir:

  Environment used to resolve functions and external values in formulas.

## Value

A `simulab_sim` base `data.frame`. Use
`as.data.frame(x, what = "definitions")` for the generating definitions.

## Examples

``` r
# `formula` is the mean or linear predictor and may refer to variables
# defined earlier. `variance` is a variance, not a standard deviation, so
# age has sd 10 and outcome has residual sd 2.
simulate_study(
  n = 20,
  specification = define_variables(
    define_variable("age", formula = 40, variance = 100, distribution = "normal"),
    define_variable("treated", formula = 0.5, distribution = "binary"),
    define_variable("outcome", formula = "10 + 2 * treated", variance = 4,
                    distribution = "normal")
  ),
  seed = 1
)
#> <simulab_sim:study> 20 rows x 4 columns
#>    id      age treated   outcome
#> 1   1 33.73546       1 14.717359
#> 2   2 41.83643       1 11.794425
#> 3   3 31.64371       1 12.775343
#> 4   4 55.95281       1 11.892390
#> 5   5 43.29508       1  9.245881
#> 6   6 31.79532       1 11.170011
#> 7   7 44.87429       0  9.211420
#> 8   8 47.38325       0  9.881373
#> 9   9 45.75781       1 14.200051
#> 10 10 36.94612       1 13.526351
#> ... 10 more rows
```
