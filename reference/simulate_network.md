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
  seed = NULL,
  batch = NULL
)
```

## Arguments

- nodes:

  Number of nodes or node labels. A single number produces the integer
  labels `1:nodes`.

- model:

  Graph model: `"bernoulli"` (the default; independent ties, Gilbert
  1959, or a stochastic block model when `probability` is a type
  matrix), `"barabasi_albert"` (preferential attachment),
  `"small_world"` (Watts-Strogatz rewiring of a ring lattice), `"block"`
  (stochastic block model), `"regular"` (every node of degree `degree`),
  `"geometric"` (random geometric graph in the unit square) or
  `"forest_fire"`. Every model except `bernoulli` requires the suggested
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

  Single logical. `TRUE` permits self-loops; defaults to `FALSE`.

- weight:

  Edge-weight distribution: `"binary"` (the default), every weight 1;
  `"uniform"` on `weight_range`; `"normal"` with `weight_mean` and
  `weight_sd`; or `"poisson"` with mean `weight_mean`.

- weight_mean, weight_sd, weight_range:

  Parameters of `weight`: the mean of normal and Poisson weights
  (default `1`), the standard deviation of normal weights (default `1`),
  and the lower and upper limits of uniform weights (default
  `c(0.1, 1)`). Unused by binary weights.

- node_type:

  Optional type label for each node. With more than one type it also
  supplies the block membership used by the `block` model.

- edge_classes:

  Optional number or labels of edge classes. Each edge is assigned one
  class at random, stored in the `edge_class` column; a single number
  `k` gives the labels `Class 1` to `Class k`.

- class_probabilities:

  Optional probabilities of the edge classes, one per class and summing
  to one. `NULL` (the default) makes them equal.

- attachment, power:

  Preferential-attachment parameters: the number of edges each new node
  adds (default `2`) and the power of the attachment (default `1`,
  linear in degree).

- neighbors, rewire:

  Small-world parameters: each node of the starting ring lattice is tied
  to the nodes within `neighbors` steps (default `2`), and each tie is
  rewired with probability `rewire` (default `0.05`).

- blocks, within_probability, between_probability:

  Block-model parameters: the number of blocks when `node_type` has
  fewer than two types (default `3`, nodes assigned to blocks in turn),
  and the tie probability within a block (default `0.3`) and between
  blocks (default `0.05`).

- degree:

  Degree of every node in the `regular` model, defaulting to `4`.

- radius:

  Connection radius of the `geometric` model, defaulting to `0.25`.
  Nodes placed uniformly in the unit square are tied when closer than
  `radius`.

- forward_probability, backward_probability:

  Forward burning probability (default `0.35`) and backward burning
  probability (default `0.32`) of the `forest_fire` model.

- seed:

  Optional random seed. A single number makes the call reproducible and
  restores the session's random-number state afterwards; `NULL` (the
  default) draws from the session's stream and advances it.

- batch:

  Optional single positive whole number. When given, the simulator runs
  `batch` times and returns a plain `list` of `batch` results, each
  exactly what the same call without `batch` returns. With a `seed`,
  every dataset gets its own seed drawn from `seed`, so the whole batch
  is reproducible; without one the datasets are consecutive draws from
  the session's random-number stream. The default `NULL` returns a
  single result.

## Value

A tidy edge-list `simulab_sim` base `data.frame` with one row per edge
and columns `from`, `to`, `weight` (plus `edge_class` when
`edge_classes` is supplied). `as.data.frame(x, what = )` also returns
`nodes` (`node`, `type`), `adjacency` (a long `row`/`column`/`weight`
table covering all `nodes^2` ordered pairs, symmetric when the generated
graph is undirected), and a one-row `settings` table. Use
[`as_igraph()`](https://pak.dynasite.org/simulab/reference/as_igraph.md)
for native graph workflows.

## References

Gilbert, E. N. (1959). Random graphs. *The Annals of Mathematical
Statistics*, 30(4), 1141–1144.
[doi:10.1214/aoms/1177706098](https://doi.org/10.1214/aoms/1177706098)

Holland, P. W., Laskey, K. B., & Leinhardt, S. (1983). Stochastic
blockmodels: First steps. *Social Networks*, 5(2), 109–137.
[doi:10.1016/0378-8733(83)90021-7](https://doi.org/10.1016/0378-8733%2883%2990021-7)

Watts, D. J., & Strogatz, S. H. (1998). Collective dynamics of
'small-world' networks. *Nature*, 393, 440–442.
[doi:10.1038/30918](https://doi.org/10.1038/30918)

Barabási, A.-L., & Albert, R. (1999). Emergence of scaling in random
networks. *Science*, 286(5439), 509–512.
[doi:10.1126/science.286.5439.509](https://doi.org/10.1126/science.286.5439.509)

Leskovec, J., Kleinberg, J., & Faloutsos, C. (2007). Graph evolution:
Densification and shrinking diameters. *ACM Transactions on Knowledge
Discovery from Data*, 1(1), 2.
[doi:10.1145/1217299.1217301](https://doi.org/10.1145/1217299.1217301)

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
#> 
#> Truth (settings):
#>       model directed loops weight nodes edges
#> 1 bernoulli     TRUE FALSE binary    60   228
#> 
#> Other tables: nodes, adjacency. Read one with as.data.frame(x, what = "nodes").
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
