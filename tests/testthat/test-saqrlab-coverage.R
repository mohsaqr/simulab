test_that("educational sequences include transition, one-hot, and grouped event-log APIs", {
  system <- generate_transition_system(4, diagonal_concentration = 3, seed = 101)
  transitions <- as.data.frame(system)
  expect_equal(as.vector(tapply(transitions$probability, transitions$from, sum)),
               rep(1, 4), tolerance = 1e-12)

  sequences <- simulate_sequences(8, chain_length = 6, n_states = 3, seed = 102)
  encoded <- encode_sequences(sequences)
  expect_equal(nrow(encoded), nrow(sequences))
  expect_equal(rowSums(encoded[, startsWith(names(encoded), "state_")]),
               rep(1, nrow(encoded)))

  events <- simulate_event_log(
    groups = 2, actors = c(4, 5), courses = c("A", "B"),
    n_states = 4, sequence_length = c(5, 8), seed = 103
  )
  expect_equal(length(unique(events$id)), 9L)
  expect_true(inherits(events$timestamp, "POSIXct"))
  expect_true(all(vapply(split(events$timestamp, events$id), function(value) {
    all(diff(value) >= 0)
  }, logical(1))))
  expect_true(all(c("wide", "one_hot", "transitions", "actors", "groups") %in%
                    components(events)$table))
})

test_that("network generators, conversion, comparison, and recovery are coherent", {
  skip_if_not_installed("igraph", minimum_version = "2.0.0")
  models <- c("bernoulli", "barabasi_albert", "small_world", "block",
              "regular", "geometric", "forest_fire")
  generated <- lapply(seq_along(models), function(index) {
    simulate_network(
      20, model = models[index], probability = 0.2,
      directed = FALSE, degree = 2, neighbors = 2,
      radius = 0.3, seed = 110 + index
    )
  })
  expect_true(all(vapply(generated, inherits, logical(1), "simulab_sim")))
  expect_true(all(vapply(generated, function(value) {
    all(c("from", "to", "weight") %in% names(value))
  }, logical(1))))

  fixed <- simulate_network(12, edges = 20, directed = FALSE,
                            weight = "uniform", seed = 120)
  expect_equal(nrow(fixed), 20L)
  expect_equal(igraph::vcount(as_igraph(fixed, directed = FALSE)), 12L)
  centrality <- network_centrality(fixed, c("degree", "pagerank"), directed = FALSE)
  expect_equal(sort(unique(centrality$measure)), c("degree", "pagerank"))
  comparison <- compare_networks(fixed, fixed)
  expect_equal(comparison$pearson, 1)
  expect_equal(comparison$jaccard, 1)
  expect_equal(compare_centralities(fixed, fixed, "degree", directed = FALSE)$correlation, 1)
  recovery <- evaluate_edge_recovery(fixed, fixed)
  expect_equal(as.data.frame(recovery, what = "summary")$f1, 1)
  expect_equal(summarize_networks(list(first = fixed))$edges, 20L)

  batches <- simulate_network_batches(3, nodes = 10, edges = 8,
                                      directed = FALSE, seed = 121)
  expect_equal(length(unique(batches$network)), 3L)
  expect_equal(nrow(batches), 24L)
})

test_that("MLM random slopes and longitudinal between-person structure are retained", {
  model <- simulate_multilevel(
    1000, 4, slopes = c(x = 0.5), random_intercept_sd = 1,
    random_slope_sd = 0.7, random_effect_correlation = 0.4,
    residual_sd = 0.5, seed = 130
  )
  random <- as.data.frame(model, what = "random_effects")
  expect_equal(stats::sd(random$random_slope), 0.7, tolerance = 0.05)
  expect_equal(stats::cor(random$random_intercept, random$random_slope),
               0.4, tolerance = 0.07)

  transition <- matrix(c(0.2, 0, 0, 0.3), 2)
  longitudinal <- simulate_longitudinal(
    500, 12, transition, innovation_covariance = diag(c(0.2, 0.2)),
    between_covariance = matrix(c(1, 0.5, 0.5, 1), 2),
    grand_means = c(2, -1), beeps_per_day = 4, burn_in = 0, seed = 131
  )
  means <- as.data.frame(longitudinal, what = "person_means")
  expect_equal(unname(colMeans(means[, -1])), c(2, -1), tolerance = 0.12)
  expect_equal(stats::cor(means[[2]], means[[3]]), 0.5, tolerance = 0.08)
  expect_equal(max(longitudinal$day), 3L)
  expect_equal(sort(unique(longitudinal$beep)), 1:4)
})

