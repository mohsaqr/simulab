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
```
