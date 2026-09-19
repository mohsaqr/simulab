# Add one or more survival processes to data

Draws one latent event time per process for every row of `data`, from
the Weibull hazard of
[`define_survival()`](https://mohsaqr.github.io/simulab/reference/define_survival.md).
The times are uncensored: censoring and competing-risk coding are
applied afterwards, for example with
[`combine_competing_risks()`](https://mohsaqr.github.io/simulab/reference/combine_competing_risks.md).
An event with several rows in `specification` has a piecewise hazard,
whose `scale` and `shape` must stay constant across its segments.

## Usage

``` r
augment_survival(
  data,
  specification,
  seed = NULL,
  digits = NULL,
  envir = parent.frame()
)
```

## Arguments

- data:

  Baseline base `data.frame`, or a `simulab_sim`, with at least one row.
  Its columns are the covariates the formulas may refer to, and none of
  them may already carry an event name.

- specification:

  Definitions from
  [`define_survivals()`](https://mohsaqr.github.io/simulab/reference/define_survivals.md),
  a `simulab_survival_spec` object.

- seed:

  Optional random seed. A single number, or `NULL` (the default) to
  leave the stream untouched.

- digits:

  Optional number of decimal places the event times are rounded to. A
  single non-negative whole number, or `NULL` (the default) for
  unrounded times.

- envir:

  Environment the formulas are evaluated in after the data columns.
  Defaults to the caller's environment.

## Value

A `simulab_sim` base `data.frame` with the columns of `data` followed by
one numeric event-time column per process, named by its `event`, and one
row per input row. The component `survival_definitions`, reached with
`as.data.frame(x, what = "survival_definitions")`, is the specification
as a plain `data.frame`.

## Examples

``` r
data <- data.frame(id = 1:100, treatment = rep(0:1, each = 50))

result <- augment_survival(
  data,
  specification = define_survivals(
    define_survival("time", formula = "-8 + 0.5 * treatment", shape = 0.3)
  ),
  seed = 1
)
head(result)
#> <simulab_sim:survival> 6 rows x 3 columns
#>   id treatment      time
#> 1  1         0 11.997214
#> 2  2         0 10.985087
#> 3  3         0  9.248955
#> 4  4         0  5.462235
#> 5  5         0 12.694901
#> 6  6         0  5.640350
```
