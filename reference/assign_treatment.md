# Assign randomized treatment groups

Assign randomized treatment groups

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

  Base `data.frame`.

- groups:

  Number of treatment groups or their labels.

- balanced:

  Use exact balance within strata.

- strata:

  Optional stratification variables.

- ratios:

  Relative allocation ratios.

- name:

  Name of the treatment variable.

- seed:

  Optional random seed.

## Value

A `simulab_sim` base `data.frame` with a treatment variable and a tidy
allocation table.

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
table(as.data.frame(result)$treatment)
#> 
#>  0  1 
#> 50 50 
```
