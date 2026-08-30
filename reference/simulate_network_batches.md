# Simulate repeated networks

Simulate repeated networks

## Usage

``` r
simulate_network_batches(repetitions, ..., seed = NULL)
```

## Arguments

- repetitions:

  Number of networks.

- ...:

  Arguments passed to
  [`simulate_network()`](https://mohsaqr.github.io/simulab/reference/simulate_network.md).

- seed:

  Optional base seed. Each network uses a deterministic offset.

## Value

A combined tidy edge-list `simulab_sim` with network identifiers.

## Examples

``` r
result <- simulate_network_batches(
  repetitions = 3, nodes = 20, model = "bernoulli", probability = 0.1, seed = 1
)
head(result)
#> <simulab_sim:network_batches> 6 rows x 4 columns
#>   network from to weight
#> 1       1    5  1      1
#> 2       1    8  1      1
#> 3       1   19  1      1
#> 4       1    3  2      1
#> 5       1    5  4      1
#> 6       1    4  5      1
```
