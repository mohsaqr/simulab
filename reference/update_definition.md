# Update one variable definition

Update one variable definition

## Usage

``` r
update_definition(
  specification,
  variable,
  formula = NULL,
  variance = NULL,
  distribution = NULL,
  link = NULL
)
```

## Arguments

- specification:

  A `simulab_spec` object in the `formula`/`variance` column form, as
  created by
  [`define_variable()`](https://mohsaqr.github.io/simulab/reference/define_variable.md),
  [`repeat_variables()`](https://mohsaqr.github.io/simulab/reference/repeat_variables.md)
  or
  [`read_definitions()`](https://mohsaqr.github.io/simulab/reference/read_definitions.md).

- variable:

  Variable to update.

- formula, variance, distribution, link:

  Replacement values. `NULL` keeps the existing value.

## Value

An updated `simulab_spec` base `data.frame`.

## Examples

``` r
specification <- define_variables(
  define_variable("a", formula = "0", variance = "1", distribution = "normal")
)
update_definition(specification, variable = "a", formula = "5")
#>   variable distribution formula variance     link
#> 1        a       normal       5        1 identity
```
