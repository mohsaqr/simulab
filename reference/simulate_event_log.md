# Simulate grouped educational event logs

Simulate grouped educational event logs

## Usage

``` r
simulate_event_log(
  groups = 5L,
  actors = 10L,
  courses = 1L,
  states = NULL,
  n_states = 8L,
  state_categories = "all",
  sequence_length = c(10L, 30L),
  achievement_levels = c("low", "medium", "high"),
  achievement_probabilities = NULL,
  start_time = as.POSIXct("2020-01-01", tz = "UTC"),
  interval_range = c(60, 600),
  transitions = NULL,
  initial = NULL,
  seed = NULL,
  ...
)
```

## Arguments

- groups:

  Number of groups.

- actors:

  Actors per group.

- courses:

  Number or labels of courses.

- states, n_states, state_categories:

  State-space options.

- sequence_length:

  Fixed length or minimum/maximum range.

- achievement_levels:

  Achievement labels.

- achievement_probabilities:

  Achievement probabilities.

- start_time:

  Initial timestamp.

- interval_range:

  Minimum and maximum seconds between events.

- transitions:

  Common matrix, one matrix per group, or `NULL`.

- initial:

  Initial probabilities.

- seed:

  Optional random seed.

- ...:

  Advanced options passed to
  [`simulate_group_sequences()`](https://mohsaqr.github.io/simulab/reference/simulate_group_sequences.md).

## Value

A long-form `simulab_sim` event log with wide, one-hot, transition,
actor, and group tables as components.

## Examples

``` r
result <- simulate_event_log(groups = 2, actors = 10, sequence_length = 8, seed = 1)
head(result)
#> <simulab_sim:event_log> 6 rows x 7 columns
#>     group    id   course achievement period         state           timestamp
#> 1 Group 1 G1_A1 Course 1        high      1     Encourage 2020-01-01 00:00:00
#> 2 Group 1 G1_A1 Course 1        high      2         Doubt 2020-01-01 00:01:10
#> 3 Group 1 G1_A1 Course 1        high      3 Differentiate 2020-01-01 00:05:15
#> 4 Group 1 G1_A1 Course 1        high      4      Practice 2020-01-01 00:06:32
#> 5 Group 1 G1_A1 Course 1        high      5     Encourage 2020-01-01 00:09:06
#> 6 Group 1 G1_A1 Course 1        high      6         Track 2020-01-01 00:10:24
components(result)
#>         table rows columns
#> 1        data  104       7
#> 2 transitions  128       4
#> 3      actors   20       4
#> 4      groups    2       2
#> 5        wide   20      12
#> 6     one_hot  104      22
```
