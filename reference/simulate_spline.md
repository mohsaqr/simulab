# Add a spline-generated variable

Add a spline-generated variable

## Usage

``` r
simulate_spline(
  data,
  predictor,
  variable,
  coefficients,
  knots = c(0.25, 0.5, 0.75),
  degree = 3L,
  output_range = NULL,
  noise_variance = 0,
  seed = NULL
)
```

## Arguments

- data:

  Base `data.frame`.

- predictor:

  Predictor variable.

- variable:

  Name of the generated variable.

- coefficients:

  Spline coefficients.

- knots:

  Quantile probabilities for interior knots.

- degree:

  Polynomial degree.

- output_range:

  Optional output range.

- noise_variance:

  Non-negative Gaussian noise variance.

- seed:

  Optional random seed.

## Value

A `simulab_sim` base `data.frame` with the spline variable and a tidy
basis table.

## Examples

``` r
data <- data.frame(id = 1:100, x = stats::runif(100))
result <- simulate_spline(
  data, predictor = "x", variable = "y",
  coefficients = c(0.1, 0.2, 0.5, 0.4, 0.7, 0.6, 0.9),
  knots = c(0.25, 0.5, 0.75), seed = 1
)
head(result)
#> <simulab_sim:spline> 6 rows x 3 columns
#>   id         x         y
#> 1  1 0.9390541 0.7459875
#> 2  2 0.5585891 0.4881785
#> 3  3 0.5710001 0.4964202
#> 4  4 0.1073091 0.2323486
#> 5  5 0.3887622 0.4466184
#> 6  6 0.9774780 0.8660810
```
