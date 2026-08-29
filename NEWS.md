# simulab 0.4.0

## First release under the simulab name

simulab continues the version line of Saqrlab (0.4.1), which it supersedes.
The numbering carries over rather than restarting, because the simulator
work it contains was developed under that name. Saqrlab remains untouched:
its seeded `simulate_data()` output is a fixture contract for other
projects, so simulab is a clean successor rather than an in-place migration.

This is a new CRAN submission.

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
