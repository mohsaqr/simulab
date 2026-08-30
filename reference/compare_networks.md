# Compare two weighted networks

Compare two weighted networks

## Usage

``` r
compare_networks(x, y, threshold = 0)
```

## Arguments

- x, y:

  Supported network representations.

- threshold:

  Absolute weight threshold for edge presence.

## Value

A one-row base `data.frame` with weight and edge-overlap metrics.

## Examples

``` r
a <- simulate_network(nodes = 30, model = "bernoulli", probability = 0.1, seed = 1)
b <- simulate_network(nodes = 30, model = "bernoulli", probability = 0.1, seed = 2)
compare_networks(a, b)
#>      pearson     cosine       mae      rmse    jaccard edges_x edges_y
#> 1 -0.9134473 0.08651809 0.9548023 0.9771398 0.04519774      95      90
```
