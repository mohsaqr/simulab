# Add one or more survival processes to data

Add one or more survival processes to data

## Usage

``` r
augment_survival(
  data,
  specification,
  seed = NULL,
  digits = NULL,
  envir = parent.frame()
)
```

## Arguments

- data:

  Baseline base `data.frame`.

- specification:

  Definitions from
  [`define_survivals()`](https://mohsaqr.github.io/simulab/reference/define_survivals.md).

- seed:

  Optional random seed.

- digits:

  Optional number of decimal places.

- envir:

  Formula evaluation environment.

## Value

A `simulab_sim` base `data.frame` with one event-time variable per
process.

## Examples

``` r
data <- data.frame(id = 1:100, treatment = rep(0:1, each = 50))

result <- augment_survival(
  data,
  specification = define_survivals(
    define_survival("time", formula = "-8 + 0.5 * treatment", shape = 0.3)
  ),
  seed = 1
)
head(result)
#> <simulab_sim:survival> 6 rows x 3 columns
#>   id treatment      time
#> 1  1         0 11.997214
#> 2  2         0 10.985087
#> 3  3         0  9.248955
#> 4  4         0  5.462235
#> 5  5         0 12.694901
#> 6  6         0  5.640350
```
