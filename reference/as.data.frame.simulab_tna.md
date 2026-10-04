# Tidy tables of a simulated transition network

Tidy tables of a simulated transition network

## Usage

``` r
# S3 method for class 'simulab_tna'
as.data.frame(x, row.names = NULL, optional = FALSE, what = "edges", ...)
```

## Arguments

- x:

  A `simulab_tna` result of
  [`simulate_tna()`](https://pak.dynasite.org/simulab/reference/simulate_tna.md).

- row.names, optional:

  Ignored; present for the generic.

- what:

  Table to return: `"edges"` (the default, the fitted network),
  `"transitions"`, `"initial_probabilities"`, `"sequences"`, `"wide"` or
  `"model_info"`.

- ...:

  Ignored.

## Value

A base `data.frame`. `"edges"` has one row per edge with columns `from`,
`to` and `weight`; `"transitions"` one row per edge with columns `from`,
`to` and `probability`; `"initial_probabilities"` one row per state with
columns `state` and `probability`; `"sequences"` one row per sequence
and position with columns `id`, `period` and `state`.

## Examples

``` r
if (requireNamespace("tna", quietly = TRUE)) {
  network <- simulate_tna(n = 30, n_states = 3, seed = 1)
  as.data.frame(network)
  as.data.frame(network, what = "transitions")
}
#>      from      to probability
#> 1 Reflect Reflect  0.06261118
#> 2   Learn Reflect  0.42158819
#> 3    Plan Reflect  0.66416516
#> 4 Reflect   Learn  0.86660136
#> 5   Learn   Learn  0.49915316
#> 6    Plan   Learn  0.16698516
#> 7 Reflect    Plan  0.07078746
#> 8   Learn    Plan  0.07925865
#> 9    Plan    Plan  0.16884968
```
