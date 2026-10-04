# simulab 0.4.8

## One transition network in one call

- New `simulate_tna()` takes or draws a transition matrix, generates
  sequences from it and fits one transition network with the `tna` package.
  The result is the native `tna` model (class `c("simulab_tna", "tna")`), so
  `plot()`, `centralities()` and every other `tna` function apply to it. It
  prints the native `tna` output, then the generating transition matrix and
  initial probabilities; `as.data.frame()` gives the fitted edges, and
  `what = "transitions"` the truth. A drawn matrix is labeled with
  metacognitive and cognitive learning states by default, as in Saqrlab, and
  the printed truth follows the fitted network's state order. It restores the single-network verb of Saqrlab, where it
  was `simulate_tna_network()`; in simulab that name remains the node-grouped
  matrix generator. Like every simulator, it takes `batch` and runs with no
  arguments.
- Without the `tna` package, TNA fitting raises the classed condition
  `simulab_missing_tna`.

## Learning-state labels by default

- `simulate_sequences()`, `simulate_group_sequences()`, `simulate_group_tna()`,
  `generate_transition_system()` and `simulate_tna()` label a drawn state
  space with metacognitive and cognitive states from the learning-state
  catalogue by default (`state_categories = c("metacognitive", "cognitive")`),
  as Saqrlab did. `state_categories = NULL` restores `State 1`, `State 2`, and
  so on. Because the labels are drawn, seeded output of these generators
  differs from 0.4.7 when they draw their own state space.
- Grouped sequences draw their labels once and share them, so every group has
  the same state space. Before, groups given `state_categories` each drew
  their own labels.
- The README is generated from `README.Rmd`, so its printed output is run, and
  it is rewritten around the current interface. The title is now "Simulates a
  Wide Variety of Data Shapes, Sizes and Distributions", and the description
  leads with the range of data and with parameters that are drawn or given,
  and in both cases recoverable. Sonsoles López-Pernas is an author and copyright holder.

## Simulation with no parameters

- `simulate_regression()`, `simulate_ttest()`, `simulate_anova()`,
  `simulate_sequences()`, `simulate_group_sequences()` and
  `simulate_group_tna()` run with no arguments. Sizes have defaults (100
  observations; 50 per group for a t-test; 3 groups of 30 for an analysis of
  variance; 100 sequences of length 20; 2 groups of 50 actors with sequences
  of length 20).
- A parameter left `NULL` is drawn inside the same seeded block as the data and
  reported as the truth in the result's tables. Regression draws an intercept
  from the standard normal distribution and `n_predictors` (new, default 2)
  slopes from the uniform distribution on [-1, 1]; group designs draw each
  mean from the standard normal distribution. Drawn values are rounded to two
  decimals, so the reported value is the value used.
- Printing a result shows its generating values under the data, headed
  `Truth`, and names the other stored tables.
- `validate_recovery()` takes a result, or a whole batch, as `truth`. A batch
  is matched by `batch_id` and `term`, so each estimate is compared with the
  truth of its own data set, which a batch with drawn parameters needs.
  `true_value` defaults to `NULL`: a `truth` column, or else the single
  numeric column of the truth table.
- `apply_batch()` takes a model function directly:
  `apply_batch(datasets, lm, formula = outcome ~ x1 + x2)`. Each data set is
  passed as `data` when the function has that argument, and a fitted model is
  returned as its coefficients, with columns `term` and `estimate`.
- `simulate_tna_batches()` and `simulate_sequence_batches()` take
  `repetitions = 1` by default, so `simulate_tna_batches()` with no arguments
  draws a transition system, generates sequences and fits one network.
- `simulate_tna_batches()` identifies data sets by `dataset` in the fitted
  edges and `model_info`, as its `sequences` and `true_transitions` tables
  already did. The column was `network`, which kept fitted edges and truth
  from being matched. Its rows are numbered 1 to n instead of `1.1`, `1.2`.
- `validate_recovery()` handles an estimate column and a true-value column of
  the same name, such as `probability`, and takes a fitted model, such as
  `lm()` or `coxph()`, as `estimates`. Grouped TNA tables are numbered 1 to n
  instead of `Group 1.1`.
