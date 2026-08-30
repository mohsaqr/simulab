# Fit TNA models to multiple datasets

Fit TNA models to multiple datasets

## Usage

``` r
fit_tna_batch(inputs, ...)
```

## Arguments

- inputs:

  Named list of sequence data frames.

- ...:

  Arguments passed to
  [`fit_tna()`](https://mohsaqr.github.io/simulab/reference/fit_tna.md).

## Value

A tidy edge-list `simulab_sim` with dataset/model metadata.

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
