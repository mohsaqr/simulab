# Create a full factorial design

Create a full factorial design

## Usage

``` r
factorial_design(
  factors,
  replications = 1L,
  coding = c("dummy", "effect", "level"),
  id = "id"
)
```

## Arguments

- factors:

  Named integer vector giving the number of levels per factor.

- replications:

  Number of replications per factor combination.

- coding:

  Numeric coding for factor levels.

- id:

  Identifier-column name.

## Value

A `simulab_sim` base `data.frame` with one row per replicated factor
combination.

## Examples

``` r
factorial_design(factors = c(dose = 3L, timing = 2L), replications = 2)
#> <simulab_sim:factorial> 12 rows x 3 columns
#>    id dose timing
#> 1   1    0      0
#> 2   2    0      0
#> 3   3    1      0
#> 4   4    1      0
#> 5   5    2      0
#> 6   6    2      0
#> 7   7    0      1
#> 8   8    0      1
#> 9   9    1      1
#> 10 10    1      1
#> ... 2 more rows
```
