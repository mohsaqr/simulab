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
  [`fit_tna()`](https://mohsaqr.github.io/simulab/reference/fit_tna.md).

## Value

A `simulab_sim` edge list with one row per dataset and transition: a
leading `dataset` column followed by the columns
[`fit_tna()`](https://mohsaqr.github.io/simulab/reference/fit_tna.md)
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
```
