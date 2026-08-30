# Sample globally diverse names

Sample globally diverse names

## Usage

``` r
sample_global_names(n, regions = "all", seed = NULL)
```

## Arguments

- n:

  Number of unique names.

- regions:

  Regions passed to
  [`global_names()`](https://mohsaqr.github.io/simulab/reference/global_names.md).

- seed:

  Optional seed.

## Value

A tidy base `data.frame` with order, region, and name.

## Examples

``` r
sample_global_names(n = 8, seed = 1)
#>   order        region   name
#> 1     1 north_america Skyler
#> 2     2   middle_east  Rania
#> 3     3        africa  Amina
#> 4     4   middle_east   Zayd
#> 5     5        europe  Freja
#> 6     6     east_asia    Wei
#> 7     7 latin_america  Tomas
#> 8     8 latin_america Camila
```
