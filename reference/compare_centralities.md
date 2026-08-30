# Compare node centralities between two networks

Compare node centralities between two networks

## Usage

``` r
compare_centralities(
  x,
  y,
  measures = c("degree", "betweenness", "closeness"),
  method = c("pearson", "spearman", "kendall"),
  directed = TRUE
)
```

## Arguments

- x, y:

  Supported network representations.

- measures:

  Centralities passed to
  [`network_centrality()`](https://mohsaqr.github.io/simulab/reference/network_centrality.md).

- method:

  Correlation method.

- directed:

  Treat networks as directed.

## Value

A tidy base `data.frame` with one comparison per measure.

## Examples

``` r
a <- simulate_network(nodes = 30, model = "bernoulli", probability = 0.1, seed = 1)
b <- simulate_network(nodes = 30, model = "bernoulli", probability = 0.1, seed = 2)
compare_centralities(a, b, measures = "degree")
#>        measure  method correlation      mae nodes
#> degree  degree pearson  0.03088574 2.866667    30
```
