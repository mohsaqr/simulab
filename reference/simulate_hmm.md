# Simulate a hidden Markov model

Simulate a hidden Markov model

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

  Number of sequences.

- transition:

  Hidden-state transition matrix, or a tidy data frame with columns
  `from`, `to` and `probability`.

- chain_length:

  Sequence length.

- emission:

  Hidden-state-by-observed-category probability matrix, or a tidy data
  frame with columns `state`, `observation` and `probability`.

- initial:

  Initial hidden-state probabilities.

- state_labels, observation_labels:

  Optional labels.

- seed:

  Optional random seed.

## Value

A long-form `simulab_sim` base `data.frame` with observed and true
hidden states, plus tidy parameter tables.

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
