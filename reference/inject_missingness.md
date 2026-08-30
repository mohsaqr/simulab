# Inject MCAR, MAR, or MNAR missingness

Inject MCAR, MAR, or MNAR missingness

## Usage

``` r
inject_missingness(
  data,
  mechanism = c("MCAR", "MAR", "MNAR"),
  proportion = 0.1,
  variables = NULL,
  predictor = NULL,
  seed = NULL
)
```

## Arguments

- data:

  Complete base `data.frame`.

- mechanism:

  Missingness mechanism.

- proportion:

  Target missing fraction.

- variables:

  Variables to make missing. `NULL` selects every variable.

- predictor:

  Observed predictor for MAR missingness.

- seed:

  Optional random seed.

## Value

A `simulab_sim` base `data.frame`. The cell-level missingness mask is
available with `as.data.frame(x, what = "missingness")`.

## Examples

``` r
data <- data.frame(id = 1:200, x = stats::rnorm(200), y = stats::rnorm(200))

result <- inject_missingness(
  data, mechanism = "MCAR", proportion = 0.2, variables = "y", seed = 1
)
head(result)
#> <simulab_sim:missingness> 6 rows x 3 columns
#>   id          x          y
#> 1  1  1.0744410 -0.3410670
#> 2  2  1.8956548  1.5024245
#> 3  3 -0.6029973  0.5283077
#> 4  4 -0.3908678  0.5421914
#> 5  5 -0.4162220 -0.1366734
#> 6  6 -0.3756574 -1.1367339

# MAR missingness in `y` driven by the observed predictor `x`.
head(inject_missingness(
  data, mechanism = "MAR", proportion = 0.2,
  variables = "y", predictor = "x", seed = 1
))
#> <simulab_sim:missingness> 6 rows x 3 columns
#>   id          x          y
#> 1  1  1.0744410         NA
#> 2  2  1.8956548         NA
#> 3  3 -0.6029973  0.5283077
#> 4  4 -0.3908678  0.5421914
#> 5  5 -0.4162220 -0.1366734
#> 6  6 -0.3756574 -1.1367339
```
