# Fit TNA models to multiple datasets

Fit TNA models to multiple datasets

## Usage

``` r
fit_tna_batch(inputs, ...)
```

## Arguments

- inputs:

  List of sequence data frames, with at least one element. Element names
  label the datasets; when `inputs` is unnamed the labels `"Dataset 1"`,
  `"Dataset 2"`, ... are used instead.

- ...:

  Arguments passed to
  [`fit_tna()`](https://pak.dynasite.org/simulab/reference/fit_tna.md).

## Value

A `simulab_sim` edge list with one row per dataset and transition: a
leading `dataset` column followed by the columns
[`fit_tna()`](https://pak.dynasite.org/simulab/reference/fit_tna.md)
returns (`from`, `to`, `weight`, and `group` when a grouped fit is
requested). The `model_info` component holds one row per dataset
describing the fitted model.

## Examples

``` r
inputs <- list(
  first = simulate_sequences(n = 30, n_states = 3, chain_length = 10, seed = 1),
  second = simulate_sequences(n = 30, n_states = 3, chain_length = 10, seed = 2)
)
if (requireNamespace("tna", quietly = TRUE)) {
  head(fit_tna_batch(inputs, model = "tna"))
}
#> <simulab_sim:tna_batch> 6 rows x 4 columns
#>         dataset    from    to     weight
#> first.1   first   Learn Learn 0.56849315
#> first.2   first    Plan Learn 0.23809524
#> first.3   first Reflect Learn 0.86585366
#> first.4   first   Learn  Plan 0.04794521
#> first.5   first    Plan  Plan 0.21428571
#> first.6   first Reflect  Plan 0.08536585
#> 
#> Other tables: model_info. Read one with as.data.frame(x, what = "model_info").
```
