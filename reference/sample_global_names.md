# Sample globally diverse names

Sample globally diverse names

## Usage

``` r
sample_global_names(n, regions = "all", seed = NULL)
```

## Arguments

- n:

  Number of unique names to draw, at most the number of distinct names
  the chosen regions hold.

- regions:

  Regions passed to
  [`global_names()`](https://mohsaqr.github.io/simulab/reference/global_names.md).

- seed:

  Optional seed.

## Value

A tidy base `data.frame` with one row per sampled name and columns
`order`, `region` and `name`. A name belonging to more than one region
carries them joined by `";"`.

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
