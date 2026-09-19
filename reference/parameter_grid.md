# Generate parameter combinations

Generate parameter combinations

## Usage

``` r
parameter_grid(
  ...,
  n = 10L,
  method = c("grid", "random", "latin_hypercube"),
  seed = NULL
)
```

## Arguments

- ...:

  Named vectors, one per parameter. Under `method = "grid"` every
  element is a level of a full factorial crossing. Under the sampling
  methods a length-2 numeric vector is read as a `c(minimum, maximum)`
  range to draw from, and any other vector is sampled from with
  replacement.

- n:

  Single positive whole number of rows to draw for the `"random"` and
  `"latin_hypercube"` methods, default `10`. Ignored by `"grid"`, whose
  row count is the product of the parameter lengths.

- method:

  One of `"grid"` (the default), `"random"`, or `"latin_hypercube"`.

- seed:

  Optional single random seed. It is applied for the sampling methods
  only and is restored on exit.

## Value

A base `data.frame` with one row per parameter combination, a leading
`scenario_id` column numbering the rows, and then one column per
parameter in the order given.

## Examples

``` r
# Full factorial grid over named parameters.
parameter_grid(sample_size = c(50, 100), effect = c(0.2, 0.5))
#>   scenario_id sample_size effect
#> 1           1          50    0.2
#> 2           2         100    0.2
#> 3           3          50    0.5
#> 4           4         100    0.5

# Latin-hypercube sample of `n` draws over two ranges. Grid parameters are
# passed through `...`, so none of them may be called `n`, `method` or `seed`.
parameter_grid(
  sample_size = c(50, 200), effect = c(0, 1),
  n = 5, method = "latin_hypercube", seed = 1
)
#>   scenario_id sample_size    effect
#> 1           1   193.94954 0.3646886
#> 2           2   122.81440 0.8460317
#> 3           3   142.75377 0.7231793
#> 4           4    98.83628 0.4625954
#> 5           5    72.03474 0.1588051
```
