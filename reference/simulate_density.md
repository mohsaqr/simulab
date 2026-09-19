# Simulate from an empirical kernel density

Simulate from an empirical kernel density

## Usage

``` r
simulate_density(
  n,
  values,
  variable = "value",
  use_limits = FALSE,
  keep_missing = FALSE,
  id = "id",
  seed = NULL
)
```

## Arguments

- n:

  Number of observations.

- values:

  Numeric source values, of which at least two must be present and
  distinct. Missing values are dropped before the density is estimated.

- variable:

  Output variable name.

- use_limits:

  Constrain draws to the observed range.

- keep_missing:

  Draw missing values at the source's missing-data rate, so the
  proportion is reproduced in expectation rather than exactly.

- id:

  Identifier variable name.

- seed:

  Optional random seed.

## Value

A `simulab_sim` base `data.frame` with `n` rows and columns `id` and
`variable`, one generated density value per row.
`as.data.frame(x, what = "source")` gives a one-row summary of the
source values.

## Examples

``` r
values <- stats::rnorm(200, mean = 5, sd = 2)
result <- simulate_density(n = 100, values = values, variable = "score", seed = 1)
head(result)
#> <simulab_sim:density> 6 rows x 2 columns
#>   id    score
#> 1  1 6.719921
#> 2  2 3.118475
#> 3  3 3.888691
#> 4  4 4.753282
#> 5  5 4.587366
#> 6  6 4.722838
```
