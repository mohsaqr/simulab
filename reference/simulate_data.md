# Simulate data through the unified catalogue

`simulate_data()` is a discoverable dispatcher. Direct verbs remain the
preferred interface because they provide explicit, documented arguments.

## Usage

``` r
simulate_data(type, ...)
```

## Arguments

- type:

  Simulator name from
  [`list_simulators()`](https://mohsaqr.github.io/simulab/reference/list_simulators.md).

- ...:

  Arguments passed to the selected canonical simulation verb.

## Value

A `simulab_sim` base `data.frame`.

## Examples

``` r
result <- simulate_data("ttest", n_a = 30, n_b = 30, mean_a = 0, mean_b = 0.5, seed = 1)
head(result)
#> <simulab_sim:ttest> 6 rows x 3 columns
#>   id group    outcome
#> 1  1     A -0.6264538
#> 2  2     A  0.1836433
#> 3  3     A -0.8356286
#> 4  4     A  1.5952808
#> 5  5     A  0.3295078
#> 6  6     A -0.8204684
```
