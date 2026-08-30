# Compare multiple TNA estimators on the same sequences

Compare multiple TNA estimators on the same sequences

## Usage

``` r
compare_tna_models(
  data,
  models = c("tna", "ftna", "ctna", "atna"),
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

  Sequence data accepted by
  [`fit_tna()`](https://mohsaqr.github.io/simulab/reference/fit_tna.md).

- models:

  One or more TNA model types.

- format, id, period, state, group:

  Input arguments passed to
  [`fit_tna()`](https://mohsaqr.github.io/simulab/reference/fit_tna.md).

- ...:

  Estimator arguments.

## Value

A tidy edge-list `simulab_sim` with one row per model/group/edge.

## Examples

``` r
data <- simulate_sequences(n = 40, n_states = 3, chain_length = 12, seed = 1)
if (requireNamespace("tna", quietly = TRUE)) {
  compare_tna_models(data, models = c("tna", "ftna"))
}
#> <simulab_sim:tna_comparison> 18 rows x 4 columns
#>    model    from      to      weight
#> 1    tna State 1 State 1  0.11046512
#> 2    tna State 2 State 1  0.56375839
#> 3    tna State 3 State 1  0.63865546
#> 4    tna State 1 State 2  0.37209302
#> 5    tna State 2 State 2  0.32885906
#> 6    tna State 3 State 2  0.32773109
#> 7    tna State 1 State 3  0.51744186
#> 8    tna State 2 State 3  0.10738255
#> 9    tna State 3 State 3  0.03361345
#> 10  ftna State 1 State 1 19.00000000
#> ... 8 more rows
```
