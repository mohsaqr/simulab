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
  envir = parent.frame(),
  batch = NULL
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

- batch:

  Optional single positive whole number. When given, the simulator runs
  `batch` times and returns a plain `list` of `batch` results, each
  exactly what the same call without `batch` returns. With a `seed`,
  every dataset gets its own seed drawn from `seed`, so the whole batch
  is reproducible; without one the datasets are consecutive draws from
  the session's random-number stream. The default `NULL` returns a
  single result.

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
