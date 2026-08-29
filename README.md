# simulab

`simulab` is a unified R package for generating study data with known ground
truth. It combines the documented capability surface of simstudy 0.9.2 with
the specialized statistical, latent, longitudinal, sequence, and network
capabilities from Saqrlab, while replacing their different return types with
one contract.

The package is an original implementation. `simstudy` is used only as an
optional equivalence oracle in tests and is not a runtime dependency.

## One result contract

Every simulator returns a base `data.frame` that also inherits from
`simulab_sim`:

```r
result <- simulate_ttest(
  n_a = 100,
  n_b = 100,
  mean_a = 0,
  mean_b = 0.5,
  seed = 42
)

head(result)
components(result)
as.data.frame(result, what = "parameters")
as.data.frame(result, what = "effects")
```

Primary observations are always directly usable as data. Correlation matrices,
parameters, latent scores, allocation summaries, transition systems, and other
ground truth are exposed as tidy secondary tables through the same accessor.

## Declarative studies

Definitions are explicit and evaluated in order:

```r
specification <- define_variables(
  define_variable("age", 40, 100, "normal"),
  define_variable("treated", 0.5, distribution = "binary"),
  define_variable("outcome", "10 + 0.2 * age + 2 * treated", 4, "normal")
)

study <- simulate_study(1000, specification, seed = 42)
```

Supported marginals include normal, beta, binary, binomial, categorical,
Poisson, zero-truncated Poisson, negative binomial, gamma, exponential,
uniform, integer uniform, deterministic, mixture, treatment, cluster-size, and
custom generators. The same definitions power Gaussian-copula simulation.

## Canonical simulator catalogue

```r
list_simulators()
simulate_data(
  "growth",
  n = 200,
  times = 0:5,
  intercept = 10,
  slope = 0.8,
  seed = 42
)
```

Direct verbs are preferred for normal use because their signatures are
discoverable. `simulate_data()` is a single dispatcher for programmatic work.
The catalogue covers:

- statistical designs: t test, ANOVA, correlation, regression, and clustering;
- latent and measurement models: LPA, LCA, factor analysis, and IRT;
- random-intercept/slope multilevel models, growth, and multivariate VAR/ESM
  processes with between-person and day/beep structure;
- Markov chains, sequence clusters, HMMs, educational event logs, one-hot
  encodings, and transition summaries;
- advanced stable/unstable sequences, categorized learning states, and grouped
  actor sequences;
- TNA, FTNA, CTNA, and ATNA models, including their grouped estimators;
- survival, competing risks, calibrated proportional survival, missingness,
  and treatment assignment;
- prediction with continuous/categorical effects, synthetic,
  empirical-density, spline, and seven graph-model families;
- repeated TNA datasets/networks, bootstrap, split-half reliability,
  cross-validation, estimation recovery, and network comparison.

## Network formats

Five explicit verbs cover the principal network representations without
changing the common result contract:

```r
edges <- simulate_edge_list(30, edges = 80, directed = FALSE, seed = 1)

temporal <- simulate_temporal_network(
  30, periods = 12,
  formation_probability = 0.08,
  dissolution_probability = 0.15,
  seed = 2
)
as.data.frame(temporal, what = "events")
as.data.frame(temporal, what = "snapshots")

transition <- simulate_network_matrix(
  8, type = "transition", probability = 0.3, seed = 3
)

bipartite <- simulate_bipartite_network(
  actors = 40, events = 10, edges = 100, seed = 4
)

multiplex <- simulate_multiplex_network(
  30, layers = c("advice", "collaboration", "friendship"),
  probability = c(0.05, 0.10, 0.15), seed = 5
)
```

Temporal results use spell rows (`from`, `to`, `onset`, `terminus`, `weight`,
`censored`) as primary data and expose event and snapshot edge lists as named
components. Network matrices support adjacency, transition, frequency, and
co-occurrence types while remaining tidy data frames.

## Scenario studies and reproducibility

