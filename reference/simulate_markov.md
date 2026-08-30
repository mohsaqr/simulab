# Simulate Markov chains

Simulate Markov chains

## Usage

``` r
simulate_markov(
  n,
  transition,
  chain_length,
  initial = NULL,
  states = NULL,
  trim_state = NULL,
  id = "id",
  period = "period",
  state = "state",
  seed = NULL
)
```

## Arguments

- n:

  Number of chains.

- transition:

  Square transition matrix or tidy transition table.

- chain_length:

  Chain length.

- initial:

  Starting-state probabilities or a single fixed start state.

- states:

  Optional state labels.

- trim_state:

  Optional terminal state. Later observations are removed.

- id, period, state:

  Output variable names.

- seed:

  Optional random seed.

## Value

A long-form `simulab_sim` base `data.frame` with one row per chain
position. Wide chains, transitions, and initial probabilities are
available through
[`as.data.frame()`](https://rdrr.io/r/base/as.data.frame.html).

## Examples

``` r
transition <- matrix(c(0.7, 0.3, 0.4, 0.6), nrow = 2, byrow = TRUE)

result <- simulate_markov(
  n = 50, transition = transition, chain_length = 20,
  states = c("A", "B"), seed = 1
)
head(result)
#> <simulab_sim:markov> 6 rows x 3 columns
#>   id period state
#> 1  1      1     A
#> 2  1      2     A
#> 3  1      3     A
#> 4  1      4     B
#> 5  1      5     B
#> 6  1      6     A
summarize_transitions(result, normalize = TRUE)
#>   from to count probability
#> 1    A  A   392   0.6938053
#> 3    A  B   173   0.3061947
#> 2    B  A   149   0.3870130
#> 4    B  B   236   0.6129870

# Transitions may also be given as a tidy from/to/probability table.
tidy_transitions <- data.frame(
  from = c("A", "A", "B", "B"),
  to = c("A", "B", "A", "B"),
  probability = c(0.7, 0.3, 0.4, 0.6)
)
head(simulate_markov(
  n = 50, transition = tidy_transitions, chain_length = 20, seed = 1
))
#> <simulab_sim:markov> 6 rows x 3 columns
#>   id period state
#> 1  1      1     A
#> 2  1      2     A
#> 3  1      3     A
#> 4  1      4     B
#> 5  1      5     B
#> 6  1      6     A
```
