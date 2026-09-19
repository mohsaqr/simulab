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

  Absolute weight threshold for edge presence: a dyad counts as an edge
  when `abs(weight) > threshold`.

## Value

A one-row base `data.frame` with columns `pearson`, `cosine`, `mae`,
`rmse`, `jaccard`, `edges_x`, and `edges_y`. `pearson` and `cosine` are
`NA` when either network's aligned weights have no variance or are all
zero.

## Details

The two networks are aligned on the union of the dyads that carry an
edge in either network; dyads absent from both are excluded, so every
metric is conditional on that union rather than on all possible dyads.

## Examples

``` r
a <- simulate_network(nodes = 30, model = "bernoulli", probability = 0.1, seed = 1)
b <- simulate_network(nodes = 30, model = "bernoulli", probability = 0.1, seed = 2)
compare_networks(a, b)
#>      pearson     cosine       mae      rmse    jaccard edges_x edges_y
#> 1 -0.9134473 0.08651809 0.9548023 0.9771398 0.04519774      95      90
```
