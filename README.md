# simulab

simulab simulates tidy data with known ground truth. Each simulator takes the
parameters of a data-generating process and returns the observations it
produces, together with the parameters themselves as tidy tables. The package
covers declarative variable definitions, correlated and clustered data,
treatment assignment, missingness, survival and competing risks,
latent-variable and item-response models, longitudinal processes, event
sequences, and static, bipartite, multiplex, temporal and transition networks.

The package is written in base R. It has no hard dependencies beyond the base
distribution and requires R 4.1.0 or later.

## Installation

```r
remotes::install_github("mohsaqr/simulab")
```

Four packages are suggested and none is required at run time. `tna` (1.2.3 or
later) supplies the transition-network estimators used by `fit_tna()`.
`igraph` (2.0.0 or later) receives graphs from `as_igraph()`. `simstudy` is
used as an equivalence oracle in the test suite. `testthat`, `knitr` and
`rmarkdown` build the tests and the vignette.

## The result contract

Every simulator returns a `simulab_sim` object. The object inherits from
`data.frame` and holds one row per observation, so it can be passed directly
to `lm()`, `table()`, `aggregate()` or any function that accepts a data frame.
The parameters that generated the data are attached as named tables.

`components()` lists the tables a result carries. It takes a `simulab_sim`
object and returns a data frame with one row per table and columns `table`,
`rows` and `columns`.

`as.data.frame()` retrieves one table. It takes the object and a `what`
argument naming the table, and returns a base data frame. `what = "data"` is
the default and returns the observations.

```r
result <- simulate_ttest(n_a = 40, n_b = 40, mean_a = 0, mean_b = 0.6, seed = 1)
components(result)
#>        table rows columns
#> 1       data   80       3
#> 2 parameters    2       4
#> 3    effects    1       4

as.data.frame(result, what = "parameters")
#>   group  n mean sd
#> 1     A 40  0.0  1
#> 2     B 40  0.6  1

as.data.frame(result, what = "effects")
#>   contrast mean_difference pooled_sd cohens_d
#> 1    B - A             0.6         1      0.6
```

The `parameters` table records the population means and standard deviations
that were requested. The `effects` table records the population contrast
implied by them: a mean difference of 0.6 with a pooled standard deviation of
1 gives a Cohen's *d* of 0.6. Neither table is estimated from the sample. Both
state what the generating process was set to.

`summary()` describes the observations. It returns one row per variable with
the storage class, the number of observations, the count of missing values,
the number of distinct values, and the mean, standard deviation, minimum and
maximum for numeric columns.

`print()` shows the first ten rows with a header giving the simulator type and
the dimensions of the observation table.

```r
print(result)
#> <simulab_sim:ttest> 80 rows x 3 columns
#>    id group    outcome
#> 1   1     A -0.6264538
#> 2   2     A  0.1836433
#> 3   3     A -0.8356286
#> ... 70 more rows
```

Results are ordinary data frames, so no accessor is needed to analyse them.
The `what` argument exists to reach the generating parameters, which are the
part a simulation study needs and a plain data frame cannot carry.

## Reproducibility

Every simulator accepts a `seed` argument. Passing a seed makes the result
reproducible. It also leaves the calling session's random-number state
unchanged, so a seeded simulator does not advance the stream that surrounds
it.

```r
set.seed(99)
before <- .Random.seed
a <- simulate_ttest(10, 10, 0, 1, seed = 7)
after <- .Random.seed
b <- simulate_ttest(10, 10, 0, 1, seed = 7)

identical(as.data.frame(a), as.data.frame(b))
#> [1] TRUE
identical(before, after)
#> [1] TRUE
```

The behaviour is implemented by saving `.Random.seed`, calling `set.seed()`,
generating the data, and restoring the saved state on exit. Sixty-four
exported functions accept a `seed` argument. Both properties were checked
directly on 33 simulators spanning every family.

## Declarative studies

