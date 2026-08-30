# Combine conditional data-generation rules into a specification

Combine conditional data-generation rules into a specification

## Usage

``` r
define_conditions(...)
```

## Arguments

- ...:

  One of three forms.

  **Rules.** `outcome = when(group == 1, normal(mean = 5, sd = 1))`
  names the variable with the argument name, states the condition that
  selects the rows the rule writes, and states their distribution as a
  call. Any distribution in
  [`list_distributions()`](https://mohsaqr.github.io/simulab/reference/list_distributions.md)
  may be used, and its parameters may be expressions over the data.
  Repeating the argument name gives one variable several rules, which is
  how a variable takes a different distribution in each group.
  `when(TRUE, ...)` applies to every row.

  **Specification columns** given as named vectors (`variable`,
  `condition`, `formula`, `variance`, `distribution`, `link`).

  **Objects** created by
  [`define_condition()`](https://mohsaqr.github.io/simulab/reference/define_condition.md).

  The forms cannot be mixed in one call.

  In the column form, `variable`, `condition` and `formula` are
  required. A column given as a single value is recycled across every
  rule. `variance` defaults to 0, `distribution` to `"normal"`, and
  `link` to `"identity"`.

## Value

A `simulab_condition_spec` base `data.frame`. Rules written with
`when()` give one row per parameter, with columns `rule`, `variable`,
`condition`, `distribution`, `parameter` and `value`; the other two
forms give one row per rule with the `formula`/`variance` columns.

## Examples

``` r
# Rules. One line per rule; a repeated name gives a variable several rules.
define_conditions(
  outcome = when(group == 1, normal(mean = 5, sd = 1)),
  outcome = when(group == 0, poisson(lambda = 2)),
  bonus   = when(group == 1, gamma(shape = 2, rate = 0.5))
)
#>   rule variable  condition distribution parameter value
#> 1    1  outcome group == 1       normal      mean     5
#> 2    1  outcome group == 1       normal        sd     1
#> 3    2  outcome group == 0      poisson    lambda     2
#> 4    3    bonus group == 1        gamma     shape     2
#> 5    3    bonus group == 1        gamma      rate   0.5

# One call, named arguments, one row per rule.
define_conditions(
  variable  = c("outcome", "outcome"),
  condition = c("group == 1", "group == 0"),
  formula   = c("2", "0"),
  variance  = "1"
)
#>   variable  condition distribution formula variance     link
#> 1  outcome group == 1       normal       2        1 identity
#> 2  outcome group == 0       normal       0        1 identity

# Definitions built one at a time are still accepted.
define_conditions(
  define_condition("outcome", condition = "group == 1",
                   formula = "2", variance = "1", distribution = "normal"),
  define_condition("outcome", condition = "group == 0",
                   formula = "0", variance = "1", distribution = "normal")
)
#>   variable  condition distribution formula variance     link
#> 1  outcome group == 1       normal       2        1 identity
#> 2  outcome group == 0       normal       0        1 identity
```
