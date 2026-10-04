# Simulate sequences and fit a grouped TNA model

Simulate sequences and fit a grouped TNA model

## Usage

``` r
simulate_group_tna(
  groups = 2L,
  actors = 50L,
  transitions = NULL,
  chain_length = 20L,
  initial = NULL,
  group_names = NULL,
  states = NULL,
  n_states = 5L,
  state_categories = c("metacognitive", "cognitive"),
  model = c("tna", "ftna", "ctna", "atna"),
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

- model:

  TNA model type.

- seed:

  Optional random seed. Group-specific deterministic offsets are used
  without leaking RNG state.

- ...:

  Advanced sequence arguments.

- batch:

  Optional single positive whole number. When given, the simulator runs
  `batch` times and returns a plain `list` of `batch` results, each
  exactly what the same call without `batch` returns. With a `seed`,
  every dataset gets its own seed drawn from `seed`, so the whole batch
  is reproducible; without one the datasets are consecutive draws from
  the session's random-number stream. The default `NULL` returns a
  single result.

## Value

A long-form `simulab_sim` base `data.frame` of grouped sequences with
columns `group`, `id`, `period`, and `state`.
`as.data.frame(x, what = )` also returns `true_transitions` (the
generating probabilities), `estimated_edges` (the fitted TNA weights),
`model_info`, `wide`, and `groups`. The native `group_tna` model is
accessible through
[`as_tna_model()`](https://pak.dynasite.org/simulab/reference/as_tna_model.md).
Requires the suggested `tna` package.

## Examples

``` r
if (requireNamespace("tna", quietly = TRUE)) {
  result <- simulate_group_tna(
    groups = 2, actors = 20, chain_length = 12, n_states = 3, seed = 1
  )
  head(result)
  components(result)

  # With no arguments, one transition matrix per group is drawn and fitted.
  drawn <- simulate_group_tna(seed = 1)
  as.data.frame(drawn, what = "true_transitions")
}
#>      group      from        to probability
#> 1  Group 1   Reflect   Reflect 0.049788256
#> 2  Group 1     Learn   Reflect 0.394948479
#> 3  Group 1      Plan   Reflect 0.585611026
#> 4  Group 1 Elaborate   Reflect 0.219063793
#> 5  Group 1   Analyze   Reflect 0.298431569
#> 6  Group 1   Reflect     Learn 0.371741544
#> 7  Group 1     Learn     Learn 0.207717030
#> 8  Group 1      Plan     Learn 0.099750600
#> 9  Group 1 Elaborate     Learn 0.024788532
#> 10 Group 1   Analyze     Learn 0.038374010
#> 11 Group 1   Reflect      Plan 0.099744248
#> 12 Group 1     Learn      Plan 0.098345088
#> 13 Group 1      Plan      Plan 0.022131805
#> 14 Group 1 Elaborate      Plan 0.327292502
#> 15 Group 1   Analyze      Plan 0.246092007
#> 16 Group 1   Reflect Elaborate 0.436757023
#> 17 Group 1     Learn Elaborate 0.253029533
#> 18 Group 1      Plan Elaborate 0.179824790
#> 19 Group 1 Elaborate Elaborate 0.316213388
#> 20 Group 1   Analyze Elaborate 0.381412115
#> 21 Group 1   Reflect   Analyze 0.041968930
#> 22 Group 1     Learn   Analyze 0.045959871
#> 23 Group 1      Plan   Analyze 0.112681779
#> 24 Group 1 Elaborate   Analyze 0.112641786
#> 25 Group 1   Analyze   Analyze 0.035690299
#> 26 Group 2   Reflect   Reflect 0.026229926
#> 27 Group 2     Learn   Reflect 0.009143277
#> 28 Group 2      Plan   Reflect 0.010820782
#> 29 Group 2 Elaborate   Reflect 0.228929820
#> 30 Group 2   Analyze   Reflect 0.027846525
#> 31 Group 2   Reflect     Learn 0.135217000
#> 32 Group 2     Learn     Learn 0.019558256
#> 33 Group 2      Plan     Learn 0.450717596
#> 34 Group 2 Elaborate     Learn 0.554263237
#> 35 Group 2   Analyze     Learn 0.058571272
#> 36 Group 2   Reflect      Plan 0.107633351
#> 37 Group 2     Learn      Plan 0.612337006
#> 38 Group 2      Plan      Plan 0.019373649
#> 39 Group 2 Elaborate      Plan 0.004433527
#> 40 Group 2   Analyze      Plan 0.281040051
#> 41 Group 2   Reflect Elaborate 0.103269753
#> 42 Group 2     Learn Elaborate 0.244923406
#> 43 Group 2      Plan Elaborate 0.054592182
#> 44 Group 2 Elaborate Elaborate 0.081621468
#> 45 Group 2   Analyze Elaborate 0.014692743
#> 46 Group 2   Reflect   Analyze 0.627649970
#> 47 Group 2     Learn   Analyze 0.114038055
#> 48 Group 2      Plan   Analyze 0.464495791
#> 49 Group 2 Elaborate   Analyze 0.130751948
#> 50 Group 2   Analyze   Analyze 0.617849410
```
