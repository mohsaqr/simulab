# Select or remove study variables

Select or remove study variables

## Usage

``` r
select_variables(data, keep = NULL, drop = NULL)
```

## Arguments

- data:

  Base `data.frame`.

- keep:

  Variables to retain.

- drop:

  Variables to remove.

## Value

A `simulab_sim` base `data.frame` with the requested variables.

## Examples

``` r
data <- data.frame(id = 1:5, keep_me = 1:5, drop_me = 6:10)
select_variables(data, keep = c("id", "keep_me"))
#> <simulab_sim:selected_variables> 5 rows x 2 columns
#>   id keep_me
#> 1  1       1
#> 2  2       2
#> 3  3       3
#> 4  4       4
#> 5  5       5
select_variables(data, drop = "drop_me")
#> <simulab_sim:selected_variables> 5 rows x 2 columns
#>   id keep_me
#> 1  1       1
#> 2  2       2
#> 3  3       3
#> 4  4       4
#> 5  5       5
```
