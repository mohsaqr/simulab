# Simulate a network from common graph models

Simulate a network from common graph models

## Usage

``` r
simulate_network(
  nodes,
  model = c("bernoulli", "barabasi_albert", "small_world", "block", "regular",
    "geometric", "forest_fire"),
  probability = 0.1,
  edges = NULL,
  directed = TRUE,
  loops = FALSE,
  weight = c("binary", "uniform", "normal", "poisson"),
  weight_mean = 1,
  weight_sd = 1,
  weight_range = c(0.1, 1),
  node_type = NULL,
  edge_classes = NULL,
  class_probabilities = NULL,
  attachment = 2L,
  power = 1,
  neighbors = 2L,
  rewire = 0.05,
  blocks = 3L,
  within_probability = 0.3,
  between_probability = 0.05,
  degree = 4L,
  radius = 0.25,
  forward_probability = 0.35,
  backward_probability = 0.32,
  seed = NULL
)
```

## Arguments

- nodes:

  Number of nodes or node labels.

- model:

  Graph model.

- probability:

  Bernoulli edge probability, node matrix, or type matrix. A matrix may
  instead be given as a tidy data frame with columns `from`, `to` and
  `probability`.

- edges:

  Exact edge count for the fixed-edge Bernoulli model.

- directed:

  Generate directed edges.

- loops:

  Permit self-loops.

- weight:

  Edge-weight distribution.

- weight_mean, weight_sd, weight_range:

  Weight parameters.

- node_type:

  Optional type label for each node.

- edge_classes:

  Optional number or labels of edge classes.

- class_probabilities:

  Optional edge-class probabilities.

- attachment, power:

  Preferential-attachment parameters.

- neighbors, rewire:

  Small-world parameters.

- blocks, within_probability, between_probability:

  Block-model parameters.

- degree:

  Regular-graph degree.

- radius:

  Geometric-graph connection radius.

- forward_probability, backward_probability:

  Forest-fire parameters.

- seed:

  Optional random seed.

## Value

A tidy edge-list `simulab_sim`; nodes, adjacency, and generation
settings are components. Use
[`as_igraph()`](https://mohsaqr.github.io/simulab/reference/as_igraph.md)
for native graph workflows.

## Examples

``` r
result <- simulate_network(
  nodes = 60, model = "bernoulli", probability = 0.06, seed = 1
)
head(result)
#> <simulab_sim:network> 6 rows x 3 columns
#>   from to weight
#> 1    8  1      1
#> 2   19  1      1
#> 3   22  2      1
#> 4   46  2      1
#> 5   53  2      1
#> 6    4  3      1
components(result)
#>       table rows columns
#> 1      data  228       3
#> 2     nodes   60       2
#> 3 adjacency 3600       3
#> 4  settings    1       6

# Other generators: barabasi_albert, small_world, block, regular,
# geometric and forest_fire.
head(simulate_network(nodes = 60, model = "small_world", neighbors = 2, seed = 1))
#> <simulab_sim:network> 6 rows x 3 columns
#>   from to weight
#> 1    1  2      1
#> 2    1  3      1
#> 3    1 59      1
#> 4    1 60      1
#> 5    2  3      1
#> 6    2  4      1
```
