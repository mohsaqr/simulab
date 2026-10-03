test_that("multilevel and growth generators recover variance and fixed trends", {
  multilevel <- simulate_multilevel(200, 50, intercept = 1,
                                    random_intercept_sd = 2, residual_sd = 1,
                                    seed = 1)
  cluster_means <- tapply(multilevel$outcome, multilevel$cluster, mean)
  expect_equal(stats::sd(cluster_means), 2, tolerance = 0.25)
  growth <- simulate_growth(500, 0:4, intercept = 2, slope = 0.5,
                            random_sd = c(0, 0), residual_sd = 0.5, seed = 2)
  means <- tapply(growth$outcome, growth$time, mean)
  expect_equal(as.vector(means), 2 + 0.5 * 0:4, tolerance = 0.06)
})

test_that("VAR, Markov, HMM, and sequence clusters return tidy long data", {
  transition <- matrix(c(0.5, 0.1, -0.1, 0.4), 2L, byrow = TRUE)
  longitudinal <- simulate_longitudinal(20, 30, transition, burn_in = 20, seed = 3)
  expect_equal(nrow(longitudinal), 600L)
  expect_equal(nrow(as.data.frame(longitudinal, what = "transition")), 4L)

  markov_transition <- matrix(c(0.8, 0.2, 0.3, 0.7), 2L, byrow = TRUE,
                              dimnames = list(c("A", "B"), c("A", "B")))
  markov <- simulate_sequences(20, markov_transition, 10, seed = 4)
  expect_equal(nrow(markov), 200L)
  augmented <- augment_markov(data.frame(id = 1:4, start = c("A", "B", "A", "B")),
                              markov_transition, 5, initial = "start", seed = 5)
  expect_equal(nrow(augmented), 20L)
  trimmed <- trim_events(data.frame(id = rep(1:2, each = 3), period = rep(1:3, 2),
                                    event = c(0, 1, 0, 0, 0, 0)),
                         "id", "period", "event")
  expect_equal(nrow(trimmed), 5L)
  until <- simulate_until_event(
    data.frame(id = rep(1:2, each = 4), period = rep(1:4, 2)),
    define_variable("event", 1, distribution = "binary"), seed = 6
  )
  expect_equal(nrow(until), 2L)

  hmm <- simulate_hmm(10, markov_transition, 8,
                      emission = matrix(c(0.9, 0.1, 0.2, 0.8), 2L, byrow = TRUE), seed = 7)
  expect_equal(nrow(hmm), 80L)
  sequence_clusters <- simulate_sequence_clusters(
    20, list(markov_transition, markov_transition[, 2:1]), 10, seed = 8
  )
  expect_equal(nrow(sequence_clusters), 200L)
  expect_true(nrow(summarize_transitions(markov)) > 0L)
})

test_that("network simulation returns edges, nodes, and adjacency tables", {
  network <- simulate_network(30, probability = 0.2, directed = FALSE, seed = 9)
  expect_true(all(c("from", "to", "weight") %in% names(network)))
  expect_equal(nrow(as.data.frame(network, what = "nodes")), 30L)
  expect_equal(nrow(as.data.frame(network, what = "adjacency")), 900L)
})

test_that("beeps_per_day resets carryover at the first beep of each day and keeps the intercept", {
  # Near-zero noise makes the process deterministic: x_t = 1 + 0.9 * x_{t-1},
  # restarting from the intercept (person mean 0 + intercept 1) at each new day.
  run <- function(burn_in) {
    simulate_longitudinal(
      n = 1, occasions = 12, transition = matrix(0.9), intercept = 1,
      innovation_covariance = matrix(1e-12), initial_covariance = matrix(1e-12),
      beeps_per_day = 4, burn_in = burn_in, seed = 7
    )
  }
  within_day <- c(1, 1.9, 2.71, 3.439)

  no_burn <- as.data.frame(run(0))
  expect_equal(no_burn$variable_1[no_burn$day > 1],
               rep(within_day, 2), tolerance = 1e-4)
  expect_equal(no_burn$variable_1[no_burn$day == 1][-1],
               within_day[-4], tolerance = 1e-4)

  burned <- as.data.frame(run(25))
  expect_equal(burned$variable_1[burned$day > 1],
               rep(within_day, 2), tolerance = 1e-4)
  # Day one continues from the burn-in, so its first beep is not a reset.
  expect_gt(burned$variable_1[1], 5)
})
