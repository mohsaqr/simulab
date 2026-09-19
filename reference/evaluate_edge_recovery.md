# Evaluate edge recovery against a known network

Evaluate edge recovery against a known network

## Usage

``` r
evaluate_edge_recovery(truth, estimate, threshold = 0)
```

## Arguments

- truth, estimate:

  Supported network representations.

- threshold:

  Absolute threshold defining a recovered edge: a dyad counts as present
  when `abs(weight) > threshold`.

## Value

A tidy `simulab_sim` base `data.frame` with one row per dyad in the
union of the two edge sets – dyads absent from both networks are not
represented, so true negatives are not counted – and columns `from`,
`to`, `truth_weight`, `estimate_weight`, `truth_present`,
`estimate_present`, `recovered`, `false_positive`, and `false_negative`.
A one-row `summary` table (`precision`, `recall`, `f1`, `true_positive`,
`false_positive`, `false_negative`) is available through
[`as.data.frame()`](https://rdrr.io/r/base/as.data.frame.html).

## Examples

``` r
truth <- simulate_network(nodes = 25, model = "bernoulli", probability = 0.15, seed = 1)
estimate <- simulate_network(nodes = 25, model = "bernoulli", probability = 0.15, seed = 2)
evaluate_edge_recovery(truth, estimate)
#> <simulab_sim:edge_recovery> 171 rows x 9 columns
#>    from to truth_weight estimate_weight truth_present estimate_present
#> 1     1  6            1               0          TRUE            FALSE
#> 2     1  9            0               1         FALSE             TRUE
#> 3     1 11            0               1         FALSE             TRUE
#> 4     1 19            0               1         FALSE             TRUE
#> 5     1 23            1               0          TRUE            FALSE
#> 6     1 25            0               1         FALSE             TRUE
#> 7     2  9            1               0          TRUE            FALSE
#> 8     2 10            1               0          TRUE            FALSE
#> 9     2 18            1               0          TRUE            FALSE
#> 10    2 20            1               1          TRUE             TRUE
#>    recovered false_positive false_negative
#> 1      FALSE          FALSE           TRUE
#> 2      FALSE           TRUE          FALSE
#> 3      FALSE           TRUE          FALSE
#> 4      FALSE           TRUE          FALSE
#> 5      FALSE          FALSE           TRUE
#> 6      FALSE           TRUE          FALSE
#> 7      FALSE          FALSE           TRUE
#> 8      FALSE          FALSE           TRUE
#> 9      FALSE          FALSE           TRUE
#> 10      TRUE          FALSE          FALSE
#> ... 161 more rows
```