`define_variable()` records one variable of a data-generating process. It
takes a name, a `formula` giving the mean or linear predictor, a `variance`,
a `distribution`, and a `link`. It returns a one-row specification. The
formula is R source text and may refer to variables defined earlier in the
same specification.

`define_variables()` collects several such definitions into one specification.
`simulate_study()` takes a sample size and a specification and generates the
variables in the order they were defined.

```r
specification <- define_variables(
  define_variable("baseline", formula = "0", variance = "1", distribution = "normal"),
  define_variable("treatment", formula = "0.5", distribution = "binary"),
  define_variable("outcome", formula = "0.4 * baseline + 0.8 * treatment",
                  variance = "1", distribution = "normal")
)
specification
#>    variable distribution                          formula variance     link
#> 1  baseline       normal                                0        1 identity
#> 2 treatment       binary                              0.5        0 identity
#> 3   outcome       normal 0.4 * baseline + 0.8 * treatment        1 identity

simulate_study(500, specification, seed = 42)
```

Seventeen distributions are available: `beta`, `binary`, `binomial`,
`categorical`, `cluster_size`, `custom`, `deterministic`, `exponential`,
`gamma`, `mixture`, `negative_binomial`, `normal`, `no_zero_poisson`,
`poisson`, `treatment`, `uniform` and `uniform_integer`.

`augment_study()` adds variables to data that already exists. It takes a data
frame and a specification, and returns the input with the new variables
appended. Formulas may refer to columns already present.

`update_definition()` replaces one field of an existing specification.
`repeat_variables()` generates a numbered family of variables from a single
template. `read_definitions()` reads a specification from a CSV file with
columns `variable`, `distribution`, `formula`, `variance` and `link`.

`apply_conditions()` applies different generating rules to different subsets of
the same data. It takes a data frame and rules built by `define_condition()`,
where each rule pairs a logical expression with a generating formula.

## Simulator catalogue

`list_simulators()` returns the canonical simulators as a data frame with
columns `simulator`, `family` and `primary_shape`. `simulate_data()` dispatches
on the `simulator` name and passes its remaining arguments through.

| Family | Simulators |
|---|---|
| general | `study`, `correlation`, `copula`, `ordinal` |
| statistical | `ttest`, `anova`, `regression`, `clusters`, `prediction` |
| latent | `lpa`, `lca`, `factors` |
| measurement | `irt` |
| longitudinal | `multilevel`, `growth`, `longitudinal` |
| sequence | `markov`, `sequence_clusters`, `hmm`, `group_sequences`, `group_tna`, `event_log` |
| survival | `survival`, `proportional_survival` |
| empirical | `synthetic`, `density` |
| functional | `spline` |
| network | `network`, `edge_list`, `temporal_network`, `network_matrix`, `bipartite_network`, `multiplex_network`, `tna_network` |

The `primary_shape` column records the layout of the observation table. Most
simulators return one row per unit. Sequence simulators return one row per unit
per position. Network simulators return one row per edge, except
`network_matrix`, which returns one row per matrix cell.

## What each simulator exposes as truth

The tables attached to a result differ by simulator, because different designs
have different parameters. The table below lists the observation columns and
the component tables for a representative set.

| Simulator | Observation columns | Component tables |
|---|---|---|
| `simulate_ttest` | `id`, `group`, `outcome` | `parameters`, `effects` |
| `simulate_regression` | `id`, `x1`, `outcome` | `coefficients`, `effects`, `predictor_correlation` |
| `simulate_multilevel` | `id`, `cluster`, `x1`, `outcome` | `fixed_effects`, `variance_components`, `random_effects` |
| `simulate_irt` | `id`, `item_1`, `item_2` | `parameters`, `abilities` |
| `simulate_lca` | `id`, `latent_class`, `item_1`, `item_2` | `parameters` |
| `simulate_markov` | `id`, `period`, `state` | `transitions`, `initial_probabilities`, `wide` |
| `simulate_sequences` | `id`, `period`, `state` | `transitions`, `initial_probabilities`, `wide`, `settings` |
| `simulate_network` | `from`, `to`, `weight` | `nodes`, `adjacency`, `settings` |
| `simulate_temporal_network` | `from`, `to`, `onset`, `terminus`, `weight`, `censored` | `events`, `snapshots`, `nodes`, `settings` |
| `simulate_copula` | `id`, `a`, `b` | `definitions`, `latent_correlation` |

