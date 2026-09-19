# Simulate repeated sequence datasets

Calls
[`simulate_sequences()`](https://mohsaqr.github.io/simulab/reference/simulate_sequences.md)
`repetitions` times and stacks the results, so each dataset is drawn
from its own transition system rather than from a shared one.

## Usage

``` r
simulate_sequence_batches(repetitions, ..., seed = NULL)
```

## Arguments

- repetitions:

  Number of datasets. A single positive whole number.

- ...:

  Arguments passed to
  [`simulate_sequences()`](https://mohsaqr.github.io/simulab/reference/simulate_sequences.md).

- seed:

  Optional base seed. A single number, or `NULL` (the default). Dataset
  `i` uses `seed + i - 1`.

## Value

A `simulab_sim` base `data.frame` in long form, one row per dataset,
sequence and position, with the column `dataset` followed by the columns
[`simulate_sequences()`](https://mohsaqr.github.io/simulab/reference/simulate_sequences.md)
returns (`id`, `period` and `state`). Components: `transitions`, the
generating transition probabilities, one row per dataset and from/to
pair with columns `dataset`, `from`, `to` and `probability`; and
`initial_probabilities`, one row per dataset and state with columns
`dataset`, `state` and `probability`.

## Examples

``` r
result <- simulate_sequence_batches(
  repetitions = 3, n = 20, n_states = 3, chain_length = 10, seed = 1
)
head(result)
#> <simulab_sim:sequence_batches> 6 rows x 4 columns
#>   dataset id period   state
#> 1       1  1      1 State 3
#> 2       1  1      2 State 2
#> 3       1  1      3 State 2
#> 4       1  1      4 State 2
#> 5       1  1      5 State 1
#> 6       1  1      6 State 2
```
