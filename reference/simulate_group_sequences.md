# Simulate grouped actor sequences

Simulate grouped actor sequences

## Usage

``` r
simulate_group_sequences(
  groups = 2L,
  actors = 50L,
  transitions = NULL,
  chain_length = 20L,
  initial = NULL,
  group_names = NULL,
  states = NULL,
  n_states = 5L,
  state_categories = c("metacognitive", "cognitive"),
  seed = NULL,
  ...,
  batch = NULL
)
```

## Arguments

- groups:

  Number of groups, defaulting to `2`.

- actors:

  Actors per group, scalar or one value per group, defaulting to `50`.

- transitions:

  A common transition matrix, one matrix per group, or `NULL` for
  randomly generated matrices. A tidy data frame with columns `group`,
  `from`, `to` and `probability` gives one matrix per group.

- chain_length:

  Sequence length, defaulting to `20`.

- initial:

  Common initial probabilities, one vector per group, or `NULL`. A tidy
  data frame with columns `group`, `state` and `probability` gives one
  vector per group.

- group_names:

  Optional group labels.

- states, n_states, state_categories:

  State-space arguments passed to
  [`simulate_sequences()`](https://pak.dynasite.org/simulab/reference/simulate_sequences.md).

- seed:

  Optional random seed. Group-specific deterministic offsets are used
  without leaking RNG state.

- ...:

  Advanced sequence arguments passed to
  [`simulate_sequences()`](https://pak.dynasite.org/simulab/reference/simulate_sequences.md).

- batch:

  Optional single positive whole number. When given, the simulator runs
  `batch` times and returns a plain `list` of `batch` results, each
  exactly what the same call without `batch` returns. With a `seed`,
  every dataset gets its own seed drawn from `seed`, so the whole batch
  is reproducible; without one the datasets are consecutive draws from
  the session's random-number stream. The default `NULL` returns a
  single result.

## Value

A long-form `simulab_sim` base `data.frame` with one row per actor
sequence position and columns `group`, `id`, `period`, and `state`.
Actor identifiers are made unique across groups as `G<group>_A<actor>`.
`as.data.frame(x, what = )` also returns `transitions` (`group`, `from`,
`to`, `probability`), `wide` (one row per actor: `id`, `S1`, `S2`, ...,
`group`), and `groups` (`group`, `actors`).

## Examples

``` r
result <- simulate_group_sequences(
  groups = 2, actors = 20, chain_length = 12, n_states = 3, seed = 1
)
head(result)
#> <simulab_sim:group_sequences> 6 rows x 4 columns
#>     group    id period   state
#> 1 Group 1 G1_A1      1    Plan
#> 2 Group 1 G1_A1      2   Learn
#> 3 Group 1 G1_A1      3   Learn
#> 4 Group 1 G1_A1      4   Learn
#> 5 Group 1 G1_A1      5 Reflect
#> 6 Group 1 G1_A1      6   Learn
#> 
#> Truth (transitions):
#>      group    from      to probability
#> 1  Group 1 Reflect Reflect  0.07830127
#> 2  Group 1   Learn Reflect  0.55164885
#> 3  Group 1    Plan Reflect  0.59019469
#> 4  Group 1 Reflect   Learn  0.42202656
#> 5  Group 1   Learn   Learn  0.35827360
#> 6  Group 1    Plan   Learn  0.37885862
#> 7  Group 1 Reflect    Plan  0.49967217
#> 8  Group 1   Learn    Plan  0.09007756
#> 9  Group 1    Plan    Plan  0.03094669
#> 10 Group 2 Reflect Reflect  0.08698614
#> ... 8 more rows
#> 
#> Other tables: wide, groups. Read one with as.data.frame(x, what = "wide").
components(result)
#>         table rows columns
#> 1        data  480       4
#> 2 transitions   18       4
#> 3        wide   40      14
#> 4      groups    2       2
```