Alternate views of one result are component tables rather than separate
functions. `simulate_markov()` returns long-form observations and carries the
wide form as a component. `simulate_network()` returns an edge list and carries
the adjacency matrix as a component. `simulate_temporal_network()` returns
spells and carries both the event stream and per-period snapshots.

## Parameter recovery

The generating parameters can be recovered from the simulated data by fitting
the corresponding model. The script below runs seven such checks and reports
the largest absolute discrepancy for each. It uses only base R and the
package itself.

```r
library(simulab)

# Linear regression coefficients, recovered by lm() on the simulated data.
d <- simulate_regression(50000, c("(Intercept)" = 1, x1 = 0.5, x2 = -0.3), seed = 1)
coef(lm(outcome ~ x1 + x2, data = as.data.frame(d)))

# Markov transition matrix, recovered by counting observed transitions.
tm <- matrix(c(0.7, 0.3, 0.4, 0.6), 2, byrow = TRUE)
summarize_transitions(simulate_markov(4000, tm, 60, states = c("A", "B"), seed = 5),
                      normalize = TRUE)
```

The full script is shipped as `inst/recovery-check.R` and is run with
`Rscript inst/recovery-check.R`. It reports:

| Quantity | True value | Recovered | Max abs. difference |
|---|---|---|---|
| Regression coefficients | 1, 0.5, -0.3 | 1.004, 0.493, -0.299 | 0.0068 |
| IRT 2PL marginal item probability | 0.697, 0.500, 0.331 | 0.696, 0.498, 0.333 | 0.0021 |
| Markov transition matrix | 0.7, 0.3, 0.4, 0.6 | 0.701, 0.299, 0.399, 0.601 | 0.0012 |
| HMM emission matrix | 0.9, 0.1, 0.2, 0.8 | 0.900, 0.100, 0.199, 0.801 | 0.0007 |
| VAR(1) transition matrix | 0.5, 0.1, 0.0, 0.4 | 0.502, 0.096, -0.004, 0.402 | 0.0038 |
| Weibull AFT log hazard ratio | -0.467 | -0.467 | 0.0007 |
| CFA loading-implied covariance | 0.56, 0.48, 0.42 and 9 zeros | 0.570, 0.484, 0.422 and 9 near-zeros | 0.0097 |

The IRT row compares the simulated item means against the marginal
probabilities obtained by integrating the two-parameter logistic curve over a
standard normal ability distribution, rather than against a rule of thumb. The
Weibull row uses the accelerated-failure-time identity, under which a
proportional-hazards coefficient of 0.7 with shape 1.5 appears as a slope of
-0.7 / 1.5 on the log-time scale. Each discrepancy is within Monte Carlo error
for the sample size used.

## Correlated data

`simulate_correlated()` draws multivariate normal variables. It takes a sample
size, means, standard deviations, and a correlation specification, and returns
one row per observation with the correlation and covariance matrices as
component tables.

The correlation is specified in one of three ways. `rho` with
`structure = "exchangeable"` gives a constant off-diagonal correlation. `rho`
with `structure = "ar1"` gives a first-order autoregressive pattern. A
`correlation` matrix gives an arbitrary target.

Leaving `structure` unset selects `"exchangeable"` when a non-zero `rho` is
supplied and `"custom"` when a `correlation` matrix is supplied. Requesting
`structure = "independent"` together with a non-zero `rho` raises an error of
class `simulab_contradictory_structure` rather than returning uncorrelated
data.

`simulate_copula()` draws correlated variables with non-normal margins. It
takes a sample size, a specification of the marginal distributions, and a
latent correlation. The correlation applies to the latent normal variables,
so the observed rank correlation is close to the requested value while the
observed product-moment correlation is attenuated by the marginal transforms.

