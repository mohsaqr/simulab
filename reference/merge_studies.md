# Merge study data by identifiers

Merge study data by identifiers

## Usage

``` r
merge_studies(x, y, by, join = c("inner", "full", "left"))
```

## Arguments

- x, y:

  Base data frames, or `simulab_sim` objects, to join.

- by:

  Identifier variables shared by both inputs. A character vector of at
  least one name present in both.

- join:

  Join type, one of `"inner"` (the default), keeping only matched
  identifiers, `"full"`, keeping every row of both inputs, or `"left"`,
  keeping every row of `x`.

## Value

A `simulab_sim` base `data.frame` containing the merged data, sorted by
`by` as [`merge()`](https://rdrr.io/r/base/merge.html) leaves it, with
unmatched cells filled with `NA` under the `"full"` and `"left"` joins.

## Examples

``` r
x <- data.frame(id = 1:5, baseline = 1:5)
y <- data.frame(id = 1:5, outcome = 6:10)
merge_studies(x, y, by = "id")
#> <simulab_sim:merged_studies> 5 rows x 3 columns
#>   id baseline outcome
#> 1  1        1       6
#> 2  2        2       7
#> 3  3        3       8
#> 4  4        4       9
#> 5  5        5      10
```
