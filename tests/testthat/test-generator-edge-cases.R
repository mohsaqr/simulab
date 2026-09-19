# Regression tests for boundary cases that previously produced a wrong answer
# silently, or refused valid input. Each test names the trap it guards, because
# every one of them is a case where the failure was not visible in the output.

test_that("a single correlated variable accepts a non-unit standard deviation", {
  ## diag() on a length-one numeric builds an identity matrix of that size, so
  ## `diag(2)` was a 2x2 identity rather than a 1x1 scale matrix and the
  ## covariance product was non-conformable.
  result <- simulate_correlated(n = 20000, means = 5, sds = 2, seed = 1)
  expect_equal(nrow(result), 20000L)
  expect_equal(mean(result$V1), 5, tolerance = 0.05)
  expect_equal(stats::sd(result$V1), 2, tolerance = 0.05)

  ## The multivariate path is unchanged.
  several <- simulate_correlated(n = 20000, means = c(0, 0), sds = c(1, 3),
                                 rho = 0.4, seed = 2)
  expect_equal(stats::sd(several$V2), 3, tolerance = 0.05)
  expect_equal(stats::cor(several$V1, several$V2), 0.4, tolerance = 0.05)
})

test_that("an item-by-threshold difficulty matrix is rejected outside the graded model", {
  ## A matrix reached sweep() as an over-long STATS, which only warns, and the
  ## parameters table came back with value.1/value.2/value.3 columns.
  thresholds <- matrix(c(-1, 0, 1, -0.5, 0.5, 1.5), nrow = 2, byrow = TRUE)
  expect_error(
    simulate_irt(n = 20, discrimination = c(1, 1), difficulty = thresholds,
                 model = "2pl", seed = 1),
    "requires model = \"graded\""
  )
  expect_error(
    simulate_irt(n = 20, discrimination = c(1, 1), difficulty = thresholds,
                 model = "rasch", seed = 1),
    "requires model = \"graded\""
  )

  graded <- simulate_irt(n = 50, discrimination = c(1, 1),
                         difficulty = thresholds, model = "graded", seed = 1)
  expect_equal(range(graded$item_1), c(0L, 3L))
  dichotomous <- simulate_irt(n = 50, difficulty = c(-1, 0, 1), model = "2pl",
                              seed = 1)
  expect_equal(sort(unique(dichotomous$item_1)), c(0L, 1L))
})

test_that("a fixed sequence length is honoured exactly", {
  ## sample() reads a length-one numeric as an upper bound, so seq.int(8, 8)
  ## collapsed to the scalar 8 and lengths came back uniform on 1:8.
  log <- as.data.frame(
    simulate_event_log(groups = 2, actors = 5, sequence_length = 8, seed = 1)
  )
  lengths <- as.vector(table(interaction(log$group, log$id, drop = TRUE)))
  expect_true(all(lengths == 8L))

  ranged <- as.data.frame(
    simulate_event_log(groups = 2, actors = 8, sequence_length = c(5, 9),
                       seed = 2)
  )
  ranged_lengths <- as.vector(table(interaction(ranged$group, ranged$id,
                                                drop = TRUE)))
  expect_true(all(ranged_lengths >= 5L & ranged_lengths <= 9L))
})

test_that("a fixed missing tail removes exactly that many positions", {
  fixed <- as.data.frame(
    simulate_sequences(n = 10, chain_length = 10, n_states = 3,
                       missing_tail = 2, seed = 3)
  )
  expect_true(all(as.vector(table(fixed$id)) == 8L))

  ranged <- as.data.frame(
    simulate_sequences(n = 20, chain_length = 10, n_states = 3,
                       missing_tail = c(1, 3), seed = 4)
  )
  ranged_lengths <- as.vector(table(ranged$id))
  expect_true(all(ranged_lengths >= 7L & ranged_lengths <= 9L))
})

test_that("the integer-range sampler covers its bounds and refuses bad input", {
  set.seed(1)
  degenerate <- simulab:::.sample_integer_range(c(4, 4), 50)
  expect_true(all(degenerate == 4L))
  expect_length(degenerate, 50L)

  spread <- simulab:::.sample_integer_range(c(2, 5), 4000)
  expect_equal(sort(unique(spread)), 2:5)
  expect_length(simulab:::.sample_integer_range(c(1, 3), 0), 0L)

  expect_error(simulab:::.sample_integer_range(c(5, 1), 10), "low then high")
  expect_error(simulab:::.sample_integer_range(3, 10), "length 2")
})

test_that("sample_tna honours non-default sequence column names", {
  skip_if_not_installed("tna", minimum_version = "1.2.3")
  ## The sampling step used to hardcode id/period/state, so any other naming
  ## produced integer state labels and all-zero weights without an error.
  set.seed(3)
  sequences <- data.frame(
    subject = rep(1:20, each = 5),
    period = rep(1:5, 20),
    state = sample(c("A", "B", "C"), 100, replace = TRUE),
    stringsAsFactors = FALSE
  )
  sampled <- as.data.frame(
    sample_tna(sequences, fraction = 0.5, id = "subject", seed = 1)
  )
  expect_setequal(unique(sampled$from), c("A", "B", "C"))
  expect_true(any(sampled$weight > 0))

  ## `format` is now consumed by the sampling step rather than colliding with
  ## the refit, which previously raised a matched-by-multiple-arguments error.
  explicit <- as.data.frame(
    sample_tna(sequences, fraction = 0.5, id = "subject", format = "long",
               seed = 1)
  )
  expect_equal(explicit, sampled)
})
