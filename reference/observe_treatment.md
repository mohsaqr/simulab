# Generate observational treatment or exposure groups

Evaluates one formula per modeled group against every row of `data` and
draws that row's exposure from the resulting probabilities, so the
formulas are the propensity model. One group is always implicit: it is
listed last and takes the remaining probability, which makes it the
reference category of the logit link.

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

  Base `data.frame`, or a `simulab_sim`, with at least one row.

- formulas:

  Character vector of at least one formula, each an expression over the
  columns of `data`. Under the identity link they are evaluated on the
  probability scale; under the logit link they are the log odds of that
  group relative to the implicit final group, that is a multinomial
  logit linear predictor. An implicit final group receives the remaining
  probability.

- link:

  Scale the formulas are stated on, one of `"identity"` (the default) or
  `"logit"`, the multinomial-logit link.

- labels:

  Optional atomic vector of group labels, one per formula plus one for
  the implicit final group. Defaults to `NULL`: `c(1, 0)` for a single
  formula, so the modeled group is `1` and the implicit reference is
  `0`, and `1` to the number of groups otherwise, the implicit group
  last.

- name:

  Name of the exposure variable, which must not already exist in `data`.
  A single non-empty string, defaulting to `"treatment"`.

- seed:

  Optional random seed. A single number, or `NULL` (the default).

- envir:

  Environment the formulas are evaluated in after the data columns.
  Defaults to the caller's environment.

## Value

A `simulab_sim` base `data.frame` with the columns of `data` followed by
the exposure variable named by `name`, one row per input row. The
component `probabilities`, reached with
`as.data.frame(x, what = "probabilities")`, holds one row per
observation and group, with columns `observation`, `group` and
`probability`.

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
