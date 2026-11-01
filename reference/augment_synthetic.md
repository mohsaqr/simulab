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

  Optional random seed. A single number makes the call reproducible and
  restores the session's random-number state afterwards; `NULL` (the
  default) draws from the session's stream and advances it.

## Value

A `simulab_sim` base `data.frame` with the resampled variables added,
one source row drawn per row of `data`.
`as.data.frame(x, what = "provenance")` gives the source row each
destination row was drawn from.

## Examples

``` r
set.seed(1)
source_data <- data.frame(x = stats::rnorm(100))
data <- data.frame(id = 1:20)
result <- augment_synthetic(data, source = source_data, variables = "x", seed = 1)
head(result)
#> <simulab_sim:augmented_synthetic> 6 rows x 2 columns
#>   id           x
#> 1  1  1.46555486
#> 2  2  1.10002537
#> 3  3 -0.62645381
#> 4  4 -0.05380504
#> 5  5  1.06309984
#> 6  6  0.69696338
#> 
#> Other tables: provenance. Read one with as.data.frame(x, what = "provenance").
```
