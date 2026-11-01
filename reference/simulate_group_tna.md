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

## References

Saqr, M., López-Pernas, S., Törmänen, T., Kaliisa, R., Misiejuk, K., &
Tikka, S. (2025). Transition network analysis: A novel framework for
modeling, visualizing, and identifying the temporal patterns of learners
and learning processes. In *Proceedings of the 15th International
Learning Analytics and Knowledge Conference* (pp. 351–361).
[doi:10.1145/3706468.3706513](https://doi.org/10.1145/3706468.3706513)

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
```