`simulate_ordinal()` draws correlated ordinal variables by thresholding latent
normal variables. `rho` again describes the latent correlation. A requested
latent correlation of 0.4 across three ordered categories produces an observed
Pearson correlation near 0.32 on the category codes, which is the expected
polychoric attenuation.

`correlation_structure()` and `block_correlation()` build correlation matrices
without simulating data. `block_correlation()` constructs matrices with
separate within-period, between-period and within-individual blocks, with
optional decay.

## Missingness

`inject_missingness()` sets values to `NA` under a named mechanism. It takes a
data frame, a `mechanism` of `"MCAR"`, `"MAR"` or `"MNAR"`, a target
`proportion`, and the variables to affect. MAR missingness additionally takes
an observed `predictor`.

The target proportion is calibrated rather than approximated. The function
solves for the multiplier that makes the expected missing fraction equal the
requested value, and the solve is checked for convergence before its result is
used.

`define_missingness()` and `missingness_matrix()` separate the two steps for
longitudinal data. `missingness_matrix()` returns a logical mask with the same
shape as the input. `observed_data()` applies a mask, holding identifier
columns exempt. The `monotone` argument makes a unit that becomes missing stay
missing at later periods.

## Treatment assignment and design structure

`assign_treatment()` allocates units to groups. It takes a data frame, a number
of groups or their labels, optional `strata`, and optional allocation `ratios`.
With `balanced = TRUE` the allocation is exactly balanced within each stratum.

`observe_treatment()` generates a non-randomised exposure from covariates. It
takes probability formulas and a link, and returns the input with an exposure
variable appended.

`assign_stepped_wedge()` builds a stepped-wedge trial. It takes long-form data
with cluster and period columns, a number of waves, and a wave length, and
returns the input with treatment and transition indicators.

`expand_clusters()` turns cluster-level data into unit-level data.
`expand_periods()` turns unit-level data into long form, with either common
period values or irregular gamma-spaced intervals. `factorial_design()` builds
a factorial grid from a named vector of level counts. `encode_factors()`
applies factor, dummy or effect coding.

## Survival and competing risks

`define_survival()` records one event-time process. It takes an event name, a
log-hazard `formula`, a Weibull `shape`, and an optional `transition` time at
which the specification takes effect. Splitting a process across two
definitions with different transition times gives a piecewise hazard.

`simulate_survival()` and `augment_survival()` generate event times from such
definitions. `combine_competing_risks()` reduces several event-time variables
to an observed time, an integer event code, and an event type.

`simulate_proportional_survival()` generates times from a proportional-hazards
model directly. It takes named covariate coefficients, a baseline of
`"weibull"`, `"exponential"` or `"gompertz"`, a shape, and a target censoring
proportion. The censoring rate is solved for rather than fixed, so the realised
proportion matches the request.

`calibrate_survival()` goes the other way. It takes observed times and survival
probabilities and returns the Weibull formula and shape that reproduce them,
with the optimiser's convergence code and the root mean squared error in the
result.

## Latent variable and measurement models

`simulate_lpa()` draws continuous indicators from a mixture of normals. It
takes a `means` matrix with one row per profile and one column per indicator,
standard deviations in the same layout or a scalar, and mixing `proportions`.

`simulate_lca()` draws categorical indicators from a latent class model. It
takes a `probabilities` array with dimensions class, indicator and category.
The array is the least obvious input in the package, so its example builds one
explicitly.

`simulate_factors()` draws indicators from a confirmatory factor model. It
takes a `loadings` matrix with one row per item and one column per factor, plus
optional uniquenesses and a factor correlation matrix.

`simulate_irt()` draws item responses from an item-response model. It takes
`discrimination` and `difficulty` vectors, a `model` of `"rasch"`, `"2pl"` or
`"3pl"`, and a `guessing` parameter for the three-parameter form. Multiple
ability dimensions are available through `dimensions` and
`ability_correlation`.

