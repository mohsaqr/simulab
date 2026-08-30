# Combine variable definitions into a specification

Combine variable definitions into a specification

## Usage

``` r
define_variables(...)
```

## Arguments

- ...:

  One of three forms.

  **Distribution calls.** `age = normal(mean = 50, sd = 10)` names the
  variable with the argument name and states its distribution as a call.
  Parameters may be given positionally or by name, in the order
  [`list_distributions()`](https://mohsaqr.github.io/simulab/reference/list_distributions.md)
  reports. A parameter may be any expression over variables defined
  earlier in the same call, so
  `outcome = normal(mean = 10 + 0.2 * age, sd = 2)` is a regression.
  Distribution names are never evaluated, so
  [`gamma()`](https://rdrr.io/r/base/Special.html),
  [`beta()`](https://rdrr.io/r/base/Special.html) and
  [`t()`](https://rdrr.io/r/base/t.html) do not reach the base functions
  of those names.

  **Specification columns** given as named vectors (`variable`,
  `formula`, `variance`, `distribution`, `link`).

  **Objects** created by
  [`define_variable()`](https://mohsaqr.github.io/simulab/reference/define_variable.md)
  or
  [`repeat_variables()`](https://mohsaqr.github.io/simulab/reference/repeat_variables.md).

  The forms cannot be mixed in one call.

  In the column form, `variable` and `formula` are required. A column
  given as a single value is recycled across every variable. `variance`
  defaults to 0, `distribution` to `"normal"`, and `link` to
  `"identity"`.

## Value

A `simulab_spec` base `data.frame` with one row per variable and columns
`variable`, `distribution`, `formula`, `variance` and `link`.

## Examples

``` r
# Distribution calls. The variable name is the argument name.
define_variables(
  age     = normal(mean = 50, sd = 10),
  treated = binary(prob = 0.5),
  outcome = normal(mean = 10 + 0.2 * age + 2 * treated, sd = 2)
)
#>   variable distribution parameter                        value
#> 1      age       normal      mean                           50
#> 2      age       normal        sd                           10
#> 3  treated       binary      prob                          0.5
#> 4  outcome       normal      mean 10 + 0.2 * age + 2 * treated
#> 5  outcome       normal        sd                            2

# Parameters may be positional, in the order list_distributions() reports.
define_variables(y = normal(5, 1), count = poisson(3))
#>   variable distribution parameter value
#> 1        y       normal      mean     5
#> 2        y       normal        sd     1
#> 3    count      poisson    lambda     3

# Specification columns. `formula` is the mean or linear predictor and may
# refer to variables defined earlier. `variance` is a variance, not a
# standard deviation.
define_variables(
  variable     = c("baseline", "treatment", "outcome"),
  formula      = c("0", "0.5", "0.4 * baseline + 0.8 * treatment"),
  variance     = c("1", "0", "1"),
  distribution = c("normal", "binary", "normal")
)
#>    variable distribution                          formula variance     link
#> 1  baseline       normal                                0        1 identity
#> 2 treatment       binary                              0.5        0 identity
#> 3   outcome       normal 0.4 * baseline + 0.8 * treatment        1 identity

# A column given once is recycled, so a specification that shares one
# distribution stays short.
define_variables(
  variable = c("x1", "x2", "x3"),
  formula  = "0",
  variance = "1"
)
#>   variable distribution formula variance     link
#> 1       x1       normal       0        1 identity
#> 2       x2       normal       0        1 identity
#> 3       x3       normal       0        1 identity

# Definitions built one at a time are still accepted.
define_variables(
  define_variable("age", formula = 40, variance = 100, distribution = "normal"),
  define_variable("treated", formula = 0.5, distribution = "binary")
)
#>   variable distribution formula variance     link
#> 1      age       normal      40      100 identity
#> 2  treated       binary     0.5        0 identity
```
