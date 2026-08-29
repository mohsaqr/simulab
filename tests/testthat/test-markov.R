two_state <- matrix(c(0.7, 0.3, 0.4, 0.6), nrow = 2, byrow = TRUE)

empirical_transitions <- function(result) {
  summary <- summarize_transitions(result, normalize = TRUE)
  matrix(
    c(
      summary$probability[summary$from == "A" & summary$to == "A"],
      summary$probability[summary$from == "A" & summary$to == "B"],
      summary$probability[summary$from == "B" & summary$to == "A"],
      summary$probability[summary$from == "B" & summary$to == "B"]
    ),
    nrow = 2, byrow = TRUE
  )
}

test_that("simulate_markov recovers its transition matrix", {
  result <- simulate_markov(
    n = 3000, transition = two_state, chain_length = 50,
    states = c("A", "B"), seed = 5
  )
  # About 147,000 transitions, so the Monte Carlo SE per cell is under 0.002.
  expect_lt(max(abs(empirical_transitions(result) - two_state)), 0.01)
})

test_that("a tidy from/to/probability table is an equivalent input", {
  tidy_transitions <- data.frame(
    from = c("A", "A", "B", "B"),
    to = c("A", "B", "A", "B"),
    probability = c(0.7, 0.3, 0.4, 0.6),
    stringsAsFactors = FALSE
  )
  from_table <- simulate_markov(
    n = 200, transition = tidy_transitions, chain_length = 20, seed = 5
  )
  from_matrix <- simulate_markov(
    n = 200, transition = two_state, chain_length = 20,
    states = c("A", "B"), seed = 5
  )
  expect_equal(as.data.frame(from_table), as.data.frame(from_matrix))
})

test_that("a named starting state fixes the first observation", {
  result <- simulate_markov(
    n = 50, transition = two_state, chain_length = 5,
    states = c("A", "B"), initial = "B", seed = 5
  )
  data <- as.data.frame(result)
  expect_true(all(data$state[data$period == min(data$period)] == "B"))
})

test_that("initial probabilities are honoured", {
  result <- simulate_markov(
    n = 4000, transition = two_state, chain_length = 3,
    states = c("A", "B"), initial = c(0.25, 0.75), seed = 5
  )
  data <- as.data.frame(result)
  first <- data$state[data$period == min(data$period)]
  expect_lt(abs(mean(first == "B") - 0.75), 0.03)
})

test_that("trim_state truncates each chain at its first occurrence", {
  result <- simulate_markov(
    n = 200, transition = two_state, chain_length = 30,
    states = c("A", "B"), trim_state = "B", seed = 5
  )
  data <- as.data.frame(result)
  counts <- vapply(split(data$state, data$id), function(x) sum(x == "B"), integer(1))
  expect_true(all(counts <= 1L))
  last <- vapply(split(data$state, data$id), function(x) x[length(x)], character(1))
  expect_true(all(last %in% c("A", "B")))
})

test_that("a chain of length one returns only the starting state", {
  result <- simulate_markov(
    n = 10, transition = two_state, chain_length = 1,
    states = c("A", "B"), seed = 5
  )
  expect_equal(nrow(result), 10L)
})

test_that("numeric state labels survive without dimnames", {
  result <- simulate_markov(
    n = 50, transition = two_state, chain_length = 10,
    states = c(0, 1), seed = 5
  )
  expect_true(all(as.data.frame(result)$state %in% c(0, 1)))
})

test_that("simulate_markov exposes its truth as tidy components", {
  result <- simulate_markov(
    n = 20, transition = two_state, chain_length = 10,
    states = c("A", "B"), seed = 5
  )
  expect_true(all(c("transitions", "initial_probabilities", "wide") %in%
                    components(result)$table))
  # Assert the from/to pairing rather than the storage order of the table.
  truth <- as.data.frame(result, what = "transitions")
  expect_equal(truth$probability[truth$from == "A" & truth$to == "B"], 0.3)
  expect_equal(truth$probability[truth$from == "B" & truth$to == "A"], 0.4)
})

test_that("a transition table naming an unknown state is refused", {
  tidy_transitions <- data.frame(
    from = c("A", "A"), to = c("A", "Z"), probability = c(0.5, 0.5),
    stringsAsFactors = FALSE
  )
  expect_error(
    simulate_markov(n = 5, transition = tidy_transitions, chain_length = 5,
                    states = c("A", "B")),
    regexp = "state"
  )
})

test_that("rows that do not sum to one are refused", {
  expect_error(
    simulate_markov(n = 5, chain_length = 5,
                    transition = matrix(c(0.7, 0.2, 0.4, 0.6), nrow = 2, byrow = TRUE)),
    regexp = "sum to one"
  )
})

test_that("augment_markov appends chains to existing units", {
  data <- data.frame(id = 1:20, group = rep(c("a", "b"), each = 10))
  result <- augment_markov(
    data, transition = two_state, chain_length = 10,
    states = c("A", "B"), seed = 5
  )
  expect_equal(length(unique(as.data.frame(result)$id)), 20L)
  expect_true("group" %in% names(result))
})
