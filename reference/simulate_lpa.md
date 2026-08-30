# Simulate a latent profile model

Simulate a latent profile model

## Usage

``` r
simulate_lpa(
  n,
  means,
  sds = 1,
  proportions = NULL,
  correlations = NULL,
  labels = NULL,
  seed = NULL
)
```

## Arguments

- n:

  Number of observations.

- means:

  Profile-by-variable mean matrix, or a tidy data frame with columns
  `profile`, `variable` and `mean`.

- sds:

  Scalar, per-variable vector, profile-by-variable matrix, or a tidy
  data frame with columns `profile`, `variable` and `sd`.

- proportions:

  Profile proportions.

- correlations:

  Optional list of within-profile correlation matrices, or a tidy data
  frame with columns `profile`, `row`, `column` and `correlation`.

- labels:

  Optional profile labels.

- seed:

  Optional random seed.

## Value

A `simulab_sim` base `data.frame` with true profile and parameters.

## Examples

``` r
# `means` is one row per profile and one column per indicator.
result <- simulate_lpa(
  n = 200,
  means = matrix(c(0, 0, 3, 3), nrow = 2, byrow = TRUE),
  proportions = c(0.6, 0.4),
  seed = 1
)
head(result)
#> <simulab_sim:lpa> 6 rows x 4 columns
#>   id   profile indicator_1 indicator_2
#> 1  1 Profile 1 -0.62036668 -1.25328976
#> 2  2 Profile 1  0.04211587  0.64224131
#> 3  3 Profile 1 -0.91092165 -0.04470914
#> 4  4 Profile 2  2.66571864  2.74883541
#> 5  5 Profile 1  0.15802877 -1.73321841
#> 6  6 Profile 2  3.73275004  1.57000655
as.data.frame(result, what = "parameters")
#>     profile    variable mean sd proportion
#> 1 Profile 1 indicator_1    0  1        0.6
#> 2 Profile 2 indicator_1    3  1        0.4
#> 3 Profile 1 indicator_2    0  1        0.6
#> 4 Profile 2 indicator_2    3  1        0.4
```
