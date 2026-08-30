# One-hot encode long-form sequence states

One-hot encode long-form sequence states

## Usage

``` r
encode_sequences(
  data,
  id = "id",
  period = "period",
  state = "state",
  prefix = "state_"
)
```

## Arguments

- data:

  Long-form sequence data.

- id, period, state:

  Column names.

- prefix:

  Generated state-column prefix.

## Value

A `simulab_sim` base `data.frame` with identifiers and one column per
state.

## Examples

``` r
data <- simulate_sequences(n = 10, n_states = 3, chain_length = 5, seed = 1)
head(encode_sequences(data))
#> <simulab_sim:one_hot_sequences> 6 rows x 5 columns
#>   id period state_State.1 state_State.2 state_State.3
#> 1  1      1             0             0             1
#> 2  1      2             0             1             0
#> 3  1      3             0             1             0
#> 4  1      4             0             1             0
#> 5  1      5             1             0             0
#> 6  2      1             0             1             0
```
