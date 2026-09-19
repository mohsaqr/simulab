# Add jointly resampled source variables to existing data

Add jointly resampled source variables to existing data

## Usage

``` r
augment_synthetic(data, source, variables = NULL, seed = NULL)
```

## Arguments

- data:

  Destination base `data.frame`.

- source:

  Source base `data.frame`.

- variables:

  Variables to resample. `NULL`, the default, resamples every variable
  in `source`.

- seed:

  Optional random seed.

## Value

A `simulab_sim` base `data.frame` with the resampled variables added,
one source row drawn per row of `data`.
`as.data.frame(x, what = "provenance")` gives the source row each
destination row was drawn from.

## Examples

``` r
source_data <- data.frame(x = stats::rnorm(100))
data <- data.frame(id = 1:20)
result <- augment_synthetic(data, source = source_data, variables = "x", seed = 1)
head(result)
#> <simulab_sim:augmented_synthetic> 6 rows x 2 columns
#>   id          x
#> 1  1 -0.9681258
#> 2  2  1.1533758
#> 3  3 -0.4293801
#> 4  4 -1.5625184
#> 5  5 -0.9414981
#> 6  6  1.1001897
```
