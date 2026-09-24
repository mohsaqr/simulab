# Evaluate TNA estimation against generated truth

Draws a transition system per replication, simulates sequences from it,
fits each estimator in `models`, and scores the fitted edges against the
generating probabilities. Fitted weights are row-normalized before the
comparison, so estimators on different weight scales are all read as
transition probabilities.

## Usage

``` r
evaluate_tna_estimation(
  repetitions = 100L,
  n = 200L,
  chain_length = 25L,
  n_states = 6L,
  models = c("tna", "ftna", "ctna", "atna"),
  concentration = 1,
  diagonal_concentration = 0,
  missing_tail = c(0L, 5L),
  threshold = 0,
  seed = NULL,
  ...
)
```

## Arguments

- repetitions:

  Number of simulation replications. A single positive whole number,
  defaulting to `100`.

- n:

  Number of sequences per replication. A single whole number of at least
  2, defaulting to `200`.

- chain_length:

  Sequence length. A single whole number of at least 2, defaulting to
  `25`.

- n_states:

  Number of states. A single whole number of at least 2, defaulting to
  `6`.

- models:

  TNA estimators to evaluate. A character vector of at least one of
  `"tna"`, `"ftna"`, `"ctna"` and `"atna"`, all four by default.

- concentration, diagonal_concentration:

  Transition-system parameters passed to
  [`generate_transition_system()`](https://mohsaqr.github.io/simulab/reference/generate_transition_system.md),
  defaulting to `1` and `0`.

- missing_tail:

  Trailing missing positions passed to
  [`simulate_sequences()`](https://mohsaqr.github.io/simulab/reference/simulate_sequences.md),
  defaulting to `c(0L, 5L)`.

- threshold:

  Absolute weight threshold above which an edge counts as present, in
  both the agreement and the recovery metrics. A single non-negative
  number, defaulting to `0`.

- seed:

  Optional base seed. A single number, or `NULL` (the default).
  Replication `i` draws its transition system with `seed + i - 1` and
  its sequences with that offset plus `100000`.

- ...:

  Arguments passed to
  [`fit_tna()`](https://mohsaqr.github.io/simulab/reference/fit_tna.md).

## Value

A `simulab_sim` base `data.frame` with one row per replication and
model, holding `iteration`, `model`, the
[`compare_networks()`](https://mohsaqr.github.io/simulab/reference/compare_networks.md)
agreement metrics and the
[`evaluate_edge_recovery()`](https://mohsaqr.github.io/simulab/reference/evaluate_edge_recovery.md)
summary. Components: `truth`, the generating probabilities with columns
`iteration`, `from`, `to` and `weight`; and `estimated_edges`, the
row-normalized fitted edges with columns `iteration`, `model`, `from`,
`to` and `weight`.

## Examples

``` r
if (requireNamespace("tna", quietly = TRUE)) {
  evaluate_tna_estimation(
    repetitions = 2, n = 30, chain_length = 10, n_states = 3,
    models = "tna", seed = 1
  )
}
#> <simulab_sim:tna_estimation> 2 rows x 15 columns
#>   iteration model   pearson    cosine        mae       rmse   jaccard edges_x
#> 1         1   tna 0.9873226 0.9963721 0.02853191 0.03352190 1.0000000       9
#> 2         2   tna 0.9812276 0.9906651 0.04997134 0.06423688 0.8888889       9
#>   edges_y precision    recall        f1 true_positive false_positive
#> 1       9         1 1.0000000 1.0000000             9              0
#> 2       8         1 0.8888889 0.9411765             8              0
#>   false_negative
#> 1              0
#> 2              1
```
