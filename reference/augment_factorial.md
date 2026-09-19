# Add factorial conditions to existing rows

Add factorial conditions to existing rows

## Usage

``` r
augment_factorial(data, factors, coding = c("dummy", "effect", "level"))
```

## Arguments

- data:

  Input base `data.frame`, with at least one row.

- factors:

  Named numeric vector of whole numbers giving the number of levels of
  each factor. Every entry must be at least 2.

- coding:

  Factor coding passed to
  [`factorial_design()`](https://mohsaqr.github.io/simulab/reference/factorial_design.md):
  `"dummy"` (the default), `"effect"` or `"level"`.

## Value

A `simulab_sim` base `data.frame` with one row per row of `data` crossed
with every design condition, so `nrow(data) * prod(factors)` rows: the
columns of `data` followed by one column per factor. The `design`
component holds the distinct conditions, one row each.

## Examples

``` r
data <- data.frame(id = 1:12)
result <- augment_factorial(data, factors = c(dose = 3L, timing = 2L))
head(result)
#> <simulab_sim:augmented_factorial> 6 rows x 3 columns
#>   id dose timing
#> 1  1    0      0
#> 2  2    0      0
#> 3  3    0      0
#> 4  4    0      0
#> 5  5    0      0
#> 6  6    0      0
```
