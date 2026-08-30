# Export a simulation component

Export a simulation component

## Usage

``` r
write_simulation(x, file, what = "data")
```

## Arguments

- x:

  A simulation result.

- file:

  Destination `.csv` or `.rds` path.

- what:

  Component name.

## Value

The normalized output path, invisibly.

## Examples

``` r
result <- simulate_ttest(n_a = 20, n_b = 20, mean_a = 0, mean_b = 0.5, seed = 1)
file <- tempfile(fileext = ".csv")
write_simulation(result, file = file)
head(utils::read.csv(file))
#>   id group    outcome
#> 1  1     A -0.6264538
#> 2  2     A  0.1836433
#> 3  3     A -0.8356286
#> 4  4     A  1.5952808
#> 5  5     A  0.3295078
#> 6  6     A -0.8204684
unlink(file)
```