- Calls that supply the parameters produce the same data as in 0.4.7, and
  positional calls keep their meaning: `n_predictors` is the last argument of
  `simulate_regression()`.

# simulab 0.4.7

## Inputs are matched by name, not position

Several simulators take two inputs that describe the same things, such as
`means` and `sds` for the same profiles, or `transition` and `emission` for the
same hidden states. The second input was matched to the first by position. A
tidy table listed in another order, or a named matrix or vector in another
order, silently attached its values to the wrong profile, state or variable,
and the parameter tables reported those wrong values as the truth. The second
input is now matched by name, and names that do not match raise
`simulab_mismatched_names`. Unnamed matrices and vectors are still matched by
position. Affected: `simulate_lpa()`, `simulate_ml_lpa()`,
`simulate_clusters()`, `simulate_hmm()`, `simulate_irt()`,
`simulate_factors()`, `simulate_regression()`, `simulate_correlated()`,
`simulate_ordinal()`, `simulate_copula()`, `simulate_network()`,
`simulate_markov()`, `simulate_sequences()`, `simulate_group_sequences()`,
`simulate_group_tna()`, `simulate_sequence_clusters()` and
`simulate_longitudinal()`.

- A square `from`/`to` table whose `to` column lists states in a different
  order from its `from` column was pivoted with mismatched rows and columns,
  so self-transitions were off the diagonal (`simulate_hmm()`,
  `simulate_network()`, grouped and clustered sequence transitions).
- Names given with an input now label the output: profiles
  (`simulate_lpa()`, `simulate_ml_lpa()`), cluster classes
  (`simulate_ml_lpa()`), latent classes and categories (`simulate_lca()`),
  hidden states and observations (`simulate_hmm()`), items
  (`simulate_irt()`), groups (`simulate_group_sequences()`) and sequence
  clusters (`simulate_sequence_clusters()`). They were replaced by
  `Profile 1`, `Class 1`, `State 1` and similar.

## Batches from every simulator

- Every simulator that produces one dataset (39 verbs, including
  `generate_transition_system()` and `simulate_until_event()`) takes
  `batch = NULL`. Given a positive whole number, it returns a plain `list` of
  that many results, each exactly what the call without `batch` returns. The
  argument also passes through `simulate_data()`. The four verbs that already
  replicate (`simulate_sequence_batches()`, `simulate_tna_batches()`,
  `simulate_network_batches()`, `simulate_scenarios()`) keep their own
  `repetitions` or replication arguments.
- With a `seed`, each dataset gets its own seed drawn from it, so a batch is
  reproducible and the caller's random-number stream is unchanged. Seeds are
  drawn rather than consecutive because several verbs already seed their
  groups or layers with `seed + k - 1`.
- An invalid `batch` raises a `simulab_invalid_batch` condition.

## Monte Carlo recovery

- `validate_recovery()` keeps every other column of `estimates`, such as the
  `batch_id` from `apply_batch()`, and returns rows in the order of
  `estimates`. It previously dropped identifiers and sorted by term, so a
  recovery table from a batch could not be traced back to its datasets.
- `summarize_simulations()` numbers its rows 1 to n instead of labeling them
  by group, and a group with no non-missing values reports `NA` statistics
  rather than `NaN`, `Inf` and two warnings.
- `simulate_lpa()` and `simulate_ml_lpa()` label profiles with the names given
  in `means` (the `profile` values of a tidy table, or matrix row names). They
  previously replaced them with `Profile 1`, `Profile 2`, and so on.
- `list_distributions()` numbers its rows 1 to n after sorting.
- `summarize_simulations()` without `by` no longer adds a `.group` column
  holding `"all"`.
- `summarize_transitions()` and `network_centrality()` number their rows 1 to
  n.
- `as_igraph()`, `network_centrality()` and `compare_centralities()` take
  `directed = NULL` by default and read the direction from the network's
  `settings` table. The default was `TRUE`, which read an undirected network
  (whose edge list stores each tie once) as directed and distorted
  betweenness, eigenvector and PageRank centrality unless `directed = FALSE`
  was passed by hand.
