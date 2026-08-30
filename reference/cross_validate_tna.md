# Cross-validate TNA estimators

Cross-validate TNA estimators

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

  Sequence data.

- models:

  TNA estimators.

- iterations:

  Number of splits.

- training_fraction:

  Training fraction.

- format, id, period, state:

  Input-format arguments.

- seed:

  Optional seed.

- ...:

  Estimator arguments.

## Value

A tidy base `data.frame` of train/test network agreement metrics.

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
