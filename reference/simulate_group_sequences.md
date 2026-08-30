# Simulate grouped actor sequences

Simulate grouped actor sequences

## Usage

``` r
simulate_group_sequences(
  groups,
  actors,
  transitions = NULL,
  chain_length,
  initial = NULL,
  group_names = NULL,
  states = NULL,
  n_states = 5L,
  state_categories = NULL,
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

- seed:

  Optional random seed. Group-specific deterministic offsets are used
  without leaking RNG state.

- ...:

  Advanced sequence arguments passed to
  [`simulate_sequences()`](https://mohsaqr.github.io/simulab/reference/simulate_sequences.md).

## Value

Long-form grouped sequences with group-specific transitions and wide
sequences as components.

## Examples

``` r
result <- simulate_group_sequences(
  groups = 2, actors = 20, chain_length = 12, n_states = 3, seed = 1
)
head(result)
#> <simulab_sim:group_sequences> 6 rows x 4 columns
#>     group    id period   state
#> 1 Group 1 G1_A1      1 State 3
#> 2 Group 1 G1_A1      2 State 2
#> 3 Group 1 G1_A1      3 State 2
#> 4 Group 1 G1_A1      4 State 2
#> 5 Group 1 G1_A1      5 State 1
#> 6 Group 1 G1_A1      6 State 2
components(result)
#>         table rows columns
#> 1        data  480       4
#> 2 transitions   18       4
#> 3        wide   40      14
#> 4      groups    2       2
```
