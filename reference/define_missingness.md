# Define missingness for one variable

Records the rule that decides whether one variable is missing for a row.
The rule is a formula evaluated row by row against the data, so
missingness may depend on any column: on a fully observed covariate,
which is MAR, or on the variable's own value, which is MNAR.

## Usage

``` r
define_missingness(
  variable,
  formula,
  link = c("identity", "logit"),
  baseline = FALSE,
  monotone = FALSE
)
```

## Arguments

- variable:

  Variable that may be missing. A single non-empty string.

- formula:

  Missingness formula, given as a number, a string, or an unquoted
  expression over the data columns. It is read as a probability under
  the identity link and as log odds under the logit link. It is stored
  as text and evaluated row by row.

- link:

  Scale the formula is stated on, one of `"identity"` (the default) or
  `"logit"`.

- baseline:

  Replace every period's draw for a unit with its first period's draw,
  so the unit is either always or never missing. A single flag,
  defaulting to `FALSE`. It needs `id` and `period` in
  [`missingness_matrix()`](https://mohsaqr.github.io/simulab/reference/missingness_matrix.md).

- monotone:

  Once missing, remain missing at every later period. A single flag,
  defaulting to `FALSE`. It needs `id` and `period` in
  [`missingness_matrix()`](https://mohsaqr.github.io/simulab/reference/missingness_matrix.md).

## Value

A one-row `simulab_missing_spec` base `data.frame` with the character
columns `variable`, `formula` and `link` and the logical columns
`baseline` and `monotone`.

## Examples

``` r
define_missingness("outcome", formula = "0.2")
#>   variable formula     link baseline monotone
#> 1  outcome     0.2 identity    FALSE    FALSE
```
