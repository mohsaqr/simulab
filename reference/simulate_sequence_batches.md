# Simulate repeated sequence datasets

Calls
[`simulate_sequences()`](https://pak.dynasite.org/simulab/reference/simulate_sequences.md)
`repetitions` times and stacks the results, so each dataset is drawn
from its own transition system rather than from a shared one.

## Usage

``` r
simulate_sequence_batches(repetitions = 1L, ..., seed = NULL)
```

## Arguments

- repetitions:

  Number of datasets. A single positive whole number, defaulting to `1`.

- ...:

  Arguments passed to
  [`simulate_sequences()`](https://pak.dynasite.org/simulab/reference/simulate_sequences.md).

- seed:

  Optional base seed. A single number, or `NULL` (the default). Dataset
  `i` uses `seed + i - 1`.

## Value

A `simulab_sim` base `data.frame` in long form, one row per dataset,
sequence and position, with the column `dataset` followed by the columns
[`simulate_sequences()`](https://pak.dynasite.org/simulab/reference/simulate_sequences.md)
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
#> 1       1  1      1 Reflect
#> 2       1  1      2   Learn
#> 3       1  1      3 Reflect
#> 4       1  1      4   Learn
#> 5       1  1      5 Reflect
#> 6       1  1      6   Learn
#> 
#> Truth (transitions):
#>    dataset    from      to probability
#> 1        1 Reflect Reflect  0.06261118
#> 2        1   Learn Reflect  0.42158819
#> 3        1    Plan Reflect  0.66416516
#> 4        1 Reflect   Learn  0.86660136
#> 5        1   Learn   Learn  0.49915316
#> 6        1    Plan   Learn  0.16698516
#> 7        1 Reflect    Plan  0.07078746
#> 8        1   Learn    Plan  0.07925865
#> 9        1    Plan    Plan  0.16884968
#> 10       2    Read    Read  0.05043712
#> ... 17 more rows
#> 
#> Other tables: initial_probabilities. Read one with as.data.frame(x, what = "initial_probabilities").
```
