# Convert a simulation component to a tidy data frame

Convert a simulation component to a tidy data frame

## Usage

``` r
# S3 method for class 'simulab_sim'
as.data.frame(x, row.names = NULL, optional = FALSE, what = "data", ...)
```

## Arguments

- x:

  A `simulab_sim` object.

- row.names:

  Ignored.

- optional:

  Ignored.

- what:

  Name of the table to return. Use `components(x)` to list the available
  choices.

- ...:

  Reserved for future methods.

## Value

A base `data.frame` containing the requested simulation table.

## Examples

``` r
result <- simulate_ttest(
  n_a = 10,
  n_b = 10,
  mean_a = 0,
  mean_b = 0.5,
  seed = 1
)
as.data.frame(result)
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
#> 11 11     B  2.0117812
#> 12 12     B  0.8898432
#> 13 13     B -0.1212406
#> 14 14     B -1.7146999
#> 15 15     B  1.6249309
#> 16 16     B  0.4550664
#> 17 17     B  0.4838097
#> 18 18     B  1.4438362
#> 19 19     B  1.3212212
#> 20 20     B  1.0939013
as.data.frame(result, what = "parameters")
#>   group  n mean sd
#> 1     A 10  0.0  1
#> 2     B 10  0.5  1
```
