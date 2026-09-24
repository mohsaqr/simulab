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
#> <simulab_sim:tna_batch> 6 rows x 4 columns
#>         dataset    from      to    weight
#> first.1   first State 1 State 1 0.0600000
#> first.2   first State 2 State 1 0.5500000
#> first.3   first State 3 State 1 0.6285714
#> first.4   first State 1 State 2 0.4100000
#> first.5   first State 2 State 2 0.3300000
#> first.6   first State 3 State 2 0.3428571
```
