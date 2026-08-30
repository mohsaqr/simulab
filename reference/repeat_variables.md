# Define repeated variables

Define repeated variables

## Usage

``` r
repeat_variables(
  n,
  prefix,
  formula,
  variance = 0,
  distribution = .simulab_distributions,
  link = c("identity", "log", "logit")
)
```

## Arguments

- n:

  Number of variables.

- prefix:

  Variable-name prefix.

- formula, variance, distribution, link:

  Arguments passed to
  [`define_variable()`](https://mohsaqr.github.io/simulab/reference/define_variable.md).

## Value

A `simulab_spec` base `data.frame` with one row per repeated variable.

## Examples

``` r
specification <- repeat_variables(
  n = 3, prefix = "item", formula = "0", variance = "1", distribution = "normal"
)
specification
#>   variable distribution formula variance     link
#> 1    item1       normal       0        1 identity
#> 2    item2       normal       0        1 identity
#> 3    item3       normal       0        1 identity
head(simulate_study(n = 20, specification = specification, seed = 1))
#> <simulab_sim:study> 6 rows x 4 columns
#>   id      item1       item2      item3
#> 1  1 -0.6264538  0.91897737 -0.1645236
#> 2  2  0.1836433  0.78213630 -0.2533617
#> 3  3 -0.8356286  0.07456498  0.6969634
#> 4  4  1.5952808 -1.98935170  0.5566632
#> 5  5  0.3295078  0.61982575 -0.6887557
#> 6  6 -0.8204684 -0.05612874 -0.7074952
```
