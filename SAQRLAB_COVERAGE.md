# Saqrlab API coverage

This audit maps every exported Saqrlab 0.4.0 name to the canonical
`simulab` API. “Consolidated” means the capability is present under a
smaller, regular verb set; it does not mean that the old alias is
exported. Plot-only wrappers are intentionally replaced by tidy result
tables and native `tna`/`igraph` objects rather than copied into the
simulation package.

| Saqrlab export | Canonical simulab API | Resolution |
|----|----|----|
| `GLOBAL_NAMES` | [`global_names()`](https://mohsaqr.github.io/simulab/reference/global_names.md) | Data object replaced by a filterable tidy catalogue. |
| `GROUP_REGULATION_ACTIONS` | `learning_states("group_regulation")` | Consolidated into the learning-state catalogue. |
| `LEARNING_STATES` | [`learning_states()`](https://mohsaqr.github.io/simulab/reference/learning_states.md) | Data object replaced by a filterable tidy catalogue. |
| `analyze_grid_results` | [`summarize_simulations()`](https://mohsaqr.github.io/simulab/reference/summarize_simulations.md) | Consolidated grid summaries use ordinary grouped tidy data. |
| `batch_apply` | [`apply_batch()`](https://mohsaqr.github.io/simulab/reference/apply_batch.md) | Canonical batch verb. |
| `batch_fit_models` | [`fit_tna_batch()`](https://mohsaqr.github.io/simulab/reference/fit_tna_batch.md) | Canonical batch TNA fitting. |
| `calculate_edge_recovery` | [`evaluate_edge_recovery()`](https://mohsaqr.github.io/simulab/reference/evaluate_edge_recovery.md) | Duplicate alias removed. |
| `compare_centralities` | [`compare_centralities()`](https://mohsaqr.github.io/simulab/reference/compare_centralities.md) | Direct coverage. |
| `compare_edge_recovery` | [`evaluate_edge_recovery()`](https://mohsaqr.github.io/simulab/reference/evaluate_edge_recovery.md) | Canonical recovery verb. |
| `compare_estimation` | [`evaluate_tna_estimation()`](https://mohsaqr.github.io/simulab/reference/evaluate_tna_estimation.md) | Repeated truth-versus-estimate experiment. |
| `compare_network_estimation` | [`evaluate_tna_estimation()`](https://mohsaqr.github.io/simulab/reference/evaluate_tna_estimation.md) | Duplicate estimation workflow consolidated. |
| `compare_networks` | [`compare_networks()`](https://mohsaqr.github.io/simulab/reference/compare_networks.md) | Direct coverage with Pearson, cosine, error, and overlap metrics. |
| `compare_reliability` | [`assess_tna_reliability()`](https://mohsaqr.github.io/simulab/reference/assess_tna_reliability.md) | Split-half reliability; condition grids compose with [`parameter_grid()`](https://mohsaqr.github.io/simulab/reference/parameter_grid.md). |
| `compare_tna_models` | [`compare_tna_models()`](https://mohsaqr.github.io/simulab/reference/compare_tna_models.md) | Direct coverage for TNA, FTNA, CTNA, and ATNA. |
| `create_param_grid` | [`parameter_grid()`](https://mohsaqr.github.io/simulab/reference/parameter_grid.md) | Duplicate alias removed. |
| `cross_validate_tna` | [`cross_validate_tna()`](https://mohsaqr.github.io/simulab/reference/cross_validate_tna.md) | Direct coverage. |
| `evaluate_bootstrap` | [`bootstrap_tna()`](https://mohsaqr.github.io/simulab/reference/bootstrap_tna.md) | Single canonical bootstrap workflow. |
| `export_simulation` | [`write_simulation()`](https://mohsaqr.github.io/simulab/reference/write_simulation.md) | Standard CSV/RDS export. |
| `fit_network_model` | [`fit_tna()`](https://mohsaqr.github.io/simulab/reference/fit_tna.md) + [`as_tna_model()`](https://mohsaqr.github.io/simulab/reference/as_tna_model.md) | Tidy fit with an explicit native-model bridge. |
| `generate_group_tna_networks` | [`simulate_tna_network()`](https://mohsaqr.github.io/simulab/reference/simulate_tna_network.md) | Group/type transition-network generator. |
| `generate_param_grid` | [`parameter_grid()`](https://mohsaqr.github.io/simulab/reference/parameter_grid.md) | Grid, random, and Latin-hypercube designs. |
| `generate_probabilities` | [`generate_transition_system()`](https://mohsaqr.github.io/simulab/reference/generate_transition_system.md) | Tidy transitions plus initial probabilities. |
| `generate_sequence_data` | [`simulate_sequence_batches()`](https://mohsaqr.github.io/simulab/reference/simulate_sequence_batches.md) | Repeated sequence-dataset generation. |
| `generate_tna_datasets` | [`simulate_sequence_batches()`](https://mohsaqr.github.io/simulab/reference/simulate_sequence_batches.md) | Duplicate generator alias removed. |
| `generate_tna_matrix` | [`simulate_tna_network()`](https://mohsaqr.github.io/simulab/reference/simulate_tna_network.md) | Transition table and adjacency component. |
| `generate_tna_networks` | [`simulate_tna_batches()`](https://mohsaqr.github.io/simulab/reference/simulate_tna_batches.md) | Repeated simulated and fitted TNA networks. |
| `get_global_names` | [`global_names()`](https://mohsaqr.github.io/simulab/reference/global_names.md) / [`sample_global_names()`](https://mohsaqr.github.io/simulab/reference/sample_global_names.md) | Listing and seeded sampling separated. |
| `get_learning_states` | [`learning_states()`](https://mohsaqr.github.io/simulab/reference/learning_states.md) / [`sample_learning_states()`](https://mohsaqr.github.io/simulab/reference/sample_learning_states.md) | Listing and seeded sampling separated. |
| `get_scenario` | [`simulation_scenarios()`](https://mohsaqr.github.io/simulab/reference/simulation_scenarios.md) | Scenario catalogue is a tidy table. |
| `inject_missingness` | [`inject_missingness()`](https://mohsaqr.github.io/simulab/reference/inject_missingness.md) | Direct coverage plus simstudy-style missingness definitions. |
| `list_learning_categories` | [`learning_state_categories()`](https://mohsaqr.github.io/simulab/reference/learning_state_categories.md) | Direct catalogue helper. |
| `list_name_regions` | [`global_name_regions()`](https://mohsaqr.github.io/simulab/reference/global_name_regions.md) | Direct catalogue helper. |
| `list_scenarios` | [`simulation_scenarios()`](https://mohsaqr.github.io/simulab/reference/simulation_scenarios.md) | Direct catalogue helper. |
| `list_simulators` | [`list_simulators()`](https://mohsaqr.github.io/simulab/reference/list_simulators.md) | Direct coverage with family filtering. |
| `plot_network_estimation` | [`evaluate_tna_estimation()`](https://mohsaqr.github.io/simulab/reference/evaluate_tna_estimation.md) output | Tidy metrics replace a fixed plotting wrapper. |
| `plot_sampling_distribution` | [`cross_validate_tna()`](https://mohsaqr.github.io/simulab/reference/cross_validate_tna.md) / [`bootstrap_tna()`](https://mohsaqr.github.io/simulab/reference/bootstrap_tna.md) output | Tidy distributions are ready for any plotting system. |
| `plot_tna_comparison` | [`as_tna_model()`](https://mohsaqr.github.io/simulab/reference/as_tna_model.md) + native [`plot()`](https://rdrr.io/r/graphics/plot.default.html) | Native `tna` plotting retained without proxy objects. |
| `run_bootstrap_iteration` | [`bootstrap_tna()`](https://mohsaqr.github.io/simulab/reference/bootstrap_tna.md) | Iterations are internal rows of one reproducible workflow. |
| `run_bootstrap_simulation` | [`bootstrap_tna()`](https://mohsaqr.github.io/simulab/reference/bootstrap_tna.md) | Duplicate bootstrap driver removed. |
| `run_grid_simulation` | [`parameter_grid()`](https://mohsaqr.github.io/simulab/reference/parameter_grid.md) + [`simulate_scenarios()`](https://mohsaqr.github.io/simulab/reference/simulate_scenarios.md) | Grid construction and execution are separate composable verbs. |
| `run_network_simulation` | [`evaluate_tna_estimation()`](https://mohsaqr.github.io/simulab/reference/evaluate_tna_estimation.md) | Canonical repeated network-recovery experiment. |
| `run_sampling_analysis` | [`sample_tna()`](https://mohsaqr.github.io/simulab/reference/sample_tna.md) / [`cross_validate_tna()`](https://mohsaqr.github.io/simulab/reference/cross_validate_tna.md) | Sampling and evaluation are explicit. |
| `run_scenario` | [`run_simulation_scenario()`](https://mohsaqr.github.io/simulab/reference/run_simulation_scenario.md) | Canonical scenario runner. |
| `sample_tna` | [`sample_tna()`](https://mohsaqr.github.io/simulab/reference/sample_tna.md) | Direct coverage. |
| `saqr_sim` | `simulab_sim` results | Constructors are internal; every simulator returns the common class. |
| `select_states` | [`sample_learning_states()`](https://mohsaqr.github.io/simulab/reference/sample_learning_states.md) | Seeded state selection. |
| `simulate` | [`simulate_data()`](https://mohsaqr.github.io/simulab/reference/simulate_data.md) | One discoverable dispatcher; direct verbs remain preferred. |
| `simulate_anova` | [`simulate_anova()`](https://mohsaqr.github.io/simulab/reference/simulate_anova.md) | Direct coverage. |
| `simulate_clusters` | [`simulate_clusters()`](https://mohsaqr.github.io/simulab/reference/simulate_clusters.md) | Direct coverage. |
| `simulate_correlation` | [`simulate_correlation()`](https://mohsaqr.github.io/simulab/reference/simulate_correlation.md) | Direct coverage. |
| `simulate_data` | [`simulate_data()`](https://mohsaqr.github.io/simulab/reference/simulate_data.md) | Direct unified dispatcher. |
| `simulate_edge_list` | [`simulate_edge_list()`](https://mohsaqr.github.io/simulab/reference/simulate_edge_list.md) | Direct canonical tidy edge-list generator. |
| `simulate_fa` | [`simulate_factors()`](https://mohsaqr.github.io/simulab/reference/simulate_factors.md) | Canonical factor-model verb. |
| `simulate_group_tna_networks` | [`simulate_tna_network()`](https://mohsaqr.github.io/simulab/reference/simulate_tna_network.md) | Group/type network generation with tidy node metadata. |
| `simulate_growth` | [`simulate_growth()`](https://mohsaqr.github.io/simulab/reference/simulate_growth.md) | Direct coverage. |
| `simulate_hmm` | [`simulate_hmm()`](https://mohsaqr.github.io/simulab/reference/simulate_hmm.md) | Direct coverage. |
| `simulate_htna` | [`simulate_tna_network()`](https://mohsaqr.github.io/simulab/reference/simulate_tna_network.md) | Hierarchical node types are ordinary network groups. |
| `simulate_igraph` | [`simulate_network()`](https://mohsaqr.github.io/simulab/reference/simulate_network.md) + [`as_igraph()`](https://mohsaqr.github.io/simulab/reference/as_igraph.md) | Generation and representation conversion separated. |
| `simulate_irt` | [`simulate_irt()`](https://mohsaqr.github.io/simulab/reference/simulate_irt.md) | Rasch, 2PL, 3PL, graded, and multidimensional support. |
| `simulate_lca` | [`simulate_lca()`](https://mohsaqr.github.io/simulab/reference/simulate_lca.md) | Direct coverage. |
| `simulate_long_data` | [`simulate_event_log()`](https://mohsaqr.github.io/simulab/reference/simulate_event_log.md) | Grouped actor/course/achievement event logs. |
| `simulate_longitudinal` | [`simulate_longitudinal()`](https://mohsaqr.github.io/simulab/reference/simulate_longitudinal.md) | VAR, between-person covariance, and day/beep structure. |
| `simulate_lpa` | [`simulate_lpa()`](https://mohsaqr.github.io/simulab/reference/simulate_lpa.md) | Direct coverage. |
| `simulate_matrix` | [`simulate_network_matrix()`](https://mohsaqr.github.io/simulab/reference/simulate_network_matrix.md) | Adjacency, transition, frequency, and co-occurrence matrices. |
| `simulate_mlm` | [`simulate_multilevel()`](https://mohsaqr.github.io/simulab/reference/simulate_multilevel.md) | Fixed effects, random intercepts, correlated random slopes. |
| `simulate_mlna` | [`simulate_tna_network()`](https://mohsaqr.github.io/simulab/reference/simulate_tna_network.md) | Multilevel node types are ordinary network groups. |
| `simulate_mtna` | [`simulate_tna_network()`](https://mohsaqr.github.io/simulab/reference/simulate_tna_network.md) | Multi-type node metadata is first-class. |
| `simulate_network` | [`simulate_network()`](https://mohsaqr.github.io/simulab/reference/simulate_network.md) | Seven graph models, typed nodes, weighted/classed edges. |
| `simulate_onehot_data` | [`simulate_event_log()`](https://mohsaqr.github.io/simulab/reference/simulate_event_log.md) + [`encode_sequences()`](https://mohsaqr.github.io/simulab/reference/encode_sequences.md) | Event generation and encoding separated. |
| `simulate_prediction` | [`simulate_prediction()`](https://mohsaqr.github.io/simulab/reference/simulate_prediction.md) | Continuous and categorical predictors with truth tables. |
| `simulate_regression` | [`simulate_regression()`](https://mohsaqr.github.io/simulab/reference/simulate_regression.md) | Direct coverage. |
| `simulate_seq_clusters` | [`simulate_sequence_clusters()`](https://mohsaqr.github.io/simulab/reference/simulate_sequence_clusters.md) | Canonical unabbreviated verb. |
| `simulate_sequences` | [`simulate_sequences()`](https://mohsaqr.github.io/simulab/reference/simulate_sequences.md) | Direct coverage. |
| `simulate_sequences_advanced` | [`simulate_sequences()`](https://mohsaqr.github.io/simulab/reference/simulate_sequences.md) | Stable transitions, perturbation, unlikely jumps, and missing tails unified. |
| `simulate_survival` | [`simulate_proportional_survival()`](https://mohsaqr.github.io/simulab/reference/simulate_proportional_survival.md) / [`simulate_survival()`](https://mohsaqr.github.io/simulab/reference/simulate_survival.md) | Standalone PH generator plus specification-driven survival engine. |
| `simulate_tna_datasets` | [`simulate_sequence_batches()`](https://mohsaqr.github.io/simulab/reference/simulate_sequence_batches.md) | Repeated sequence generation. |
| `simulate_tna_matrix` | [`simulate_tna_network()`](https://mohsaqr.github.io/simulab/reference/simulate_tna_network.md) | Tidy transition network plus adjacency component. |
| `simulate_tna_network` | [`simulate_sequences()`](https://mohsaqr.github.io/simulab/reference/simulate_sequences.md) + [`fit_tna()`](https://mohsaqr.github.io/simulab/reference/fit_tna.md) | Simulation and fitting compose explicitly. |
| `simulate_tna_networks` | [`simulate_tna_batches()`](https://mohsaqr.github.io/simulab/reference/simulate_tna_batches.md) | Direct repeated fitted-network workflow. |
| `simulate_ttest` | [`simulate_ttest()`](https://mohsaqr.github.io/simulab/reference/simulate_ttest.md) | Direct coverage. |
| `smart_select_states` | [`sample_learning_states()`](https://mohsaqr.github.io/simulab/reference/sample_learning_states.md) | Duplicate selection alias removed. |
| `summarize_grid_results` | [`summarize_simulations()`](https://mohsaqr.github.io/simulab/reference/summarize_simulations.md) | General grouped simulation summaries. |
| `summarize_networks` | [`summarize_networks()`](https://mohsaqr.github.io/simulab/reference/summarize_networks.md) | Direct coverage. |
| `summarize_simulation` | [`summary()`](https://rdrr.io/r/base/summary.html) / [`summarize_simulations()`](https://mohsaqr.github.io/simulab/reference/summarize_simulations.md) | One-result and grouped-result summaries. |
| `tidy_simulation_results` | [`as.data.frame()`](https://rdrr.io/r/base/as.data.frame.html) / [`components()`](https://mohsaqr.github.io/simulab/reference/components.md) | All results are tidy at creation; components have one extraction API. |
| `validate_recovery` | [`validate_recovery()`](https://mohsaqr.github.io/simulab/reference/validate_recovery.md) | Direct parameter-recovery coverage. |
| `validate_sim_params` | Direct simulator validation | Validation is colocated with each explicit public signature. |

## Coverage interpretation

- 87 of 87 Saqrlab exports have an explicit resolution above.
- Compatibility aliases are deliberately not reproduced when two old
  names performed the same operation.
- Plot wrappers are the only presentation functions not recreated. Their
  data are now ordinary data frames, and fitted TNA objects remain
  available through
  [`as_tna_model()`](https://mohsaqr.github.io/simulab/reference/as_tna_model.md)
  for the native `tna` plot methods.
- Capability claims are backed by package tests, including sequence
  groups, TNA/FTNA/CTNA/ATNA, repeated TNA networks, split-half
  reliability, cross-validation, bootstrap, recovery, educational event
  logs, network models, random-slope MLM, 3PL IRT, prediction, and
  survival calibration.
