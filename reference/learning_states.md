# List categorized learning states for sequence simulation

List categorized learning states for sequence simulation

## Usage

``` r
learning_states(categories = "all")
```

## Arguments

- categories:

  One or more learning-state categories, or `"all"`.

## Value

A tidy base `data.frame` with category and state columns.

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
