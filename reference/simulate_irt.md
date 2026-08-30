# Simulate item-response data

Simulate item-response data

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

  Number of respondents.

- discrimination:

  Positive item discriminations.

- difficulty:

  Item difficulties. A vector gives dichotomous items; a matrix gives
  ordered thresholds by item.

- dimensions:

  Item-by-dimension loading weights, or a tidy data frame with columns
  `item`, `dimension` and `loading`. `NULL` uses one dimension.

- ability_correlation:

  Latent ability correlation matrix, or a tidy data frame with columns
  `row`, `column` and `correlation`.

- model:

  Logistic model: Rasch, 2PL, 3PL, or graded response.

- guessing:

  Lower-asymptote guessing parameters for 3PL items.

- seed:

  Optional random seed.

## Value

A `simulab_sim` base `data.frame` with responses and true parameters.

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
