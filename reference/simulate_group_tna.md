# Simulate sequences and fit a grouped TNA model

Simulate sequences and fit a grouped TNA model

## Usage

``` r
simulate_group_tna(
  groups,
  actors,
  transitions = NULL,
  chain_length,
  initial = NULL,
  group_names = NULL,
  states = NULL,
  n_states = 5L,
  state_categories = NULL,
  model = c("tna", "ftna", "ctna", "atna"),
  seed = NULL,
  ...
)
```

## Arguments

- groups:

  Number of groups.

- actors:

  Actors per group, scalar or one value per group.

- transitions:

  A common transition matrix, one matrix per group, or `NULL` for
  randomly generated matrices. A tidy data frame with columns `group`,
  `from`, `to` and `probability` gives one matrix per group.

- chain_length:

  Sequence length.

- initial:

  Common initial probabilities, one vector per group, or `NULL`. A tidy
  data frame with columns `group`, `state` and `probability` gives one
  vector per group.

- group_names:

  Optional group labels.

- states, n_states, state_categories:

  State-space arguments passed to
  [`simulate_sequences()`](https://mohsaqr.github.io/simulab/reference/simulate_sequences.md).

- model:

  TNA model type.

- seed:

  Optional random seed. Group-specific deterministic offsets are used
  without leaking RNG state.

- ...:

  Advanced sequence arguments.

## Value

A long-form `simulab_sim` base `data.frame` of grouped sequences with
columns `group`, `id`, `period`, and `state`.
`as.data.frame(x, what = )` also returns `true_transitions` (the
generating probabilities), `estimated_edges` (the fitted TNA weights),
`model_info`, `wide`, and `groups`. The native `group_tna` model is
accessible through
[`as_tna_model()`](https://mohsaqr.github.io/simulab/reference/as_tna_model.md).
Requires the suggested `tna` package.

## Examples

``` r
if (requireNamespace("tna", quietly = TRUE)) {
  result <- simulate_group_tna(
    groups = 2, actors = 20, chain_length = 12, n_states = 3, seed = 1
  )
  head(result)
  components(result)
}
#>              table rows columns
#> 1             data  480       4
#> 2 true_transitions   18       4
#> 3  estimated_edges   18       4
#> 4       model_info    2       5
#> 5             wide   40      14
#> 6           groups    2       2
```
