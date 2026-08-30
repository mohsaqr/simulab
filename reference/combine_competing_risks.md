# Combine competing event times

Combine competing event times

## Usage

``` r
combine_competing_risks(
  data,
  events,
  censor = NULL,
  time = "time",
  event = "event",
  type = "event_type",
  keep_events = FALSE
)
```

## Arguments

- data:

  Base `data.frame` containing event-time variables.

- events:

  Event-time variable names.

- censor:

  Optional censoring-event variable.

- time:

  Name of the observed-time variable.

- event:

  Name of the integer event-code variable.

- type:

  Name of the event-type variable.

- keep_events:

  Retain the component event-time variables.

## Value

A `simulab_sim` base `data.frame` with observed time, event code, and
event type.

## Examples

``` r
data <- data.frame(id = 1:100, treatment = rep(0:1, each = 50))
data <- augment_survival(
  data,
  specification = define_survivals(
    define_survival("time_relapse", formula = -8, shape = 0.3),
    define_survival("time_death", formula = -9, shape = 0.3)
  ),
  seed = 1
)

result <- combine_competing_risks(
  data, events = c("time_relapse", "time_death")
)
head(result)
#> <simulab_sim:competing_risks> 6 rows x 5 columns
#>   id treatment      time event   event_type
#> 1  1         0 11.499102     2   time_death
#> 2  2         0 10.985087     1 time_relapse
#> 3  3         0  9.248955     1 time_relapse
#> 4  4         0  3.406859     2   time_death
#> 5  5         0 11.760588     2   time_death
#> 6  6         0  5.640350     1 time_relapse
```
