# Bootstrap a TNA model

Bootstrap a TNA model

## Usage

``` r
bootstrap_tna(
  data,
  model = c("tna", "ftna", "ctna", "atna"),
  repetitions = 100L,
  fraction = 1,
  format = c("auto", "long", "wide"),
  id = "id",
  period = "period",
  state = "state",
  group = NULL,
  seed = NULL,
  ...
)
```

## Arguments

- data:

  Sequence data.

- model:

  TNA estimator.

- repetitions:

  Number of bootstrap samples.

- fraction:

  Fraction of sequences sampled with replacement.

- format, id, period, state, group:

  Input arguments passed to
  [`fit_tna()`](https://mohsaqr.github.io/simulab/reference/fit_tna.md).

- seed:

  Optional seed.

- ...:

  Estimator arguments.

## Value

A tidy edge-by-bootstrap `simulab_sim` with percentile summaries.

## Examples

``` r
data <- simulate_sequences(n = 40, n_states = 3, chain_length = 12, seed = 1)
if (requireNamespace("tna", quietly = TRUE)) {
  head(bootstrap_tna(data, model = "tna", repetitions = 5, seed = 1))
}
#> <simulab_sim:tna_bootstrap> 6 rows x 4 columns
#>   iteration    from      to    weight
#> 1         1 State 1 State 1 0.1071429
#> 2         1 State 2 State 1 0.5414013
#> 3         1 State 3 State 1 0.5652174
#> 4         1 State 1 State 2 0.3928571
#> 5         1 State 2 State 2 0.3757962
#> 6         1 State 3 State 2 0.3739130
```
