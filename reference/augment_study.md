# Add declaratively specified variables to existing data

A parameter or formula may refer to a column `data` already has as
readily as to a variable defined earlier in the same specification. A
variable that already exists is refused rather than overwritten.

## Usage

``` r
augment_study(data, specification, seed = NULL, envir = parent.frame())
```

## Arguments

- data:

  A base `data.frame`.

- specification:

  A tidy definition table created with
  [`define_variables()`](https://mohsaqr.github.io/simulab/reference/define_variables.md),
  in either the distribution-call form or the `formula`/`variance`
  column form.

- seed:

  Optional random seed.

- envir:

  Environment used to resolve formula values.

## Value

A `simulab_sim` base `data.frame` containing the original and new
variables.

## Conditions

`simulab_existing_variable` when the specification names a column `data`
already has.

## Examples

``` r
# Distribution calls, generated into data that is already there.
head(augment_study(
  data.frame(id = 1:100, treated = rep(0:1, each = 50)),
  specification = define_variables(
    outcome = normal(mean = 3 + 2 * treated, sd = 1),
    visits  = poisson(lambda = 4)
  ),
  seed = 3
))
#> <simulab_sim:augmented_study> 6 rows x 4 columns
#>   id treated  outcome visits
#> 1  1       0 2.038067      5
#> 2  2       0 2.707474      6
#> 3  3       0 3.258788      3
#> 4  4       0 1.847868      4
#> 5  5       0 3.195783      6
#> 6  6       0 3.030124      3

base <- simulate_study(
  n = 100,
  specification = define_variables(
    define_variable("baseline", formula = "0", variance = "1", distribution = "normal")
  ),
  seed = 1
)

result <- augment_study(
  base,
  specification = define_variables(
    define_variable("outcome", formula = "2 * baseline", variance = "1",
                    distribution = "normal")
  ),
  seed = 2
)
head(result)
#> <simulab_sim:augmented_study> 6 rows x 3 columns
#>   id   baseline     outcome
#> 1  1 -0.6264538 -2.14982217
#> 2  2  0.1836433  0.55213583
#> 3  3 -0.8356286 -0.08341189
#> 4  4  1.5952808  2.06018593
#> 5  5  0.3295078  0.57876379
#> 6  6 -0.8204684 -1.50851648
```
