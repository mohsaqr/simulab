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

A tidy base `data.frame` with one row per measure and columns `measure`,
`method`, `correlation`, `mae`, and `nodes`. Nodes present in only one
network contribute a centrality of zero to the other. `correlation` is
`NA` when either set of centralities has no variance. Requires the
suggested `igraph` package.

## Examples

``` r
a <- simulate_network(nodes = 30, model = "bernoulli", probability = 0.1, seed = 1)
b <- simulate_network(nodes = 30, model = "bernoulli", probability = 0.1, seed = 2)
if (requireNamespace("igraph", quietly = TRUE)) {
  compare_centralities(a, b, measures = "degree")
}
```