## Longitudinal and multilevel designs

`simulate_multilevel()` draws data from a random-intercept and random-slope
model. It takes a number of clusters, a cluster size, a fixed intercept, named
fixed `slopes`, and standard deviations for the random intercept, the random
slope and the residual. The realised intraclass correlation matches the value
implied by the variance components.

`simulate_growth()` draws latent growth curves. It takes measurement `times`, a
mean intercept and slope, an optional quadratic term, random-effect standard
deviations, and a residual standard deviation.

`simulate_longitudinal()` draws a multivariate first-order vector
autoregressive process. It takes a lag-one `transition` matrix, an innovation
covariance, an initial covariance, and a between-unit covariance of person
means. `beeps_per_day` resets temporal carryover at each day boundary, which
matches experience-sampling designs. `burn_in` discards warm-up occasions.

## Sequences and transition networks

`simulate_markov()` draws state sequences from a first-order Markov chain. It
takes a `transition` matrix or a tidy table with `from`, `to` and `probability`
columns, a `chain_length`, and state labels. `initial` accepts either a named
starting state or a vector of starting probabilities. `trim_state` truncates
each sequence at the first occurrence of an absorbing state.

`simulate_sequences()` generates sequences with additional structure. Without a
supplied transition matrix it draws one from a Dirichlet distribution, with
`concentration` controlling how uneven the rows are. `stable_transitions` names
preferred `from` and `to` pairs that are followed with probability
`stability_probability`. `instability` perturbs the remaining transitions by
one of `"random_jump"`, `"perturb"` or `"unlikely_jump"`. `missing_tail`
removes a random number of trailing positions from each sequence.

`simulate_hmm()` draws observed symbols from a hidden Markov model, returning
both the latent state and the observation for each position.
`simulate_sequence_clusters()` draws sequences from a mixture of transition
matrices and records the generating cluster.

`summarize_transitions()` counts observed transitions in long-form sequence
data. It returns one row per ordered state pair with a count and, when
`normalize = TRUE`, a row-normalised probability.

`fit_tna()` estimates a transition network from sequence data using the `tna`
package. It takes sequence data and a `model` of `"tna"`, `"ftna"`, `"ctna"` or
`"atna"`, and returns a tidy edge list. `as_tna_model()` converts the result to
a native `tna` object when downstream plotting or inference requires one.

`bootstrap_tna()`, `sample_tna()`, `cross_validate_tna()`,
`assess_tna_reliability()` and `compare_tna_models()` are simulation workflows
built on the same estimators. `evaluate_tna_estimation()` repeatedly generates
sequences from a known transition system and reports how well each estimator
recovers it.

`learning_states()` and `sample_learning_states()` supply labelled state spaces
in eight categories, including metacognitive, cognitive, behavioural, social,
motivational, affective, group-regulation and learning-management-system
states. `simulate_event_log()` generates educational event logs with groups,
actors, courses, timestamps and achievement levels.

## Networks

`simulate_network()` generates a graph from one of seven models: `"bernoulli"`,
`"barabasi_albert"`, `"small_world"`, `"block"`, `"regular"`, `"geometric"` and
`"forest_fire"`. It returns a tidy edge list with `from`, `to` and `weight`
columns, and carries the node table and the adjacency matrix as components.

Five further verbs cover the network layouts that a tidy edge list alone does
not express. `simulate_edge_list()` generates plain edge lists with optional
node types and edge classes. `simulate_temporal_network()` generates activity
spells with formation and dissolution probabilities, and carries an event
stream and per-period snapshots. `simulate_network_matrix()` generates
adjacency, transition, frequency or co-occurrence matrices.
`simulate_bipartite_network()` generates actor-event incidence.
`simulate_multiplex_network()` generates several layers over a shared node set.

`network_centrality()` computes degree, strength, betweenness, closeness,
eigenvector and PageRank centralities. `compare_networks()` and
`compare_centralities()` compare two graphs. `evaluate_edge_recovery()` scores
an estimated edge set against a known one. `as_igraph()` converts a result to
an `igraph` graph.

