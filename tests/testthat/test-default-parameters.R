# Generators that run with no arguments draw the parameters a caller leaves
# NULL inside the seeded block and report them as the truth. Supplying the
# parameters must leave the random stream, and so the data, unchanged.

test_that("generators run with no arguments at all", {
  regression <- simulate_regression(seed = 1)
  expect_identical(dim(regression), c(100L, 4L))
  expect_identical(names(regression), c("id", "x1", "x2", "outcome"))

  ttest <- simulate_ttest(seed = 1)
  expect_identical(nrow(ttest), 100L)

  anova <- simulate_anova(seed = 1)
  expect_identical(nrow(as.data.frame(anova, what = "parameters")), 3L)
  expect_identical(nrow(anova), 90L)

  sequences <- simulate_sequences(seed = 1)
  expect_identical(nrow(sequences), 2000L)

  grouped <- simulate_group_sequences(seed = 1)
  expect_identical(nrow(grouped), 2000L)
})

test_that("simulate_group_tna() runs with no arguments", {
  skip_if_not_installed("tna")
  fitted <- simulate_group_tna(seed = 1)
  expect_identical(nrow(as.data.frame(fitted, what = "groups")), 2L)
  expect_true(all(c("true_transitions", "estimated_edges") %in%
                    components(fitted)$table))
})

test_that("drawn coefficients and means are reported, rounded and in range", {
  coefficients <- as.data.frame(simulate_regression(n_predictors = 4, seed = 2),
                                what = "coefficients")
  expect_identical(coefficients$term, c("(Intercept)", "x1", "x2", "x3", "x4"))
  expect_equal(coefficients$coefficient, round(coefficients$coefficient, 2))
  slopes <- subset(coefficients, term != "(Intercept)")$coefficient
  expect_true(all(slopes >= -1 & slopes <= 1))
  expect_true(any(abs(slopes) > 0))

  means <- as.data.frame(simulate_anova(labels = c("a", "b", "c", "d"), seed = 2),
                         what = "parameters")$mean
  expect_length(means, 4L)
  expect_equal(means, round(means, 2))
})

test_that("drawn regression coefficients are the ones that generated the outcome", {
  drawn <- simulate_regression(n = 20000, error_sd = 0.5, seed = 3)
  truth <- as.data.frame(drawn, what = "coefficients")
  fit <- stats::lm(outcome ~ x1 + x2, data = drawn)
  expect_equal(unname(stats::coef(fit)), truth$coefficient, tolerance = 0.02)
})

test_that("drawn group means are the ones that generated the outcome", {
  drawn <- simulate_ttest(n_a = 20000, n_b = 20000, seed = 4)
  truth <- as.data.frame(drawn, what = "parameters")
  observed <- tapply(drawn$outcome, drawn$group, mean)
  expect_equal(as.vector(observed[truth$group]), truth$mean, tolerance = 0.03)

  one_way <- simulate_anova(n = 10000, seed = 5)
  truth <- as.data.frame(one_way, what = "parameters")
  observed <- tapply(one_way$outcome, one_way$group, mean)
  expect_equal(as.vector(observed[truth$group]), truth$mean, tolerance = 0.03)
})

test_that("a seed reproduces drawn parameters and data, and restores the RNG", {
  set.seed(99)
  before <- .Random.seed
  first <- simulate_regression(seed = 7)
  expect_identical(before, .Random.seed)
  expect_identical(first, simulate_regression(seed = 7))
  expect_false(identical(
    as.data.frame(first, what = "coefficients"),
    as.data.frame(simulate_regression(seed = 8), what = "coefficients")
  ))
})

test_that("batch draws new parameters for every data set", {
  datasets <- simulate_regression(seed = 1, batch = 3)
  coefficient_sets <- lapply(datasets, \(x) as.data.frame(x, what = "coefficients")$coefficient)
  expect_false(identical(coefficient_sets[[1]], coefficient_sets[[2]]))
  standalone <- simulate_regression(seed = attr(datasets[[2]], "simulab_seed"))
  expect_identical(as.data.frame(datasets[[2]]), as.data.frame(standalone))
})

test_that("supplied parameters leave the 0.4.7 random stream unchanged", {
  # Values recorded from simulab 0.4.7, before the no-argument defaults.
  regression <- simulate_regression(
    n = 50, coefficients = c("(Intercept)" = 1, x1 = 0.5, x2 = -0.3), seed = 11
  )
  expect_equal(utils::head(regression$outcome, 3),
               c(0.0258546576464655, 1.32593412751312, 1.08405534779946),
               tolerance = 1e-12)
  ttest <- simulate_ttest(n_a = 20, n_b = 20, mean_a = 0, mean_b = 1, seed = 11)
  expect_equal(utils::head(ttest$outcome, 2),
               c(-0.591031102584369, 0.026594369016167),
               tolerance = 1e-12)
})

test_that("invalid defaults-related input is rejected", {
  expect_error(simulate_regression(n_predictors = 0), "`n_predictors` must be")
  expect_error(simulate_regression(n_predictors = 1.5), "`n_predictors` must be")
  expect_error(simulate_anova(means = 1), "`means` must be NULL or")
  expect_error(simulate_ttest(mean_a = NA_real_), "`mean_a` must be NULL or")
})

test_that("positional calls keep their 0.4.7 meaning", {
  coefficients <- c("(Intercept)" = 1, x1 = 0.5, x2 = -0.3)
  positional <- simulate_regression(50, coefficients, 0, 1, NULL, 1, "outcome", 11)
  named <- simulate_regression(n = 50, coefficients = coefficients, seed = 11)
  expect_identical(as.data.frame(positional), as.data.frame(named))
})

test_that("grouped TNA edge tables are numbered 1 to n", {
  skip_if_not_installed("tna")
  fitted <- simulate_group_tna(groups = 2, actors = 5, chain_length = 5, n_states = 2, seed = 1)
  edges <- as.data.frame(fitted, what = "estimated_edges")
  expect_identical(rownames(edges), as.character(seq_len(nrow(edges))))
})

test_that("simulate_tna_batches() simulates one network directly and recovers it", {
  skip_if_not_installed("tna")
  network <- simulate_tna_batches(seed = 1)
  edges <- as.data.frame(network)
  expect_identical(unique(edges$dataset), 1L)
  expect_identical(rownames(edges), as.character(seq_len(nrow(edges))))
  recovery <- validate_recovery(network, network, term = "to", estimate = "weight")
  expect_identical(nrow(recovery), nrow(edges))
  expect_false(anyNA(recovery$truth))
  truth <- as.data.frame(network, what = "true_transitions")
  expect_setequal(recovery$truth, truth$probability)
})

test_that("drawn states carry learning-state labels, shared across groups", {
  catalogue <- learning_states(c("metacognitive", "cognitive"))$state
  sequences <- simulate_sequences(seed = 1)
  expect_true(all(unique(sequences$state) %in% catalogue))
  expect_true(all(generate_transition_system(seed = 1)$from %in% catalogue))
  grouped <- simulate_group_sequences(seed = 1)
  truth <- as.data.frame(grouped, what = "transitions")
  states_by_group <- lapply(split(truth$from, truth$group), function(x) sort(unique(x)))
  expect_identical(states_by_group[[1]], states_by_group[[2]])
  expect_true(all(states_by_group[[1]] %in% catalogue))
  generic <- simulate_sequences(state_categories = NULL, seed = 1)
  expect_true(all(unique(generic$state) %in% sprintf("State %d", 1:5)))
})
