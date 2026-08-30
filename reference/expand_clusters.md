# Expand cluster-level rows into unit-level rows

Expand cluster-level rows into unit-level rows

## Usage

``` r
expand_clusters(data, cluster, size, unit = "id", include_cluster_data = TRUE)
```

## Arguments

- data:

  Cluster-level base `data.frame`.

- cluster:

  Name of the cluster identifier.

- size:

  Name of a cluster-size variable or a positive integer applied to every
  cluster.

- unit:

  Name of the new unit identifier.

- include_cluster_data:

  Include all cluster-level columns.

## Value

A `simulab_sim` base `data.frame` with one row per unit.

## Examples

``` r
clusters <- data.frame(cluster = 1:5, site = rep(c("north", "south"), length.out = 5))
result <- expand_clusters(clusters, cluster = "cluster", size = 4)
head(result)
#> <simulab_sim:clusters> 6 rows x 3 columns
#>   id cluster  site
#> 1  1       1 north
#> 2  2       1 north
#> 3  3       1 north
#> 4  4       1 north
#> 5  5       2 south
#> 6  6       2 south
```
