# Assign randomized treatment groups

Randomizes the rows of `data` to treatment groups, independently within
each combination of the `strata` variables. Balanced assignment
allocates the group sizes a stratum is due, rounding the shares to whole
units and giving the remainder to the groups with the largest fractional
part, then permutes them; unbalanced assignment draws each row
independently with probabilities proportional to `ratios`.

## Usage

``` r
assign_treatment(
  data,
  groups = 2L,
  balanced = TRUE,
  strata = NULL,
  ratios = NULL,
  name = "treatment",
  seed = NULL
)
```

## Arguments

- data:

  Base `data.frame`, or a `simulab_sim`, with at least one row.

- groups:

  Number of treatment groups, as a single whole number of at least 2
  (defaulting to `2`), or an atomic vector of at least two unique
  labels. A count of 2 is labeled `0` and `1`, and a larger count `1` to
  `groups`.

- balanced:

  Use exact allocation within each stratum. A single flag, defaulting to
  `TRUE`. `FALSE` draws each row independently instead, so the realized
  group sizes vary.

- strata:

  Optional character vector of stratification variables, all present in
  `data`. Defaults to `NULL`, one stratum holding every row.

- ratios:

  Relative allocation ratios, a positive numeric vector with one value
  per group. Defaults to `NULL`, equal allocation.

- name:

  Name of the treatment variable, which must not already exist in
  `data`. A single non-empty string, defaulting to `"treatment"`.

- seed:

  Optional random seed. A single number, or `NULL` (the default).

## Value

A `simulab_sim` base `data.frame` with the columns of `data` followed by
the treatment variable named by `name`, one row per input row. The
component `allocation`, reached with
`as.data.frame(x, what = "allocation")`, holds one row per stratum and
group, with columns `stratum`, `treatment` and `observations`.

## Examples

``` r
data <- data.frame(id = 1:100, site = rep(c("north", "south"), each = 50))

result <- assign_treatment(data, groups = 2, strata = "site", seed = 1)
head(result)
#> <simulab_sim:treatment_assignment> 6 rows x 3 columns
#>   id  site treatment
#> 1  1 north         0
#> 2  2 north         1
#> 3  3 north         0
#> 4  4 north         1
#> 5  5 north         0
#> 6  6 north         1
as.data.frame(result, what = "allocation")
#>   stratum treatment observations
#> 1   north         0           25
#> 2   south         0           25
#> 3   north         1           25
#> 4   south         1           25
```
