# simulate_tna() generates sequences from a transition matrix and fits one
# network in a single call; the truth it stores must be the matrix the
# sequences came from.

test_that("simulate_tna() runs with no arguments and stores its truth", {
  skip_if_not_installed("tna")
  network <- simulate_tna(seed = 1)
  expect_s3_class(network, "tna")
  expect_identical(dim(network$weights), c(5L, 5L))
  edges <- as.data.frame(network)
  expect_identical(names(edges), c("from", "to", "weight"))
  expect_identical(nrow(edges), 25L)
  truth <- as.data.frame(network, what = "transitions")
  expect_identical(names(truth), c("from", "to", "probability"))
  row_sums <- tapply(truth$probability, truth$from, sum)
  expect_equal(as.vector(row_sums), rep(1, 5))
  expect_identical(nrow(as.data.frame(network, what = "sequences")), 2000L)
  expect_s3_class(as_tna_model(network), "tna")
})

test_that("the fitted network recovers the generating matrix", {
  skip_if_not_installed("tna")
  transition <- data.frame(
    from = rep(c("plan", "act", "check"), each = 3),
    to = rep(c("plan", "act", "check"), times = 3),
    probability = c(0.2, 0.7, 0.1, 0.1, 0.5, 0.4, 0.4, 0.3, 0.3)
  )
  network <- simulate_tna(n = 2000, transition = transition, chain_length = 30, seed = 2)
  truth <- as.data.frame(network, what = "transitions")
  expect_setequal(truth$probability, transition$probability)
  recovery <- validate_recovery(network, network, term = "to", estimate = "weight")
  expect_identical(nrow(recovery), 9L)
  expect_lt(max(recovery$absolute_error), 0.02)
})

test_that("simulate_tna() fits the same network as simulate_sequences() + fit_tna()", {
  skip_if_not_installed("tna")
  direct <- simulate_tna(n = 50, chain_length = 10, n_states = 3, seed = 3)
  sequences <- simulate_sequences(n = 50, chain_length = 10, n_states = 3,
                                  state_categories = c("metacognitive", "cognitive"),
                                  seed = 3)
  composed <- fit_tna(sequences, format = "long")
  expect_identical(as.data.frame(direct), as.data.frame(composed))
})

test_that("simulate_tna() is reproducible, restores the RNG and takes batch", {
  skip_if_not_installed("tna")
  set.seed(10)
  before <- .Random.seed
  first <- simulate_tna(n = 20, chain_length = 8, seed = 4)
  expect_identical(before, .Random.seed)
  expect_identical(first, simulate_tna(n = 20, chain_length = 8, seed = 4))
  networks <- simulate_tna(n = 20, chain_length = 8, seed = 4, batch = 3)
  expect_length(networks, 3L)
  expect_true(all(vapply(networks, inherits, logical(1), what = "simulab_tna")))
})

test_that("simulate_tna() accepts the other estimators", {
  skip_if_not_installed("tna")
  frequency <- simulate_tna(n = 20, chain_length = 8, model = "ftna", seed = 5)
  expect_identical(as.data.frame(frequency, what = "model_info")$model, "ftna")
})

test_that("simulate_tna() raises a classed error without tna", {
  local_mocked_bindings(requireNamespace = function(...) FALSE, .package = "base")
  expect_error(simulate_tna(seed = 1), class = "simulab_missing_tna")
})

test_that("simulate_tna() works with native tna functions and prints its truth", {
  skip_if_not_installed("tna")
  network <- simulate_tna(n = 40, n_states = 3, seed = 6)
  centrality <- tna::centralities(network)
  expect_identical(nrow(centrality), 3L)
  output <- capture.output(print(network))
  expect_true(any(grepl("Transition Probability Matrix", output, fixed = TRUE)))
  expect_true("Generating Transition Probability Matrix (truth) :" %in% output)
  plain <- as_tna_model(network)
  expect_identical(class(plain), "tna")
  expect_null(attr(plain, "simulab_tables"))
  expect_identical(components(network)$table,
                   c("transitions", "initial_probabilities", "edges", "sequences",
                     "wide", "model_info"))
})

test_that("a drawn network is labeled with learning states by default", {
  skip_if_not_installed("tna")
  network <- simulate_tna(seed = 1)
  catalogue <- learning_states(c("metacognitive", "cognitive"))$state
  expect_true(all(network$labels %in% catalogue))
  plain <- simulate_tna(state_categories = NULL, seed = 1)
  expect_identical(plain$labels, sprintf("State %d", 1:5))
})

test_that("the printed truth uses the fitted network's state order", {
  skip_if_not_installed("tna")
  network <- simulate_tna(seed = 1)
  output <- capture.output(print(network))
  header <- output[which(output == "Generating Transition Probability Matrix (truth) :") + 2L]
  expect_identical(strsplit(trimws(header), " +")[[1]], network$labels)
})
