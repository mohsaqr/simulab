# Simulate correlated general-distribution variables with a Gaussian copula

Simulate correlated general-distribution variables with a Gaussian
copula

## Usage

``` r
simulate_copula(
  n,
  specification,
  rho = 0,
  tau = NULL,
  structure = c("independent", "exchangeable", "ar1", "custom"),
  correlation = NULL,
  id = "id",
  seed = NULL,
  envir = parent.frame()
)
```

## Arguments

- n:

  Number of observations.

- specification:

  Variable definitions from
  [`define_variables()`](https://mohsaqr.github.io/simulab/reference/define_variables.md).
  In the distribution-call form every marginal must carry a quantile
  function; `list_distributions(copula = TRUE)` reports which do. In the
  `formula`/`variance` column form the marginal is stated as a mean and
  a dispersion.

- rho:

  Optional latent Pearson correlation.

- tau:

  Optional Kendall correlation, overriding `rho`.

- structure:

  Correlation structure: one of `"independent"`, `"exchangeable"`,
  `"ar1"`, or `"custom"`. If left unset it is chosen from the other
  arguments: `"custom"` when `correlation` is supplied, `"exchangeable"`
  when a non-zero `rho` (or `tau`) is supplied, and `"independent"`
  otherwise. Passing `"independent"` together with a non-zero `rho` is a
  contradiction and raises an error.

- correlation:

  Custom latent correlation matrix or tidy table.

- id:

  Identifier name.

- seed:

  Optional random seed.

- envir:

  Formula evaluation environment.

## Value

A `simulab_sim` base `data.frame` with one row per observation and a
tidy latent-correlation table.

## Conditions

`simulab_no_quantile` when a distribution call names a marginal with no
quantile function, such as `rice()` or `mixture()`.

## Examples

``` r
# Distribution calls. Each marginal keeps its own distribution while the
# variables are correlated through a Gaussian copula.
result <- simulate_copula(
  n = 200,
  specification = define_variables(
    score  = normal(mean = 10, sd = 2),
    visits = poisson(lambda = 4),
    rate   = beta(shape1 = 2, shape2 = 5)
  ),
  rho = 0.5, seed = 1
)
head(result)
#> <simulab_sim:copula> 6 rows x 4 columns
#>   id     score visits      rate
#> 1  1  9.518238      5 0.4463908
#> 2  2 12.036044      9 0.6890614
#> 3  3  8.887993      6 0.2012495
#> 4  4 12.667842      4 0.2524626
#> 5  5  9.347847      0 0.1384510
#> 6  6  9.453232      9 0.2715592

specification <- define_variables(
  define_variable("normal_var", formula = "0", variance = "1", distribution = "normal"),
  define_variable("count_var", formula = "3", variance = "0", distribution = "poisson")
)
result <- simulate_copula(n = 200, specification = specification, rho = 0.5, seed = 1)
head(result)
#> <simulab_sim:copula> 6 rows x 3 columns
#>   id normal_var count_var
#> 1  1 -0.4991469         3
#> 2  2  0.6144984         6
#> 3  3 -0.3965160         5
#> 4  4  1.4552777         3
#> 5  5 -0.2731824         0
#> 6  6 -0.1460692         7
components(result)
#>                table rows columns
#> 1               data  200       3
#> 2        definitions    2       5
#> 3 latent_correlation    4       3
```
