# Calculate tidy network centralities

Calculate tidy network centralities

## Usage

``` r
network_centrality(
  network,
  measures = c("degree", "strength", "betweenness", "closeness", "eigenvector",
    "pagerank"),
  directed = NULL
)
```

## Arguments

- network:

  A supported network representation.

- measures:

  Centrality measures.

- directed:

  Treat edges as directed. `NULL` (the default) takes it from the
  network's `settings` table, as
  [`as_igraph()`](https://mohsaqr.github.io/simulab/reference/as_igraph.md)
  does. This governs the graph conversion and the `betweenness`,
  `eigenvector`, and `pagerank` measures only; `degree`, `strength`, and
  `closeness` always combine incoming and outgoing ties. `betweenness`
  and `closeness` use `1 / |weight|` as the edge distance.

## Value

A tidy base `data.frame` with one row per node and measure and columns
`node`, `measure`, and `value`, stacked measure after measure. Requires
the suggested `igraph` package.

## Examples

``` r
network <- simulate_network(nodes = 30, model = "bernoulli", probability = 0.1, seed = 1)
if (requireNamespace("igraph", quietly = TRUE)) {
  head(network_centrality(network, measures = c("degree", "strength")))
}
#>   node measure value
#> 1    1  degree     4
#> 2    2  degree     4
#> 3    3  degree     6
#> 4    4  degree     6
#> 5    5  degree    11
#> 6    6  degree     4
```
