# Define missingness for one variable

Define missingness for one variable

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

  Variable that may be missing.

- formula:

  Probability or log-odds formula.

- link:

  Identity or logit link.

- baseline:

  Apply one baseline missingness draw to every period for a unit.

- monotone:

  Once missing, remain missing at later periods.

## Value

A one-row `simulab_missing_spec` base `data.frame`.

## Examples

``` r
define_missingness("outcome", formula = "0.2")
#>   variable formula     link baseline monotone
#> 1  outcome     0.2 identity    FALSE    FALSE
```
