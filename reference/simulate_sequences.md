# Simulate basic or perturbed state sequences

Simulate basic or perturbed state sequences

## Usage

``` r
simulate_sequences(
  n,
  transition = NULL,
  chain_length,
  initial = NULL,
  states = NULL,
  n_states = 5L,
  state_categories = NULL,
  concentration = 1,
  missing_tail = c(0L, 0L),
  stable_transitions = NULL,
  stability_probability = 0.95,
  instability = c("none", "random_jump", "perturb", "unlikely_jump"),
  instability_probability = 0.4,
  perturbation = 0.5,
  unlikely_threshold = 0.1,
  seed = NULL
)
```

## Arguments

- n:

  Number of sequences.

- transition:

  Optional transition matrix. When `NULL`, a random matrix is generated.

- chain_length:

  Maximum sequence length.

- initial:

  Initial probabilities or a fixed starting state.

- states:

  State labels.

- n_states:

  Number of automatically generated states.

- state_categories:

  Optional learning-state categories used to name an automatically
  generated state space.

- concentration:

  Positive Dirichlet concentration used for automatic transition and
  initial probabilities.

- missing_tail:

  Number or range of trailing positions removed from each sequence.

- stable_transitions:

  Optional two-column data frame named `from` and `to` defining
  preferred transitions.

- stability_probability:

  Probability of following a preferred transition.

- instability:

  Instability mechanism for other transitions.

- instability_probability:

  Probability of applying that mechanism.

- perturbation:

  Multiplicative probability perturbation magnitude.

- unlikely_threshold:

  Maximum probability considered unlikely.

- seed:

  Optional random seed.

## Value

A long-form `simulab_sim` base `data.frame`. Wide sequences, transition
probabilities, initial probabilities, and settings are tidy components.

## Examples

``` r
result <- simulate_sequences(n = 40, n_states = 4, chain_length = 20, seed = 1)
head(result)
#> <simulab_sim:sequences> 6 rows x 3 columns
#>   id period   state
#> 1  1      1 State 4
#> 2  1      2 State 4
#> 3  1      3 State 4
#> 4  1      4 State 4
#> 5  1      5 State 1
#> 6  1      6 State 2
components(result)
#>                   table rows columns
#> 1                  data  800       3
#> 2           transitions   16       3
#> 3 initial_probabilities    4       2
#> 4                  wide   40      21
#> 5              settings    1       7

# Preferred transitions followed with a given probability.
stable <- data.frame(
  from = sprintf("State %d", 1:4),
  to = sprintf("State %d", c(2, 3, 4, 1))
)
head(simulate_sequences(
  n = 40, n_states = 4, chain_length = 20,
  stable_transitions = stable, stability_probability = 0.85, seed = 1
))
#> <simulab_sim:sequences> 6 rows x 3 columns
#>   id period   state
#> 1  1      1 State 4
#> 2  1      2 State 1
#> 3  1      3 State 2
#> 4  1      4 State 3
#> 5  1      5 State 4
#> 6  1      6 State 1
```
