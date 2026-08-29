# simulab Feature Coverage

This matrix defines the required scope. A row is complete only when the public
verb, validation tests, statistical calibration test, and documentation exist.

| Capability | simstudy 0.9.2 reference | simulab API | Status |
|---|---|---|---|
| Declarative variable definitions | `defData`, `defDataAdd`, `defRepeat`, `defRepeatAdd`, `defRead*`, `updateDef*` | `define_variable()`, `define_variables()`, `repeat_variables()`, `read_definitions()`, `update_definition()` | Complete |
| Generate or augment study data | `genData`, `addColumns`, `addCondition`, `delColumns`, `mergeData` | `simulate_study()`, `augment_study()`, `apply_conditions()`, `select_variables()`, `merge_studies()` | Complete |
| Core distributions | distribution definitions | `simulate_study()` distributions | Complete |
| Correlated normal data | `genCorData`, `addCorData` | `simulate_correlated()`, `augment_correlated()` | Complete |
| Correlated general data | `genCorFlex`, `addCorFlex`, `genCorGen`, `addCorGen` | `simulate_copula()`, `augment_correlated()` | Complete |
| Correlation structures | `genCorMat`, `blockExchangeMat`, `blockDecayMat` | `correlation_structure()`, `block_correlation()` | Complete |
| Ordinal/categorical correlation | `genOrdCat`, `genCorOrdCat` | `simulate_ordinal()` | Complete |
| Clusters and periods | `genCluster`, `addPeriods` | `expand_clusters()`, `expand_periods()` | Complete |
| Factorial designs and encoding | `genMultiFac`, `addMultiFac`, `genFactor`, `genDummy` | `factorial_design()`, `augment_factorial()`, `encode_factors()` | Complete |
| Markov chains and event trimming | `genMarkov`, `addMarkov`, `genNthEvent`, `trimData` | `simulate_markov()`, `augment_markov()`, `simulate_until_event()`, `trim_events()` | Complete |
| Missing-data mechanisms | `defMiss`, `genMiss`, `genObs` | `define_missingness()`, `missingness_matrix()`, `observed_data()`, `inject_missingness()` | Complete |
| Survival and competing risks | `defSurv`, `genSurv`, `addCompRisk` | `define_survival()`, `simulate_survival()`, `combine_competing_risks()` | Complete |
| Treatment assignment/observation | `trtAssign`, `trtObserve` | `assign_treatment()`, `observe_treatment()` | Complete |
| Stepped-wedge trials | `trtStepWedge` | `assign_stepped_wedge()` | Complete |
| Synthetic and empirical-density data | `genSynthetic`, `addSynthetic`, `genDataDensity`, `addDataDensity` | `simulate_synthetic()`, `augment_synthetic()`, `simulate_density()`, `augment_density()` | Complete |
| Formula helpers | `genFormula`, `genMixFormula`, `genCatFormula`, `catProbs` | `linear_formula()`, `mixture_formula()`, `categorical_formula()` | Complete |
| Splines | `genSpline`, `viewBasis`, `viewSplines` | `simulate_spline()`, `spline_basis()`, `spline_curves()` | Complete |
| Parameter calibration | `betaGetShapes`, `gammaGetShapeRate`, `negbinomGetSizeProb`, `iccRE`, `logisticCoefs`, `survGetParams`, `survParamPlot` | `calibrate_distribution()`, `calibrate_icc()`, `calibrate_logistic()`, `calibrate_survival()`, `survival_curve()` | Complete |
| Scenario expansion and execution | `grouped`, `scenario_list` | `scenario_grid()`, `simulate_scenarios()` | Complete |
| Saqrlab statistical designs | explicit statistical simulators | `simulate_ttest()`, `simulate_anova()`, `simulate_regression()`, `simulate_correlation()`, `simulate_clusters()` | Complete |
| Saqrlab latent models | LPA, LCA, FA, sequence clusters | `simulate_lpa()`, `simulate_lca()`, `simulate_factors()`, `simulate_sequence_clusters()` | Complete |
| Saqrlab multilevel/longitudinal | random-intercept/slope MLM, growth, VAR/ESM, between-person effects, day/beep structure | `simulate_multilevel()`, `simulate_growth()`, `simulate_longitudinal()` | Complete |
| Saqrlab IRT and HMM | Rasch, 2PL, 3PL, graded/multidimensional IRT and HMM | `simulate_irt()`, `simulate_hmm()` | Complete |
| Prediction and standalone PH survival | continuous/categorical prediction and calibrated censoring | `simulate_prediction()`, `simulate_proportional_survival()` | Complete |
| Basic and advanced sequences | automatic probabilities, learning states, stable transitions, perturbation, unlikely jumps, trailing missingness | `simulate_sequences()`, `learning_states()`, `sample_learning_states()` | Complete |
| Group and clustered sequences | group/actor generation and sequence mixtures | `simulate_group_sequences()`, `simulate_sequence_clusters()` | Complete |
| Educational logs and one-hot encoding | groups, actors, courses, achievement, timestamps, wide/one-hot views | `simulate_event_log()`, `encode_sequences()` | Complete |
| TNA model families | TNA, FTNA, CTNA, and ATNA | `fit_tna()`, `as_tna_model()`, `compare_tna_models()` | Complete |
| Grouped TNA models | group TNA, group FTNA, group CTNA, and group ATNA | `fit_tna(group = ...)`, `simulate_group_tna()` | Complete |
| Repeated sequence and TNA generation | multiple datasets and fitted networks | `simulate_sequence_batches()`, `simulate_tna_batches()` | Complete |
| TNA assessment workflows | bootstrap, sampling, cross-validation, split-half reliability, truth recovery | `bootstrap_tna()`, `sample_tna()`, `cross_validate_tna()`, `assess_tna_reliability()`, `evaluate_tna_estimation()` | Complete |
| TNA/network structures | transition, edge, adjacency, grouped/hierarchical node structures | `summarize_transitions()`, `simulate_network()`, `simulate_tna_network()` | Complete |
| Graph-model and network analysis | Bernoulli, BA, small-world, block, regular, geometric, forest-fire; conversion, centrality, comparison | `simulate_network()`, `as_igraph()`, `network_centrality()`, `compare_networks()` | Complete |
| Explicit network formats | ordinary edge lists, temporal spells/events/snapshots, adjacency/transition/frequency/co-occurrence matrices, bipartite and multiplex networks | `simulate_edge_list()`, `simulate_temporal_network()`, `simulate_network_matrix()`, `simulate_bipartite_network()`, `simulate_multiplex_network()` | Complete |
| Batch, parameter-grid, scenario, and export workflows | repeated application, full/random/LHS grids, scenarios, summaries, CSV/RDS | `apply_batch()`, `parameter_grid()`, `simulate_scenarios()`, `summarize_simulations()`, `write_simulation()` | Complete |
| Recovery assessment | parameter and edge recovery | `validate_recovery()`, `evaluate_edge_recovery()` | Complete |

“Complete” means the capability is implemented through the canonical API,
documented with a runnable example, and covered by a functional, calibration,
seeded-regression, or equivalence test.

Two rows previously carried “Complete” without meeting that bar. As of
2026-08-29 both do: `simulate_markov()` had no test of any kind (see
`tests/testthat/test-markov.R`), and `read_definitions()` had neither a test
nor a working round trip into `simulate_study()` (see
`tests/testthat/test-read-definitions.R`). It does not mean that legacy function names or legacy nested
return objects are reproduced. Those are intentionally consolidated.

TNA estimation uses the suggested `tna` package (version 1.2.3 or newer).
`fit_tna()` keeps the standard simulab result as a tidy edge list;
`as_tna_model()` provides the native model only when downstream TNA plotting or
inference explicitly requires it.

The separate `SAQRLAB_COVERAGE.md` audit maps every one of Saqrlab 0.4.0's
87 exported names, including aliases and presentation-only functions, to its
canonical resolution.
