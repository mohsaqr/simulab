# Simulate repeated sequence datasets

Simulate repeated sequence datasets

## Usage

``` r
simulate_sequence_batches(repetitions, ..., seed = NULL)
```

## Arguments

- repetitions:

  Number of datasets.

- ...:

  Arguments passed to
  [`simulate_sequences()`](https://mohsaqr.github.io/simulab/reference/simulate_sequences.md).

- seed:

  Optional base seed. Each dataset uses a deterministic offset.

## Value

A combined long-form `simulab_sim` with dataset identifiers and
dataset-specific transition parameters.

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
