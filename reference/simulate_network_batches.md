# Simulate repeated networks

Calls
[`simulate_network()`](https://mohsaqr.github.io/simulab/reference/simulate_network.md)
`repetitions` times and stacks the edge lists.

## Usage

``` r
simulate_network_batches(repetitions, ..., seed = NULL)
```

## Arguments

- repetitions:

  Number of networks. A single positive whole number.

- ...:

  Arguments passed to
  [`simulate_network()`](https://mohsaqr.github.io/simulab/reference/simulate_network.md).

- seed:

  Optional base seed. A single number, or `NULL` (the default). Network
  `i` uses `seed + i - 1`.

## Value

A `simulab_sim` base `data.frame` edge list, one row per network and
edge, with the column `network` followed by the columns
[`simulate_network()`](https://mohsaqr.github.io/simulab/reference/simulate_network.md)
returns (`from`, `to` and `weight`). The component `settings`, reached
with `as.data.frame(x, what = "settings")`, holds one row per network
with its generator arguments and realized edge count.

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
