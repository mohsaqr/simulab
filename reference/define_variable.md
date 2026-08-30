# Define one simulated variable

Define one simulated variable

## Usage

``` r
define_variable(
  name,
  formula,
  variance = 0,
  distribution = .simulab_distributions,
  link = c("identity", "log", "logit")
)
```

## Arguments

- name:

  Variable name.

- formula:

  Numeric value, expression string, or one-sided formula that defines
  the distribution mean or probability.

- variance:

  Variance, dispersion, precision, trial count, category labels, or
  distribution-specific secondary parameter.

- distribution:

  Distribution name.

- link:

  Link applied to `formula`.

## Value

A one-row `simulab_spec` base `data.frame`.

## Examples

``` r
define_variable(
  name = "score",
  formula = 50,
  variance = 100,
  distribution = "normal"
)
#>   variable distribution formula variance     link
#> 1    score       normal      50      100 identity
```
