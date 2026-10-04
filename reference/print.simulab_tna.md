# Print a simulated transition network

Prints the fitted network with the native `tna` print method, then the
transition matrix and initial probabilities that generated the
sequences, in the same format, then the names of the other stored
tables.

## Usage

``` r
# S3 method for class 'simulab_tna'
print(x, digits = 3L, ...)
```

## Arguments

- x:

  A `simulab_tna` result of
  [`simulate_tna()`](https://pak.dynasite.org/simulab/reference/simulate_tna.md).

- digits:

  Digits for the generating probabilities, default `3`.

- ...:

  Passed to the `tna` print method.

## Value

`x`, invisibly.

## Examples

``` r
if (requireNamespace("tna", quietly = TRUE)) {
  print(simulate_tna(n = 30, n_states = 3, seed = 1))
}
#> State Labels : 
#> 
#>    Learn, Plan, Reflect 
#> 
#> Transition Probability Matrix :
#> 
#>             Learn       Plan    Reflect
#> Learn   0.5440252 0.11635220 0.33962264
#> Plan    0.1566265 0.19277108 0.65060241
#> Reflect 0.8934911 0.06508876 0.04142012
#> 
#> Initial Probabilities : 
#> 
#>      Learn       Plan    Reflect 
#> 0.06666667 0.66666667 0.26666667 
#> 
#> Generating Transition Probability Matrix (truth) :
#> 
#>         Learn  Plan Reflect
#> Learn   0.499 0.079   0.422
#> Plan    0.167 0.169   0.664
#> Reflect 0.867 0.071   0.063
#> 
#> Generating Initial Probabilities (truth) :
#> 
#>   Learn    Plan Reflect 
#>   0.038   0.699   0.262 
#> 
#> Other tables: edges, sequences, wide, model_info. Read one with as.data.frame(x, what = "edges").
```