## Calibration

`calibrate_distribution()` converts a mean and dispersion into the shape
parameters of a beta, gamma or negative binomial distribution.

`calibrate_icc()` returns the random-effect variance that produces a target
intraclass correlation, for normal, binary, Poisson, gamma and negative
binomial outcomes.

`calibrate_logistic()` returns logistic coefficients that produce a target
population prevalence. It optionally scales the coefficients to a target area
under the ROC curve, or solves for a treatment coefficient that produces a
target risk ratio or risk difference.

Every calibration is solved by root finding, and every solve is checked. A
target that no coefficient can produce raises an error of class
`simulab_no_solution`. A search that does not reach its tolerance raises
`simulab_no_convergence`. Neither returns an approximate answer silently.

## Scenario studies, batches and export

`scenario_grid()` builds a scenario table from named vectors, with
replications. `simulate_scenarios()` runs one simulator across every row of
such a table, giving each row a deterministic seed offset, and returns the
pooled results with a scenario identifier.

`parameter_grid()` builds parameter designs by full factorial expansion, random
sampling or Latin hypercube sampling. Its own arguments are named `n`, `method`
and `seed`, so a grid parameter cannot use those three names.

`apply_batch()` applies a function across a named list of inputs and stacks the
results with a batch identifier. `simulate_sequence_batches()`,
`simulate_network_batches()` and `simulate_tna_batches()` repeat a simulator a
fixed number of times with independent seeds.

`summarize_simulations()` aggregates simulated variables by group.
`validate_recovery()` compares estimated parameters against known truth and
reports bias, absolute and relative error, and whether each parameter falls
within a tolerance. `write_simulation()` writes a result or one of its
component tables to CSV or RDS.

## Input validation

Argument checks state the contract that was broken and name the argument.

```r
simulate_clusters(n = 10, centers = list(c(0, 0), c(4, 4)))
#> Error: `centers` must be a matrix, with at least 2 rows

simulate_regression(n = 10, coefficients = c(1, 0.5))
#> Error: `coefficients` must be a named numeric vector, with at least one element
```

Conditions that a caller might reasonably catch carry a class:
`simulab_contradictory_structure` for a correlation request that cannot be
satisfied, `simulab_no_solution` and `simulab_no_convergence` for calibration
failures, and `simulab_bad_definition_file`, `simulab_duplicate_variable`,
`simulab_unknown_distribution` and `simulab_unknown_link` for malformed
specification files.

## Relationship to other packages

simulab supersedes Saqrlab and continues its version numbering. Saqrlab is
unchanged, because the seeded output of its `simulate_data()` is a fixture
contract for other projects. `SAQRLAB_COVERAGE.md` maps each of Saqrlab's 87
exported names to its resolution in simulab.

simstudy is an equivalence oracle rather than a dependency. Two tests assert
that simulab reproduces simstudy 0.9.2 values exactly under the same seed, for
normal, binary and gamma declarative generation and for the beta, gamma and
negative binomial parameter conversions. Both tests skip when simstudy is not
installed, which is the case in the environment where the figures reported
below were measured.
`FEATURE_COVERAGE.md` maps each simstudy capability to its simulab verb.

The `tna` package supplies the transition-network estimators. simulab keeps
tidy edge lists as its result contract and provides `as_tna_model()` as the
explicit bridge to native `tna` objects.

## Package status

Version 0.4.0 is the first release under the simulab name. The version
continues the line of Saqrlab (0.4.1), which has never been on CRAN. The
package is a CRAN release candidate and a new submission.

The test suite contains 341 assertions across 21 files and covers 90.79% of
package lines, measured with `covr`. Two assertions skip when simstudy is
absent. Tests include statistical calibration checks, seeded regression checks,
recovery checks for transition networks and grouped models, error-path checks
by condition class, and equivalence tests against simstudy.

