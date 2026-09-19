# Define a survival process

Records one Weibull hazard segment for one event time. The simstudy
parameterization is used throughout: an event time drawn from this
segment has survival function
`S(t) = exp(-exp(formula) * t^(1 / shape) / scale)`, so `shape` is the
*reciprocal* of the textbook Weibull shape, and `exp(formula)`
multiplies the whole cumulative hazard. A coefficient inside `formula`
is therefore a log hazard ratio, while `formula` itself equals the log
hazard only when `shape` and `scale` are both 1.

## Usage

``` r
define_survival(event, formula = 0, scale = 1, shape = 1, transition = 0)
```

## Arguments

- event:

  Name of the event-time variable. A single non-empty string.

- formula:

  Linear predictor on the log scale, given as a number, a string, or an
  unquoted expression over the covariate columns (for example
  `"-8 + 0.5 * treatment"`). Defaults to `0`. It is stored as text and
  evaluated row by row against the data.

- scale:

  Positive Weibull scale, as a number, a string, or an expression over
  the covariates. Defaults to `1`. It divides the cumulative hazard.

- shape:

  Positive Weibull shape in the simstudy parameterization (the exponent
  applied to the transformed time, so the hazard is constant when
  `shape` is 1 and decreasing when `shape` is above 1). Defaults to `1`.

- transition:

  Time at which this hazard segment begins. A single finite non-negative
  number, defaulting to `0`. The first segment of an event must start at
  `0`.

## Value

A one-row `simulab_survival_spec` base `data.frame` with columns
`event`, `formula`, `scale` and `shape` (all character, the stored
definition text) and the numeric column `transition`.

## Examples

``` r
define_survival("time", formula = -8, shape = 0.3)
#>   event formula scale shape transition
#> 1  time      -8     1   0.3          0
```
