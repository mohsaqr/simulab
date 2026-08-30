# Generate a transition system

Generate a transition system

## Usage

``` r
generate_transition_system(
  n_states = 8L,
  states = NULL,
  concentration = 1,
  diagonal_concentration = 0,
  state_categories = NULL,
  seed = NULL
)
```

## Arguments

- n_states:

  Number of states.

- states:

  Optional state labels.

- concentration:

  Dirichlet concentration for off-diagonal transitions.

- diagonal_concentration:

  Optional additional self-transition concentration.

- state_categories:

  Optional learning-state categories.

- seed:

  Optional random seed.

## Value

A tidy transition-edge `simulab_sim` with initial probabilities as a
component.

## Examples

``` r
result <- generate_transition_system(n_states = 3, seed = 1)
result
#> <simulab_sim:transition_system> 9 rows x 3 columns
#>      from      to probability
#> 1 State 1 State 1  0.07830127
#> 2 State 2 State 1  0.55164885
#> 3 State 3 State 1  0.59019469
#> 4 State 1 State 2  0.42202656
#> 5 State 2 State 2  0.35827360
#> 6 State 3 State 2  0.37885862
#> 7 State 1 State 3  0.49967217
#> 8 State 2 State 3  0.09007756
#> 9 State 3 State 3  0.03094669
```
