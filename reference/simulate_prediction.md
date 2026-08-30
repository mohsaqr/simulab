# Simulate a prediction design with continuous and categorical predictors

Simulate a prediction design with continuous and categorical predictors

## Usage

``` r
simulate_prediction(
  n,
  coefficients,
  categorical_levels = NULL,
  categorical_effects = NULL,
  category_probabilities = NULL,
  predictor_means = 0,
  predictor_sds = 1,
  error_sd = 1,
  outcome = "outcome",
  seed = NULL
)
```

## Arguments

- n:

  Sample size.

- coefficients:

  Named continuous-predictor coefficients with optional `(Intercept)`.

- categorical_levels:

  Named list of levels for categorical predictors, or a tidy data frame
  with columns `variable` and `level`. Optional `effect` and
  `probability` columns in that table supply `categorical_effects` and
  `category_probabilities`, so one table replaces all three arguments.

- categorical_effects:

  Named list of level effects matching `categorical_levels`.

- category_probabilities:

  Optional named list of sampling probabilities.

- predictor_means, predictor_sds:

  Continuous-predictor parameters.

- error_sd:

  Residual standard deviation.

- outcome:

  Outcome-column name.

- seed:

  Optional random seed.

## Value

A `simulab_sim` base `data.frame` with coefficient, categorical effect,
and population R-squared tables.

## Examples

``` r
result <- simulate_prediction(
  n = 200,
  coefficients = c("(Intercept)" = 0.5, x1 = 1, x2 = -1),
  seed = 1
)
head(result)
#> <simulab_sim:regression> 6 rows x 4 columns
#>   id         x1         x2    outcome
#> 1  1 -0.6264538  0.4094018  0.5385853
#> 2  2  0.1836433  1.6888733  0.8904248
#> 3  3 -0.8356286  1.5865884 -2.5252143
#> 4  4  1.5952808 -0.3309078  2.0353208
#> 5  5  0.3295078 -2.2852355  2.6985213
#> 6  6 -0.8204684  2.4976616 -3.1937874
as.data.frame(result, what = "coefficients")
#>          term coefficient
#> 1 (Intercept)         0.5
#> 2          x1         1.0
#> 3          x2        -1.0
```
