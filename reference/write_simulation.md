# Export a simulation component

Export a simulation component

## Usage

``` r
write_simulation(x, file, what = "data")
```

## Arguments

- x:

  A `simulab_sim` simulation result.

- file:

  Destination path. The extension decides the format and must be `.csv`
  (written with
  [`utils::write.csv()`](https://rdrr.io/r/utils/write.table.html),
  without row names) or `.rds`; any other extension is an error.

- what:

  Single string naming the component to write, default `"data"`. Use
  `components(x)` to list the choices.

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
