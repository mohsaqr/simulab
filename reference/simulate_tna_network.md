# Simulate a grouped TNA transition network

Simulate a grouped TNA transition network

## Usage

``` r
simulate_tna_network(
  groups,
  nodes_per_group,
  group_names = NULL,
  within_probability = 0.4,
  between_probability = 0.15,
  loops = FALSE,
  seed = NULL
)
```

## Arguments

- groups:

  Number of node groups.

- nodes_per_group:

  Nodes per group, scalar or vector.

- group_names:

  Optional group names.

- within_probability, between_probability:

  Edge probabilities within and between node groups.

- loops:

  Permit self transitions when drawing the underlying edges. A node left
  with no outgoing edge is nevertheless given a self transition of
  probability one, so self-loops can appear even when `loops` is
  `FALSE`.

- seed:

  Optional random seed.

## Value

A tidy `simulab_sim` base `data.frame` holding the non-zero transitions
only, one row per edge, with columns `from`, `to`, and `probability`.
`as.data.frame(x, what = )` also returns `nodes` (`node`, `group`),
`adjacency` (the long `row`/`column`/`weight` table of the underlying
directed Bernoulli graph), and `transitions` (the full `nodes^2`-row
transition table including zeros). The transition matrix is
row-stochastic: every `from` node's probabilities sum to one.

## Examples

``` r
result <- simulate_tna_network(groups = 3, nodes_per_group = 4, seed = 1)
head(result)
#> <simulab_sim:tna_network> 6 rows x 3 columns
#>     from    to probability
#> 5  G2_N1 G1_N1   0.3333333
#> 7  G2_N3 G1_N1   0.3333333
#> 8  G2_N4 G1_N1   0.3333333
#> 15 G1_N3 G1_N2   0.3333333
#> 20 G2_N4 G1_N2   0.3333333
#> 23 G3_N3 G1_N2   0.3333333
components(result)
#>         table rows columns
#> 1        data   27       3
#> 2       nodes   12       2
#> 3   adjacency  144       3
#> 4 transitions  144       3
```
