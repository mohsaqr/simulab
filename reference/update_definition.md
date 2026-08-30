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

  A `simulab_spec` object.

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
