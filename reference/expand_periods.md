# Expand observations across periods

Expand observations across periods

## Usage

``` r
expand_periods(
  data,
  periods = NULL,
  id = "id",
  period = "period",
  period_values = NULL,
  interval_mean = NULL,
  interval_dispersion = 0,
  time = "time",
  time_variables = NULL,
  value = "value",
  seed = NULL
)
```

## Arguments

- data:

  Base `data.frame` with one row per observational unit.

- periods:

  Number of periods, a variable containing counts, or `NULL` when
  `period_values` is supplied.

- id:

  Identifier variable.

- period:

  Name of the period column.

- period_values:

  Optional common period values.

- interval_mean:

  Optional constant or variable defining mean intervals.

- interval_dispersion:

  Optional constant or variable defining gamma interval dispersion.

- time:

  Name of the generated elapsed-time column.

- time_variables:

  Optional wide variables to gather by period.

- value:

  Name of the gathered time-varying value.

- seed:

  Optional random seed for irregular intervals.

## Value

A `simulab_sim` base `data.frame` with one row per unit-period.

## Examples

``` r
data <- data.frame(id = 1:10)
result <- expand_periods(data, periods = 4, id = "id", period = "period")
head(result)
#> <simulab_sim:periods> 6 rows x 3 columns
#>   id period time
#> 1  1      0    0
#> 2  1      1    1
#> 3  1      2    2
#> 4  1      3    3
#> 5  2      0    0
#> 6  2      1    1
```
