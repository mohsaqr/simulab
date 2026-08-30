# List canonical simulation verbs

List canonical simulation verbs

## Usage

``` r
list_simulators(family = NULL)
```

## Arguments

- family:

  Optional family filter.

## Value

A base `data.frame` with simulator, family, and primary shape.

## Examples

``` r
head(list_simulators())
#>     simulator      family primary_shape
#> 1       study     general          wide
#> 2 correlation     general          wide
#> 3      copula     general          wide
#> 4     ordinal     general          wide
#> 5       ttest statistical          wide
#> 6       anova statistical          wide
list_simulators(family = "network")
#>           simulator  family primary_shape
#> 1           network network     edge_list
#> 2         edge_list network     edge_list
#> 3  temporal_network network     edge_list
#> 4    network_matrix network        matrix
#> 5 bipartite_network network     edge_list
#> 6 multiplex_network network     edge_list
#> 7       tna_network network     edge_list
```
