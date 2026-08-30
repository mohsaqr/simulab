# Summarize simulated numeric variables

Summarize simulated numeric variables

## Usage

``` r
summarize_simulations(data, by = NULL, variables = NULL)
```

## Arguments

- data:

  Simulation data.

- by:

  Optional grouping columns.

- variables:

  Numeric variables. `NULL` selects all numeric non-grouping columns.

## Value

A tidy base `data.frame` of variable/group summaries.

## Examples

``` r
data <- simulate_ttest(n_a = 50, n_b = 50, mean_a = 0, mean_b = 0.6, seed = 1)
summarize_simulations(data, by = "group", variables = "outcome")
#>   group variable observations      mean        sd   minimum  maximum
#> A     A  outcome           50 0.1004483 0.8313939 -2.214700 1.595281
#> B     B  outcome           50 0.7173265 0.9688279 -1.204959 3.001618
```
