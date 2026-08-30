# Run a simulator across a scenario grid

Scenario columns are matched to simulator arguments. Identifier and
replication columns are added to each generated observation, which makes
the result immediately suitable for grouped estimation and recovery
checks.

## Usage

``` r
simulate_scenarios(
  scenarios,
  simulator,
  ...,
  id = "scenario_id",
  replication = "replication",
  seed = NULL
)
```

## Arguments

- scenarios:

  A base `data.frame`, commonly from
  [`scenario_grid()`](https://mohsaqr.github.io/simulab/reference/scenario_grid.md).

- simulator:

  Canonical simulator name from
  [`list_simulators()`](https://mohsaqr.github.io/simulab/reference/list_simulators.md).

- ...:

  Arguments held constant across scenarios.

- id:

  Scenario identifier column.

- replication:

  Replication column.

- seed:

  Optional base seed. Each row receives a deterministic offset.

## Value

A combined `simulab_sim` base `data.frame`; the scenario grid is a
secondary component.

## Examples

``` r
scenarios <- scenario_grid(mean_b = c(0, 0.5), replications = 2)
result <- simulate_scenarios(
  scenarios, simulator = "ttest",
  n_a = 20, n_b = 20, mean_a = 0, seed = 1
)
head(result)
#> <simulab_sim:scenarios> 6 rows x 5 columns
#>   scenario_id replication id group    outcome
#> 1           1           1  1     A -0.6264538
#> 2           1           1  2     A  0.1836433
#> 3           1           1  3     A -0.8356286
#> 4           1           1  4     A  1.5952808
#> 5           1           1  5     A  0.3295078
#> 6           1           1  6     A -0.8204684
```
