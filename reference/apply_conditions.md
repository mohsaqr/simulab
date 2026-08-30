# Apply conditional generation rules

Rules are evaluated in order, so later rules may intentionally replace
values written by earlier rules. A row no rule selects is left missing.

## Usage

``` r
apply_conditions(data, specification, seed = NULL, envir = parent.frame())
```

## Arguments

- data:

  Input base `data.frame`.

- specification:

  Rules from
  [`define_conditions()`](https://mohsaqr.github.io/simulab/reference/define_conditions.md),
  in either the rule form written with `when()` or the
  `formula`/`variance` column form.

- seed:

  Optional random seed.

- envir:

  Formula evaluation environment.

## Value

A `simulab_sim` base `data.frame` with conditional variables added.

## Examples

``` r
data <- data.frame(id = 1:100, group = rep(0:1, each = 50))

# Rules written with when() may use any distribution in the catalogue.
result <- apply_conditions(
  data,
  specification = define_conditions(
    outcome = when(group == 1, normal(mean = 5, sd = 1)),
    outcome = when(group == 0, poisson(lambda = 2))
  ),
  seed = 1
)
head(result)
#> <simulab_sim:conditional> 6 rows x 3 columns
#>   id group outcome
#> 1  1     0       2
#> 2  2     0       1
#> 3  3     0       1
#> 4  4     0       6
#> 5  5     0       2
#> 6  6     0       1

specification <- define_conditions(
  define_condition("outcome", condition = "group == 1",
                   formula = "2", variance = "1", distribution = "normal"),
  define_condition("outcome", condition = "group == 0",
                   formula = "0", variance = "1", distribution = "normal")
)
result <- apply_conditions(data, specification = specification, seed = 1)
head(result)
#> <simulab_sim:conditional> 6 rows x 3 columns
#>   id group    outcome
#> 1  1     0  0.3981059
#> 2  2     0 -0.6120264
#> 3  3     0  0.3411197
#> 4  4     0 -1.1293631
#> 5  5     0  1.4330237
#> 6  6     0  1.9803999
```
