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
  list of centres now says ``` `centers` must be a matrix, with at least 2
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
  the cluster-by-variable centre matrix of `simulate_clusters()`, and the
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
