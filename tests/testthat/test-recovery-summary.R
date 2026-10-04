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

test_that("validate_recovery() compares each batch data set with its own truth", {
  datasets <- simulate_regression(n = 50, seed = 2, batch = 4)
  fit_coefficients <- function(data) {
    fit <- stats::lm(outcome ~ x1 + x2, data = data)
    data.frame(term = names(stats::coef(fit)), estimate = unname(stats::coef(fit)))
  }
  estimates <- apply_batch(datasets, fit_coefficients)
  recovery <- validate_recovery(estimates, datasets)
  expect_identical(nrow(recovery), 12L)
  expected_truth <- unlist(lapply(datasets, function(result) {
    as.data.frame(result, what = "coefficients")$coefficient
  }), use.names = FALSE)
  expect_identical(recovery$truth, expected_truth)
  expect_identical(recovery$batch_id, rep(as.character(1:4), each = 3))
})

test_that("validate_recovery() takes a single result as truth", {
  result <- simulate_regression(seed = 3)
  estimates <- data.frame(term = c("x1", "x2"), estimate = c(0, 0))
  recovery <- validate_recovery(estimates, result)
  truth <- as.data.frame(result, what = "coefficients")
  expect_identical(recovery$truth[1:2], subset(truth, term != "(Intercept)")$coefficient)
})

test_that("validate_recovery() reports a result without generating values", {
  synthetic <- simulate_synthetic(data.frame(id = 1:4, x = c(1, 2, 3, 4)), n = 2, seed = 1)
  estimates <- data.frame(term = "x", estimate = 1)
  expect_error(validate_recovery(estimates, synthetic), class = "simulab_no_truth")
})

test_that("validate_recovery() asks for true_value when it is ambiguous", {
  estimates <- data.frame(term = "a", estimate = 1)
  truth <- data.frame(term = "a", mean = 1, sd = 2)
  expect_error(validate_recovery(estimates, truth), "several numeric columns: mean, sd")
  expect_identical(validate_recovery(estimates, truth, true_value = "mean")$truth, 1)
})

test_that("validate_recovery() refuses a truth with duplicated keys", {
  estimates <- data.frame(term = "a", estimate = 1)
  truth <- data.frame(term = c("a", "a"), truth = c(1, 2))
  expect_error(validate_recovery(estimates, truth), "more than one row")
})

test_that("validate_recovery() takes a fitted model as estimates", {
  data_set <- simulate_regression(n = 200, seed = 4)
  fit <- stats::lm(outcome ~ x1 + x2, data = data_set)
  recovery <- validate_recovery(fit, data_set)
  expect_identical(recovery$term, c("(Intercept)", "x1", "x2"))
  expect_identical(recovery$estimate, unname(stats::coef(fit)))
  expect_identical(recovery$truth, as.data.frame(data_set, what = "coefficients")$coefficient)
})

test_that("validate_recovery() handles estimate and truth columns of the same name", {
  transition <- data.frame(from = rep(c("a", "b"), each = 2), to = rep(c("a", "b"), 2),
                           probability = c(0.7, 0.3, 0.4, 0.6))
  chains <- simulate_markov(n = 50, transition = transition, chain_length = 10, seed = 1)
  recovery <- validate_recovery(summarize_transitions(chains), chains,
                                term = "to", estimate = "probability")
  expect_identical(nrow(recovery), 4L)
  expected <- merge(summarize_transitions(chains), transition, by = c("from", "to"),
                    suffixes = c("_estimated", "_generating"))
  expected <- expected[order(expected$from, expected$to), ]
  observed <- recovery[order(recovery$from, recovery$term), ]
  expect_equal(observed$truth, expected$probability_generating)
  expect_equal(observed$estimate, expected$probability_estimated)
})
