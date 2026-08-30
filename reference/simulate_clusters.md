# Simulate Gaussian clusters

Simulate Gaussian clusters

## Usage

``` r
simulate_clusters(
  n,
  centers,
  sds = 1,
  proportions = NULL,
  labels = NULL,
  seed = NULL
)
```

## Arguments

- n:

  Sample size.

- centers:

  Matrix with one row per cluster and one column per variable, or a tidy
  data frame with columns `cluster`, `variable` and `center`.

- sds:

  Scalar, per-variable vector, cluster-by-variable matrix, or a tidy
  data frame with columns `cluster`, `variable` and `sd`.

- proportions:

  Optional cluster proportions.

- labels:

  Optional cluster labels.

- seed:

  Optional random seed.

## Value

A `simulab_sim` base `data.frame` with true cluster membership and tidy
center/scale tables.

## Examples

``` r
# `centers` is one row per cluster and one column per variable.
result <- simulate_clusters(
  n = 150,
  centers = matrix(c(0, 0, 4, 4, 0, 4), nrow = 3, byrow = TRUE),
  sds = 1,
  seed = 1
)
head(result)
#> <simulab_sim:clusters> 6 rows x 4 columns
#>   id   cluster           V1         V2
#> 1  1 Cluster 2  4.291446236  5.8031419
#> 2  2 Cluster 3 -0.443291873  3.6688680
#> 3  3 Cluster 3  0.001105352  2.3944866
#> 4  4 Cluster 1  0.074341324  0.1971934
#> 5  5 Cluster 2  3.410479054  4.2631756
#> 6  6 Cluster 1 -0.568668733 -0.9858267
as.data.frame(result, what = "parameters")
#>     cluster variable center sd proportion
#> 1 Cluster 1       V1      0  1  0.3333333
#> 2 Cluster 2       V1      4  1  0.3333333
#> 3 Cluster 3       V1      0  1  0.3333333
#> 4 Cluster 1       V2      0  1  0.3333333
#> 5 Cluster 2       V2      4  1  0.3333333
#> 6 Cluster 3       V2      4  1  0.3333333
```