- `survival` is suggested, for the Cox model in the vignette.
- The vignette is rewritten as a methodological guide: the model behind each
  family of simulators, with its references, a simulation from it, its
  parameter tables, and a recovery check where one is short.

## Bug fixes found by the batch sweep

- `simulate_bipartite_network()` failed with "arguments imply differing number
  of rows: 0, 1" whenever a probability draw produced no edges (94 of seeds
  1 to 300 at the defaults). It now returns an empty edge list.
- `simulate_proportional_survival()` occasionally raised
  `simulab_no_convergence` when solving for the censoring rate (24 of seeds
  1 to 2000 at `n = 10`). The shared root solver now refines to machine
  precision, so convergence is decided by the residual alone.
- `simulate_longitudinal(beeps_per_day = )` reset the carryover one occasion
  late, at the second beep of each day (and at the second beep of day one),
  so the first beep of every later day still carried over the previous
  evening. The reset also dropped `intercept`, setting the value to the person
  mean instead of the person mean plus the intercept. The carryover now
  resets at the first beep of each day after the first, and only the lagged
  term is removed.

# simulab 0.4.6

- `VignetteBuilder` now lists `rmarkdown` as well as `knitr`. Under CRAN's
  no-Suggests check (`_R_CHECK_DEPENDS_ONLY_=true`) only the `VignetteBuilder`
  packages stay available, so the `knitr::rmarkdown` vignette failed to
  re-build without `rmarkdown`. Found by the R-hub `nosuggests` platform.

# simulab 0.4.5

- Adds the R-hub v2 check workflow (`.github/workflows/rhub.yaml`). No change
  to package code.

# simulab 0.4.4

## CRAN preparation

- The seed-contract test no longer errors when the suggested `tna` package is
  unavailable: `simulate_group_tna()` also calls `fit_tna()` and is now skipped
  alongside `simulate_tna_batches()` in that case.
- Documentation uses US spelling throughout, matching `Language: en-US`.
- `DESCRIPTION` names the maintainer as copyright holder (`cph`).

# simulab 0.4.3

## Two-level latent profile data

- New `simulate_ml_lpa()` generates the nonparametric two-level mixture of
  Vermunt (2003): clusters belong to latent cluster classes, a cluster class
  fixes how common each individual profile is inside its clusters, and one
  measurement model is shared by every cluster. This is the generating model
  behind two-level latent profile and latent class software, and it was the
  gap between `simulate_lpa()` (a mixture with no clusters) and
  `simulate_multilevel()` (clusters with no mixture).
- The verb returns one row per individual with `id`, `cluster`,
  `cluster_class`, `profile` and the indicators, plus three tidy components:
  `parameters` (profile means, standard deviations and marginal prevalence),
  `profile_probabilities` (the cluster-class-by-profile prevalence matrix that
  defines the two-level structure) and `clusters` (each cluster's class and
  size). Matrix and tidy-data-frame input are both accepted, as elsewhere in
  the package.
- Registered in `list_simulators()` and dispatchable through
  `simulate_data("ml_lpa", ...)`.

# simulab 0.4.2

## Correctness fixes found by a documentation audit

A function-by-function audit of every exported verb's documentation against its
implementation found five cases where the code did not do what the
documentation described. All five are fixed, and each carries a regression
test.

- `simulate_longitudinal()` read a tidy `transition` table with `from` and `to`
  reversed. A row written as `from = "a", to = "b"` produced the effect of `b`
  on `a`, the opposite of what it says. `from` is now the driving variable at
  `t-1` and `to` the driven variable at `t`, matching the column names and the
  documented VAR recursion. Callers who compensated for the old behavior by
  swapping the columns must stop doing so; the matrix form is unaffected.
- `simulate_event_log()` ignored a fixed `sequence_length`. Because `sample()`
  reads a length-one numeric as an upper bound, `sequence_length = 8` drew
  lengths uniformly from 1 to 8 instead of producing sequences of exactly 8.
  The same trap affected `simulate_sequences(missing_tail = )` with a fixed
  count. Both now draw through a shared range sampler, which leaves seeded
  output unchanged wherever the range was already non-degenerate.
