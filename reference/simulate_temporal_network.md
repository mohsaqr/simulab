# Simulate a temporal network as edge-activity spells

Simulate a temporal network as edge-activity spells

## Usage

``` r
simulate_temporal_network(
  nodes,
  periods,
  initial_probability = 0.1,
  formation_probability = 0.05,
  dissolution_probability = 0.1,
  directed = TRUE,
  loops = FALSE,
  weight = c("binary", "uniform", "normal", "poisson"),
  weight_mean = 1,
  weight_sd = 1,
  weight_range = c(0.1, 1),
  node_type = NULL,
  seed = NULL
)
```

## Arguments

- nodes:

  Number of nodes or unique node labels.

- periods:

  Number of discrete observation periods.

- initial_probability:

  Probability that a dyad is active initially.

- formation_probability:

  Probability that an inactive dyad forms at the next period.

- dissolution_probability:

  Probability that an active dyad dissolves at the next period.

- directed:

  Generate directed dyads.

- loops:

  Permit self-loops.

- weight:

  Edge-spell weight distribution.

- weight_mean, weight_sd, weight_range:

  Weight parameters.

- node_type:

  Optional node type for each node.

- seed:

  Optional seed.

## Value

A tidy spell-level `simulab_sim` with `from`, `to`, `onset`, `terminus`,
`weight`, and `censored`. Event and snapshot edge lists are available as
components.

## Examples

``` r
result <- simulate_temporal_network(
  nodes = 20, periods = 4, initial_probability = 0.1, seed = 1
)
head(result)
#> <simulab_sim:temporal_network> 6 rows x 6 columns
#>      from     to onset terminus weight censored
#> 1  Node 5 Node 1     1        5      1     TRUE
#> 2  Node 8 Node 1     1        5      1     TRUE
#> 3 Node 14 Node 1     2        5      1     TRUE
#> 4 Node 18 Node 1     2        3      1    FALSE
#> 5 Node 19 Node 1     1        5      1     TRUE
#> 6  Node 3 Node 2     1        3      1    FALSE
components(result)
#>       table rows columns
#> 1      data   94       6
#> 2    events  117       5
#> 3 snapshots  225       4
#> 4     nodes   20       2
#> 5  settings    1       7
```
