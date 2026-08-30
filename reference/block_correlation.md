# Create clustered-period correlation structures

Create clustered-period correlation structures

## Usage

``` r
block_correlation(
  n_individuals,
  n_periods,
  within_period,
  between_period = 0,
  within_individual = NULL,
  decay = NULL,
  design = c("cross_sectional", "cohort"),
  n_clusters = 1L
)
```

## Arguments

- n_individuals:

  Individuals per period. Supply one value, one value per cluster, or
  one value per cluster-period combination.

- n_periods:

  Number of periods.

- within_period:

  Correlation between different individuals in the same period.

- between_period:

  Correlation between different individuals in different periods for an
  exchangeable structure.

- within_individual:

  Correlation for the same individual across periods in a cohort design.

- decay:

  Optional period-to-period correlation decay. Supplying this selects a
  decay structure.

- design:

  Cross-sectional or closed-cohort design.

- n_clusters:

  Number of cluster-specific structures.

## Value

A base `data.frame` with one row per cluster and correlation-matrix
cell.

## Examples

``` r
block_correlation(
  n_individuals = 3,
  n_periods = 4,
  within_period = 0.3,
  between_period = 0.1,
  design = "cross_sectional"
)
#>                  row           column correlation cluster
#> 1    period_1_unit_1  period_1_unit_1         1.0       1
#> 2    period_1_unit_2  period_1_unit_1         0.3       1
#> 3    period_1_unit_3  period_1_unit_1         0.3       1
#> 4    period_2_unit_4  period_1_unit_1         0.1       1
#> 5    period_2_unit_5  period_1_unit_1         0.1       1
#> 6    period_2_unit_6  period_1_unit_1         0.1       1
#> 7    period_3_unit_7  period_1_unit_1         0.1       1
#> 8    period_3_unit_8  period_1_unit_1         0.1       1
#> 9    period_3_unit_9  period_1_unit_1         0.1       1
#> 10  period_4_unit_10  period_1_unit_1         0.1       1
#> 11  period_4_unit_11  period_1_unit_1         0.1       1
#> 12  period_4_unit_12  period_1_unit_1         0.1       1
#> 13   period_1_unit_1  period_1_unit_2         0.3       1
#> 14   period_1_unit_2  period_1_unit_2         1.0       1
#> 15   period_1_unit_3  period_1_unit_2         0.3       1
#> 16   period_2_unit_4  period_1_unit_2         0.1       1
#> 17   period_2_unit_5  period_1_unit_2         0.1       1
#> 18   period_2_unit_6  period_1_unit_2         0.1       1
#> 19   period_3_unit_7  period_1_unit_2         0.1       1
#> 20   period_3_unit_8  period_1_unit_2         0.1       1
#> 21   period_3_unit_9  period_1_unit_2         0.1       1
#> 22  period_4_unit_10  period_1_unit_2         0.1       1
#> 23  period_4_unit_11  period_1_unit_2         0.1       1
#> 24  period_4_unit_12  period_1_unit_2         0.1       1
#> 25   period_1_unit_1  period_1_unit_3         0.3       1
#> 26   period_1_unit_2  period_1_unit_3         0.3       1
#> 27   period_1_unit_3  period_1_unit_3         1.0       1
#> 28   period_2_unit_4  period_1_unit_3         0.1       1
#> 29   period_2_unit_5  period_1_unit_3         0.1       1
#> 30   period_2_unit_6  period_1_unit_3         0.1       1
#> 31   period_3_unit_7  period_1_unit_3         0.1       1
#> 32   period_3_unit_8  period_1_unit_3         0.1       1
#> 33   period_3_unit_9  period_1_unit_3         0.1       1
#> 34  period_4_unit_10  period_1_unit_3         0.1       1
#> 35  period_4_unit_11  period_1_unit_3         0.1       1
#> 36  period_4_unit_12  period_1_unit_3         0.1       1
#> 37   period_1_unit_1  period_2_unit_4         0.1       1
#> 38   period_1_unit_2  period_2_unit_4         0.1       1
#> 39   period_1_unit_3  period_2_unit_4         0.1       1
#> 40   period_2_unit_4  period_2_unit_4         1.0       1
#> 41   period_2_unit_5  period_2_unit_4         0.3       1
#> 42   period_2_unit_6  period_2_unit_4         0.3       1
#> 43   period_3_unit_7  period_2_unit_4         0.1       1
#> 44   period_3_unit_8  period_2_unit_4         0.1       1
#> 45   period_3_unit_9  period_2_unit_4         0.1       1
#> 46  period_4_unit_10  period_2_unit_4         0.1       1
#> 47  period_4_unit_11  period_2_unit_4         0.1       1
#> 48  period_4_unit_12  period_2_unit_4         0.1       1
#> 49   period_1_unit_1  period_2_unit_5         0.1       1
#> 50   period_1_unit_2  period_2_unit_5         0.1       1
#> 51   period_1_unit_3  period_2_unit_5         0.1       1
#> 52   period_2_unit_4  period_2_unit_5         0.3       1
#> 53   period_2_unit_5  period_2_unit_5         1.0       1
#> 54   period_2_unit_6  period_2_unit_5         0.3       1
#> 55   period_3_unit_7  period_2_unit_5         0.1       1
#> 56   period_3_unit_8  period_2_unit_5         0.1       1
#> 57   period_3_unit_9  period_2_unit_5         0.1       1
#> 58  period_4_unit_10  period_2_unit_5         0.1       1
#> 59  period_4_unit_11  period_2_unit_5         0.1       1
#> 60  period_4_unit_12  period_2_unit_5         0.1       1
#> 61   period_1_unit_1  period_2_unit_6         0.1       1
#> 62   period_1_unit_2  period_2_unit_6         0.1       1
#> 63   period_1_unit_3  period_2_unit_6         0.1       1
#> 64   period_2_unit_4  period_2_unit_6         0.3       1
#> 65   period_2_unit_5  period_2_unit_6         0.3       1
#> 66   period_2_unit_6  period_2_unit_6         1.0       1
#> 67   period_3_unit_7  period_2_unit_6         0.1       1
#> 68   period_3_unit_8  period_2_unit_6         0.1       1
#> 69   period_3_unit_9  period_2_unit_6         0.1       1
#> 70  period_4_unit_10  period_2_unit_6         0.1       1
#> 71  period_4_unit_11  period_2_unit_6         0.1       1
#> 72  period_4_unit_12  period_2_unit_6         0.1       1
#> 73   period_1_unit_1  period_3_unit_7         0.1       1
#> 74   period_1_unit_2  period_3_unit_7         0.1       1
#> 75   period_1_unit_3  period_3_unit_7         0.1       1
#> 76   period_2_unit_4  period_3_unit_7         0.1       1
#> 77   period_2_unit_5  period_3_unit_7         0.1       1
#> 78   period_2_unit_6  period_3_unit_7         0.1       1
#> 79   period_3_unit_7  period_3_unit_7         1.0       1
#> 80   period_3_unit_8  period_3_unit_7         0.3       1
#> 81   period_3_unit_9  period_3_unit_7         0.3       1
#> 82  period_4_unit_10  period_3_unit_7         0.1       1
#> 83  period_4_unit_11  period_3_unit_7         0.1       1
#> 84  period_4_unit_12  period_3_unit_7         0.1       1
#> 85   period_1_unit_1  period_3_unit_8         0.1       1
#> 86   period_1_unit_2  period_3_unit_8         0.1       1
#> 87   period_1_unit_3  period_3_unit_8         0.1       1
#> 88   period_2_unit_4  period_3_unit_8         0.1       1
#> 89   period_2_unit_5  period_3_unit_8         0.1       1
#> 90   period_2_unit_6  period_3_unit_8         0.1       1
#> 91   period_3_unit_7  period_3_unit_8         0.3       1
#> 92   period_3_unit_8  period_3_unit_8         1.0       1
#> 93   period_3_unit_9  period_3_unit_8         0.3       1
#> 94  period_4_unit_10  period_3_unit_8         0.1       1
#> 95  period_4_unit_11  period_3_unit_8         0.1       1
#> 96  period_4_unit_12  period_3_unit_8         0.1       1
#> 97   period_1_unit_1  period_3_unit_9         0.1       1
#> 98   period_1_unit_2  period_3_unit_9         0.1       1
#> 99   period_1_unit_3  period_3_unit_9         0.1       1
#> 100  period_2_unit_4  period_3_unit_9         0.1       1
#> 101  period_2_unit_5  period_3_unit_9         0.1       1
#> 102  period_2_unit_6  period_3_unit_9         0.1       1
#> 103  period_3_unit_7  period_3_unit_9         0.3       1
#> 104  period_3_unit_8  period_3_unit_9         0.3       1
#> 105  period_3_unit_9  period_3_unit_9         1.0       1
#> 106 period_4_unit_10  period_3_unit_9         0.1       1
#> 107 period_4_unit_11  period_3_unit_9         0.1       1
#> 108 period_4_unit_12  period_3_unit_9         0.1       1
#> 109  period_1_unit_1 period_4_unit_10         0.1       1
#> 110  period_1_unit_2 period_4_unit_10         0.1       1
#> 111  period_1_unit_3 period_4_unit_10         0.1       1
#> 112  period_2_unit_4 period_4_unit_10         0.1       1
#> 113  period_2_unit_5 period_4_unit_10         0.1       1
#> 114  period_2_unit_6 period_4_unit_10         0.1       1
#> 115  period_3_unit_7 period_4_unit_10         0.1       1
#> 116  period_3_unit_8 period_4_unit_10         0.1       1
#> 117  period_3_unit_9 period_4_unit_10         0.1       1
#> 118 period_4_unit_10 period_4_unit_10         1.0       1
#> 119 period_4_unit_11 period_4_unit_10         0.3       1
#> 120 period_4_unit_12 period_4_unit_10         0.3       1
#> 121  period_1_unit_1 period_4_unit_11         0.1       1
#> 122  period_1_unit_2 period_4_unit_11         0.1       1
#> 123  period_1_unit_3 period_4_unit_11         0.1       1
#> 124  period_2_unit_4 period_4_unit_11         0.1       1
#> 125  period_2_unit_5 period_4_unit_11         0.1       1
#> 126  period_2_unit_6 period_4_unit_11         0.1       1
#> 127  period_3_unit_7 period_4_unit_11         0.1       1
#> 128  period_3_unit_8 period_4_unit_11         0.1       1
#> 129  period_3_unit_9 period_4_unit_11         0.1       1
#> 130 period_4_unit_10 period_4_unit_11         0.3       1
#> 131 period_4_unit_11 period_4_unit_11         1.0       1
#> 132 period_4_unit_12 period_4_unit_11         0.3       1
#> 133  period_1_unit_1 period_4_unit_12         0.1       1
#> 134  period_1_unit_2 period_4_unit_12         0.1       1
#> 135  period_1_unit_3 period_4_unit_12         0.1       1
#> 136  period_2_unit_4 period_4_unit_12         0.1       1
#> 137  period_2_unit_5 period_4_unit_12         0.1       1
#> 138  period_2_unit_6 period_4_unit_12         0.1       1
#> 139  period_3_unit_7 period_4_unit_12         0.1       1
#> 140  period_3_unit_8 period_4_unit_12         0.1       1
#> 141  period_3_unit_9 period_4_unit_12         0.1       1
#> 142 period_4_unit_10 period_4_unit_12         0.3       1
#> 143 period_4_unit_11 period_4_unit_12         0.3       1
#> 144 period_4_unit_12 period_4_unit_12         1.0       1
```
