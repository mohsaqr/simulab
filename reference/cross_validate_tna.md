# Cross-validate TNA estimators

Each iteration splits the sequences once into a training and a testing
set, fits every estimator to both halves, and compares the two networks
with
[`compare_networks()`](https://pak.dynasite.org/simulab/reference/compare_networks.md).

## Usage

``` r
cross_validate_tna(
  data,
  models = c("tna", "ftna", "ctna", "atna"),
  iterations = 20L,
  training_fraction = 0.7,
  format = c("auto", "long", "wide"),
  id = "id",
  period = "period",
  state = "state",
  seed = NULL,
  ...
)
```

## Arguments

- data:

  Sequence data in long or wide form.

- models:

  Character vector of TNA estimators to compare, any of `"tna"`,
  `"ftna"`, `"ctna"`, `"atna"`. The default runs all four.

- iterations:

  Number of train/test splits, a whole number of at least 1, default
  `20`.

- training_fraction:

  Fraction of sequences assigned to the training half, strictly between
  0 and 1, default `0.7`. At least two training sequences are always
  used, and a split leaving fewer than two testing sequences is an
  error.

- format, id, period, state:

  Arguments describing the shape and column names of `data`. They are
  used to reshape `data` before splitting; both halves are then fitted
  in wide form.

- seed:

  Optional single seed, restored on exit.

- ...:

  Further arguments passed to
  [`fit_tna()`](https://pak.dynasite.org/simulab/reference/fit_tna.md).

## Value

A plain base `data.frame` with one row per iteration and estimator and
the columns `iteration`, `model`, and the
[`compare_networks()`](https://pak.dynasite.org/simulab/reference/compare_networks.md)
agreement metrics `pearson`, `cosine`, `mae`, `rmse`, `jaccard`,
`edges_x` and `edges_y`. This is not a `simulab_sim`.

## Examples

``` r
data <- simulate_sequences(n = 60, n_states = 3, chain_length = 12, seed = 1)
if (requireNamespace("tna", quietly = TRUE)) {
  cross_validate_tna(data, models = c("tna", "ftna"), iterations = 2, seed = 1)
}
#>   iteration model   pearson    cosine         mae        rmse   jaccard edges_x
#> 1         1   tna 0.9838410 0.9929185  0.04560538  0.05282897 0.8888889       9
#> 2         1  ftna 0.9832673 0.9917742 29.77777778 42.07664963 0.8888889       9
#> 3         2   tna 0.9903498 0.9954154  0.03047942  0.04354214 1.0000000       9
#> 4         2  ftna 0.9929774 0.9947696 29.33333333 43.53542619 1.0000000       9
#>   edges_y
#> 1       8
#> 2       8
#> 3       9
#> 4       9
```
