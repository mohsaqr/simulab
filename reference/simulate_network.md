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

  Number of nodes or node labels. A single number produces the integer
  labels `1:nodes`.

- model:

  Graph model. Every model except `bernoulli` requires the suggested
  `igraph` package.

- probability:

  Bernoulli edge probability, node matrix, or type matrix. A matrix may
  instead be given as a tidy data frame with columns `from`, `to` and
  `probability`. Used by the `bernoulli` model only; the `block` model
  uses `within_probability` and `between_probability` instead.

- edges:

  Exact edge count for the fixed-edge Bernoulli model, capped at the
  number of admissible dyads.

- directed:

  Generate directed edges. Ignored by the `small_world` and `geometric`
  models, which are always undirected; the `directed` column of the
  `settings` table reports what was actually generated.

- loops:

  Permit self-loops.

- weight:

  Edge-weight distribution.

- weight_mean, weight_sd, weight_range:

  Weight parameters.

- node_type:

  Optional type label for each node. With more than one type it also
  supplies the block membership used by the `block` model.

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

A tidy edge-list `simulab_sim` base `data.frame` with one row per edge
and columns `from`, `to`, `weight` (plus `edge_class` when
`edge_classes` is supplied). `as.data.frame(x, what = )` also returns
`nodes` (`node`, `type`), `adjacency` (a long `row`/`column`/`weight`
table covering all `nodes^2` ordered pairs, symmetric when the generated
graph is undirected), and a one-row `settings` table. Use
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
# geometric and forest_fire. These require the suggested igraph package.
if (requireNamespace("igraph", quietly = TRUE)) {
  head(simulate_network(nodes = 60, model = "small_world", neighbors = 2, seed = 1))
}
```
