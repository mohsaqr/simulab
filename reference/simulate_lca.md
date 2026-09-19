# Simulate a latent class model

Draws a latent class for each observation from `proportions`, then draws
every indicator independently from that class's category probabilities
(the usual local-independence assumption of latent class analysis).

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

  Number of observations. A single whole number of at least 2.

- probabilities:

  Item probabilities as an array with dimensions class, indicator and
  category, or as a tidy data frame with columns `class`, `indicator`,
  `category` and `probability`. Category probabilities must sum to one
  within each class and indicator. Only the `indicator` dimnames are
  used, to name the indicator columns; any class and category dimnames
  are ignored, so class and category labels must be supplied through
  `class_labels` and `category_labels`.

- proportions:

  Latent-class proportions, one positive value per class; they are
  rescaled to sum to one. `NULL` (the default) makes every class equally
  likely.

- class_labels, category_labels:

  Optional labels, one unique value per class and per category.
  `class_labels` defaults to `"Class 1"`, `"Class 2"` and so on;
  `category_labels` defaults to the integers `1:categories`, which are
  the values written into the indicator columns.

- seed:

  Optional random seed.

## Value

A `simulab_sim` base `data.frame` with one row per observation and
columns `id`, `latent_class` (the true class label) and one column per
indicator holding the sampled value of `category_labels`. A `parameters`
component holds one row per class-by-indicator-by-category combination
with columns `latent_class`, `indicator`, `category`, `probability` and
`proportion`.

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

# Only the `indicator` dimnames name the output columns, so the class and
# category labels are passed explicitly.
result <- simulate_lca(
  n = 200,
  probabilities = probabilities,
  proportions = c(0.6, 0.4),
  category_labels = c("no", "yes"),
  seed = 1
)
head(result)
#> <simulab_sim:lca> 6 rows x 4 columns
#>   id latent_class item_1 item_2
#> 1  1      Class 1     no     no
#> 2  2      Class 1     no     no
#> 3  3      Class 1     no    yes
#> 4  4      Class 2    yes     no
#> 5  5      Class 1     no    yes
#> 6  6      Class 2    yes     no
as.data.frame(result, what = "parameters")
#>   latent_class indicator category probability proportion
#> 1      Class 1    item_1       no         0.8        0.6
#> 2      Class 2    item_1       no         0.2        0.4
#> 3      Class 1    item_2       no         0.7        0.6
#> 4      Class 2    item_2       no         0.3        0.4
#> 5      Class 1    item_1      yes         0.2        0.6
#> 6      Class 2    item_1      yes         0.8        0.4
#> 7      Class 1    item_2      yes         0.3        0.6
#> 8      Class 2    item_2      yes         0.7        0.4
```
