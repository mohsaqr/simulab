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

  Sequence data in long or wide form.

- model:

  TNA estimator, one of `"tna"` (the default), `"ftna"`, `"ctna"`,
  `"atna"`.

- repetitions:

  Single whole number of bootstrap samples, at least 2, default `100`.

- fraction:

  Single number in `(0, 1]` giving the fraction of sequences drawn with
  replacement in each repetition, default `1`. At least two sequences
  are always drawn.

- format, id, period, state, group:

  Arguments describing the shape and column names of `data`. They are
  used to reshape `data` before resampling; the resampled sequences are
  then fitted in wide form, so only `group` is forwarded to
  [`fit_tna()`](https://mohsaqr.github.io/simulab/reference/fit_tna.md).
  `group` resamples within each group.

- seed:

  Optional single seed, restored on exit and recorded on the result.

- ...:

  Further arguments passed to
  [`fit_tna()`](https://mohsaqr.github.io/simulab/reference/fit_tna.md).

## Value

A `simulab_sim` edge list with one row per repetition and transition: a
leading `iteration` column followed by the columns
[`fit_tna()`](https://mohsaqr.github.io/simulab/reference/fit_tna.md)
returns. The `summary` component holds one row per edge (per group, when
`group` is given) with the bootstrap `mean`, `sd`, and the 2.5% and
97.5% percentiles as `lower` and `upper`.

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
