# Calculate tidy network centralities

Calculate tidy network centralities

## Usage

``` r
network_centrality(
  network,
  measures = c("degree", "strength", "betweenness", "closeness", "eigenvector",
    "pagerank"),
  directed = TRUE
)
```

## Arguments

- network:

  A supported network representation.

- measures:

  Centrality measures.

- directed:

  Treat edges as directed.

## Value

A tidy base `data.frame` with one node/measure/value row.

## Examples

``` r
network <- simulate_network(nodes = 30, model = "bernoulli", probability = 0.1, seed = 1)
head(network_centrality(network, measures = c("degree", "strength")))
#>          node measure value
#> degree.1    1  degree     4
#> degree.2    2  degree     4
#> degree.3    3  degree     6
#> degree.4    4  degree     6
#> degree.5    5  degree    11
#> degree.6    6  degree     4
```
