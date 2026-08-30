# List built-in simulation scenarios

List built-in simulation scenarios

## Usage

``` r
simulation_scenarios()
```

## Value

A base `data.frame` with scenario, family, and description.

## Examples

``` r
simulation_scenarios()
#>             scenario       family
#> 1       small_effect  statistical
#> 2       large_effect  statistical
#> 3    clustered_trial   multilevel
#> 4             growth longitudinal
#> 5 learning_sequences     sequence
#> 6          group_tna     sequence
#>                                              description
#> 1            Two groups with Cohen's d approximately 0.2
#> 2            Two groups with Cohen's d approximately 0.8
#> 3             Clustered outcome with treatment predictor
#> 4                            Five-occasion linear growth
#> 5 Learning-state sequences with probability perturbation
#> 6               Three grouped TNA learning-state systems
```
