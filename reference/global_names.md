# List the global-name catalogue

List the global-name catalogue

## Usage

``` r
global_names(regions = "all")
```

## Arguments

- regions:

  Region names or `"all"`.

## Value

A tidy base `data.frame` with region and name columns.

## Examples

``` r
head(global_names())
#>   region   name
#> 1 africa  Amina
#> 2 africa  Kwame
#> 3 africa    Nia
#> 4 africa Tendai
#> 5 africa   Zuri
#> 6 africa  Chidi
head(global_names(regions = c("east_asia", "africa")))
#>      region   name
#> 1 east_asia    Mei
#> 2 east_asia Haruto
#> 3 east_asia  Jiwoo
#> 4 east_asia    Wei
#> 5 east_asia   Yuna
#> 6 east_asia    Ren
```
