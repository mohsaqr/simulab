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
  seed = NULL,
  batch = NULL
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

  Optional random seed. A single number makes the call reproducible and
  restores the session's random-number state afterwards; `NULL` (the
  default) draws from the session's stream and advances it.

- batch:

  Optional single positive whole number. When given, the simulator runs
  `batch` times and returns a plain `list` of `batch` results, each
  exactly what the same call without `batch` returns. With a `seed`,
  every dataset gets its own seed drawn from `seed`, so the whole batch
  is reproducible; without one the datasets are consecutive draws from
  the session's random-number stream. The default `NULL` returns a
  single result.

## Value

A `simulab_sim` base `data.frame` with `n` rows and columns `id` and
`variable`, one generated density value per row.
`as.data.frame(x, what = "source")` gives a one-row summary of the
source values.

## References

Silverman, B. W. (1986). *Density Estimation for Statistics and Data
Analysis*. Chapman and Hall.

## Examples

``` r
set.seed(1)
values <- stats::rnorm(200, mean = 5, sd = 2)
result <- simulate_density(n = 100, values = values, variable = "score", seed = 1)
head(result)
#> <simulab_sim:density> 6 rows x 2 columns
#>   id    score
#> 1  1 6.361205
#> 2  2 4.901417
#> 3  3 4.377261
#> 4  4 9.569445
#> 5  5 4.969786
#> 6  6 5.088797
#> 
#> Other tables: source. Read one with as.data.frame(x, what = "source").
```
