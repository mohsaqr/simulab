# Summarize multiple networks

Summarize multiple networks

## Usage

``` r
summarize_networks(networks, threshold = 0, directed = TRUE)
```

## Arguments

- networks:

  Named list of supported networks. Unnamed elements are labelled
  `Network 1`, `Network 2`, and so on.

- threshold:

  Edge-presence threshold, applied as `abs(weight) > threshold`. It
  affects the `edges` and `mean_weight` columns only; `density` and
  `components` are computed from every edge in the network, thresholded
  or not.

- directed:

  Treat networks as directed. `density` is the directed edge density
  when `TRUE`; `components` always counts weakly connected components.

## Value

A tidy base `data.frame` with one row per network and columns `network`,
`nodes`, `edges`, `density`, `mean_weight`, and `components`.
`mean_weight` is `NA` when no edge passes the threshold. Requires the
suggested `igraph` package.

## Examples

``` r
networks <- list(
  first = simulate_network(nodes = 25, model = "bernoulli", probability = 0.1, seed = 1),
  second = simulate_network(nodes = 25, model = "bernoulli", probability = 0.2, seed = 2)
)
if (requireNamespace("igraph", quietly = TRUE)) {
  summarize_networks(networks)
}
```
