# Sample learning states reproducibly

Samples without replacement from the distinct states of the selected
categories, so the result never repeats a state.

## Usage

``` r
sample_learning_states(n, categories = "all", seed = NULL)
```

## Arguments

- n:

  Number of unique states to draw. A single positive whole number, at
  most the number of distinct states in the selected categories.

- categories:

  Categories passed to
  [`learning_states()`](https://mohsaqr.github.io/simulab/reference/learning_states.md),
  defaulting to `"all"`.

- seed:

  Optional random seed.

## Value

A tidy base `data.frame` with `n` rows, one per sampled state, and
columns `order` (the selection order, `1:n`), `category` and `state`. A
state belonging to several categories gets all of them in `category`,
joined by `";"`.

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