- `simulate_correlated()` failed with "non-conformable arguments" for a single
  variable whose standard deviation was not 1, because `diag()` on a
  length-one numeric builds an identity matrix of that size.
- `simulate_irt()` accepted an item-by-threshold `difficulty` matrix outside
  the graded model, where it reached `sweep()` as an over-long `STATS`. That
  produced a warning rather than an error and a malformed parameters table. It
  is now rejected with a message naming the model that takes a matrix.
- `sample_tna()` hardcoded the `id`, `period` and `state` column names, so
  sequence data using any other names yielded integer state labels and
  all-zero weights with no error. It now takes `format`, `id`, `period`,
  `state` and `group` arguments and passes them to the sampling step.

## Documentation

- Every exported function's documentation was checked against its
  implementation and corrected where the two disagreed. The corrections
  concentrate on `@return` sections, which now name the component tables and
  their columns, and on parameterizations that were stated imprecisely:
  survival status coding and the Weibull shape convention, IRT difficulty and
  guessing, factor uniquenesses as variances, copula marginals, the latent
  rather than realized ordinal correlation, and the missingness mechanisms.
- Examples that use the suggested `igraph` and `tna` packages are now guarded
  with `requireNamespace()`, so they no longer fail where a suggested package
  is absent.
- Added a seed-contract test that checks reproducibility and random-number
  state restoration on every dispatchable verb, reading its case list from the
  simulator registry.

# simulab 0.4.1

## Simulator registry and generator hardening

- `list_simulators()` and `simulate_data()` now share one internal registry.
  All 43 public `simulate_*` and `generate_*` verbs are represented and
  classified as simulators, generators, workflows, or the dispatcher itself;
  the catalogue also reports the backing function and dispatchability.
- Previously undiscoverable sequence, transition-system, batch, scenario,
  correlated-data and until-event verbs can now be called through
  `simulate_data()`.
- Fixed multiplex generation when a layer legitimately contains zero edges.
- Fixed one-predictor Gaussian generation when its standard deviation is a
  non-unit scalar; scalar `diag()` interpretation had produced a zero-sized
  scale matrix.
- Added registry-contract, dispatch, calibration and validation tests for the
  least-covered prediction, ordinal, cluster, latent-profile and multiplex
  generator branches.

## The distribution-call lane reaches every simulator

A specification written as distribution calls is now accepted wherever one is
taken. Previously only `simulate_study()` understood it.

- `augment_study()` generates a call specification into data that already
  exists. A parameter may refer to a column that was already there as readily
  as to a variable defined earlier in the same specification. A variable that
  already exists is refused with the new condition class
  `simulab_existing_variable`, in both specification lanes.

- `simulate_copula()` takes a call specification as the marginals of a
  Gaussian copula, so each variable keeps its own distribution while the set
  is correlated. A marginal must be invertible;
  `list_distributions(copula = TRUE)` reports the 69 distributions that carry
  a quantile function, and naming one of the other ten raises
  `simulab_no_quantile` rather than failing later.

- `define_conditions()` states a rule as `when(condition, distribution)`.
  Repeating the variable name gives it one rule per condition, and every
  distribution in the catalogue is available rather than the fifteen the
  `formula`/`variance` lane covers:

  ```r
  define_conditions(
    outcome = when(group == 1, normal(mean = 5, sd = 1)),
    outcome = when(group == 0, poisson(lambda = 2))
  )
  ```

  `when(TRUE, ...)` applies to every row. `apply_conditions()` detects the
  rule form and draws it through the registry.

- `define_survivals()` states a process as `hazard(log_rate, shape, scale,
  from)`, whose log rate is an expression over the covariates rather than a
  string. Repeating the event name gives a piecewise hazard. The hazard lane
  is a front end on the columns `define_survival()` writes, so it produces the
  same specification and the same event times.

## Distribution catalogue

