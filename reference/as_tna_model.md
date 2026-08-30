# Convert a tidy simulab TNA result to a native tna model

Convert a tidy simulab TNA result to a native tna model

## Usage

``` r
as_tna_model(x, group = NULL)
```

## Arguments

- x:

  A result from
  [`fit_tna()`](https://mohsaqr.github.io/simulab/reference/fit_tna.md)
  or
  [`simulate_group_tna()`](https://mohsaqr.github.io/simulab/reference/simulate_group_tna.md).

- group:

  Optional group name for a grouped model. When omitted, the complete
  native grouped model is returned.

## Value

A native `tna` or `group_tna` model object.

## Examples

``` r
data <- simulate_sequences(n = 40, n_states = 3, chain_length = 12, seed = 1)
if (requireNamespace("tna", quietly = TRUE)) {
  model <- as_tna_model(fit_tna(data, model = "tna"))
  class(model)
}
#> [1] "tna"
```
