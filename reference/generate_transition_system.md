# Generate a transition system

Generate a transition system

## Usage

``` r
generate_transition_system(
  n_states = 8L,
  states = NULL,
  concentration = 1,
  diagonal_concentration = 0,
  state_categories = c("metacognitive", "cognitive"),
  seed = NULL,
  batch = NULL
)
```

## Arguments

- n_states:

  Number of states.

- states:

  Optional state labels.

- concentration:

  Dirichlet concentration applied to every transition and to the
  initial-state probabilities.

- diagonal_concentration:

  Optional extra concentration added to the self-transition (diagonal)
  entries only. The default `0` leaves self-transitions no more likely
  than any other transition.

- state_categories:

  Learning-state categories the state labels are drawn from with
  [`sample_learning_states()`](https://pak.dynasite.org/simulab/reference/sample_learning_states.md)
  when `states` is `NULL`, defaulting to
  `c("metacognitive", "cognitive")`; see
  [`learning_state_categories()`](https://pak.dynasite.org/simulab/reference/learning_state_categories.md).
  `NULL` labels the states `State 1`, `State 2`, and so on.

- seed:

  Optional random seed.

- batch:

  Optional single positive whole number. When given, the simulator runs
  `batch` times and returns a plain `list` of `batch` results, each
  exactly what the same call without `batch` returns. With a `seed`,
  every dataset gets its own seed drawn from `seed`, so the whole batch
  is reproducible; without one the datasets are consecutive draws from
  the session's random-number stream. The default `NULL` returns a
  single result.

## Value

A tidy transition-edge `simulab_sim` base `data.frame` with `n_states^2`
rows and columns `from`, `to`, and `probability`; every `from` state's
probabilities sum to one. An `initial_probabilities` table (`state`,
`probability`) is available through
[`as.data.frame()`](https://rdrr.io/r/base/as.data.frame.html).

## Examples

``` r
result <- generate_transition_system(n_states = 3, seed = 1)
result
#> <simulab_sim:transition_system> 9 rows x 3 columns
#>      from      to probability
#> 1 Reflect Reflect  0.07830127
#> 2   Learn Reflect  0.55164885
#> 3    Plan Reflect  0.59019469
#> 4 Reflect   Learn  0.42202656
#> 5   Learn   Learn  0.35827360
#> 6    Plan   Learn  0.37885862
#> 7 Reflect    Plan  0.49967217
#> 8   Learn    Plan  0.09007756
#> 9    Plan    Plan  0.03094669
#> 
#> Other tables: initial_probabilities. Read one with as.data.frame(x, what = "initial_probabilities").
```
