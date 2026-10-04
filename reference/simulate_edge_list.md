# Simulate a tidy network edge list

Simulate a tidy network edge list

## Usage

``` r
simulate_edge_list(
  nodes,
  edges = NULL,
  probability = 0.1,
  directed = TRUE,
  loops = FALSE,
  weight = c("binary", "uniform", "normal", "poisson"),
  weight_mean = 1,
  weight_sd = 1,
  weight_range = c(0.1, 1),
  node_type = NULL,
  edge_classes = NULL,
  class_probabilities = NULL,
  seed = NULL,
  batch = NULL
)
```

## Arguments

- nodes:

  Number of nodes or unique node labels.

- edges:

  Optional exact number of edges.

- probability:

  Edge probability when `edges` is `NULL`.

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

- edge_classes:

  Optional number or labels of edge classes.

- class_probabilities:

  Optional edge-class probabilities.

- seed:

  Optional seed.

- batch:

  Optional single positive whole number. When given, the simulator runs
  `batch` times and returns a plain `list` of `batch` results, each
  exactly what the same call without `batch` returns. With a `seed`,
  every dataset gets its own seed drawn from `seed`, so the whole batch
  is reproducible; without one the datasets are consecutive draws from
  the session's random-number stream. The default `NULL` returns a
  single result.

## Value

A tidy `simulab_sim` base `data.frame` with one row per edge and columns
`from`, `to`, and `weight` (plus `edge_class` when `edge_classes` is
supplied). `as.data.frame(x, what = )` also returns `nodes` (`node`,
`type`), `adjacency` (a long `row`/`column`/`weight` table over all
ordered node pairs), and a one-row `settings` table.

## Examples

``` r
result <- simulate_edge_list(nodes = 40, probability = 0.08, seed = 1)
head(result)
#> <simulab_sim:edge_list> 6 rows x 3 columns
#>   from to weight
#> 1    8  1      1
#> 2   19  1      1
#> 3   22  1      1
#> 4    2  3      1
#> 5   27  3      1
#> 6   32  3      1
#> 
#> Truth (settings):
#>       model directed loops weight nodes edges
#> 1 bernoulli     TRUE FALSE binary    40   138
#> 
#> Other tables: nodes, adjacency. Read one with as.data.frame(x, what = "nodes").
components(result)
#>       table rows columns
#> 1      data  138       3
#> 2     nodes   40       2
#> 3 adjacency 1600       3
#> 4  settings    1       6
```
