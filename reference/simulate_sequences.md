# Simulate basic or perturbed state sequences

Simulate basic or perturbed state sequences

## Usage

``` r
simulate_sequences(
  n = 100L,
  transition = NULL,
  chain_length = 20L,
  initial = NULL,
  states = NULL,
  n_states = 5L,
  state_categories = c("metacognitive", "cognitive"),
  concentration = 1,
  missing_tail = c(0L, 0L),
  stable_transitions = NULL,
  stability_probability = 0.95,
  instability = c("none", "random_jump", "perturb", "unlikely_jump"),
  instability_probability = 0.4,
  perturbation = 0.5,
  unlikely_threshold = 0.1,
  seed = NULL,
  batch = NULL
)
```

## Arguments

- n:

  Number of sequences, defaulting to `100`.

- transition:

  Optional transition matrix. When `NULL`, a random matrix is generated.

- chain_length:

  Maximum sequence length, defaulting to `20`.

- initial:

  Initial probabilities or a fixed starting state. When `NULL` and
  `transition` is supplied, every sequence starts in the first state.

- states:

  State labels.

- n_states:

  Number of automatically generated states.

- state_categories:

  Learning-state categories that name a generated state space,
  defaulting to `c("metacognitive", "cognitive")`; see
  [`learning_state_categories()`](https://pak.dynasite.org/simulab/reference/learning_state_categories.md).
  `NULL` labels the states `State 1`, `State 2`, and so on. Ignored when
  `transition` or `states` names the states.

- concentration:

  Positive Dirichlet concentration used for automatic transition and
  initial probabilities.

- missing_tail:

  Number or range of trailing positions removed from each sequence.

- stable_transitions:

  Optional two-column data frame named `from` and `to` defining
  preferred transitions.

- stability_probability:

  Probability of following a preferred transition.

- instability:

  Instability mechanism for other transitions.

- instability_probability:

  Probability of applying that mechanism.

- perturbation:

  Multiplicative probability perturbation magnitude.

- unlikely_threshold:

  Maximum probability considered unlikely.

- seed:

  Optional random seed.

- batch:

  Optional single positive whole number. When given, the simulator runs
  `batch` times and returns a plain `list` of `batch` results, each
  exactly what the same call without `batch` returns. With a `seed`,
  every dataset gets its own seed drawn from `seed`, so the whole batch
  is reproducible; without one the datasets are consecutive draws from
  the session's random-number stream. The default `NULL` returns a
  single result.

## Value

A long-form `simulab_sim` base `data.frame` with columns `id`, `period`,
and `state`, one row per observed sequence position.
`as.data.frame(x, what = )` also returns `transitions` (`from`, `to`,
`probability`, row-stochastic in `from`), `initial_probabilities`
(`state`, `probability`), `wide` (one row per sequence, columns `id`,
`S1`, `S2`, ...), and a one-row `settings` table.

## Examples

``` r
result <- simulate_sequences(n = 40, n_states = 4, chain_length = 20, seed = 1)
head(result)
#> <simulab_sim:sequences> 6 rows x 3 columns
#>   id period     state
#> 1  1      1     Learn
#> 2  1      2     Learn
#> 3  1      3 Elaborate
#> 4  1      4   Reflect
#> 5  1      5   Reflect
#> 6  1      6 Elaborate
#> 
#> Truth (transitions):
#>         from      to probability
#> 1    Reflect Reflect  0.43868385
#> 2      Learn Reflect  0.28123564
#> 3       Plan Reflect  0.47177898
#> 4  Elaborate Reflect  0.37139099
#> 5    Reflect   Learn  0.24067761
#> 6      Learn   Learn  0.10338034
#> 7       Plan   Learn  0.03651346
#> 8  Elaborate   Learn  0.05040184
#> 9    Reflect    Plan  0.07555797
#> 10     Learn    Plan  0.15765085
#> ... 6 more rows
#> 
#> Other tables: initial_probabilities, wide, settings. Read one with as.data.frame(x, what = "initial_probabilities").
components(result)
#>                   table rows columns
#> 1                  data  800       3
#> 2           transitions   16       3
#> 3 initial_probabilities    4       2
#> 4                  wide   40      21
#> 5              settings    1       7

# With no arguments, a random transition matrix is drawn and reported.
drawn <- simulate_sequences(seed = 1)
as.data.frame(drawn, what = "transitions")
#>         from        to probability
#> 1    Reflect   Reflect  0.21906379
#> 2      Learn   Reflect  0.29843157
#> 3       Plan   Reflect  0.30462200
#> 4  Elaborate   Reflect  0.31668452
#> 5    Analyze   Reflect  0.10757643
#> 6    Reflect     Learn  0.02478853
#> 7      Learn     Learn  0.03837401
#> 8       Plan     Learn  0.08173499
#> 9  Elaborate     Learn  0.14993651
#> 10   Analyze     Learn  0.02386813
#> 11   Reflect      Plan  0.32729250
#> 12     Learn      Plan  0.24609201
#> 13      Plan      Plan  0.35789866
#> 14 Elaborate      Plan  0.38576778
#> 15   Analyze      Plan  0.19393277
#> 16   Reflect Elaborate  0.31621339
#> 17     Learn Elaborate  0.38141211
#> 18      Plan Elaborate  0.03439126
#> 19 Elaborate Elaborate  0.07007023
#> 20   Analyze Elaborate  0.12152212
#> 21   Reflect   Analyze  0.11264179
#> 22     Learn   Analyze  0.03569030
#> 23      Plan   Analyze  0.22135308
#> 24 Elaborate   Analyze  0.07754096
#> 25   Analyze   Analyze  0.55310055

# Preferred transitions followed with a given probability.
stable <- data.frame(
  from = sprintf("State %d", 1:4),
  to = sprintf("State %d", c(2, 3, 4, 1))
)
head(simulate_sequences(
  n = 40, n_states = 4, chain_length = 20, state_categories = NULL,
  stable_transitions = stable, stability_probability = 0.85, seed = 1
))
#> <simulab_sim:sequences> 6 rows x 3 columns
#>   id period   state
#> 1  1      1 State 4
#> 2  1      2 State 1
#> 3  1      3 State 2
#> 4  1      4 State 3
#> 5  1      5 State 4
#> 6  1      6 State 1
#> 
#> Truth (transitions):
#>       from      to probability
#> 1  State 1 State 1  0.10070835
#> 2  State 2 State 1  0.42327312
#> 3  State 3 State 1  0.43868385
#> 4  State 4 State 1  0.28123564
#> 5  State 1 State 2  0.79360111
#> 6  State 2 State 2  0.26046548
#> 7  State 3 State 2  0.24067761
#> 8  State 4 State 2  0.10338034
#> 9  State 1 State 3  0.06142097
#> 10 State 2 State 3  0.03534803
#> ... 6 more rows
#> 
#> Other tables: initial_probabilities, wide, settings. Read one with as.data.frame(x, what = "initial_probabilities").
```
