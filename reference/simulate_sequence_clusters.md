# Simulate sequences from a mixture of transition systems

Simulate sequences from a mixture of transition systems

## Usage

``` r
simulate_sequence_clusters(
  n,
  transitions,
  chain_length,
  proportions = NULL,
  initial = NULL,
  labels = NULL,
  states = NULL,
  seed = NULL
)
```

## Arguments

- n:

  Number of sequences.

- transitions:

  List of transition matrices, or a tidy data frame with columns
  `cluster`, `from`, `to` and `probability`.

- chain_length:

  Sequence length.

- proportions:

  Cluster proportions.

- initial:

  Optional common initial probabilities.

- labels:

  Optional sequence-cluster labels.

- states:

  Optional state labels.

- seed:

  Optional random seed.

## Value

A long-form `simulab_sim` base `data.frame` with true sequence cluster
and tidy transition parameters.

## Examples

``` r
# One transition matrix per latent cluster.
result <- simulate_sequence_clusters(
  n = 60,
  transitions = list(
    matrix(c(0.8, 0.2, 0.3, 0.7), nrow = 2, byrow = TRUE),
    matrix(c(0.3, 0.7, 0.6, 0.4), nrow = 2, byrow = TRUE)
  ),
  chain_length = 12,
  seed = 1
)
head(result)
#> <simulab_sim:sequence_clusters> 6 rows x 4 columns
#>   id period state   sequence_cluster
#> 1  1      1     1 Sequence cluster 2
#> 2  1      2     2 Sequence cluster 2
#> 3  1      3     1 Sequence cluster 2
#> 4  1      4     2 Sequence cluster 2
#> 5  1      5     2 Sequence cluster 2
#> 6  1      6     1 Sequence cluster 2
components(result)
#>         table rows columns
#> 1        data  720       4
#> 2 transitions    8       4
```
