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
  [`fit_tna()`](https://pak.dynasite.org/simulab/reference/fit_tna.md).

- models:

  One or more TNA model types.

- format, id, period, state, group:

  Input arguments passed to
  [`fit_tna()`](https://pak.dynasite.org/simulab/reference/fit_tna.md).

- ...:

  Estimator arguments.

## Value

A tidy edge-list `simulab_sim` base `data.frame` with one row per
model/group/edge and columns `model`, `from`, `to`, and `weight` (with
`group` inserted when `group` is supplied). A stacked `model_info`
table, one row per fitted model and group, is available through
[`as.data.frame()`](https://rdrr.io/r/base/as.data.frame.html). The
fitted native models are stored as a named list and returned by
[`as_tna_model()`](https://pak.dynasite.org/simulab/reference/as_tna_model.md).

## Examples

``` r
data <- simulate_sequences(n = 40, n_states = 3, chain_length = 12, seed = 1)
if (requireNamespace("tna", quietly = TRUE)) {
  compare_tna_models(data, models = c("tna", "ftna"))
}
#> <simulab_sim:tna_comparison> 18 rows x 4 columns
#>    model    from      to       weight
#> 1    tna   Learn   Learn   0.53112033
#> 2    tna    Plan   Learn   0.17187500
#> 3    tna Reflect   Learn   0.90370370
#> 4    tna   Learn    Plan   0.10788382
#> 5    tna    Plan    Plan   0.17187500
#> 6    tna Reflect    Plan   0.03703704
#> 7    tna   Learn Reflect   0.36099585
#> 8    tna    Plan Reflect   0.65625000
#> 9    tna Reflect Reflect   0.05925926
#> 10  ftna   Learn   Learn 128.00000000
#> ... 8 more rows
#> 
#> Other tables: model_info. Read one with as.data.frame(x, what = "model_info").
```
