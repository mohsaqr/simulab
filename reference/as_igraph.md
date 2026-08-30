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

  Whether the resulting graph is directed.

## Value

A native `igraph` object.

## Examples

``` r
network <- simulate_network(nodes = 30, model = "bernoulli", probability = 0.1, seed = 1)
if (requireNamespace("igraph", quietly = TRUE)) {
  graph <- as_igraph(network)
  igraph::vcount(graph)
}
#> [1] 30
```
