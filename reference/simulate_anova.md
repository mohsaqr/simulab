# Simulate a one-way group design

Simulate a one-way group design

## Usage

``` r
simulate_anova(
  n,
  means,
  sds = 1,
  labels = NULL,
  outcome = "outcome",
  seed = NULL
)
```

## Arguments

- n:

  Group sample size or one size per group.

- means:

  Group means.

- sds:

  Group standard deviations.

- labels:

  Optional group labels.

- outcome:

  Name of the outcome variable.

- seed:

  Optional random seed.

## Value

A `simulab_sim` base `data.frame` with group parameters and the
population eta-squared effect.

## Examples

``` r
result <- simulate_anova(n = 90, means = c(0, 0.4, 0.9), seed = 1)
head(result)
#> <simulab_sim:anova> 6 rows x 3 columns
#>   id   group    outcome
#> 1  1 Group 1 -0.6264538
#> 2  2 Group 1  0.1836433
#> 3  3 Group 1 -0.8356286
#> 4  4 Group 1  1.5952808
#> 5  5 Group 1  0.3295078
#> 6  6 Group 1 -0.8204684
as.data.frame(result, what = "parameters")
#>     group  n mean sd
#> 1 Group 1 90  0.0  1
#> 2 Group 2 90  0.4  1
#> 3 Group 3 90  0.9  1
```
