# Count observed transitions in sequence data

Count observed transitions in sequence data

## Usage

``` r
summarize_transitions(
  data,
  id = "id",
  period = "period",
  state = "state",
  normalize = TRUE
)
```

## Arguments

- data:

  Long-form sequence data.

- id, period, state:

  Column names.

- normalize:

  Return row-conditional transition proportions.

## Value

A tidy base `data.frame` with `from`, `to`, count, and probability.

## Examples

``` r
data <- simulate_markov(
  n = 40,
  transition = matrix(c(0.7, 0.3, 0.4, 0.6), nrow = 2, byrow = TRUE),
  chain_length = 20, states = c("A", "B"), seed = 1
)
summarize_transitions(data, normalize = TRUE)
#>   from to count probability
#> 1    A  A   325   0.7049892
#> 3    A  B   136   0.2950108
#> 2    B  A   119   0.3979933
#> 4    B  B   180   0.6020067
```
