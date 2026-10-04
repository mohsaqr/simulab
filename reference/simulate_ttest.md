# Simulate a two-group design

Simulate a two-group design

## Usage

``` r
simulate_ttest(
  n_a = 50L,
  n_b = 50L,
  mean_a = NULL,
  mean_b = NULL,
  sd_a = 1,
  sd_b = 1,
  labels = c("A", "B"),
  outcome = "outcome",
  seed = NULL,
  batch = NULL
)
```

## Arguments

- n_a, n_b:

  Group sample sizes, each defaulting to `50`.

- mean_a, mean_b:

  Group means. A mean left `NULL` (the default) is drawn from the
  standard normal distribution and rounded to two decimals, inside the
  same seeded draw as the data, and is reported in the `parameters`
  table.

- sd_a, sd_b:

  Positive group standard deviations.

- labels:

  Two group labels.

- outcome:

  Name of the outcome variable.

- seed:

  Optional random seed.

- batch:

  Optional single positive whole number. When given, the simulator runs
  `batch` times and returns a plain `list` of `batch` results, each
  exactly what the same call without `batch` returns. With a `seed`,
  every dataset gets its own seed drawn from `seed`, so the whole batch
  is reproducible; without one the datasets are consecutive draws from
  the session's random-number stream. The default `NULL` returns a
  single result.

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
#> 
#> Truth (parameters):
#>   group  n mean sd
#> 1     A 40  0.0  1
#> 2     B 40  0.6  1
#> 
#> Other tables: effects. Read one with as.data.frame(x, what = "effects").
as.data.frame(result, what = "parameters")
#>   group  n mean sd
#> 1     A 40  0.0  1
#> 2     B 40  0.6  1

# With no arguments, the group means are drawn and reported.
drawn <- simulate_ttest(seed = 1)
as.data.frame(drawn, what = "parameters")
#>   group  n  mean sd
#> 1     A 50 -0.63  1
#> 2     B 50  0.18  1
```
