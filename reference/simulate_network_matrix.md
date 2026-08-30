# Simulate a network matrix

Simulate a network matrix

## Usage

``` r
simulate_network_matrix(
  nodes,
  type = c("adjacency", "transition", "frequency", "cooccurrence"),
  probability = 0.2,
  directed = TRUE,
  loops = FALSE,
  weighted = TRUE,
  weight_range = c(0.1, 1),
  frequency_mean = 10,
  seed = NULL
)
```

## Arguments

- nodes:

  Number of nodes or unique node labels.

- type:

  Matrix type.

- probability:

  Probability of a non-zero dyad.

- directed:

  Generate an asymmetric matrix where applicable.

- loops:

  Permit non-zero diagonal entries.

- weighted:

  Generate weighted adjacency/co-occurrence values.

- weight_range:

  Range for continuous weights.

- frequency_mean:

  Mean positive count for frequency matrices.

- seed:

  Optional seed.

## Value

A tidy full matrix table with `from`, `to`, and `value`; non-zero edges,
nodes, and a wide matrix are components.

## Examples

``` r
result <- simulate_network_matrix(nodes = 8, type = "adjacency", seed = 1)
head(result)
#> <simulab_sim:network_matrix_adjacency> 6 rows x 3 columns
#>     from     to     value
#> 1 Node 1 Node 1 0.0000000
#> 2 Node 2 Node 1 0.0000000
#> 3 Node 3 Node 1 0.0000000
#> 4 Node 4 Node 1 0.0000000
#> 5 Node 5 Node 1 0.3846445
#> 6 Node 6 Node 1 0.0000000
components(result)
#>      table rows columns
#> 1     data   64       3
#> 2    edges    9       3
#> 3    nodes    8       1
#> 4   matrix    8       9
#> 5 settings    1       4
```
