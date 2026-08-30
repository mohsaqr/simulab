# Simulate and fit repeated TNA networks

Simulate and fit repeated TNA networks

## Usage

``` r
simulate_tna_batches(
  repetitions,
  model = c("tna", "ftna", "ctna", "atna"),
  ...,
  seed = NULL
)
```

## Arguments

- repetitions:

  Number of fitted networks.

- model:

  TNA estimator.

- ...:

  Arguments passed to
  [`simulate_sequences()`](https://mohsaqr.github.io/simulab/reference/simulate_sequences.md).

- seed:

  Optional base seed. Each dataset uses a deterministic offset.

## Value

A tidy fitted-edge `simulab_sim` with network identifiers; generated
sequences and true transitions are available as components.

## Examples

``` r
if (requireNamespace("tna", quietly = TRUE)) {
  head(simulate_tna_batches(
    repetitions = 2, model = "tna", n = 20, n_states = 3, chain_length = 10, seed = 1
  ))
}
#> <simulab_sim:tna_batches> 6 rows x 4 columns
#>     network    from      to     weight
#> 1.1       1 State 1 State 1 0.03225806
#> 1.2       1 State 2 State 1 0.55263158
#> 1.3       1 State 3 State 1 0.54761905
#> 1.4       1 State 1 State 2 0.50000000
#> 1.5       1 State 2 State 2 0.34210526
#> 1.6       1 State 3 State 2 0.45238095
```
