# Build a replicated scenario grid

Build a replicated scenario grid

## Usage

``` r
scenario_grid(..., replications = 1L, id = "scenario_id")
```

## Arguments

- ...:

  Named vectors of scenario values.

- replications:

  Replications per scenario combination.

- id:

  Name of the scenario identifier.

## Value

A base `data.frame` with one row per scenario replication.

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
