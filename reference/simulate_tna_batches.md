# Simulate and fit repeated TNA networks

Generates `repetitions` sequence datasets with
[`simulate_sequence_batches()`](https://pak.dynasite.org/simulab/reference/simulate_sequence_batches.md)
and fits one transition network to each with
[`fit_tna()`](https://pak.dynasite.org/simulab/reference/fit_tna.md), so
the estimated networks can be held against the transition systems that
generated them.

## Usage

``` r
simulate_tna_batches(
  repetitions = 1L,
  model = c("tna", "ftna", "ctna", "atna"),
  ...,
  seed = NULL
)
```

## Arguments

- repetitions:

  Number of fitted networks. A single positive whole number, defaulting
  to `1`, so a call with no arguments draws one transition system,
  generates sequences from it and fits one network.

- model:

  TNA estimator, one of `"tna"` (the default), `"ftna"`, `"ctna"` or
  `"atna"`.

- ...:

  Arguments passed to
  [`simulate_sequences()`](https://pak.dynasite.org/simulab/reference/simulate_sequences.md).

- seed:

  Optional base seed. A single number, or `NULL` (the default). Dataset
  `i` uses `seed + i - 1`.

## Value

A `simulab_sim` base `data.frame` of fitted edges, one row per dataset
and from/to pair, with columns `dataset`, `from`, `to` and `weight`.
Printing it shows `true_transitions` as the truth, keyed by the same
`dataset`. Components: `sequences`, the generated sequences in long form
with columns `dataset`, `id`, `period` and `state`; `true_transitions`,
the generating probabilities with columns `dataset`, `from`, `to` and
`probability`; and `model_info`, one row per dataset describing the fit.

## Examples

``` r
if (requireNamespace("tna", quietly = TRUE)) {
  head(simulate_tna_batches(
    repetitions = 2, model = "tna", n = 20, n_states = 3, chain_length = 10, seed = 1
  ))

  # One network with no arguments, recovered against its own truth.
  network <- simulate_tna_batches(seed = 1)
  head(validate_recovery(network, network, term = "to", estimate = "weight"))
}
#>   dataset      from      term   estimate      truth         bias absolute_error
#> 1       1   Analyze   Analyze 0.56750572 0.55310055  0.014405175    0.014405175
#> 2       1 Elaborate   Analyze 0.05590062 0.07754096 -0.021640340    0.021640340
#> 3       1     Learn   Analyze 0.04237288 0.03569030  0.006682582    0.006682582
#> 4       1      Plan   Analyze 0.22473868 0.22135308  0.003385591    0.003385591
#> 5       1   Reflect   Analyze 0.13363029 0.11264179  0.020988504    0.020988504
#> 6       1   Analyze Elaborate 0.12356979 0.12152212  0.002047676    0.002047676
#>   relative_error recovered
#> 1     0.02604441      TRUE
#> 2    -0.27908269      TRUE
#> 3     0.18723806      TRUE
#> 4     0.01529498      TRUE
#> 5     0.18632964      TRUE
#> 6     0.01685024      TRUE
```
