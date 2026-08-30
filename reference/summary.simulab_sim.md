# Summarize simulated variables

Summarize simulated variables

## Usage

``` r
# S3 method for class 'simulab_sim'
summary(object, ...)
```

## Arguments

- object:

  A `simulab_sim` object.

- ...:

  Reserved for future methods.

## Value

A base `data.frame` with one row per variable and columns describing
storage class, missingness, uniqueness, and numeric summaries.

## Examples

``` r
result <- simulate_ttest(n_a = 30, n_b = 30, mean_a = 0, mean_b = 0.5, seed = 1)
summary(result)
#>         variable     class observations missing unique       mean         sd
#> id            id   integer           60       0     60 30.5000000 17.4642492
#> group      group character           60       0      2         NA         NA
#> outcome  outcome   numeric           60       0     60  0.3576164  0.8987021
#>         minimum maximum
#> id       1.0000 60.0000
#> group        NA      NA
#> outcome -2.2147  2.4804
```
