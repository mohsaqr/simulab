# Define a conditional data-generation rule

Define a conditional data-generation rule

## Usage

``` r
define_condition(
  variable,
  condition,
  formula,
  variance = 0,
  distribution = .simulab_distributions,
  link = c("identity", "log", "logit")
)
```

## Arguments

- variable:

  Variable to create or replace.

- condition:

  Logical expression identifying affected rows.

- formula, variance, distribution, link:

  Generation arguments used for affected rows.

## Value

A one-row `simulab_condition_spec` base `data.frame`.

## Examples

``` r
define_condition(
  "outcome", condition = "group == 1",
  formula = "2", variance = "1", distribution = "normal"
)
#>   variable  condition distribution formula variance     link
#> 1  outcome group == 1       normal       2        1 identity
```
