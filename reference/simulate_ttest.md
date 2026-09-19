# Simulate a two-group design

Simulate a two-group design

## Usage

``` r
simulate_ttest(
  n_a,
  n_b,
  mean_a,
  mean_b,
  sd_a = 1,
  sd_b = 1,
  labels = c("A", "B"),
  outcome = "outcome",
  seed = NULL
)
```

## Arguments

- n_a, n_b:

  Group sample sizes.

- mean_a, mean_b:

  Group means.

- sd_a, sd_b:

  Positive group standard deviations.

- labels:

  Two group labels.

- outcome:

  Name of the outcome variable.

- seed:

  Optional random seed.

## Value

A `simulab_sim` base `data.frame` with one row per observation and
columns `id`, `group` and `outcome` (renamed by `outcome`). Two tidy
tables come from
[`as.data.frame()`](https://rdrr.io/r/base/as.data.frame.html):
`what = "parameters"` has one row per group with columns `group`, `n`,
`mean` and `sd`; `what = "effects"` has a single row with columns
`contrast`, `mean_difference`, `pooled_sd` and `cohens_d`, the
population Cohen's d formed from the sample-size-weighted pooled
standard deviation.

## Examples

``` r
result <- simulate_ttest(n_a = 40, n_b = 40, mean_a = 0, mean_b = 0.6, seed = 1)
head(result)
#> <simulab_sim:ttest> 6 rows x 3 columns
#>   id group    outcome
#> 1  1     A -0.6264538
#> 2  2     A  0.1836433
#> 3  3     A -0.8356286
#> 4  4     A  1.5952808
#> 5  5     A  0.3295078
#> 6  6     A -0.8204684
as.data.frame(result, what = "parameters")
#>   group  n mean sd
#> 1     A 40  0.0  1
#> 2     B 40  0.6  1
```