```r
scenarios <- scenario_grid(
  mean_b = c(0, 0.25, 0.5),
  replications = 100
)

simulations <- simulate_scenarios(
  scenarios,
  simulator = "ttest",
  n_a = 50,
  n_b = 50,
  mean_a = 0,
  seed = 2026
)
```

Seeded functions restore the caller's random-number state. Scenario rows use
deterministic seed offsets, so a study can be reproduced without hidden global
RNG side effects.

## Capability correspondence

The full capability map is maintained in `FEATURE_COVERAGE.md`; the separate
`SAQRLAB_COVERAGE.md` audit resolves every one of Saqrlab 0.4.0's 87 exports.
Important consolidations include:

| Existing capability family | Canonical `simulab` interface |
|---|---|
| `defData*`, `genData`, `addColumns` | `define_variable()`, `simulate_study()`, `augment_study()` |
| `genCor*`, `addCor*`, ordinal correlation | `simulate_correlated()`, `simulate_copula()`, `simulate_ordinal()` |
| condition, missingness, treatment | `apply_conditions()`, `inject_missingness()`, `assign_treatment()` |
| clusters, periods, factorial designs | `expand_clusters()`, `expand_periods()`, `factorial_design()` |
| Markov/event utilities | `simulate_markov()`, `simulate_until_event()`, `trim_events()` |
| survival and competing risks | `simulate_survival()`, `combine_competing_risks()` |
| Saqrlab FA/LPA/LCA/IRT/HMM | `simulate_factors()`, `simulate_lpa()`, `simulate_lca()`, `simulate_irt()`, `simulate_hmm()` |
| Saqrlab sequence/TNA/network shapes | `simulate_sequences()`, `simulate_tna_batches()`, `fit_tna()`, `simulate_network()` |
| Saqrlab workflow/recovery functions | `parameter_grid()`, `bootstrap_tna()`, `assess_tna_reliability()`, `evaluate_tna_estimation()` |

## Sequences, TNA models, and groups

Sequence simulation supports supplied or automatically generated transition
systems, stable transitions, random jumps, probability perturbation, unlikely
jumps, and trailing missing positions:

```r
sequences <- simulate_sequences(
  n = 200,
  chain_length = 20,
  n_states = 6,
  state_categories = c("metacognitive", "cognitive"),
  instability = "perturb",
  seed = 42
)
```

All primary TNA estimators share one fitting verb:

```r
tna_edges <- fit_tna(sequences, model = "tna")
ftna_edges <- fit_tna(sequences, model = "ftna")
ctna_edges <- fit_tna(sequences, model = "ctna")
atna_edges <- fit_tna(sequences, model = "atna")

as.data.frame(tna_edges, what = "initial_probabilities")
native_tna <- as_tna_model(tna_edges)
```

Grouped actor sequences and grouped models are generated together when needed:

```r
grouped <- simulate_group_tna(
  groups = 4,
  actors = c(20, 25, 20, 30),
  chain_length = 15,
  n_states = 5,
  model = "tna",
  seed = 42
)

as.data.frame(grouped, what = "true_transitions")
as.data.frame(grouped, what = "estimated_edges")
as_tna_model(grouped, group = "Group 1")
```

`fit_tna(group = ...)` also supports grouped FTNA, CTNA, and ATNA. Native
objects are retained for interoperability, while public simulation results
remain tidy data frames.

Repeated fitted networks and their generated truth use one call:

```r
networks <- simulate_tna_batches(
  repetitions = 20,
  model = "tna",
  n = 200,
  chain_length = 25,
  n_states = 6,
  seed = 42
)

as.data.frame(networks, what = "true_transitions")
```

## Development status

Version 0.4.0 is the first release under the simulab name, continuing the
version line of its predecessor Saqrlab (0.4.1). It is a CRAN release
candidate and a new submission. The test suite includes
statistical calibration, seeded regression checks, TNA/group recovery checks,
error-path checks, and direct equivalence tests against simstudy 0.9.2 for core
distributions and parameter conversions.
