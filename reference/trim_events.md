# Trim longitudinal records at an event occurrence

Trim longitudinal records at an event occurrence

## Usage

``` r
trim_events(data, id, period, event, occurrence = 1L, event_value = 1)
```

## Arguments

- data:

  Long-form base `data.frame`.

- id:

  Unit identifier.

- period:

  Ordered period variable.

- event:

  Event indicator variable.

- occurrence:

  Event occurrence at which to stop.

- event_value:

  Value identifying an event.

## Value

A `simulab_sim` base `data.frame` retaining observations through the
requested event, or all observations when it never occurs.

## Examples

``` r
# A long-form event log: `simulate_until_event()` generates the indicator,
# `trim_events()` then keeps records through its first occurrence.
data <- simulate_until_event(
  expand_periods(data.frame(id = 1:20), periods = 10,
                 id = "id", period = "period"),
  definition = define_variable("event", formula = "0.25",
                               distribution = "binary"),
  seed = 1
)

result <- trim_events(
  data, id = "id", period = "period", event = "event", occurrence = 1
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
