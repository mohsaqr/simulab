# Print a simulation result

Print a simulation result

## Usage

``` r
# S3 method for class 'simulab_sim'
print(x, ...)
```

## Arguments

- x:

  A `simulab_sim` object.

- ...:

  Arguments passed to the base data-frame print method.

## Value

`x`, invisibly.

## Examples

``` r
result <- simulate_ttest(n_a = 30, n_b = 30, mean_a = 0, mean_b = 0.5, seed = 1)
print(result)
#> <simulab_sim:ttest> 60 rows x 3 columns
#>    id group    outcome
#> 1   1     A -0.6264538
#> 2   2     A  0.1836433
#> 3   3     A -0.8356286
#> 4   4     A  1.5952808
#> 5   5     A  0.3295078
#> 6   6     A -0.8204684
#> 7   7     A  0.4874291
#> 8   8     A  0.7383247
#> 9   9     A  0.5757814
#> 10 10     A -0.3053884
#> ... 50 more rows
```
