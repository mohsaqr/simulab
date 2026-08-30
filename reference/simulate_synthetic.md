# Simulate row-bootstrap synthetic data

Simulate row-bootstrap synthetic data

## Usage

``` r
simulate_synthetic(
  data,
  n = nrow(data),
  variables = NULL,
  id = "id",
  seed = NULL
)
```

## Arguments

- data:

  Source base `data.frame`.

- n:

  Number of synthetic observations.

- variables:

  Variables to sample. `NULL` selects every non-identifier variable.

- id:

  Identifier variable in the result.

- seed:

  Optional random seed.

## Value

A `simulab_sim` base `data.frame` with jointly resampled rows.

## Examples

``` r
source_data <- data.frame(id = 1:100, x = stats::rnorm(100), y = stats::runif(100))
result <- simulate_synthetic(source_data, n = 50, seed = 1)
head(result)
#> <simulab_sim:synthetic> 6 rows x 3 columns
#>   id           x          y
#> 1  1  0.95128307 0.47347613
#> 2  2 -0.80686530 0.37747662
#> 3  3 -0.65854506 0.36668013
#> 4  4  0.08223295 0.81356647
#> 5  5 -0.22485900 0.88616309
#> 6  6 -0.38808828 0.01565196
```
