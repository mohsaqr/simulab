# Compare multiple TNA estimators on the same sequences

Compare multiple TNA estimators on the same sequences

## Usage

``` r
compare_tna_models(
  data,
  models = c("tna", "ftna", "ctna", "atna"),
  format = c("auto", "long", "wide"),
  id = "id",
  period = "period",
  state = "state",
  group = NULL,
  ...
)
```

## Arguments

- data:

  Sequence data accepted by
  [`fit_tna()`](https://mohsaqr.github.io/simulab/reference/fit_tna.md).

- models:

  One or more TNA model types.

- format, id, period, state, group:

  Input arguments passed to
  [`fit_tna()`](https://mohsaqr.github.io/simulab/reference/fit_tna.md).

- ...:

  Estimator arguments.

## Value

A tidy edge-list `simulab_sim` base `data.frame` with one row per
model/group/edge and columns `model`, `from`, `to`, and `weight` (with
`group` inserted when `group` is supplied). A stacked `model_info`
table, one row per fitted model and group, is available through
[`as.data.frame()`](https://rdrr.io/r/base/as.data.frame.html). The
fitted native models are stored as a named list and returned by
[`as_tna_model()`](https://mohsaqr.github.io/simulab/reference/as_tna_model.md).

## Examples

``` r
data <- simulate_sequences(n = 40, n_states = 3, chain_length = 12, seed = 1)
if (requireNamespace("tna", quietly = TRUE)) {
  compare_tna_models(data, models = c("tna", "ftna"))
}
```
