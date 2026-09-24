# Cross-validate TNA estimators

Each iteration splits the sequences once into a training and a testing
set, fits every estimator to both halves, and compares the two networks
with
[`compare_networks()`](https://mohsaqr.github.io/simulab/reference/compare_networks.md).

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
  [`fit_tna()`](https://mohsaqr.github.io/simulab/reference/fit_tna.md).

## Value

A plain base `data.frame` with one row per iteration and estimator and
the columns `iteration`, `model`, and the
[`compare_networks()`](https://mohsaqr.github.io/simulab/reference/compare_networks.md)
agreement metrics `pearson`, `cosine`, `mae`, `rmse`, `jaccard`,
`edges_x` and `edges_y`. This is not a `simulab_sim`.

## Examples

``` r
data <- simulate_sequences(n = 60, n_states = 3, chain_length = 12, seed = 1)
if (requireNamespace("tna", quietly = TRUE)) {
  cross_validate_tna(data, models = c("tna", "ftna"), iterations = 2, seed = 1)
}
#>   iteration model   pearson    cosine         mae        rmse   jaccard edges_x
#> 1         1   tna 0.9923218 0.9950624  0.03939268  0.04322439 1.0000000       9
#> 2         1  ftna 0.9916963 0.9945819 29.33333333 32.80582604 1.0000000       9
#> 3         2   tna 0.9780752 0.9925225  0.04101001  0.04970991 0.8888889       9
#> 4         2  ftna 0.9688537 0.9905214 29.33333333 33.89854143 0.8888889       9
#>   edges_y
#> 1       9
#> 2       9
#> 3       8
#> 4       8
```
