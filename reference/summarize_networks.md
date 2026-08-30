# Summarize multiple networks

Summarize multiple networks

## Usage

``` r
summarize_networks(networks, threshold = 0, directed = TRUE)
```

## Arguments

- networks:

  Named list of supported networks.

- threshold:

  Edge-presence threshold.

- directed:

  Treat networks as directed.

## Value

A tidy base `data.frame` with one summary row per network.

## Examples

``` r
networks <- list(
  first = simulate_network(nodes = 25, model = "bernoulli", probability = 0.1, seed = 1),
  second = simulate_network(nodes = 25, model = "bernoulli", probability = 0.2, seed = 2)
)
summarize_networks(networks)
#>        network nodes edges   density mean_weight components
#> first    first    25    63 0.1050000           1          1
#> second  second    25   130 0.2166667           1          1
```
