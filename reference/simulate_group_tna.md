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

Grouped long-form sequences with true transitions, fitted edges, model
metadata, and a native grouped model accessible through
[`as_tna_model()`](https://mohsaqr.github.io/simulab/reference/as_tna_model.md).

## Examples

``` r
result <- simulate_group_tna(
  groups = 2, actors = 20, chain_length = 12, n_states = 3, seed = 1
)
head(result)
#> <simulab_sim:group_tna> 6 rows x 4 columns
#>     group    id period   state
#> 1 Group 1 G1_A1      1 State 3
#> 2 Group 1 G1_A1      2 State 2
#> 3 Group 1 G1_A1      3 State 2
#> 4 Group 1 G1_A1      4 State 2
#> 5 Group 1 G1_A1      5 State 1
#> 6 Group 1 G1_A1      6 State 2
components(result)
#>              table rows columns
#> 1             data  480       4
#> 2 true_transitions   18       4
#> 3  estimated_edges   18       4
#> 4       model_info    2       5
#> 5             wide   40      14
#> 6           groups    2       2
```