test_that("3PL, categorical prediction, and proportional survival close model gaps", {
  irt <- simulate_irt(5000, difficulty = rep(8, 3), model = "3pl",
                      guessing = 0.25, seed = 140)
  expect_equal(unname(colMeans(irt[, -1])), rep(0.25, 3), tolerance = 0.03)
  expect_equal(as.data.frame(irt, what = "parameters")$guessing,
               rep(0.25, 3))

  prediction <- simulate_prediction(
    3000, c("(Intercept)" = 1, x = 0.5),
    categorical_levels = list(group = c("control", "treatment")),
    categorical_effects = list(group = c(0, 2)), error_sd = 0.5, seed = 141
  )
  group_means <- tapply(prediction$outcome, prediction$group, mean)
  expect_equal(unname(group_means["treatment"] - group_means["control"]),
               2, tolerance = 0.08)
  expect_true(as.data.frame(prediction, what = "effects")$r_squared > 0.7)

  survival <- simulate_proportional_survival(
    4000, c(x = 0.5), baseline = "weibull", shape = 1.5,
    censoring = 0.35, seed = 142
  )
  diagnostics <- as.data.frame(survival, what = "diagnostics")
  expect_equal(diagnostics$realized_censoring, 0.35, tolerance = 0.03)
  expect_true(all(survival$time > 0))
})

test_that("grid, batch, summary, catalogue, scenarios, and export APIs are unified", {
  full <- parameter_grid(a = 1:2, b = c("x", "y"), method = "grid")
  expect_equal(nrow(full), 4L)
  random <- parameter_grid(a = c(0, 1), b = 1:4, n = 10,
                           method = "latin_hypercube", seed = 150)
  expect_equal(nrow(random), 10L)
  expect_true(all(random$a >= 0 & random$a <= 1))

  inputs <- list(a = data.frame(x = 1:3), b = data.frame(x = 4:6))
  applied <- apply_batch(inputs, function(value) {
    data.frame(mean = mean(value$x), row.names = NULL)
  })
  expect_equal(applied$batch_id, c("a", "b"))

  summary <- summarize_simulations(data.frame(group = rep(c("a", "b"), each = 3), x = 1:6),
                                   by = "group")
  expect_equal(nrow(summary), 2L)
  expect_true(all(c("mean", "sd", "minimum", "maximum") %in% names(summary)))

  expect_true(nrow(global_names()) >= 60L)
  expect_equal(length(global_name_regions()), 8L)
  expect_equal(nrow(sample_global_names(10, seed = 151)), 10L)
  expect_equal(length(learning_state_categories()), 8L)
  expect_true("group_tna" %in% simulation_scenarios()$scenario)
  scenario <- run_simulation_scenario("learning_sequences", seed = 152)
  expect_s3_class(scenario, "simulab_sim")

  output <- tempfile(fileext = ".csv")
  expect_equal(write_simulation(scenario, output), normalizePath(output))
  expect_true(file.exists(output))
})

test_that("sequence batches and TNA estimation, reliability, bootstrap, and CV work", {
  batches <- simulate_sequence_batches(
    3, n = 10, chain_length = 6, n_states = 3, seed = 160
  )
  expect_equal(length(unique(batches$dataset)), 3L)
  expect_equal(nrow(batches), 180L)

  skip_if_not_installed("tna", minimum_version = "1.2.3")
  transition <- matrix(c(0.8, 0.2, 0.3, 0.7), 2, byrow = TRUE,
                       dimnames = list(c("A", "B"), c("A", "B")))
  sequences <- simulate_sequences(40, transition, 10, seed = 161)
  inputs <- split(as.data.frame(sequences, what = "wide"), rep(1:2, each = 20))
  fitted <- fit_tna_batch(inputs, model = "tna", format = "wide")
  expect_equal(length(unique(fitted$dataset)), 2L)
  networks <- simulate_tna_batches(
    2, model = "tna", n = 20, chain_length = 8, n_states = 3, seed = 1610
  )
  expect_equal(length(unique(networks$network)), 2L)
  expect_true(all(c("sequences", "true_transitions") %in% components(networks)$table))

  bootstrap <- bootstrap_tna(sequences, repetitions = 3, seed = 162)
  expect_equal(length(unique(bootstrap$iteration)), 3L)
  expect_true(nrow(as.data.frame(bootstrap, what = "summary")) > 0L)
  validation <- cross_validate_tna(sequences, models = c("tna", "ftna"),
                                   iterations = 2, seed = 163)
  expect_equal(nrow(validation), 4L)
  reliability <- assess_tna_reliability(sequences, iterations = 3, seed = 164)
  expect_equal(nrow(reliability), 3L)
  expect_true(all(c("pearson", "cosine", "jaccard") %in% names(reliability)))
  sampled <- sample_tna(sequences, fraction = 0.5, seed = 165)
  expect_s3_class(as_tna_model(sampled), "tna")

  estimation <- evaluate_tna_estimation(
    repetitions = 2, n = 40, chain_length = 10, n_states = 3,
    models = c("tna", "ftna"), missing_tail = 0, seed = 166
  )
  expect_equal(nrow(estimation), 4L)
  expect_true(all(c("truth", "estimated_edges") %in% components(estimation)$table))
})
