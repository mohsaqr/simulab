# Expand observations across periods

Repeats every unit's row once per period, numbering the periods and
adding the elapsed time each period falls at. Units may be followed for
different numbers of periods, and the spacing may be regular or
irregular. A set of wide columns, one per period, can be gathered into a
single long value column at the same time.

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

  Base `data.frame`, or a `simulab_sim`, with one row per observational
  unit and at least one row.

- periods:

  Number of periods: a single whole number applied to every unit, the
  name of a column of `data` holding a count per unit, or `NULL` when
  `period_values` is supplied.

- id:

  Identifier variable. A single string naming a column of `data`. It is
  carried into the schedule component; the returned rows are the input
  rows repeated, so the identifier is not renumbered.

- period:

  Name of the period column. A single non-empty string, defaulting to
  `"period"`. Periods generated from `periods` are numbered from `0`, so
  a unit followed for `k` periods gets `0` to `k - 1`.

- period_values:

  Optional atomic vector of period values shared by every unit, used in
  place of the numbering above. Defaults to `NULL`, and may not be
  combined with `periods`.

- interval_mean:

  Mean interval between consecutive periods: a single number, the name
  of a column of `data`, or `NULL` (the default) for an interval of `1`.

- interval_dispersion:

  Dispersion of the gamma-distributed intervals: a single non-negative
  number, or the name of a column of `data`. Defaults to `0`, exactly
  regular spacing; a positive value draws each interval from a gamma
  distribution with mean `interval_mean` and variance
  `interval_mean^2 * interval_dispersion`.

- time:

  Name of the generated elapsed-time column, which starts at `0` for
  every unit and accumulates the intervals. A single string, defaulting
  to `"time"`.

- time_variables:

  Optional character vector of wide columns of `data`, exactly one per
  period, gathered into the long value column and then dropped. Defaults
  to `NULL`.

- value:

  Name of the gathered time-varying value. A single non-empty string,
  defaulting to `"value"`.

- seed:

  Optional random seed for irregular intervals. A single number, or
  `NULL` (the default).

## Value

A `simulab_sim` base `data.frame` with one row per unit-period, holding
the columns of `data` plus the period and elapsed-time columns, and the
gathered value column in place of `time_variables` when those are given.
The component `schedule`, reached with
`as.data.frame(x, what = "schedule")`, holds one row per input unit with
columns `input_row`, `id`, `periods`, `interval_mean` and
`interval_dispersion`.

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
