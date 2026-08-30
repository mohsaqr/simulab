# Read variable definitions from a CSV file

Read variable definitions from a CSV file

## Usage

``` r
read_definitions(file)
```

## Arguments

- file:

  Path to a CSV file containing `variable`, `distribution`, `formula`,
  `variance`, and `link` columns.

## Value

A `simulab_spec` base `data.frame`.

## Examples

``` r
file <- tempfile(fileext = ".csv")
utils::write.csv(
  data.frame(
    variable = c("baseline", "outcome"),
    distribution = c("normal", "normal"),
    formula = c("0", "0.5 * baseline"),
    variance = c("1", "1"),
    link = c("identity", "identity")
  ),
  file, row.names = FALSE
)

specification <- read_definitions(file)
specification
#>   variable distribution        formula variance     link
#> 1 baseline       normal              0        1 identity
#> 2  outcome       normal 0.5 * baseline        1 identity
head(simulate_study(n = 50, specification = specification, seed = 1))
#> <simulab_sim:study> 6 rows x 3 columns
#>   id   baseline     outcome
#> 1  1 -0.6264538  0.08487897
#> 2  2  0.1836433 -0.52020473
#> 3  3 -0.8356286 -0.07669461
#> 4  4  1.5952808 -0.33172270
#> 5  5  0.3295078  1.59777759
#> 6  6 -0.8204684  1.57016571
unlink(file)
```
