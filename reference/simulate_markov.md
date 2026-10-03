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
  seed = NULL,
  batch = NULL
)
```

## Arguments

- n:

  Number of chains.

- transition:

  Square transition matrix, or a tidy transition table with `from`,
  `to`, and `probability` columns. Every row of the implied matrix must
  sum to one.

- chain_length:

  Chain length.

- initial:

  Starting-state probabilities or a single fixed start state. When
  `NULL`, every chain starts in the first state.

- states:

  Optional state labels.

- trim_state:

  Optional terminal state. The first occurrence is kept and all later
  observations of that chain are removed.

- id, period, state:

  Output variable names.

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

A long-form `simulab_sim` base `data.frame` with columns `id`, `period`,
and `state` (renamed by those arguments), one row per chain position.
`as.data.frame(x, what = )` also returns `transitions` (`from`, `to`,
`probability`), `initial_probabilities` (`state`, `probability`), and
`wide` (one row per chain, columns `id`, `S1`, `S2`, ...).

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
#> 2    A  B   173   0.3061947
#> 3    B  A   149   0.3870130
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
