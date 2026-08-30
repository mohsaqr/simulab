# Calibrate logistic coefficients to prevalence and treatment contrast

Calibrate logistic coefficients to prevalence and treatment contrast

## Usage

``` r
calibrate_logistic(
  data,
  coefficients,
  prevalence,
  risk_ratio = NULL,
  risk_difference = NULL,
  treatment = "treatment",
  treatment_prevalence = 0.5,
  auc = NULL,
  tolerance = 1e-08
)
```

## Arguments

- data:

  Covariate data.

- coefficients:

  Named covariate coefficients.

- prevalence:

  Target population prevalence.

- risk_ratio:

  Optional treated/control risk ratio.

- risk_difference:

  Optional treated-control risk difference.

- treatment:

  Name for the optional treatment coefficient.

- treatment_prevalence:

  Treatment prevalence used for calibration.

- auc:

  Optional target population area under the ROC curve. Covariate
  coefficients are proportionally scaled to reach this target.

- tolerance:

  Numerical root tolerance.

## Value

A base `data.frame` with one row per calibrated coefficient.

## Examples

``` r
set.seed(1)
covariates <- data.frame(x1 = stats::rnorm(200), x2 = stats::rnorm(200))

calibrate_logistic(
  covariates, coefficients = c(x1 = 0.5, x2 = -0.3), prevalence = 0.2
)
#>          term coefficient calibration coefficient_scale
#> 1 (Intercept)    -1.48188  prevalence                 1
#> 2          x1     0.50000  prevalence                 1
#> 3          x2    -0.30000  prevalence                 1

# Scale the coefficients to hit a target discrimination instead.
calibrate_logistic(
  covariates, coefficients = c(x1 = 0.5, x2 = -0.3),
  prevalence = 0.2, auc = 0.75
)
#>          term coefficient calibration coefficient_scale
#> 1 (Intercept)  -1.6789042         auc          1.843123
#> 2          x1   0.9215615         auc          1.843123
#> 3          x2  -0.5529369         auc          1.843123
```
