# Build a replicated scenario grid

Crosses every combination of the supplied scenario values and repeats
each combination `replications` times, giving the grid a simulation
study is run over.

## Usage

``` r
scenario_grid(..., replications = 1L, id = "scenario_id")
```

## Arguments

- ...:

  Named vectors of scenario values, at least one, crossed with
  [`expand.grid()`](https://rdrr.io/r/base/expand.grid.html). The names
  become the value columns.

- replications:

  Replications per scenario combination. A single positive whole number,
  defaulting to `1`.

- id:

  Name of the scenario identifier, numbering the distinct combinations.
  A single non-empty string, defaulting to `"scenario_id"`.

## Value

A plain base `data.frame`, not a `simulab_sim`, with one row per
scenario replication and columns: the scenario identifier named by `id`,
the integer `replication` counting from 1 within each scenario, and one
column per named argument.

## Examples

``` r
scenario_grid(mean_b = c(0, 0.5), n_b = c(20, 40), replications = 2)
#>   scenario_id replication mean_b n_b
#> 1           1           1    0.0  20
#> 2           1           2    0.0  20
#> 3           2           1    0.5  20
#> 4           2           2    0.5  20
#> 5           3           1    0.0  40
#> 6           3           2    0.0  40
#> 7           4           1    0.5  40
#> 8           4           2    0.5  40
```
