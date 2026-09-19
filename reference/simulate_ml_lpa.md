# Simulate a two-level latent profile model

Draws data from the nonparametric two-level mixture of Vermunt (2003).
Every cluster belongs to a latent cluster class, a cluster class fixes
how common each individual profile is inside its clusters, and the
profiles themselves share one measurement model across every cluster.
Cluster classes therefore differ in profile prevalence, not in profile
means, which is what separates this design from simulating one latent
profile model per cluster.

## Usage

``` r
simulate_ml_lpa(
  clusters,
  cluster_size,
  means,
  profile_probabilities,
  sds = 1,
  cluster_class_proportions = NULL,
  correlations = NULL,
  labels = NULL,
  cluster_class_labels = NULL,
  seed = NULL
)
```

## Arguments

- clusters:

  Number of clusters (level-2 units). A single whole number of at least
  2.

- cluster_size:

  Individuals per cluster: a single whole number recycled across
  clusters, or one whole number per cluster, so clusters may be
  unbalanced.

- means:

  Profile-by-variable mean matrix (one row per profile, one column per
  indicator, at least 2 rows), or a tidy data frame with columns
  `profile`, `variable` and `mean`. Column names become the indicator
  columns of the returned data; row names are ignored, profile names
  come from `labels`.

- profile_probabilities:

  Cluster-class-by-profile matrix of profile prevalences (one row per
  cluster class, one column per profile), or a tidy data frame with
  columns `cluster_class`, `profile` and `probability`. Every value must
  be positive and each row is rescaled to sum to one. A single row gives
  an ordinary latent profile model observed in clusters.

- sds:

  Scalar (the default, `1`), per-variable vector, profile-by-variable
  matrix, or a tidy data frame with columns `profile`, `variable` and
  `sd`. All values must be positive. The measurement model is shared by
  every cluster class, so standard deviations do not vary across them.

- cluster_class_proportions:

  Cluster-class proportions, one positive value per cluster class; they
  are rescaled to sum to one. `NULL` (the default) makes every cluster
  class equally likely.

- correlations:

  Optional list of within-profile correlation matrices, one per profile,
  or a tidy data frame with columns `profile`, `row`, `column` and
  `correlation`. `NULL` (the default) makes the indicators uncorrelated
  within every profile, the conditional-independence measurement model.

- labels:

  Optional profile labels, one unique value per profile. Defaults to
  `"Profile 1"`, `"Profile 2"` and so on.

- cluster_class_labels:

  Optional cluster-class labels, one unique value per cluster class.
  Defaults to `"Class 1"`, `"Class 2"` and so on.

- seed:

  Optional random seed.

## Value

A `simulab_sim` base `data.frame` with one row per individual
(`sum(cluster_size)` rows) and the columns `id`, `cluster` (the level-2
identifier), `cluster_class` (the true cluster-class label), `profile`
(the true profile label) and one numeric column per indicator. A
`parameters` component holds one row per profile-by-variable combination
with columns `profile`, `variable`, `mean`, `sd` and `proportion`, the
profile's marginal prevalence across cluster classes. A
`profile_probabilities` component holds one row per
cluster-class-by-profile combination with columns `cluster_class`,
`profile`, `probability` and `cluster_class_proportion`. A `clusters`
component holds one row per cluster with columns `cluster`,
`cluster_class` and `size`.

## References

Vermunt, J. K. (2003). Multilevel latent class models. *Sociological
Methodology*, 33, 213–239.
[doi:10.1111/j.0081-1750.2003.t01-1-00131.x](https://doi.org/10.1111/j.0081-1750.2003.t01-1-00131.x)

## Examples

``` r
# One measurement model, two cluster classes that differ only in how common
# each profile is inside their clusters.
means <- matrix(
  c(-1.5, -1.2,
     0.0,  0.2,
     1.5,  1.2),
  nrow = 3, byrow = TRUE,
  dimnames = list(NULL, c("reading", "maths"))
)
prevalence <- matrix(
  c(0.60, 0.30, 0.10,
    0.10, 0.30, 0.60),
  nrow = 2, byrow = TRUE
)
result <- simulate_ml_lpa(
  clusters = 30,
  cluster_size = 20,
  means = means,
  profile_probabilities = prevalence,
  seed = 1
)
head(result)
#> <simulab_sim:ml_lpa> 6 rows x 6 columns
#>   id cluster cluster_class   profile    reading     maths
#> 1  1       1       Class 2 Profile 3  0.5414565 1.1459974
#> 2  2       1       Class 2 Profile 3 -0.1043103 0.5318527
#> 3  3       1       Class 2 Profile 3 -0.3456094 1.6458080
#> 4  4       1       Class 2 Profile 2  1.7537948 1.5942530
#> 5  5       1       Class 2 Profile 3  2.0557372 0.7941748
#> 6  6       1       Class 2 Profile 3  1.4398808 1.8352831
as.data.frame(result, what = "profile_probabilities")
#>   cluster_class   profile probability cluster_class_proportion
#> 1       Class 1 Profile 1         0.6                      0.5
#> 2       Class 2 Profile 1         0.1                      0.5
#> 3       Class 1 Profile 2         0.3                      0.5
#> 4       Class 2 Profile 2         0.3                      0.5
#> 5       Class 1 Profile 3         0.1                      0.5
#> 6       Class 2 Profile 3         0.6                      0.5
as.data.frame(result, what = "clusters")
#>    cluster cluster_class size
#> 1        1       Class 2   20
#> 2        2       Class 2   20
#> 3        3       Class 1   20
#> 4        4       Class 1   20
#> 5        5       Class 2   20
#> 6        6       Class 1   20
#> 7        7       Class 1   20
#> 8        8       Class 1   20
#> 9        9       Class 1   20
#> 10      10       Class 2   20
#> 11      11       Class 2   20
#> 12      12       Class 2   20
#> 13      13       Class 1   20
#> 14      14       Class 2   20
#> 15      15       Class 1   20
#> 16      16       Class 2   20
#> 17      17       Class 1   20
#> 18      18       Class 1   20
#> 19      19       Class 2   20
#> 20      20       Class 1   20
#> 21      21       Class 1   20
#> 22      22       Class 2   20
#> 23      23       Class 1   20
#> 24      24       Class 2   20
#> 25      25       Class 2   20
#> 26      26       Class 2   20
#> 27      27       Class 2   20
#> 28      28       Class 2   20
#> 29      29       Class 1   20
#> 30      30       Class 2   20
```