All 121 exported functions carry runnable examples, which `R CMD check`
executes. `R CMD check --as-cran` reports one note, the standard note for a
first submission, on R 4.5.2 under macOS on arm64. Windows and Linux checks are
still outstanding.

## Function reference

Specification and study generation: `define_variable()`, `define_variables()`,
`update_definition()`, `repeat_variables()`, `read_definitions()`,
`simulate_study()`, `augment_study()`, `define_condition()`,
`define_conditions()`, `apply_conditions()`.

Correlated data: `simulate_correlated()`, `simulate_correlation()`,
`simulate_copula()`, `augment_correlated()`, `simulate_ordinal()`,
`correlation_structure()`, `block_correlation()`.

Statistical designs: `simulate_ttest()`, `simulate_anova()`,
`simulate_regression()`, `simulate_clusters()`, `simulate_prediction()`.

Latent and measurement models: `simulate_lpa()`, `simulate_lca()`,
`simulate_factors()`, `simulate_irt()`, `simulate_hmm()`.

Longitudinal designs: `simulate_multilevel()`, `simulate_growth()`,
`simulate_longitudinal()`.

Survival: `define_survival()`, `define_survivals()`, `simulate_survival()`,
`augment_survival()`, `combine_competing_risks()`,
`simulate_proportional_survival()`, `calibrate_survival()`,
`survival_curve()`.

Missingness: `define_missingness()`, `define_missingnesses()`,
`missingness_matrix()`, `observed_data()`, `inject_missingness()`.

Treatment and design structure: `assign_treatment()`, `observe_treatment()`,
`assign_stepped_wedge()`, `expand_clusters()`, `expand_periods()`,
`factorial_design()`, `augment_factorial()`, `encode_factors()`,
`merge_studies()`, `select_variables()`.

Sequences: `simulate_markov()`, `augment_markov()`, `simulate_sequences()`,
`simulate_sequence_clusters()`, `simulate_group_sequences()`,
`simulate_until_event()`, `trim_events()`, `summarize_transitions()`,
`encode_sequences()`, `generate_transition_system()`, `simulate_event_log()`,
`learning_states()`, `learning_state_categories()`,
`sample_learning_states()`.

Transition networks: `fit_tna()`, `as_tna_model()`, `simulate_group_tna()`,
`simulate_tna_network()`, `compare_tna_models()`, `bootstrap_tna()`,
`sample_tna()`, `cross_validate_tna()`, `assess_tna_reliability()`,
`evaluate_tna_estimation()`, `fit_tna_batch()`, `simulate_tna_batches()`.

Networks: `simulate_network()`, `simulate_edge_list()`,
`simulate_temporal_network()`, `simulate_network_matrix()`,
`simulate_bipartite_network()`, `simulate_multiplex_network()`,
`simulate_network_batches()`, `network_centrality()`, `compare_networks()`,
`compare_centralities()`, `evaluate_edge_recovery()`, `summarize_networks()`,
`as_igraph()`.

Empirical and functional: `simulate_synthetic()`, `augment_synthetic()`,
`simulate_density()`, `augment_density()`, `simulate_spline()`,
`spline_basis()`, `spline_curves()`, `linear_formula()`, `mixture_formula()`,
`categorical_formula()`.

Calibration: `calibrate_distribution()`, `calibrate_icc()`,
`calibrate_logistic()`.

Workflows: `scenario_grid()`, `simulate_scenarios()`, `parameter_grid()`,
`apply_batch()`, `simulate_sequence_batches()`, `summarize_simulations()`,
`validate_recovery()`, `write_simulation()`, `simulation_scenarios()`,
`run_simulation_scenario()`, `list_simulators()`, `simulate_data()`,
`global_names()`, `global_name_regions()`, `sample_global_names()`.

Result methods: `components()`, `as.data.frame()`, `print()`, `summary()`.

## License

MIT. See `LICENSE`.

## Citation

Saqr, M. (2026). simulab: Unified Simulation of Statistical and Study Data.
R package version 0.4.0. https://github.com/mohsaqr/simulab
