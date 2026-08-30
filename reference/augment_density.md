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

  Numeric source values.

- variable:

  Name of the new variable.

- use_limits, keep_missing, seed:

  Density-simulation arguments.

## Value

A `simulab_sim` base `data.frame` with the density variable added.

## Examples

``` r
values <- stats::rnorm(200, mean = 5, sd = 2)
data <- data.frame(id = 1:50)
result <- augment_density(data, values = values, variable = "score", seed = 1)
head(result)
#> <simulab_sim:augmented_density> 6 rows x 2 columns
#>   id     score
#> 1  1  6.781219
#> 2  2  3.460304
#> 3  3  4.658483
#> 4  4 10.128057
#> 5  5  5.273414
#> 6  6  5.401585
```