- The catalogue grows from 47 distributions to **79**, still with no added
  dependency. A registry entry may now carry a `quantile` function as well as
  or instead of a `sampler`. A quantile function yields a sampler for free and
  is what a copula margin needs, so a distribution added as an inverse CDF
  reaches `simulate_study()` and `simulate_copula()` in one definition.

  Added: `arcsine`, `kumaraswamy`, `power`, `burr`, `dagum`, `log_logistic`,
  `levy`, `generalized_logistic`, `hyperbolic_secant`, `anglit`, `bradford`,
  `truncated_exponential`, `tukey_lambda`, `moyal`, `maxwell`, `chi`,
  `nakagami`, `exponentiated_weibull`, `johnson_su`, `johnson_sb`, `benini`,
  `generalized_gamma`, `generalized_normal`, `logit_normal`, `power_normal`,
  `inverse_gaussian`, `rice`, `skew_normal`, `semicircular`, `skellam`,
  `zero_truncated_negative_binomial` and `zero_inflated_negative_binomial`.

- `list_distributions()` gains a `copula` column and a `copula` argument, so
  the distributions usable as a copula marginal are one call away.

- A parameter that leaves its distribution's support now raises
  `simulab_invalid_parameter`, naming the variable and the parameters that did
  it. Base R's samplers return `NA` with a warning in that case, which a
  specification could carry silently into a result.

- Fixed: `zero_inflated_poisson()` warned "NaNs produced" because `ifelse()`
  evaluates both arms across the whole vector, so the arm it discarded still
  called `qpois()` with a negative probability.

### Reproducibility note

Every distribution simulab defines itself is now defined once, as a quantile
function, with the sampler derived from it, rather than as a separate sampler
that stated the same distribution a second time. The distributions are
unchanged, but an inverse-CDF sampler written on `u` and one written on
`1 - u` do not produce the same numbers from the same seed.

Comparing the 47 distributions of 0.4.0 draw for draw under a fixed seed,
**eleven** now produce different numbers: `pareto`, `lomax`, `rayleigh`,
`gompertz`, `inv_gamma`, `half_normal`, `half_cauchy`, `half_logistic`,
`gpd`, `beta_prime` and `zero_inflated_poisson`. The other thirty-six,
including every base R sampler and every distribution whose quantile form
happens to consume `u` the same way, reproduce exactly. A stored result from
0.4.0 that used one of the eleven will differ; its distribution has not
changed.

## Calibration

- New `calibrate_moments()` solves a distribution's own parameters from a
  target mean and variance, across 36 distributions. The result names the
  parameters a distribution call takes, so a moment target becomes a
  specification:

  ```r
  calibrate_moments("lognormal", mean = 10, variance = 25)
  ```

  A one-parameter family takes the mean alone and reports the variance its
  mean fixes. Targets recycle. Moments no member of the family attains raise
  `simulab_unattainable_moments`; a distribution with no implemented inversion
  raises `simulab_no_moment_solution`. Most solves are closed form; for a scale
  family whose shape is fixed by the coefficient of variation alone -- Weibull,
  log-logistic, Frechet, Nakagami -- the shape is found with the package's
  checked root finder and the scale then follows exactly. Gamma ratios are
  taken in log space, because `gamma()` overflows long before the shape does.

- `calibrate_distribution()` now returns one row per parameter, with columns
  `distribution`, `mean`, `dispersion`, `parameter` and `value`, instead of
  the wide `parameter_1`/`value_1`/`parameter_2`/`value_2` layout. The wide
  form made the caller reach for a positional column. **This is a breaking
  change** to the shape of its result; the values are unchanged and still
  agree with {simstudy} 0.9.2.

- Both calibration verbs now raise `simulab_incompatible_lengths` for
  targets of non-recyclable lengths, where the message was previously
  unclassed.

## Other

- `DESCRIPTION` now declares `Imports: stats, utils`. The `NAMESPACE` imported
  from `stats` without the package being declared.
- `actions/checkout` bumped from `@v4` to `@v5` in both workflows, clearing the
  Node.js 20 deprecation annotation on every CI job.

## The two specification lanes

Neither lane is deprecated, and they are not two spellings of one thing. A
distribution call parameterizes a distribution by its own parameters and
reaches all 79. A specification column parameterizes it by a mean and a
dispersion on a link scale, which is what `calibrate_distribution()`,
`calibrate_icc()` and `calibrate_logistic()` speak, what `read_definitions()`
reads from a CSV, and what the multilevel and longitudinal simulators build
programmatically. `link` is meaningful only in the column lane; in a call, a
link is a function inside the expression. `calibrate_moments()` converts
between the two.

