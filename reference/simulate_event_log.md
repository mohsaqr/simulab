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
  ...,
  batch = NULL
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

  Achievement probabilities, one per level and summing to one. When
  `NULL`, the levels are equally likely.

- start_time:

  Initial timestamp. Every actor's first event is placed at this time.

- interval_range:

  Minimum and maximum seconds between an actor's consecutive events,
  drawn uniformly.

- transitions:

  Common matrix, one matrix per group, or `NULL`.

- initial:

  Initial probabilities.

- seed:

  Optional random seed.

- ...:

  Advanced options passed to
  [`simulate_group_sequences()`](https://pak.dynasite.org/simulab/reference/simulate_group_sequences.md).

- batch:

  Optional single positive whole number. When given, the simulator runs
  `batch` times and returns a plain `list` of `batch` results, each
  exactly what the same call without `batch` returns. With a `seed`,
  every dataset gets its own seed drawn from `seed`, so the whole batch
  is reproducible; without one the datasets are consecutive draws from
  the session's random-number stream. The default `NULL` returns a
  single result.

## Value

A long-form `simulab_sim` base `data.frame` with one row per actor event
and columns `group`, `id`, `course`, `achievement`, `period`, `state`,
and `timestamp`. `as.data.frame(x, what = )` also returns `transitions`
(`group`, `from`, `to`, `probability`), `actors` (`group`, `id`,
`course`, `achievement`), `groups` (`group`, `actors`), `wide` (one row
per actor, columns `id`, `S1`, ..., plus actor metadata), and `one_hot`
(the event log with `state` replaced by indicator columns).

## Examples

``` r
result <- simulate_event_log(groups = 2, actors = 10, sequence_length = 8, seed = 1)
head(result)
#> <simulab_sim:event_log> 6 rows x 7 columns
#>     group    id   course achievement period    state           timestamp
#> 1 Group 1 G1_A1 Course 1        high      1 Continue 2020-01-01 00:00:00
#> 2 Group 1 G1_A1 Course 1        high      2 Complete 2020-01-01 00:01:10
#> 3 Group 1 G1_A1 Course 1        high      3 Practice 2020-01-01 00:05:15
#> 4 Group 1 G1_A1 Course 1        high      4    Track 2020-01-01 00:06:32
#> 5 Group 1 G1_A1 Course 1        high      5    Track 2020-01-01 00:09:06
#> 6 Group 1 G1_A1 Course 1        high      6 Complete 2020-01-01 00:10:24
#> 
#> Truth (transitions):
#>      group          from        to probability
#> 1  Group 1      Complete  Complete  0.05326849
#> 2  Group 1     Encourage  Complete  0.21668978
#> 3  Group 1      Continue  Complete  0.29212077
#> 4  Group 1         Doubt  Complete  0.12525831
#> 5  Group 1 Differentiate  Complete  0.20205291
#> 6  Group 1         Track  Complete  0.12203496
#> 7  Group 1         Forum  Complete  0.09929164
#> 8  Group 1      Practice  Complete  0.06490684
#> 9  Group 1      Complete Encourage  0.03248789
#> 10 Group 1     Encourage Encourage  0.01809601
#> ... 118 more rows
#> 
#> Other tables: actors, groups, wide, one_hot. Read one with as.data.frame(x, what = "actors").
components(result)
#>         table rows columns
#> 1        data  160       7
#> 2 transitions  128       4
#> 3      actors   20       4
#> 4      groups    2       2
#> 5        wide   20      12
#> 6     one_hot  160      14
```
