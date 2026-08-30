# List the distributions a specification may use

`list_distributions()` reports the distribution catalogue. Each row
names one distribution, the parameters it takes in the order a
positional call supplies them, and whether it carries a quantile
function. Only a distribution with a quantile function can be a marginal
in
[`simulate_copula()`](https://mohsaqr.github.io/simulab/reference/simulate_copula.md).

## Usage

``` r
list_distributions(pattern = NULL, copula = NULL)
```

## Arguments

- pattern:

  Optional regular expression matched against distribution names.

- copula:

  If `TRUE`, keep only distributions usable as copula marginals; if
  `FALSE`, keep only those that are not. `NULL`, the default, keeps
  every distribution.

## Value

A base `data.frame` with one row per distribution and columns
`distribution`, `parameters`, `n_parameters` and `copula`.

## Examples

``` r
head(list_distributions())
#>     distribution            parameters n_parameters copula
#> 40        anglit       location, scale            2   TRUE
#> 31       arcsine              min, max            2   TRUE
#> 51        benini shape1, shape2, scale            3   TRUE
#> 5           beta        shape1, shape2            2   TRUE
#> 74 beta_binomial  size, shape1, shape2            3  FALSE
#> 29    beta_prime        shape1, shape2            2   TRUE

# Distributions whose name mentions normal.
list_distributions("normal")
#>         distribution             parameters n_parameters copula
#> 4      folded_normal               mean, sd            2  FALSE
#> 6 generalized_normal shape, location, scale            3   TRUE
#> 3        half_normal                     sd            1   TRUE
#> 7       logit_normal               mean, sd            2   TRUE
#> 2          lognormal         meanlog, sdlog            2   TRUE
#> 1             normal               mean, sd            2   TRUE
#> 8       power_normal shape, location, scale            3   TRUE
#> 9        skew_normal location, scale, shape            3  FALSE
#> 5   truncated_normal mean, sd, lower, upper            4   TRUE

# Distributions that cannot be a copula marginal.
list_distributions(copula = FALSE)
#>        distribution             parameters n_parameters copula
#> 74    beta_binomial   size, shape1, shape2            3  FALSE
#> 78      categorical                  probs            1  FALSE
#> 24    folded_normal               mean, sd            2  FALSE
#> 56 inverse_gaussian            mean, shape            2  FALSE
#> 79          mixture                weights            1  FALSE
#> 57             rice        location, scale            2  FALSE
#> 59     semicircular        location, scale            2  FALSE
#> 75          skellam       lambda1, lambda2            2  FALSE
#> 58      skew_normal location, scale, shape            3  FALSE
#> 77        treatment                 groups            1  FALSE
```
