# Generate observational treatment or exposure groups

Generate observational treatment or exposure groups

## Usage

``` r
observe_treatment(
  data,
  formulas,
  link = c("identity", "logit"),
  labels = NULL,
  name = "treatment",
  seed = NULL,
  envir = parent.frame()
)
```

## Arguments

- data:

  Base `data.frame`.

- formulas:

  Character vector of probability formulas. An implicit final group
  receives the remaining probability.

- link:

  Identity or multinomial-logit link.

- labels:

  Optional group labels.

- name:

  Name of the exposure variable.

- seed:

  Optional random seed.

- envir:

  Formula evaluation environment.

## Value

A `simulab_sim` base `data.frame` with the generated exposure group.

## Examples

``` r
data <- data.frame(id = 1:100, severity = stats::rnorm(100))

result <- observe_treatment(
  data, formulas = "-0.5 + 0.8 * severity", link = "logit", seed = 1
)
head(result)
#> <simulab_sim:observed_treatment> 6 rows x 3 columns
#>   id    severity treatment
#> 1  1  1.13496509         1
#> 2  2  1.11193185         1
#> 3  3 -0.87077763         0
#> 4  4  0.21073159         1
#> 5  5  0.06939565         0
#> 6  6 -1.66264885         1
```
