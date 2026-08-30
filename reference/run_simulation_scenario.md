# Run a built-in simulation scenario

Run a built-in simulation scenario

## Usage

``` r
run_simulation_scenario(scenario, seed = NULL)
```

## Arguments

- scenario:

  Scenario from
  [`simulation_scenarios()`](https://mohsaqr.github.io/simulab/reference/simulation_scenarios.md).

- seed:

  Optional seed.

## Value

A `simulab_sim` result.

## Examples

``` r
result <- run_simulation_scenario("small_effect", seed = 1)
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
