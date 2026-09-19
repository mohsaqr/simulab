# Simulate a hidden Markov model

Draws an initial hidden state for each sequence from `initial`, evolves
it with `transition` for `chain_length` occasions, and emits one
observed category per occasion from `emission`.

## Usage

``` r
simulate_hmm(
  n,
  transition,
  chain_length,
  emission,
  initial = NULL,
  state_labels = NULL,
  observation_labels = NULL,
  seed = NULL
)
```

## Arguments

- n:

  Number of sequences. A single positive whole number.

- transition:

  Hidden-state transition matrix, or a tidy data frame with columns
  `from`, `to` and `probability`. Square, with rows indexing the current
  state and columns the next state; every row must sum to one.

- chain_length:

  Sequence length. A single positive whole number; every sequence has
  the same length.

- emission:

  Hidden-state-by-observed-category probability matrix, or a tidy data
  frame with columns `state`, `observation` and `probability`. Rows
  index the hidden states and must sum to one; columns index the
  observed categories.

- initial:

  Initial hidden-state probabilities, one per hidden state, summing to
  one. `NULL` (the default) starts every sequence in the first hidden
  state with probability one; supply a vector for a random start.

- state_labels, observation_labels:

  Optional labels, one unique value per hidden state and per observed
  category. They default to `"State 1"`, `"State 2"`, ... and
  `"Observation 1"`, `"Observation 2"`, ...

- seed:

  Optional random seed.

## Value

A long-form `simulab_sim` base `data.frame` with one row per
sequence-occasion (`n * chain_length` rows) and columns `id`,
`occasion`, `state` (the true hidden state label) and `observation` (the
emitted category label). Components `transitions` (columns `from`, `to`,
`probability`), `emissions` (columns `state`, `observation`,
`probability`) and `initial_probabilities` (columns `state`,
`probability`) hold the generating parameters in tidy form.

## Examples

``` r
result <- simulate_hmm(
  n = 50,
  transition = matrix(c(0.7, 0.3, 0.4, 0.6), nrow = 2, byrow = TRUE),
  chain_length = 20,
  emission = matrix(c(0.9, 0.1, 0.2, 0.8), nrow = 2, byrow = TRUE),
  seed = 1
)
head(result)
#> <simulab_sim:hmm> 6 rows x 4 columns
#>   id occasion   state   observation
#> 1  1        1 State 1 Observation 2
#> 2  1        2 State 1 Observation 1
#> 3  1        3 State 1 Observation 1
#> 4  1        4 State 2 Observation 2
#> 5  1        5 State 2 Observation 2
#> 6  1        6 State 1 Observation 1
components(result)
#>                   table rows columns
#> 1                  data 1000       4
#> 2           transitions    4       3
#> 3             emissions    4       3
#> 4 initial_probabilities    2       2
```
