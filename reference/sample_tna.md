# Fit TNA to a sequence sample

Fit TNA to a sequence sample

## Usage

``` r
sample_tna(
  data,
  fraction = 0.3,
  replace = FALSE,
  seed = NULL,
  format = c("auto", "long", "wide"),
  id = "id",
  period = "period",
  state = "state",
  group = NULL,
  ...
)
```

## Arguments

- data:

  Sequence data, in long or wide form.

- fraction:

  Single number in `(0, 1]` giving the fraction of sequences to draw,
  default `0.3`. At least two sequences are always drawn.

- replace:

  Single flag, whether to draw with replacement. Default `FALSE`.

- seed:

  Optional single seed, restored on exit.

- format:

  One of `"auto"`, `"long"` or `"wide"`, naming the layout of `data`.
  The default `"auto"` detects it.

- id, period, state:

  Column names identifying the sequence, the position within it, and the
  state. Used only when `data` is in long form; the defaults are `"id"`,
  `"period"` and `"state"`.

- group:

  Optional column name. When given, sequences are sampled within each
  group and the refit is grouped.

- ...:

  Further arguments passed to
  [`fit_tna()`](https://mohsaqr.github.io/simulab/reference/fit_tna.md),
  such as `model`. The sampled sequences are always refitted in wide
  form, so `format` is consumed by the sampling step and is not
  forwarded.

## Value

The
[`fit_tna()`](https://mohsaqr.github.io/simulab/reference/fit_tna.md)
result for the sampled sequences: a `simulab_sim` edge list with one row
per transition and the columns `from`, `to` and `weight`, plus the
`initial_probabilities` and `model_info` components.

## Examples

``` r
data <- simulate_sequences(n = 40, n_states = 3, chain_length = 12, seed = 1)
if (requireNamespace("tna", quietly = TRUE)) {
  head(sample_tna(data, fraction = 0.5, seed = 1))
}
```
