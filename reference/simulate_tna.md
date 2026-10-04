# Simulate one transition network

Takes or draws a transition matrix, generates sequences from it with
[`simulate_sequences()`](https://pak.dynasite.org/simulab/reference/simulate_sequences.md),
and fits one transition network to the sequences with the `tna` package,
all in one call.

## Usage

``` r
simulate_tna(
  n = 100L,
  transition = NULL,
  chain_length = 20L,
  initial = NULL,
  states = NULL,
  n_states = 5L,
  state_categories = c("metacognitive", "cognitive"),
  model = c("tna", "ftna", "ctna", "atna"),
  seed = NULL,
  ...,
  batch = NULL
)
```

## Arguments

- n:

  Number of sequences, defaulting to `100`.

- transition:

  Generating transition matrix, or a tidy data frame with columns
  `from`, `to` and `probability`. `NULL` (the default) draws one over
  `n_states` states from a Dirichlet distribution.

- chain_length:

  Sequence length, defaulting to `20`.

- initial:

  Initial probabilities or a fixed starting state. When `NULL` and
  `transition` is supplied, every sequence starts in the first state.

- states:

  State labels.

- n_states:

  Number of automatically generated states.

- state_categories:

  Learning-state categories the labels of a drawn matrix come from,
  defaulting to `c("metacognitive", "cognitive")`; see
  [`learning_state_categories()`](https://pak.dynasite.org/simulab/reference/learning_state_categories.md).
  `NULL` labels the states `State 1`, `State 2`, and so on. Ignored when
  `transition` or `states` names the states.

- model:

  TNA estimator, one of `"tna"` (the default), `"ftna"`, `"ctna"` or
  `"atna"`.

- seed:

  Optional random seed.

- ...:

  Further arguments passed to
  [`simulate_sequences()`](https://pak.dynasite.org/simulab/reference/simulate_sequences.md),
  such as `concentration` or `missing_tail`.

- batch:

  Optional single positive whole number. When given, the simulator runs
  `batch` times and returns a plain `list` of `batch` results, each
  exactly what the same call without `batch` returns. With a `seed`,
  every dataset gets its own seed drawn from `seed`, so the whole batch
  is reproducible; without one the datasets are consecutive draws from
  the session's random-number stream. The default `NULL` returns a
  single result.

## Value

The fitted network as a native `tna` model, of class
`c("simulab_tna", "tna")`, so every `tna` function
([`plot()`](https://rdrr.io/r/graphics/plot.default.html),
`centralities()`, [`summary()`](https://rdrr.io/r/base/summary.html) and
the rest) applies to it. Printing it shows the native `tna` print, then
the generating transition matrix and initial probabilities. Tidy tables
come from
[as.data.frame()](https://pak.dynasite.org/simulab/reference/as.data.frame.simulab_tna.md):
the fitted `edges` (the default; columns `from`, `to` and `weight`), the
generating `transitions` (columns `from`, `to` and `probability`),
`initial_probabilities`, the generated `sequences` in long form, `wide`
and `model_info`. Requires the suggested `tna` package, and raises
`simulab_missing_tna` without it.

## Examples

``` r
if (requireNamespace("tna", quietly = TRUE)) {
  # With no arguments: a drawn 5-state system, 100 sequences, one network.
  network <- simulate_tna(seed = 1)
  network
  validate_recovery(network, network, term = "to", estimate = "weight")

  # From a given transition matrix.
  transition <- data.frame(
    from = rep(c("plan", "act"), each = 2),
    to = rep(c("plan", "act"), times = 2),
    probability = c(0.3, 0.7, 0.6, 0.4)
  )
  simulate_tna(n = 200, transition = transition, seed = 1)
}
#> State Labels : 
#> 
#>    act, plan 
#> 
#> Transition Probability Matrix :
#> 
#>            act      plan
#> act  0.3924374 0.6075626
#> plan 0.6983180 0.3016820
#> 
#> Initial Probabilities : 
#> 
#>  act plan 
#>    0    1 
#> 
#> Generating Transition Probability Matrix (truth) :
#> 
#>      act plan
#> act  0.4  0.6
#> plan 0.7  0.3
#> 
#> Generating Initial Probabilities (truth) :
#> 
#>  act plan 
#>    0    1 
#> 
#> Other tables: edges, sequences, wide, model_info. Read one with as.data.frame(x, what = "edges").
```
