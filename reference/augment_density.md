# Add an empirical-density variable to existing data

Add an empirical-density variable to existing data

## Usage

``` r
augment_density(
  data,
  values,
  variable,
  use_limits = FALSE,
  keep_missing = FALSE,
  seed = NULL
)
```

## Arguments

- data:

  Destination base `data.frame`.

- values:

  Numeric source values, of which at least two must be present and
  distinct.

- variable:

  Name of the new variable.

- use_limits, keep_missing, seed:

  Density-simulation arguments, as in
  [`simulate_density()`](https://pak.dynasite.org/simulab/reference/simulate_density.md).

## Value

A `simulab_sim` base `data.frame` with one row per row of `data`: the
columns of `data` followed by the drawn values in a column named by
`variable`.

## Examples

``` r
set.seed(1)
values <- stats::rnorm(200, mean = 5, sd = 2)
data <- data.frame(id = 1:50)
result <- augment_density(data, values = values, variable = "score", seed = 1)
head(result)
#> <simulab_sim:augmented_density> 6 rows x 2 columns
#>   id    score
#> 1  1 6.361205
#> 2  2 4.901417
#> 3  3 4.377261
#> 4  4 9.569445
#> 5  5 4.969786
#> 6  6 5.088797
```
