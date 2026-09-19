# Assess split-half TNA reliability

Splits the sequences at random into two halves, fits the same estimator
to each, and compares the two networks. Repeating that over `iterations`
independent splits shows how stable an estimate this much data supports.

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
  [`fit_tna()`](https://mohsaqr.github.io/simulab/reference/fit_tna.md),
  with at least 4 rows.

- model:

  TNA estimator, one of `"tna"` (the default), `"ftna"`, `"ctna"` or
  `"atna"`.

- iterations:

  Number of random split halves. A single whole number of at least 2,
  defaulting to `100`.

- split:

  Fraction of the sequences assigned to the first half, rounded down. A
  single number strictly between 0 and 1, defaulting to `0.5`. Each half
  must end up with at least two sequences.

- format, id, period, state:

  Input-format arguments passed on when the sequences are prepared:
  `format` is one of `"auto"` (the default), `"long"` or `"wide"`, and
  the other three name the identifier, period and state columns of long
  input.

- seed:

  Optional seed. A single number, or `NULL` (the default).

- ...:

  Arguments passed to
  [`fit_tna()`](https://mohsaqr.github.io/simulab/reference/fit_tna.md).

## Value

A plain base `data.frame`, not a `simulab_sim`, with one row per split,
holding `iteration`, `model` and the
[`compare_networks()`](https://mohsaqr.github.io/simulab/reference/compare_networks.md)
agreement metrics for the two halves.

## Examples

``` r
data <- simulate_sequences(n = 40, n_states = 3, chain_length = 12, seed = 1)
if (requireNamespace("tna", quietly = TRUE)) {
  assess_tna_reliability(data, model = "tna", iterations = 2, seed = 1)
}
```
