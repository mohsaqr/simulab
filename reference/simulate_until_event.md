# Simulate events and retain records through the nth event

Simulate events and retain records through the nth event

## Usage

``` r
simulate_until_event(
  data,
  definition,
  occurrence = 1L,
  id = "id",
  period = "period",
  seed = NULL,
  envir = parent.frame()
)
```

## Arguments

- data:

  Long-form base `data.frame`.

- definition:

  One binary variable definition from
  [`define_variable()`](https://mohsaqr.github.io/simulab/reference/define_variable.md).

- occurrence, id, period:

  Event trimming arguments.

- seed:

  Optional random seed.

- envir:

  Formula evaluation environment.

## Value

A `simulab_sim` base `data.frame` with the generated event indicator and
records through the requested occurrence.

## Examples

``` r
# Long-form input: one row per unit per period.
data <- expand_periods(data.frame(id = 1:30), periods = 8,
                       id = "id", period = "period")

result <- simulate_until_event(
  data,
  definition = define_variable("event", formula = "0.3", distribution = "binary"),
  occurrence = 1,
  seed = 1
)
head(result)
#> <simulab_sim:trimmed_events> 6 rows x 4 columns
#>   id period time event
#> 1  1      0    0     0
#> 2  1      1    1     0
#> 3  1      2    2     0
#> 4  1      3    3     1
#> 5  2      0    0     0
#> 6  2      1    1     0
```
