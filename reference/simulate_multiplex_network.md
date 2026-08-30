# Simulate a multiplex network

Simulate a multiplex network

## Usage

``` r
simulate_multiplex_network(
  nodes,
  layers,
  edges = NULL,
  probability = 0.1,
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

  Number of nodes or unique labels shared across layers.

- layers:

  Number of layers or unique layer labels.

- edges:

  Optional exact edge count, scalar or one value per layer.

- probability:

  Edge probability, scalar or one value per layer.

- directed:

  Generate directed edges.

- loops:

  Permit self-loops.

- weight:

  Edge-weight distribution.

- weight_mean, weight_sd, weight_range:

  Weight parameters.

- node_type:

  Optional node type for each node.

- seed:

  Optional base seed; layers use deterministic offsets.

## Value

A tidy layered edge-list `simulab_sim` with `layer`, `from`, `to`, and
`weight`; nodes, layers, adjacency, and settings are components.

## Examples

``` r
result <- simulate_multiplex_network(nodes = 25, layers = 3, probability = 0.1, seed = 1)
head(result)
#> <simulab_sim:multiplex_network> 6 rows x 4 columns
#>     layer    from     to weight
#> 1 Layer 1  Node 5 Node 1      1
#> 2 Layer 1  Node 8 Node 1      1
#> 3 Layer 1 Node 19 Node 1      1
#> 4 Layer 1 Node 22 Node 1      1
#> 5 Layer 1 Node 14 Node 3      1
#> 6 Layer 1  Node 9 Node 4      1
components(result)
#>       table rows columns
#> 1      data  182       4
#> 2     nodes   25       2
#> 3    layers    3       2
#> 4 adjacency 1875       4
#> 5  settings    1       4
```
