# Simulate correlated ordinal variables

Simulate correlated ordinal variables

## Usage

``` r
simulate_ordinal(
  n,
  probabilities,
  n_variables = 1L,
  rho = 0,
  structure = c("independent", "exchangeable", "ar1", "custom"),
  correlation = NULL,
  labels = NULL,
  variable_names = NULL,
  seed = NULL
)
```

## Arguments

- n:

  Number of observations.

- probabilities:

  A numeric vector used for every variable or a matrix with one row per
  variable and one column per category.

- n_variables:

  Number of variables when `probabilities` is a vector.

- rho, structure, correlation:

  Correlation arguments for the latent normal variables. `structure`
  follows the same resolution rule as
  [`simulate_correlated()`](https://mohsaqr.github.io/simulab/reference/simulate_correlated.md):
  leaving it unset selects `"exchangeable"` when a non-zero `rho` is
  given. Passed to the latent Gaussian generator.

- labels:

  Optional category labels.

- variable_names:

  Optional variable names.

- seed:

  Optional random seed.

## Value

A `simulab_sim` base `data.frame` with one row per observation.

## Examples

``` r
result <- simulate_ordinal(
  n = 200, probabilities = c(0.2, 0.5, 0.3), n_variables = 2, rho = 0.4, seed = 1
)
head(result)
#> <simulab_sim:ordinal> 6 rows x 3 columns
#>   id V1 V2
#> 1  1  2  2
#> 2  2  3  3
#> 3  3  2  3
#> 4  4  3  2
#> 5  5  2  1
#> 6  6  2  3
as.data.frame(result, what = "probabilities")
#>   variable category probability
#> 1       V1        1         0.2
#> 2       V1        2         0.5
#> 3       V1        3         0.3
#> 4       V2        1         0.2
#> 5       V2        2         0.5
#> 6       V2        3         0.3
```
