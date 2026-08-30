# Add a Markov chain to each input row

Add a Markov chain to each input row

## Usage

``` r
augment_markov(
  data,
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

- data:

  Base `data.frame` with a unique identifier.

- transition, chain_length, states, trim_state:

  Markov-chain arguments.

- initial:

  Starting-state probabilities or the name of an input variable
  containing each row's starting state.

- id, period, state:

  Output variable names.

- seed:

  Optional random seed.

## Value

A long-form `simulab_sim` base `data.frame` combining input variables
with one row per chain position.

## Examples

``` r
data <- data.frame(id = 1:20, group = rep(c("a", "b"), each = 10))

result <- augment_markov(
  data,
  transition = matrix(c(0.7, 0.3, 0.4, 0.6), nrow = 2, byrow = TRUE),
  chain_length = 10,
  states = c("A", "B"),
  seed = 1
)
head(result)
#> <simulab_sim:augmented_markov> 6 rows x 4 columns
#>   id period state group
#> 1  1      1     A     a
#> 2  1      2     A     a
#> 3  1      3     A     a
#> 4  1      4     B     a
#> 5  1      5     B     a
#> 6  1      6     A     a
```
