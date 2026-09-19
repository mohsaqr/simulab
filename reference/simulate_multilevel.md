# Simulate a two-level Gaussian model

Draws a random intercept (and optionally a random slope) per cluster,
draws the predictors independently for every unit, and forms the outcome
as the fixed part plus the cluster random effects plus normal residual
noise.

## Usage

``` r
simulate_multilevel(
  clusters,
  cluster_size,
  intercept = 0,
  slopes = numeric(0L),
  predictor_means = 0,
  predictor_sds = 1,
  random_intercept_sd = 1,
  random_slope_sd = 0,
  random_effect_correlation = 0,
  residual_sd = 1,
  seed = NULL
)
```

## Arguments

- clusters:

  Number of clusters. A single whole number of at least 2.

- cluster_size:

  Units per cluster: a single whole number recycled across clusters, or
  one whole number per cluster, so clusters may be unbalanced.

- intercept:

  Fixed intercept. A single number, defaulting to `0`.

- slopes:

  Named fixed-effect slopes; the names become the predictor columns of
  the returned data. Defaults to `numeric(0)`, an intercept-only model
  with no predictor columns.

- predictor_means, predictor_sds:

  Mean and standard deviation of each predictor, a scalar recycled
  across predictors (the defaults, `0` and `1`) or one value per entry
  of `slopes`. Predictors are drawn independently at the unit level, not
  at the cluster level, so they carry no between-cluster variance by
  construction.

- random_intercept_sd:

  Random-intercept standard deviation. A single non-negative number,
  defaulting to `1`.

- random_slope_sd:

  Random-slope standard deviation for the first predictor only; the
  remaining predictors have fixed slopes. A single non-negative number,
  defaulting to `0` (no random slope).

- random_effect_correlation:

  Correlation between random intercept and slope. A single number in
  `[-1, 1]`, defaulting to `0`.

- residual_sd:

  Residual standard deviation. A single positive number, defaulting to
  `1`.

- seed:

  Optional random seed.

## Value

A `simulab_sim` base `data.frame` with one row per unit
(`sum(cluster_size)` rows) and columns `id`, `cluster`, one column per
name of `slopes`, and `outcome`. Components: `fixed_effects` (one row
per fixed term, columns `term` and `coefficient`), `variance_components`
(one row for each of `random_intercept`, `random_slope` and `residual`,
columns `component` and `variance` – the *squared* standard deviations
supplied as arguments), and `random_effects` (one row per cluster,
columns `cluster`, `random_intercept` and `random_slope`; the
`random_slope` column is present but zero when `random_slope_sd = 0`).

## Examples

``` r
# `slopes` must be named; the names become the predictor columns.
result <- simulate_multilevel(
  clusters = 30,
  cluster_size = 10,
  intercept = 1,
  slopes = c(x1 = 0.5),
  random_intercept_sd = 0.8,
  seed = 1
)
head(result)
#> <simulab_sim:multilevel> 6 rows x 4 columns
#>   id cluster          x1     outcome
#> 1  1       1  2.40161776 -0.89268184
#> 2  2       1 -0.03924000  1.79321912
#> 3  3       1  0.68973936  0.20816363
#> 4  4       1  0.02800216  0.08285919
#> 5  5       1 -0.74327321 -0.04211799
#> 6  6       1  0.18879230  1.20545128
as.data.frame(result, what = "fixed_effects")
#>          term coefficient
#> 1 (Intercept)         1.0
#> 2          x1         0.5
as.data.frame(result, what = "variance_components")
#>          component variance
#> 1 random_intercept     0.64
#> 2     random_slope     0.00
#> 3         residual     1.00
```
