# Assign a stepped-wedge treatment schedule

Splits the clusters into equally sized waves and switches each wave on
at `start + (wave - 1) * wave_length`, the wave's treatment-start
period. A row is treated from `treatment_start + lag` onwards, and the
`lag` periods from `treatment_start` up to that point are flagged as
transition periods instead. The period values are compared as they
stand, so they must be on the same scale as `start`. Periods created by
[`expand_periods()`](https://mohsaqr.github.io/simulab/reference/expand_periods.md)
are numbered from `0`.

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

  Long-form base `data.frame`, or a `simulab_sim`, with one row per
  cluster unit and period and at least one row.

- cluster:

  Cluster identifier. A single string naming a column of `data`, whose
  number of unique values must be divisible by `waves`.

- period:

  Period variable. A single string naming a column of `data`, which must
  reach `start + (waves - 1) * wave_length + lag`.

- waves:

  Number of waves. A single positive whole number.

- wave_length:

  Periods between consecutive wave starts. A single positive whole
  number.

- start:

  Treatment-start period of the first wave. A single number.

- lag:

  Transition periods after a cluster's start before treatment becomes
  active. A single non-negative whole number, defaulting to `0`.

- treatment:

  Name of the active-treatment variable, which is `1` from
  `treatment_start + lag` onwards and `0` before. A single string,
  defaulting to `"treatment"`.

- transition:

  Name of the transition variable, which is `1` in the `lag` periods
  between a cluster's `treatment_start` and the start of active
  treatment. A single string, defaulting to `"transition"`. The column
  is only added when `lag` is above `0`.

- randomize:

  Randomize the allocation of clusters to waves. A single flag,
  defaulting to `TRUE`. `FALSE` fills the waves in the order the
  clusters appear in `data`.

- seed:

  Optional random seed. A single number, or `NULL` (the default).

## Value

A `simulab_sim` base `data.frame` with the columns of `data` followed by
the transition variable (only when `lag` is above `0`) and the treatment
variable, one row per input row. The component `schedule`, reached with
`as.data.frame(x, what = "schedule")`, holds one row per cluster with
the cluster identifier under its own name plus columns `wave` and
`treatment_start`.

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
