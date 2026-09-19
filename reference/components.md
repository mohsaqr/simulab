# List the tidy tables available from a simulation

List the tidy tables available from a simulation

## Usage

``` r
components(x)
```

## Arguments

- x:

  A `simulab_sim` object.

## Value

A base `data.frame` with one row per available table and the columns
`table` (the name to pass as `what` to
[`as.data.frame()`](https://rdrr.io/r/base/as.data.frame.html)), `rows`
and `columns`. The first row is always the primary `"data"` table; a
result that carries no extra tables returns that single row.

## Examples

``` r
result <- simulate_ttest(
  n_a = 10,
  n_b = 10,
  mean_a = 0,
  mean_b = 0.5,
  seed = 1
)
components(result)
#>        table rows columns
#> 1       data   20       3
#> 2 parameters    2       4
#> 3    effects    1       4
```
