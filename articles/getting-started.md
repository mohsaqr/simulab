# Getting started with simulab

`simulab` separates a simulation into three ideas: define the
data-generating process, generate primary observations, and retrieve
known truth as tidy tables.

## A declarative study

``` r

library(simulab)

specification <- define_variables(
  variable     = c("baseline", "treatment", "outcome"),
  formula      = c("0", "0.5", "0.5 * baseline + treatment"),
  variance     = c("1", "0", "1"),
  distribution = c("normal", "binary", "normal")
)

study <- simulate_study(200, specification, seed = 42)
head(study)
#> <simulab_sim:study> 6 rows x 4 columns
#>   id   baseline treatment    outcome
#> 1  1  1.3709584         0  0.6808585
#> 2  2 -0.5646982         1  1.4778931
#> 3  3  0.3631284         1  1.2205551
#> 4  4  0.6328626         0  1.0515034
#> 5  5  0.4042683         1  1.0556615
#> 6  6 -0.1061245         0 -0.1109496
components(study)
#>         table rows columns
#> 1        data  200       4
#> 2 definitions    3       5
#> 3    metadata    1       3
```

## Specialized data with ground truth

``` r

growth <- simulate_growth(
  n = 100,
  times = 0:4,
  intercept = 10,
  slope = 0.5,
  seed = 42
)

head(growth)
#> <simulab_sim:growth> 6 rows x 3 columns
#>   id time   outcome
#> 1  1    0  9.370029
#> 2  2    0  9.769079
#> 3  3    0 11.534454
#> 4  4    0 12.692402
#> 5  5    0  9.027407
#> 6  6    0  8.743020
as.data.frame(growth, what = "parameters")
#>          term value
#> 1   intercept  10.0
#> 2       slope   0.5
#> 3   quadratic   0.0
#> 4 residual_sd   1.0
```

## Repeated scenarios

``` r

scenarios <- scenario_grid(
  mean_b = c(0, 0.5),
  replications = 3
)

batch <- simulate_scenarios(
  scenarios,
  simulator = "ttest",
  n_a = 20,
  n_b = 20,
  mean_a = 0,
  seed = 100
)

head(batch)
#> <simulab_sim:scenarios> 6 rows x 5 columns
#>   scenario_id replication id group     outcome
#> 1           1           1  1     A -0.50219235
#> 2           1           1  2     A  0.13153117
#> 3           1           1  3     A -0.07891709
#> 4           1           1  4     A  0.88678481
#> 5           1           1  5     A  0.11697127
#> 6           1           1  6     A  0.31863009
```
