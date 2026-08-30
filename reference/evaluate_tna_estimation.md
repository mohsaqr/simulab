# Evaluate TNA estimation against generated truth

Evaluate TNA estimation against generated truth

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

  Number of simulation replications.

- n:

  Number of sequences per replication.

- chain_length:

  Sequence length.

- n_states:

  Number of states.

- models:

  TNA estimators to evaluate.

- concentration, diagonal_concentration:

  Transition-system parameters.

- missing_tail:

  Trailing missing positions passed to
  [`simulate_sequences()`](https://mohsaqr.github.io/simulab/reference/simulate_sequences.md).

- threshold:

  Edge-presence threshold for recovery metrics.

- seed:

  Optional base seed.

- ...:

  Arguments passed to
  [`fit_tna()`](https://mohsaqr.github.io/simulab/reference/fit_tna.md).

## Value

A tidy `simulab_sim` of replication/model agreement metrics, with
generated truth and estimated edges as components.

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
