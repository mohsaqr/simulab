# Simulate proportional-hazards survival data with calibrated censoring

Draws independent covariates, multiplies the baseline cumulative hazard
by `exp(x %*% coefficients)`, and inverts it to an event time, so the
model is proportional hazards and each coefficient is a log hazard
ratio. The three baselines are, for a unit with linear predictor `eta`,
Weibull `H(t) = rate * exp(eta) * t^shape`, exponential
`H(t) = rate * exp(eta) * t`, and Gompertz
`H(t) = rate * exp(eta) * (exp(shape * t) - 1) / shape`. Censoring is
random, not administrative: an independent exponential censoring time is
drawn for every unit, its rate solved so that the expected censored
fraction equals `censoring`.

## Usage

``` r
simulate_proportional_survival(
  n,
  coefficients,
  baseline = c("weibull", "exponential", "gompertz"),
  rate = 0.1,
  shape = 1,
  censoring = 0.3,
  covariate_distribution = c("normal", "binary"),
  seed = NULL
)
```

## Arguments

- n:

  Sample size. A single whole number of at least 5.

- coefficients:

  Covariate log-hazard coefficients, a numeric vector with at least one
  element and one entry per covariate. Its names become the covariate
  columns; unnamed vectors are named `X1`, `X2`, and so on.

- baseline:

  Baseline hazard family, one of `"weibull"` (the default),
  `"exponential"` or `"gompertz"`.

- rate:

  Positive scale factor of the baseline cumulative hazard. A single
  positive number, defaulting to `0.1`. It is the constant hazard when
  `baseline` is `"exponential"`.

- shape:

  Positive shape of the Weibull or Gompertz baseline, in the textbook
  parameterization of the formulas above (so the hazard rises with time
  when `shape` is above 1 for a Weibull baseline). A single positive
  number, defaulting to `1`. It is ignored for an exponential baseline.

- censoring:

  Target fraction of censored observations. A single number in `[0, 1)`,
  defaulting to `0.3`. Exactly `0` turns censoring off and every
  observation is then an event; the realized fraction is random around
  the target otherwise.

- covariate_distribution:

  Distribution the covariates are drawn from, independently, one of
  `"normal"` (the default, standard normal) or `"binary"` (Bernoulli
  with probability 0.5).

- seed:

  Optional random seed. A single number, or `NULL` (the default).

## Value

A `simulab_sim` base `data.frame` with one row per unit and columns
`id`, `time` (the observed time, the smaller of the event and censoring
times), the integer `status` (**`1` for an event and `0` for a censored
observation**), and one covariate column per entry of `coefficients`.
Components: `parameters` (one row per term, columns `term` and `value`,
holding the coefficients followed by `baseline_rate`, `shape` and the
solved `censoring_rate`) and `diagnostics` (one row, columns
`target_censoring`, `realized_censoring` and `baseline`).

## Examples

``` r
result <- simulate_proportional_survival(
  n = 200,
  coefficients = c(x1 = 0.7),
  shape = 1.5,
  censoring = 0.2,
  seed = 1
)
head(result)
#> <simulab_sim:proportional_survival> 6 rows x 4 columns
#>   id      time status         x1
#> 1  1 3.4716735      1 -0.6264538
#> 2  2 1.8516781      0  0.1836433
#> 3  3 0.8889412      1 -0.8356286
#> 4  4 0.4992354      1  1.5952808
#> 5  5 0.5960112      1  0.3295078
#> 6  6 1.1976905      0 -0.8204684
as.data.frame(result, what = "parameters")
#>             term      value
#> 1             x1 0.70000000
#> 2  baseline_rate 0.10000000
#> 3          shape 1.50000000
#> 4 censoring_rate 0.05520726
```
