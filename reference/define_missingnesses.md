# Combine missingness definitions into a specification

Combine missingness definitions into a specification

## Usage

``` r
define_missingnesses(...)
```

## Arguments

- ...:

  Either the columns of a specification given as named vectors
  (`variable`, `formula`, `link`, `baseline`, `monotone`), or objects
  created by
  [`define_missingness()`](https://mohsaqr.github.io/simulab/reference/define_missingness.md).
  The two forms cannot be mixed in one call.

  In the column form, `variable` and `formula` are required. A column
  given as a single value is recycled across every variable. `link`
  defaults to `"identity"`, and `baseline` and `monotone` to `FALSE`.

## Value

A `simulab_missing_spec` base `data.frame` with one row per target
variable.

## Examples

``` r
# One call, named arguments, one row per target variable.
define_missingnesses(
  variable = c("outcome", "baseline"),
  formula  = c("0.2", "0.1")
)
#>   variable formula     link baseline monotone
#> 1  outcome     0.2 identity    FALSE    FALSE
#> 2 baseline     0.1 identity    FALSE    FALSE

# `monotone` keeps a unit missing at every later period once it drops out.
define_missingnesses(
  variable = c("outcome", "baseline"),
  formula  = c("0.2", "0.1"),
  monotone = TRUE
)
#>   variable formula     link baseline monotone
#> 1  outcome     0.2 identity    FALSE     TRUE
#> 2 baseline     0.1 identity    FALSE     TRUE

# Definitions built one at a time are still accepted.
define_missingnesses(
  define_missingness("outcome", formula = "0.2"),
  define_missingness("baseline", formula = "0.1")
)
#>   variable formula     link baseline monotone
#> 1  outcome     0.2 identity    FALSE    FALSE
#> 2 baseline     0.1 identity    FALSE    FALSE
```