# simulab 0.4.0

## First release under the simulab name

simulab continues the version line of Saqrlab (0.4.1), which it supersedes.
The numbering carries over rather than restarting, because the simulator
work it contains was developed under that name. Saqrlab remains untouched:
its seeded `simulate_data()` output is a fixture contract for other
projects, so simulab is a clean successor rather than an in-place migration.

This is a new CRAN submission.

### Specification API

- `define_variables()`, `define_survivals()`, `define_missingnesses()` and
  `define_conditions()` now accept the columns of a specification directly as
  named vectors, so a data-generating process is one call rather than a
  constructor invoked once per row:

  ```r
  define_variables(
    variable     = c("baseline", "treatment", "outcome"),
    formula      = c("0", "0.5", "0.4 * baseline + 0.8 * treatment"),
    variance     = c("1", "0", "1"),
    distribution = c("normal", "binary", "normal")
  )
  ```

  A column given as a single value is recycled across every row, so shared
  settings are written once. The previous form, passing objects from
  `define_variable()` and friends, still works and produces an identical
  specification. The two forms cannot be mixed in one call, which raises
  `simulab_mixed_specification`.

  Column-form errors are classed: `simulab_incomplete_specification`,
  `simulab_unknown_column`, `simulab_unnamed_specification`,
  `simulab_column_length` and `simulab_column_type`.

### Distribution calls

- `define_variables()` accepts a data-generating process written as
  distribution calls. The variable name is the argument name and the
  distribution is a call whose arguments are its parameters:

  ```r
  define_variables(
    age     = normal(mean = 50, sd = 10),
    treated = binary(prob = 0.5),
    outcome = normal(mean = 10 + 0.2 * age + 2 * treated, sd = 2)
  )
  ```

  Parameters may be positional or named, matched with R's own rules, so
  `normal(5, 1)` and `normal(mean = 5, sd = 1)` produce identical data.
  Partial matching is rejected: a specification is saved and re-run, and an
  abbreviation that is unique today becomes ambiguous when a parameter is
  added later.

  A parameter may be any expression over variables defined earlier, so a
  regression is written directly. A link is a function in that expression
  rather than a separate `link` column, and a mixture nests real distribution
  calls rather than referring to variables defined elsewhere.

  Distribution calls are captured unevaluated, so `gamma()`, `beta()`, `t()`
  and `f()` name distributions without reaching the base functions of those
  names. A parameter referring to an undefined variable raises
  `simulab_undefined_variable` naming the variable, where it previously
  resolved to a base function and failed with "non-numeric argument to binary
  operator".

- Added `list_distributions()`, which reports the catalogue with the
  parameters each distribution takes in positional order.

- The catalogue is 47 distributions, up from 17, all built on base R with no
  added dependency: 12 base-R continuous, 18 derived continuous, 11 discrete,
  3 non-central, and mixture, categorical, deterministic and treatment. Each
  is checked against its theoretical mean.

- The specification-column and constructor forms are unchanged and continue to
  work.

### Long-form input package-wide

