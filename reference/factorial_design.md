# Create a full factorial design

Crosses every level of every factor, repeats each combination
`replications` times, and returns one numeric column per factor holding
its coded level.

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

  Named numeric vector of whole numbers giving the number of levels per
  factor, each at least 2. The names become the design columns.

- replications:

  Number of replications per factor combination. A single positive whole
  number, defaulting to `1`.

- coding:

  Numeric coding of the levels, one value per factor per row, one of
  `"dummy"` (the default), which codes the levels `0` to `levels - 1`,
  `"effect"`, which codes a two-level factor `-1` and `1` and codes a
  factor with more levels exactly as `"dummy"` does, or `"level"`, which
  keeps the level numbers `1` to `levels`.

- id:

  Identifier-column name, numbering the rows. A single non-empty string,
  defaulting to `"id"`.

## Value

A `simulab_sim` base `data.frame` with one row per replicated factor
combination (`replications * prod(factors)` rows), the identifier column
first and then one coded column per factor. The component `factors`,
reached with `as.data.frame(x, what = "factors")`, holds one row per
factor with columns `factor`, the integer `levels` and `coding`.

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
