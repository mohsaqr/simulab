# Add correlated variables to existing data

Add correlated variables to existing data

## Usage

``` r
augment_correlated(
  data,
  specification,
  rho = 0,
  tau = NULL,
  structure = c("independent", "exchangeable", "ar1", "custom"),
  correlation = NULL,
  group = NULL,
  seed = NULL,
  envir = parent.frame()
)
```

## Arguments

- data:

  Base `data.frame`.

- specification:

  New variable definitions, in the `formula`/`variance` column form
  built by
  [`define_variable()`](https://mohsaqr.github.io/simulab/reference/define_variable.md).
  Unlike
  [`simulate_copula()`](https://mohsaqr.github.io/simulab/reference/simulate_copula.md),
  `augment_correlated()` does not accept the distribution-call form, and
  one row of `specification` is one new variable. None of the named
  variables may already exist in `data`.

- rho, tau, structure, correlation:

  Copula correlation arguments. `structure` follows the same resolution
  rule as
  [`simulate_copula()`](https://mohsaqr.github.io/simulab/reference/simulate_copula.md):
  leaving it unset selects `"exchangeable"` when a non-zero `rho` or
  `tau` is given. `tau` is converted to the latent Pearson correlation
  `sin(pi * tau / 2)`.

- group:

  Optional grouping variable. With grouping, one definition is generated
  as correlated observations within each group.

- seed:

  Optional random seed.

- envir:

  Formula evaluation environment.

## Value

A `simulab_sim` base `data.frame` holding every column of `data` plus
one column per new variable. Two tidy tables come from
[`as.data.frame()`](https://rdrr.io/r/base/as.data.frame.html):
`what = "definitions"` restates the specification, and
`what = "latent_correlation"` describes the latent Gaussian correlation.
Without `group` that table has one row per correlation-matrix cell, with
columns `row`, `column` and `correlation`; with `group` the correlation
is across the observations inside each group, so the table instead has
one row per group with columns `group`, `observations`, `rho` and
`structure`.

## Examples

``` r
data <- data.frame(id = 1:100)
specification <- define_variables(
  define_variable("a", formula = "0", variance = "1", distribution = "normal"),
  define_variable("b", formula = "0", variance = "1", distribution = "normal")
)
result <- augment_correlated(data, specification = specification, rho = 0.5, seed = 1)
head(result)
#> <simulab_sim:augmented_correlated> 6 rows x 3 columns
#>   id          a          b
#> 1  1 -0.7656706 -0.7613664
#> 2  2  0.1882862  0.0882112
#> 3  3 -1.0429191 -1.0961593
#> 4  4  1.5818238  0.5655331
#> 5  5  0.1488611 -0.5469973
#> 6  6 -0.3351040  1.4947156
```
