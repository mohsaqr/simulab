# Summarize simulated numeric variables

Summarize simulated numeric variables

## Usage

``` r
summarize_simulations(data, by = NULL, variables = NULL)
```

## Arguments

- data:

  Simulation data: a `simulab_sim` or a plain base `data.frame`.

- by:

  Optional character vector of grouping column names. `NULL`, the
  default, summarizes all rows together.

- variables:

  Character vector of numeric variables to summarize. `NULL`, the
  default, selects every numeric non-grouping column.

## Value

A plain base `data.frame` with one row per group and variable: the `by`
columns (or a single `.group` column holding `"all"` when `by` is
`NULL`), then `variable`, `observations` (the non-missing count),
`mean`, `sd`, `minimum` and `maximum`.

## Examples

``` r
data <- simulate_ttest(n_a = 50, n_b = 50, mean_a = 0, mean_b = 0.6, seed = 1)
summarize_simulations(data, by = "group", variables = "outcome")
#>   group variable observations      mean        sd   minimum  maximum
#> A     A  outcome           50 0.1004483 0.8313939 -2.214700 1.595281
#> B     B  outcome           50 0.7173265 0.9688279 -1.204959 3.001618
```
