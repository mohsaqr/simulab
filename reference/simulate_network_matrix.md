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

  Generate weighted adjacency/co-occurrence values. Ignored by the
  `frequency` and `transition` types, which are always weighted.

- weight_range:

  Range for continuous weights.

- frequency_mean:

  Mean positive count for frequency matrices; drawn as
  `1 + rpois(frequency_mean - 1)`, so entries are at least one.

- seed:

  Optional seed.

## Value

A tidy `simulab_sim` base `data.frame` holding the complete matrix in
long form: `nodes^2` rows with columns `from`, `to`, and `value`, zeros
included. `as.data.frame(x, what = )` also returns `edges` (the non-zero
rows only), `nodes` (`node`), `matrix` (the wide form: a `from` column
followed by one column per node), and a one-row `settings` table whose
`directed` field reports whether the generated matrix is asymmetric. The
`transition` type is row-stochastic: every `from` state's `value`
entries sum to one.

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
