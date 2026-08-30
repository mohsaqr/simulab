# Assess split-half TNA reliability

Assess split-half TNA reliability

## Usage

``` r
assess_tna_reliability(
  data,
  model = c("tna", "ftna", "ctna", "atna"),
  iterations = 100L,
  split = 0.5,
  format = c("auto", "long", "wide"),
  id = "id",
  period = "period",
  state = "state",
  seed = NULL,
  ...
)
```

## Arguments

- data:

  Sequence data accepted by
  [`fit_tna()`](https://mohsaqr.github.io/simulab/reference/fit_tna.md).

- model:

  TNA estimator.

- iterations:

  Number of random split halves.

- split:

  Fraction assigned to the first half.

- format, id, period, state:

  Input-format arguments.

- seed:

  Optional seed.

- ...:

  Arguments passed to
  [`fit_tna()`](https://mohsaqr.github.io/simulab/reference/fit_tna.md).

## Value

A tidy base `data.frame` with one row of network agreement metrics per
split.

## Examples

``` r
data <- simulate_sequences(n = 40, n_states = 3, chain_length = 12, seed = 1)
if (requireNamespace("tna", quietly = TRUE)) {
  assess_tna_reliability(data, model = "tna", iterations = 2, seed = 1)
}
#>   iteration model   pearson    cosine        mae       rmse jaccard edges_x
#> 1         1   tna 0.9932296 0.9976692 0.02105045 0.02770700       1       9
#> 2         2   tna 0.9806632 0.9937841 0.03506547 0.04483295       1       9
#>   edges_y
#> 1       9
#> 2       9
```
