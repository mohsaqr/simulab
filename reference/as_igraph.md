# Convert tidy network data to an igraph object

Convert tidy network data to an igraph object

## Usage

``` r
as_igraph(x, directed = TRUE)
```

## Arguments

- x:

  A simulab network, tidy edge list, matrix, or native TNA model.

- directed:

  Whether the resulting graph is directed. It is not inferred from `x`,
  so a network generated with `directed = FALSE` must be converted with
  `directed = FALSE` as well.

## Value

A native `igraph` object carrying a `weight` edge attribute. When `x` is
a `simulab_sim` with a `nodes` component, that node set supplies the
vertices, so isolates are preserved; otherwise the vertices are the
nodes appearing in the edge list.

## Examples

``` r
network <- simulate_network(nodes = 30, model = "bernoulli", probability = 0.1, seed = 1)
if (requireNamespace("igraph", quietly = TRUE)) {
  graph <- as_igraph(network)
  igraph::vcount(graph)
}
#> [1] 30
```
