# validate_recovery() and summarize_simulations() are the two verbs a Monte
# Carlo study pipes a batch through, so identifiers and row layout matter.

.batch_estimates <- data.frame(
  batch_id = rep(c(2L, 1L), each = 2L),
  term     = rep(c("b", "a"), 2L),
  estimate = c(0.52, 1.1, 0.47, 0.9)
)
.batch_truth <- data.frame(term = c("a", "b", "c"), value = c(1, 0.5, 0))

test_that("validate_recovery() keeps identifier columns and the estimates' row order", {
  recovery <- validate_recovery(.batch_estimates, .batch_truth, true_value = "value")
  expect_named(recovery, c("batch_id", "term", "estimate", "truth", "bias",
                           "absolute_error", "relative_error", "recovered"))
  expect_identical(recovery$batch_id, c(2L, 2L, 1L, 1L, NA))
  expect_identical(recovery$term, c("b", "a", "b", "a", "c"))
  expect_equal(recovery$bias, c(0.02, 0.1, -0.03, -0.1, NA))
  expect_identical(rownames(recovery), as.character(seq_len(5L)))
})

test_that("validate_recovery() without identifiers keeps its original columns", {
  recovery <- validate_recovery(data.frame(term = "a", estimate = 1.05),
                                data.frame(term = "a", truth = 1))
  expect_named(recovery, c("term", "estimate", "truth", "bias",
                           "absolute_error", "relative_error", "recovered"))
  expect_true(recovery$recovered)
})

test_that("summarize_simulations() numbers its rows plainly", {
  recovery <- validate_recovery(.batch_estimates, .batch_truth, true_value = "value")
  summary <- summarize_simulations(recovery, by = "term", variables = c("estimate", "bias"))
  expect_identical(rownames(summary), as.character(seq_len(nrow(summary))))
  expect_identical(summary$term, rep(c("a", "b", "c"), each = 2L))
})

test_that("summarize_simulations() reports NA, not NaN or Inf, for an empty group", {
  data <- data.frame(group = c("a", "a", "b"), value = c(1, 3, NA))
  expect_no_warning(
    summary <- summarize_simulations(data, by = "group", variables = "value")
  )
  expect_identical(summary$observations, c(2L, 0L))
  expect_equal(summary$mean, c(2, NA))
  expect_equal(summary$sd, c(sqrt(2), NA))
  expect_equal(summary$minimum, c(1, NA))
  expect_equal(summary$maximum, c(3, NA))
})

test_that("list_distributions() numbers its rows plainly after sorting", {
  catalogue <- list_distributions()
  expect_identical(rownames(catalogue), as.character(seq_len(nrow(catalogue))))
  expect_false(is.unsorted(catalogue$distribution))
  copula_only <- list_distributions(copula = TRUE)
  expect_identical(rownames(copula_only), as.character(seq_len(nrow(copula_only))))
})

test_that("summarize_simulations() without `by` has no grouping column", {
  data <- data.frame(x = c(1, 2, 3), y = c(2, 4, NA))
  summary <- summarize_simulations(data)
  expect_named(summary, c("variable", "observations", "mean", "sd", "minimum", "maximum"))
  expect_identical(summary$variable, c("x", "y"))
  expect_identical(summary$observations, c(3L, 2L))
})

test_that("summarize_transitions() numbers its rows plainly", {
  sequences <- simulate_markov(n = 20, transition = matrix(c(0.6, 0.4, 0.3, 0.7), 2, byrow = TRUE),
                               chain_length = 6, states = c("a", "b"), seed = 1)
  transitions <- summarize_transitions(sequences)
  expect_identical(rownames(transitions), as.character(seq_len(nrow(transitions))))
})

test_that("network centrality reads direction from the network's settings", {
  skip_if_not_installed("igraph")
  undirected <- simulate_network(nodes = 30, model = "barabasi_albert", directed = FALSE,
                                 seed = 1)
  expect_no_warning(inferred <- network_centrality(undirected))
  # Eigenvector centrality is iterative, so repeated runs agree to ~1e-15.
  expect_equal(inferred, network_centrality(undirected, directed = FALSE))
  expect_false(igraph::is_directed(as_igraph(undirected)))
  expect_identical(rownames(inferred), as.character(seq_len(nrow(inferred))))
  directed <- simulate_network(nodes = 10, probability = 0.3, directed = TRUE, seed = 1)
  expect_true(igraph::is_directed(as_igraph(directed)))
  expect_true(igraph::is_directed(as_igraph(as.data.frame(directed))))
})
