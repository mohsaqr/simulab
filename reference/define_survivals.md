# Combine survival definitions into a specification

Combine survival definitions into a specification

## Usage

``` r
define_survivals(...)
```

## Arguments

- ...:

  One of three forms.

  **Hazard calls.**
  `time = hazard(log_rate = -8 + 0.5 * treatment, shape = 0.3)` names
  the event with the argument name and states its hazard as a call.
  `log_rate` is the log hazard and may be any expression over the
  covariates; `shape` and `scale` default to 1 and `from`, the time at
  which the segment begins, to 0. Arguments may be positional or named,
  and repeating the argument name gives one event several segments,
  which is a piecewise hazard.

  **Specification columns** given as named vectors (`event`, `formula`,
  `scale`, `shape`, `transition`).

  **Objects** created by
  [`define_survival()`](https://mohsaqr.github.io/simulab/reference/define_survival.md).

  The forms cannot be mixed in one call.

  In the column form, `event` and `formula` are required. A column given
  as a single value is recycled across every row. `scale` and `shape`
  default to 1 and `transition` to 0. Two rows for one event with
  different `transition` times give a piecewise hazard.

## Value

A `simulab_survival_spec` base `data.frame` with one row per hazard
segment.

## Examples

``` r
# One call, named arguments, one row per event.
define_survivals(
  event   = c("time_relapse", "time_death"),
  formula = c(-8, -9),
  shape   = 0.3
)
#>          event formula scale shape transition
#> 1   time_death      -9     1   0.3          0
#> 2 time_relapse      -8     1   0.3          0

# A piecewise hazard is two rows for one event.
define_survivals(
  event      = c("time", "time"),
  formula    = c(-8, -6),
  shape      = 0.3,
  transition = c(0, 50)
)
#>   event formula scale shape transition
#> 1  time      -8     1   0.3          0
#> 2  time      -6     1   0.3         50

# Definitions built one at a time are still accepted.
define_survivals(
  define_survival("time_relapse", formula = -8, shape = 0.3),
  define_survival("time_death", formula = -9, shape = 0.3)
)
#>          event formula scale shape transition
#> 1 time_relapse      -8     1   0.3          0
#> 2   time_death      -9     1   0.3          0

# Hazard calls. The log rate is an expression over the covariates.
define_survivals(
  time_relapse = hazard(log_rate = -8 + 0.5 * treatment, shape = 0.3),
  time_death   = hazard(log_rate = -9, shape = 0.3)
)
#>          event              formula scale shape transition
#> 1   time_death                   -9     1   0.3          0
#> 2 time_relapse -8 + 0.5 * treatment     1   0.3          0

# A repeated event name is a piecewise hazard: the rate rises after day 60.
define_survivals(
  time = hazard(log_rate = -8, shape = 0.3),
  time = hazard(log_rate = -5, shape = 0.3, from = 60)
)
#>   event formula scale shape transition
#> 1  time      -8     1   0.3          0
#> 2  time      -5     1   0.3         60
```
