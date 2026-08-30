# Fit TNA to a sequence sample

Fit TNA to a sequence sample

## Usage

``` r
sample_tna(data, fraction = 0.3, replace = FALSE, seed = NULL, ...)
```

## Arguments

- data:

  Sequence data.

- fraction:

  Sampling fraction.

- replace:

  Sample with replacement.

- seed:

  Optional seed.

- ...:

  Arguments passed to
  [`fit_tna()`](https://mohsaqr.github.io/simulab/reference/fit_tna.md).

## Value

A tidy fitted TNA result.

## Examples

``` r
data <- simulate_sequences(n = 40, n_states = 3, chain_length = 12, seed = 1)
if (requireNamespace("tna", quietly = TRUE)) {
  head(sample_tna(data, fraction = 0.5, seed = 1))
}
#> <simulab_sim:tna_model> 6 rows x 3 columns
#>      from      to    weight
#> 1 State 1 State 1 0.1411765
#> 2 State 2 State 1 0.5526316
#> 3 State 3 State 1 0.6440678
#> 4 State 1 State 2 0.3529412
#> 5 State 2 State 2 0.3289474
#> 6 State 3 State 2 0.3220339
```
