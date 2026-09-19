# List public simulation and generation verbs

List public simulation and generation verbs

## Usage

``` r
list_simulators(family = NULL, kind = NULL, dispatchable = NULL)
```

## Arguments

- family:

  Optional single-string family filter, one of `"general"`,
  `"statistical"`, `"latent"`, `"longitudinal"`, `"measurement"`,
  `"sequence"`, `"survival"`, `"empirical"`, `"functional"` or
  `"network"`. An unknown family is an error.

- kind:

  Optional single-string kind filter: `"simulator"`, `"generator"`,
  `"workflow"`, or `"dispatcher"`. An unknown kind is an error.

- dispatchable:

  Optional single logical filter: `TRUE` keeps only the verbs that can
  be called through
  [`simulate_data()`](https://mohsaqr.github.io/simulab/reference/simulate_data.md),
  `FALSE` keeps only those that cannot.

## Value

A base `data.frame` with one row per catalogued verb and the columns
`simulator` (the catalogue name), `function_name`, `kind`, `family`,
`primary_shape` and `dispatchable`.

## Examples

``` r
head(list_simulators())
#>     simulator        function_name      kind      family primary_shape
#> 1       study       simulate_study simulator     general          wide
#> 2 correlation simulate_correlation simulator     general          wide
#> 3  correlated  simulate_correlated simulator     general          wide
#> 4      copula      simulate_copula simulator     general          wide
#> 5     ordinal     simulate_ordinal simulator     general          wide
#> 6       ttest       simulate_ttest simulator statistical          wide
#>   dispatchable
#> 1         TRUE
#> 2         TRUE
#> 3         TRUE
#> 4         TRUE
#> 5         TRUE
#> 6         TRUE
list_simulators(kind = "workflow")
#>          simulator             function_name     kind   family primary_shape
#> 1      until_event      simulate_until_event workflow sequence          long
#> 2 sequence_batches simulate_sequence_batches workflow sequence          long
#> 3      tna_batches      simulate_tna_batches workflow sequence     edge_list
#> 4  network_batches  simulate_network_batches workflow  network     edge_list
#> 5        scenarios        simulate_scenarios workflow  general        varies
#>   dispatchable
#> 1         TRUE
#> 2         TRUE
#> 3         TRUE
#> 4         TRUE
#> 5         TRUE
```
