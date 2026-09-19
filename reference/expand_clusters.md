# Expand cluster-level rows into unit-level rows

Repeats every cluster-level row once per unit it contains, so cluster
attributes are copied down to the units, and numbers the units.

## Usage

``` r
expand_clusters(data, cluster, size, unit = "id", include_cluster_data = TRUE)
```

## Arguments

- data:

  Cluster-level base `data.frame`, or a `simulab_sim`, with one row per
  cluster and at least one row.

- cluster:

  Name of the cluster identifier. A single string naming a column of
  `data`.

- size:

  Units per cluster: the name of a cluster-size column of `data`, or a
  single positive whole number applied to every cluster.

- unit:

  Name of the new unit identifier, numbered `1` to the total number of
  units across all clusters rather than restarting within a cluster. A
  single non-empty string, defaulting to `"id"`.

- include_cluster_data:

  Copy every cluster-level column down to the units. A single flag,
  defaulting to `TRUE`. `FALSE` keeps only the cluster identifier.

## Value

A `simulab_sim` base `data.frame` with one row per unit, the unit
identifier first and then the retained cluster-level columns. The
component `clusters`, reached with
`as.data.frame(x, what = "clusters")`, holds one row per input cluster
with columns `cluster`, the identifier values under that fixed name
whatever `cluster` was called, and the integer `size`.

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
