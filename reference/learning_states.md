# List categorized learning states for sequence simulation

List categorized learning states for sequence simulation

## Usage

``` r
learning_states(categories = "all")
```

## Arguments

- categories:

  A character vector of one or more category identifiers from
  [`learning_state_categories()`](https://mohsaqr.github.io/simulab/reference/learning_state_categories.md),
  or `"all"` (the default) for every category. Unknown identifiers raise
  an error.

## Value

A tidy base `data.frame` with one row per category-state pair and
columns `category` and `state`. A state may belong to more than one
category and then appears once per category, so `state` is not unique:
the full catalogue has 209 rows covering 202 distinct states.

## Examples

``` r
head(learning_states())
#>        category    state
#> 1 metacognitive     Plan
#> 2 metacognitive  Monitor
#> 3 metacognitive Evaluate
#> 4 metacognitive  Reflect
#> 5 metacognitive Regulate
#> 6 metacognitive   Adjust
head(learning_states(categories = "metacognitive"))
#>        category    state
#> 1 metacognitive     Plan
#> 2 metacognitive  Monitor
#> 3 metacognitive Evaluate
#> 4 metacognitive  Reflect
#> 5 metacognitive Regulate
#> 6 metacognitive   Adjust
```
