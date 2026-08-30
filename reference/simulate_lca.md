# Simulate a latent class model

Simulate a latent class model

## Usage

``` r
simulate_lca(
  n,
  probabilities,
  proportions = NULL,
  class_labels = NULL,
  category_labels = NULL,
  seed = NULL
)
```

## Arguments

- n:

  Number of observations.

- probabilities:

  Item probabilities as an array with dimensions class, indicator and
  category, or as a tidy data frame with columns `class`, `indicator`,
  `category` and `probability`.

- proportions:

  Latent-class proportions.

- class_labels, category_labels:

  Optional labels.

- seed:

  Optional random seed.

## Value

A `simulab_sim` base `data.frame` with true class and indicators.

## Examples

``` r
# `probabilities` is a class x indicator x category array. Values fill the
# class dimension fastest, so each pair below is one category across the two
# classes: P(indicator = 1) then P(indicator = 2).
probabilities <- array(
  c(0.8, 0.2,   0.7, 0.3,     # category 1, for each class and indicator
    0.2, 0.8,   0.3, 0.7),    # category 2, for each class and indicator
  dim = c(2, 2, 2),
  dimnames = list(
    class = c("Class 1", "Class 2"),
    indicator = c("item_1", "item_2"),
    category = c("no", "yes")
  )
)

result <- simulate_lca(
  n = 200, probabilities = probabilities, proportions = c(0.6, 0.4), seed = 1
)
head(result)
#> <simulab_sim:lca> 6 rows x 4 columns
#>   id latent_class item_1 item_2
#> 1  1      Class 1      1      1
#> 2  2      Class 1      1      1
#> 3  3      Class 1      1      2
#> 4  4      Class 2      2      1
#> 5  5      Class 1      1      2
#> 6  6      Class 2      2      1
as.data.frame(result, what = "parameters")
#>   latent_class indicator category probability proportion
#> 1      Class 1    item_1        1         0.8        0.6
#> 2      Class 2    item_1        1         0.2        0.4
#> 3      Class 1    item_2        1         0.7        0.6
#> 4      Class 2    item_2        1         0.3        0.4
#> 5      Class 1    item_1        2         0.2        0.6
#> 6      Class 2    item_1        2         0.8        0.4
#> 7      Class 1    item_2        2         0.3        0.6
#> 8      Class 2    item_2        2         0.7        0.4
```
