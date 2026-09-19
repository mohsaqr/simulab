# Simulate baseline data with survival outcomes

Simulate baseline data with survival outcomes

## Usage

``` r
simulate_survival(
  n,
  specification,
  covariates = NULL,
  id = "id",
  seed = NULL,
  digits = NULL,
  envir = parent.frame()
)
```

## Arguments

- n:

  Number of observations.

- specification:

  Survival definitions from
  [`define_survivals()`](https://mohsaqr.github.io/simulab/reference/define_survivals.md),
  in either the `hazard()` call form or the column form.

- covariates:

  Optional baseline base `data.frame` with `n` rows.

- id:

  Identifier name used when covariates are omitted. Defaults to `"id"`
  and is ignored when `covariates` is supplied.

- seed, digits, envir:

  Arguments passed to
  [`augment_survival()`](https://mohsaqr.github.io/simulab/reference/augment_survival.md).

## Value

A `simulab_sim` base `data.frame` with one row per simulated subject:
the identifier (or the supplied covariates) followed by one column per
event defined in `specification`. The `survival_definitions` component
holds the specification that generated it.

## Examples

``` r
result <- simulate_survival(
  n = 100,
  specification = define_survivals(define_survival("time", formula = -8, shape = 0.3)),
  seed = 1
)
head(result)
#> <simulab_sim:survival> 6 rows x 2 columns
#>   id      time
#> 1  1 11.997214
#> 2  2 10.985087
#> 3  3  9.248955
#> 4  4  5.462235
#> 5  5 12.694901
#> 6  6  5.640350

# A hazard call states the same process, with the log rate as an expression.
head(simulate_survival(
  n = 100,
  specification = define_survivals(time = hazard(log_rate = -8, shape = 0.3)),
  seed = 1
))
#> <simulab_sim:survival> 6 rows x 2 columns
#>   id      time
#> 1  1 11.997214
#> 2  2 10.985087
#> 3  3  9.248955
#> 4  4  5.462235
#> 5  5 12.694901
#> 6  6  5.640350
```
