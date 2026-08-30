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

  Named vectors or two-value numeric ranges.

- n:

  Number of rows for random or Latin-hypercube designs.

- method:

  Full grid, random sampling, or Latin hypercube.

- seed:

  Optional random seed.

## Value

A base `data.frame` with one row per parameter combination.

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
