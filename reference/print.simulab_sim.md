# Print a simulation result

Prints a one-line header giving the simulation type and the full
dimensions, then at most the first 10 rows of the primary data, then a
count of the rows not shown. The table of generating values follows
under the heading `Truth`: the first of `coefficients`, `fixed_effects`,
`parameters`, `transition`, `transitions`, `true_transitions`,
`definitions`, `probabilities`, `survival_definitions` and `settings`
that the result stores, again at most 10 rows. A last line names the
other stored tables, which
[`as.data.frame()`](https://rdrr.io/r/base/as.data.frame.html) returns
with `what`.

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
#> 
#> Truth (parameters):
#>   group  n mean sd
#> 1     A 30  0.0  1
#> 2     B 30  0.5  1
#> 
#> Other tables: effects. Read one with as.data.frame(x, what = "effects").
```
