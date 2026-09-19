# Run a simulator across a scenario grid

Every column of `scenarios` other than `id` and `replication` is passed
to the simulator as a named argument, so the column names must be
simulator argument names and must not repeat an argument given in `...`.
The identifier and replication values are prepended to each generated
observation, which makes the result immediately suitable for grouped
estimation and recovery checks. Every scenario must produce the same
primary columns, otherwise the run is an error.

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

  A base `data.frame` with at least one row, commonly from
  [`scenario_grid()`](https://mohsaqr.github.io/simulab/reference/scenario_grid.md),
  containing the `id` and `replication` columns.

- simulator:

  Canonical simulator name, taken from the `simulator` column of
  [`list_simulators()`](https://mohsaqr.github.io/simulab/reference/list_simulators.md)
  and dispatched through
  [`simulate_data()`](https://mohsaqr.github.io/simulab/reference/simulate_data.md).

- ...:

  Arguments held constant across scenarios.

- id:

  Single string naming the scenario identifier column of `scenarios`,
  default `"scenario_id"`.

- replication:

  Single string naming the replication column of `scenarios`, default
  `"replication"`.

- seed:

  Optional single base seed. Row `i` of `scenarios` is simulated with
  `seed + i - 1`, unless `scenarios` or `...` already supplies a `seed`.

## Value

A `simulab_sim` base `data.frame` stacking every scenario's output, with
one row per generated observation: the `id` and `replication` columns
first, then the simulator's own columns. The `scenarios` component holds
the grid that was run, one row per scenario.

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
