test_that("advanced sequences support generation, stability, perturbation, and tails", {
  transition <- matrix(c(0.7, 0.3, 0.4, 0.6), 2L, byrow = TRUE,
                       dimnames = list(c("A", "B"), c("A", "B")))
  stable <- data.frame(from = "A", to = "B")
  result <- simulate_sequences(
    n = 100, transition = transition, chain_length = 12,
    stable_transitions = stable, stability_probability = 1,
    instability = "unlikely_jump", instability_probability = 0.5,
    missing_tail = c(0, 3), seed = 20
  )
  pairs <- split(result, result$id)
  follows_rule <- vapply(pairs, function(sequence) {
    current <- utils::head(sequence$state, -1L)
    next_state <- utils::tail(sequence$state, -1L)
    all(next_state[current == "A"] == "B")
  }, logical(1))
  expect_true(all(follows_rule))
  expect_true(nrow(result) < 1200L)
  expect_equal(nrow(as.data.frame(result, what = "wide")), 100L)

  automatic <- simulate_sequences(20, chain_length = 8, n_states = 4, seed = 21)
  transitions <- as.data.frame(automatic, what = "transitions")
  expect_equal(as.vector(tapply(transitions$probability, transitions$from, sum)),
               rep(1, 4), tolerance = 1e-12)
  educational <- simulate_sequences(
    10, chain_length = 5, n_states = 4,
    state_categories = c("metacognitive", "cognitive"), seed = 210
  )
  expect_true(all(unique(educational$state) %in%
                    learning_states(c("metacognitive", "cognitive"))$state))
  sampled <- sample_learning_states(6, "group_regulation", seed = 211)
  expect_equal(nrow(sampled), 6L)
})

test_that("group sequence simulation preserves actor and transition groupings", {
  grouped <- simulate_group_sequences(
    groups = 3, actors = c(4, 5, 6), chain_length = 10,
    n_states = 3, seed = 22
  )
  expect_equal(length(unique(grouped$id)), 15L)
  expect_equal(length(unique(grouped$group)), 3L)
  expect_equal(nrow(as.data.frame(grouped, what = "groups")), 3L)
  expect_equal(nrow(as.data.frame(grouped, what = "transitions")), 27L)
})

test_that("all TNA estimators and grouped TNA return tidy and native models", {
  skip_if_not_installed("tna", minimum_version = "1.2.3")
  transition <- matrix(c(0.8, 0.2, 0.3, 0.7), 2L, byrow = TRUE,
                       dimnames = list(c("A", "B"), c("A", "B")))
  sequences <- simulate_sequences(100, transition, 15, seed = 23)
  comparison <- compare_tna_models(sequences)
  expect_equal(sort(unique(comparison$model)), c("atna", "ctna", "ftna", "tna"))
  expect_equal(nrow(comparison), 16L)

  fitted <- fit_tna(sequences, model = "tna")
  expect_s3_class(as_tna_model(fitted), "tna")
  expect_equal(nrow(as.data.frame(fitted, what = "initial_probabilities")), 2L)

  grouped <- simulate_group_tna(
    groups = 2, actors = 30, transitions = transition,
    chain_length = 12, model = "tna", seed = 24
  )
  expect_equal(length(unique(grouped$group)), 2L)
  expect_equal(nrow(as.data.frame(grouped, what = "estimated_edges")), 8L)
  expect_s3_class(as_tna_model(grouped), "group_tna")
  expect_s3_class(as_tna_model(grouped, "Group 1"), "tna")
})

test_that("grouped TNA networks provide row-stochastic transition matrices", {
  network <- simulate_tna_network(3, c(2, 3, 2), seed = 25)
  transitions <- as.data.frame(network, what = "transitions")
  totals <- tapply(transitions$probability, transitions$from, sum)
  expect_equal(as.vector(totals), rep(1, 7), tolerance = 1e-12)
  nodes <- as.data.frame(network, what = "nodes")
  expect_equal(as.vector(table(nodes$group)), c(2, 3, 2))
})
