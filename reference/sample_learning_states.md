# Sample learning states reproducibly

Sample learning states reproducibly

## Usage

``` r
sample_learning_states(n, categories = "all", seed = NULL)
```

## Arguments

- n:

  Number of unique states.

- categories:

  Categories passed to
  [`learning_states()`](https://mohsaqr.github.io/simulab/reference/learning_states.md).

- seed:

  Optional random seed.

## Value

A tidy base `data.frame` with selection order, category, and state.

## Examples

``` r
sample_learning_states(n = 6, categories = "cognitive", seed = 1)
#>   order  category         state
#> 1     1 cognitive    Generalize
#> 2     2 cognitive     Summarize
#> 3     3 cognitive         Apply
#> 4     4 cognitive          Read
#> 5     5 cognitive         Study
#> 6     6 cognitive Differentiate
```
