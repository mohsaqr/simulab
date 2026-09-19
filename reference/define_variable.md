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

  Numeric value, expression string, or one-sided formula giving the
  distribution's primary argument. For most families that is the mean or
  probability, but `"uniform"` and `"uniform_integer"` take
  `"minimum;maximum"`, `"categorical"` takes semicolon-separated
  category probabilities, `"mixture"` takes
  `"value | probability + ..."`, `"treatment"` takes semicolon-separated
  allocation ratios, `"cluster_size"` takes the total to be split, and
  `"custom"` takes the name of a generator function.

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
