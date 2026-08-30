# Simulate a bipartite network

Simulate a bipartite network

## Usage

``` r
simulate_bipartite_network(
  actors,
  events,
  edges = NULL,
  probability = 0.1,
  weight = c("binary", "uniform", "normal", "poisson"),
  weight_mean = 1,
  weight_sd = 1,
  weight_range = c(0.1, 1),
  seed = NULL
)
```

## Arguments

- actors:

  Number or labels of primary-mode nodes.

- events:

  Number or labels of secondary-mode nodes.

- edges:

  Optional exact number of cross-mode edges.

- probability:

  Cross-mode edge probability when `edges` is `NULL`.

- weight:

  Edge-weight distribution.

- weight_mean, weight_sd, weight_range:

  Weight parameters.

- seed:

  Optional seed.

## Value

A tidy cross-mode edge-list `simulab_sim`; nodes and the actor-by-event
incidence matrix are components.

## Examples

``` r
result <- simulate_bipartite_network(actors = 20, events = 6, probability = 0.3, seed = 1)
head(result)
#> <simulab_sim:bipartite_network> 6 rows x 5 columns
#>       from      to weight from_mode to_mode
#> 1  Actor 4 Event 1      1     actor   event
#> 2  Actor 6 Event 1      1     actor   event
#> 3  Actor 7 Event 1      1     actor   event
#> 4 Actor 15 Event 1      1     actor   event
#> 5 Actor 17 Event 1      1     actor   event
#> 6 Actor 18 Event 1      1     actor   event
components(result)
#>       table rows columns
#> 1      data   37       5
#> 2     nodes   26       2
#> 3 incidence   20       7
#> 4  settings    1       4
```
