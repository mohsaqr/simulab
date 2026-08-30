# Define a survival process

Define a survival process

## Usage

``` r
define_survival(event, formula = 0, scale = 1, shape = 1, transition = 0)
```

## Arguments

- event:

  Name of the event-time variable.

- formula:

  Log-hazard formula.

- scale:

  Positive Weibull scale formula.

- shape:

  Positive Weibull shape formula in the simstudy parameterization.

- transition:

  Time at which this hazard specification begins.

## Value

A one-row `simulab_survival_spec` base `data.frame`.

## Examples

``` r
define_survival("time", formula = -8, shape = 0.3)
#>   event formula scale shape transition
#> 1  time      -8     1   0.3          0
```
