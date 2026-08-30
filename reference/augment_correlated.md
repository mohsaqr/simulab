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

  New variable definitions.

- rho, tau, structure, correlation:

  Copula correlation arguments. `structure` follows the same resolution
  rule as
  [`simulate_copula()`](https://mohsaqr.github.io/simulab/reference/simulate_copula.md):
  leaving it unset selects `"exchangeable"` when a non-zero `rho` or
  `tau` is given.

- group:

  Optional grouping variable. With grouping, one definition is generated
  as correlated observations within each group.

- seed:

  Optional random seed.

- envir:

  Formula evaluation environment.

## Value

A `simulab_sim` base `data.frame` with the correlated variables.

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
