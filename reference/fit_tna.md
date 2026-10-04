# Fit a temporal network analysis model

Fit a temporal network analysis model

## Usage

``` r
fit_tna(
  data,
  model = c("tna", "ftna", "ctna", "atna"),
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

  Long- or wide-form sequence data.

- model:

  TNA, frequency TNA, co-occurrence TNA, or attention TNA.

- format:

  Input format. `auto` recognizes canonical long data.

- id, period, state:

  Canonical long-form column names.

- group:

  Optional grouping-column name. Supplying it fits a model per group
  through the corresponding grouped TNA estimator.

- ...:

  Additional arguments passed to the estimator in `tna`.

## Value

A tidy edge-list `simulab_sim` base `data.frame` with one row per
ordered state pair and columns `from`, `to`, and `weight`, prefixed by a
`group` column when `group` is supplied. For `model = "tna"` the weights
are the estimated transition probabilities and sum to one within each
`from` state; the other estimators return their own (not row-stochastic)
weights. `as.data.frame(x, what = )` also returns
`initial_probabilities` (`state`, `probability`) and `model_info`
(`model`, `grouped`, `group`, `observations`, `sequence_positions`). Use
[`as_tna_model()`](https://pak.dynasite.org/simulab/reference/as_tna_model.md)
when a native model object is required by `tna` plotting or inference
functions.

## Examples

``` r
data <- simulate_sequences(n = 40, n_states = 3, chain_length = 12, seed = 1)
if (requireNamespace("tna", quietly = TRUE)) {
  head(fit_tna(data, model = "tna"))
}
#> <simulab_sim:tna_model> 6 rows x 3 columns
#>      from    to     weight
#> 1   Learn Learn 0.53112033
#> 2    Plan Learn 0.17187500
#> 3 Reflect Learn 0.90370370
#> 4   Learn  Plan 0.10788382
#> 5    Plan  Plan 0.17187500
#> 6 Reflect  Plan 0.03703704
#> 
#> Other tables: initial_probabilities, model_info. Read one with as.data.frame(x, what = "initial_probabilities").
```
