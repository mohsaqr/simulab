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
  seed = NULL,
  batch = NULL
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

  Cluster proportions. When `NULL`, clusters are equally likely.

- initial:

  Optional common initial probabilities, shared by every cluster. When
  `NULL`, every sequence starts in the first state.

- labels:

  Optional sequence-cluster labels.

- states:

  Optional state labels. When the matrices carry no dimnames and
  `states` is `NULL`, states are labeled by their row index.

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
`state`, and the true `sequence_cluster`, one row per sequence position.
A `transitions` table (`sequence_cluster`, `from`, `to`, `probability`)
is available through
[`as.data.frame()`](https://rdrr.io/r/base/as.data.frame.html).

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
#> 
#> Truth (transitions):
#>     sequence_cluster from to probability
#> 1 Sequence cluster 1    1  1         0.8
#> 2 Sequence cluster 1    2  1         0.3
#> 3 Sequence cluster 1    1  2         0.2
#> 4 Sequence cluster 1    2  2         0.7
#> 5 Sequence cluster 2    1  1         0.3
#> 6 Sequence cluster 2    2  1         0.6
#> 7 Sequence cluster 2    1  2         0.7
#> 8 Sequence cluster 2    2  2         0.4
components(result)
#>         table rows columns
#> 1        data  720       4
#> 2 transitions    8       4
```
