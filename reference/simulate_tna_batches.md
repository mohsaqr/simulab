# Simulate and fit repeated TNA networks

Generates `repetitions` sequence datasets with
[`simulate_sequence_batches()`](https://mohsaqr.github.io/simulab/reference/simulate_sequence_batches.md)
and fits one transition network to each with
[`fit_tna()`](https://mohsaqr.github.io/simulab/reference/fit_tna.md),
so the estimated networks can be held against the transition systems
that generated them.

## Usage

``` r
simulate_tna_batches(
  repetitions,
  model = c("tna", "ftna", "ctna", "atna"),
  ...,
  seed = NULL
)
```

## Arguments

- repetitions:

  Number of fitted networks. A single positive whole number.

- model:

  TNA estimator, one of `"tna"` (the default), `"ftna"`, `"ctna"` or
  `"atna"`.

- ...:

  Arguments passed to
  [`simulate_sequences()`](https://mohsaqr.github.io/simulab/reference/simulate_sequences.md).

- seed:

  Optional base seed. A single number, or `NULL` (the default). Dataset
  `i` uses `seed + i - 1`.

## Value

A `simulab_sim` base `data.frame` of fitted edges, one row per network
and from/to pair, with columns `network`, `from`, `to` and `weight`.
Components: `sequences`, the generated sequences in long form with
columns `dataset`, `id`, `period` and `state`; `true_transitions`, the
generating probabilities with columns `dataset`, `from`, `to` and
`probability`; and `model_info`, one row per network describing the fit.

## Examples

``` r
if (requireNamespace("tna", quietly = TRUE)) {
  head(simulate_tna_batches(
    repetitions = 2, model = "tna", n = 20, n_states = 3, chain_length = 10, seed = 1
  ))
}
#> <simulab_sim:tna_batches> 6 rows x 4 columns
#>     network    from      to     weight
#> 1.1       1 State 1 State 1 0.03225806
#> 1.2       1 State 2 State 1 0.55263158
#> 1.3       1 State 3 State 1 0.54761905
#> 1.4       1 State 1 State 2 0.50000000
#> 1.5       1 State 2 State 2 0.34210526
#> 1.6       1 State 3 State 2 0.45238095
```
