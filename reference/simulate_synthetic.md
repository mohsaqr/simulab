# Simulate row-bootstrap synthetic data

Simulate row-bootstrap synthetic data

## Usage

``` r
simulate_synthetic(
  data,
  n = nrow(data),
  variables = NULL,
  id = "id",
  seed = NULL,
  batch = NULL
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

A `simulab_sim` base `data.frame` with `n` rows of jointly resampled
values, the identifier column first.
`as.data.frame(x, what = "provenance")` gives the source row each
synthetic row was drawn from.

## Examples

``` r
set.seed(1)
source_data <- data.frame(id = 1:100, x = stats::rnorm(100), y = stats::runif(100))
result <- simulate_synthetic(source_data, n = 50, seed = 1)
head(result)
#> <simulab_sim:synthetic> 6 rows x 3 columns
#>   id           x         y
#> 1  1  1.46555486 0.7547056
#> 2  2  1.10002537 0.4296244
#> 3  3 -0.62645381 0.2675082
#> 4  4 -0.05380504 0.6314202
#> 5  5  1.06309984 0.3214921
#> 6  6  0.69696338 0.9103703
#> 
#> Other tables: provenance. Read one with as.data.frame(x, what = "provenance").
```
