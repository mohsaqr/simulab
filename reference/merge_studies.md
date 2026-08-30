# Merge study data by identifiers

Merge study data by identifiers

## Usage

``` r
merge_studies(x, y, by, join = c("inner", "full", "left"))
```

## Arguments

- x, y:

  Base data frames.

- by:

  Identifier variables shared by both inputs.

- join:

  Join type.

## Value

A `simulab_sim` base `data.frame` containing the merged data.

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
