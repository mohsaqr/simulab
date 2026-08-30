# Assign a stepped-wedge treatment schedule

Assign a stepped-wedge treatment schedule

## Usage

``` r
assign_stepped_wedge(
  data,
  cluster,
  period,
  waves,
  wave_length,
  start,
  lag = 0L,
  treatment = "treatment",
  transition = "transition",
  randomize = TRUE,
  seed = NULL
)
```

## Arguments

- data:

  Long-form base `data.frame`.

- cluster:

  Cluster identifier.

- period:

  Period variable.

- waves:

  Number of waves.

- wave_length:

  Periods between wave starts.

- start:

  First treatment-start period.

- lag:

  Transition periods before treatment becomes active.

- treatment:

  Name of the active-treatment variable.

- transition:

  Name of the transition variable.

- randomize:

  Randomize clusters to waves.

- seed:

  Optional random seed.

## Value

A `simulab_sim` base `data.frame` and a tidy cluster-wave schedule.

## Examples

``` r
data <- expand_clusters(
  data.frame(cluster = 1:6), cluster = "cluster", size = 4
)
data <- expand_periods(data, periods = 5, id = "id", period = "period")

result <- assign_stepped_wedge(
  data, cluster = "cluster", period = "period",
  waves = 3, wave_length = 1, start = 2, seed = 1
)
head(result)
#> <simulab_sim:stepped_wedge> 6 rows x 5 columns
#>   id cluster period time treatment
#> 1  1       1      0    0         0
#> 2  1       1      1    1         0
#> 3  1       1      2    2         1
#> 4  1       1      3    3         1
#> 5  1       1      4    4         1
#> 6  2       1      0    0         0
```
