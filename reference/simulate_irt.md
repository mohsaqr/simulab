# Simulate item-response data

Draws latent abilities from a standard multivariate normal (mean zero,
unit variance, correlation `ability_correlation`), projects them onto
each item through `dimensions`, and samples responses from a logistic
item-response model.

## Usage

``` r
simulate_irt(
  n,
  discrimination = 1,
  difficulty,
  dimensions = NULL,
  ability_correlation = NULL,
  model = c("2pl", "rasch", "3pl", "graded"),
  guessing = 0.2,
  seed = NULL
)
```

## Arguments

- n:

  Number of respondents. A single whole number of at least 2.

- discrimination:

  Positive item discriminations, a scalar recycled across items (the
  default, `1`) or one value per item. Must equal one for
  `model = "rasch"`.

- difficulty:

  Item difficulties, on the same scale as the latent ability. A numeric
  vector, one difficulty per item, for the dichotomous models.
  `model = "graded"` instead requires an item-by-threshold matrix (or a
  tidy data frame with columns `item`, `dimension` and `difficulty`)
  whose thresholds increase within each item.

- dimensions:

  Item-by-dimension loading weights, or a tidy data frame with columns
  `item`, `dimension` and `loading`. `NULL` (the default) uses one
  dimension. Each row is rescaled to unit length before use, so only the
  relative weights within an item matter, not their scale. Row and
  column names, when present, name the items and the ability columns.

- ability_correlation:

  Latent ability correlation matrix, or a tidy data frame with columns
  `row`, `column` and `correlation`. `NULL` (the default) makes the
  abilities uncorrelated.

- model:

  Logistic model: `"2pl"` (the default), `"rasch"`, `"3pl"`, or
  `"graded"`.

- guessing:

  Lower-asymptote guessing parameters in `[0, 1)`, a scalar recycled
  across items (the default, `0.2`) or one value per item. It is
  silently reset to zero unless `model = "3pl"`.

- seed:

  Optional random seed.

## Value

A `simulab_sim` base `data.frame` with one row per respondent and
columns `id` and one integer column per item, coded `0`/`1` for the
dichotomous models and `0` to the number of thresholds for
`model = "graded"`. An `abilities` component holds one row per
respondent with columns `id` and one true ability per dimension. A
`parameters` component holds one row per item for the dichotomous
models, with columns `item`, `parameter` (`"difficulty"`), `category`
(`NA`), `value`, `discrimination` and `guessing`; for `model = "graded"`
it holds one row per item-by-threshold combination, with `parameter`
equal to `"threshold"`, `category` the threshold index, and no
`guessing` column.

## Details

For the dichotomous models the probability of a correct response is
`guessing + (1 - guessing) * plogis(discrimination * (theta - difficulty))`,
so `difficulty` is on the ability scale (the point of inflection), not
an intercept. `"rasch"` fixes all discriminations at one and `"2pl"`
sets `guessing` to zero; only `"3pl"` uses `guessing`.

For `model = "graded"` the cumulative category probabilities are
`plogis(discrimination * (theta - threshold))` for each threshold of an
item, and the category probabilities are their successive differences,
so the thresholds are also on the ability scale.

## Examples

``` r
result <- simulate_irt(
  n = 200,
  discrimination = c(1, 1.2, 0.8),
  difficulty = c(-1, 0, 1),
  seed = 1
)
head(result)
#> <simulab_sim:irt_2pl> 6 rows x 4 columns
#>   id item_1 item_2 item_3
#> 1  1      0      1      1
#> 2  2      1      0      0
#> 3  3      0      0      1
#> 4  4      1      1      0
#> 5  5      0      0      0
#> 6  6      0      1      0
as.data.frame(result, what = "parameters")
#>     item  parameter category value discrimination guessing
#> 1 item_1 difficulty       NA    -1            1.0        0
#> 2 item_2 difficulty       NA     0            1.2        0
#> 3 item_3 difficulty       NA     1            0.8        0

# Three-parameter logistic with a guessing floor.
head(simulate_irt(
  n = 200,
  discrimination = c(1, 1.2, 0.8),
  difficulty = c(-1, 0, 1),
  model = "3pl",
  guessing = 0.2,
  seed = 1
))
#> <simulab_sim:irt_3pl> 6 rows x 4 columns
#>   id item_1 item_2 item_3
#> 1  1      1      1      1
#> 2  2      1      0      0
#> 3  3      0      0      1
#> 4  4      1      1      0
#> 5  5      0      0      0
#> 6  6      0      1      1
```
