# Apply a function across simulation results

Apply a function across simulation results

## Usage

``` r
apply_batch(inputs, fun, ..., id = "batch_id")
```

## Arguments

- inputs:

  List with at least one element, commonly data frames or simulation
  results. Element names label the batches; when `inputs` is unnamed the
  positions `"1"`, `"2"`, ... are used instead.

- fun:

  Function applied to each element. It must return a base `data.frame`,
  and every call must return the same columns, otherwise the run is an
  error.

- ...:

  Arguments passed to `fun`.

- id:

  Single string naming the batch-label column, default `"batch_id"`.

## Value

A base `data.frame` stacking the `fun` outputs by row, with the batch
label in a leading column named by `id`, so one row per row of each
output.

## Examples

``` r
inputs <- list(
  small = simulate_ttest(n_a = 20, n_b = 20, mean_a = 0, mean_b = 0.5, seed = 1),
  large = simulate_ttest(n_a = 60, n_b = 60, mean_a = 0, mean_b = 0.5, seed = 2)
)
apply_batch(inputs, fun = summary)
#>   batch_id variable     class observations missing unique       mean         sd
#> 1    small       id   integer           40       0     40 20.5000000 11.6904519
#> 2    small    group character           40       0      2         NA         NA
#> 3    small  outcome   numeric           40       0     40  0.3420262  0.8942982
#> 4    large       id   integer          120       0    120 60.5000000 34.7850543
#> 5    large    group character          120       0      2         NA         NA
#> 6    large  outcome   numeric          120       0    120  0.2819833  1.1451379
#>     minimum   maximum
#> 1  1.000000  40.00000
#> 2        NA        NA
#> 3 -2.214700   1.85868
#> 4  1.000000 120.00000
#> 5        NA        NA
#> 6 -2.451706   2.54804
```