- Every argument that is a matrix, an array or a list of matrices now also
  accepts the equivalent long-form data frame. 30 of the package's 35 such
  arguments take tidy input, up from 6. The affected simulators are
  `simulate_hmm()`, `simulate_longitudinal()`, `simulate_clusters()`,
  `simulate_factors()`, `simulate_lpa()`, `simulate_lca()`, `simulate_irt()`,
  `simulate_growth()`, `simulate_network()`, `simulate_sequence_clusters()`,
  `simulate_group_sequences()`, `simulate_group_tna()`,
  `simulate_prediction()` and `encode_factors()`.

  ```r
  simulate_hmm(
    n = 40, chain_length = 10,
    transition = data.frame(from = c("A", "A", "B", "B"),
                            to = c("A", "B", "A", "B"),
                            probability = c(0.7, 0.3, 0.4, 0.6)),
    emission = data.frame(state = c("A", "A", "B", "B"),
                          observation = c("x", "y", "x", "y"),
                          probability = c(0.9, 0.1, 0.2, 0.8))
  )
  ```

  A symmetric argument may be given as one triangle, with the mirror cell
  filled and the diagonal defaulted. A list of matrices is expressible as one
  table with a grouping column. `simulate_prediction()` takes its levels,
  effects and sampling probabilities as a single table rather than three
  parallel lists.

  Matrices and lists continue to work. Tests assert that the two call styles
  return byte-identical results under the same seed for every wired argument.
  Malformed long-form input raises `simulab_bad_tidy_input`, and a table that
  omits cells raises `simulab_incomplete_tidy_input`.

  The five arguments that remain list-only are named lists of data frames
  (`apply_batch(inputs)`, `fit_tna_batch(inputs)`,
  `summarize_networks(networks)`), where a list is the correct shape, and the
  two `simulate_prediction()` arguments superseded by its tidy table.

### Validation and error reporting

- Every `stopifnot()` in the package now carries a named message stating the
  argument contract, so a rejected call reports what the argument must be
  rather than the deparsed predicate that failed. `simulate_clusters()` with a
  list of centers now says ``` `centers` must be a matrix, with at least 2
  rows ``` instead of `is.matrix(centers) is not TRUE`.

- Calibration and missingness solvers no longer return an unconverged root.
  `calibrate_logistic()`, `inject_missingness()`,
  `missingness_matrix()` and `simulate_proportional_survival()` now raise a
  classed `simulab_no_solution` error when the requested target is
  unattainable, and `simulab_no_convergence` when the search does not reach
  its tolerance. The censoring-rate solve is also tightened by one iteration,
  moving its residual from 1.6e-07 to 3.2e-14.

- `read_definitions()` now returns character specification columns. A file
  whose formulas were all numeric literals previously read back with integer
  `formula` and `variance` columns, which `simulate_study()` rejected, so a
  specification could not round-trip through CSV. It also validates `link`,
  rejects empty entries, and raises classed
  `simulab_bad_definition_file`, `simulab_duplicate_variable`,
  `simulab_unknown_distribution` and `simulab_unknown_link` errors.

### Documentation

- Every exported function now has a runnable `@examples` block, including the
  arguments whose required shape was previously undiscoverable: the
  class-by-indicator-by-category array of `simulate_lca()`, the named
  coefficient vectors of `simulate_regression()` and `simulate_multilevel()`,
  the cluster-by-variable center matrix of `simulate_clusters()`, and the
  tidy from/to/probability transition table accepted throughout the sequence
  simulators.

### Fixes carried from development

- `rho` is now applied when `structure` is left at its default. Previously
  `structure` defaulted to `"independent"`, so a supplied `rho` was silently
  discarded by `simulate_correlation()`, `simulate_correlated()`,
  `simulate_ordinal()`, `simulate_copula()`, `augment_correlated()` and
  `correlation_structure()`. Leaving `structure` unset now selects
  `"exchangeable"` when a non-zero `rho` or `tau` is given, and `"custom"`
  when a `correlation` matrix is given. Requesting
  `structure = "independent"` together with a non-zero `rho` raises a classed
  error rather than returning uncorrelated data.

- Added a unified `simulab_sim` result contract: primary observations behave
  as ordinary data frames and secondary truth/design tables use
  `as.data.frame(x, what = ...)`.
- Added declarative study definitions, correlated and copula data, missingness,
  treatment assignment, survival, competing risks, clustering, longitudinal
  designs, factorial designs, conditions, and calibration helpers.
- Added statistical, latent-variable, item-response, multilevel, growth,
  longitudinal, hidden-Markov, prediction, survival, sequence, and educational
  event-log simulators.
- Added sequence and temporal-network analysis workflows, including grouped
  TNA, FTNA, CTNA, and ATNA models, bootstrap, cross-validation, reliability,
  model comparison, and recovery assessment.
- Added static graph models and explicit edge-list, temporal, matrix,
  bipartite, multiplex, grouped, and repeated-network simulators.
- Added reproducible scenario, batch, parameter-grid, summary, and export
  workflows.
