# A secondary input (standard deviations, a correlation, emission rows, ...)
# describes things its primary input already names. It must be matched by
# name: permuting its rows, or the rows of a named matrix or vector, may not
# change the result. Before this was enforced, a differently ordered table
# attached its values to the wrong profile, state or variable, and the truth
# tables reported the wrong values as the generating parameters.

.reverse_rows <- function(table) table[rev(seq_len(nrow(table))), , drop = FALSE]
.reverse_names <- function(x) x[rev(seq_along(x))]
.reverse_matrix <- function(x) {
  x[rev(seq_len(nrow(x))), rev(seq_len(ncol(x))), drop = FALSE]
}

.profile_means <- data.frame(
  profile = rep(c("low", "high"), each = 2),
  variable = rep(c("y1", "y2"), 2),
  mean = c(0, 0, 5, 5)
)
.profile_sds <- data.frame(
  profile = rep(c("low", "high"), each = 2),
  variable = rep(c("y1", "y2"), 2),
  sd = c(0.1, 0.2, 3, 4)
)

test_that("simulate_lpa() matches sds and correlations to profiles by name", {
  reference <- simulate_lpa(n = 60, means = .profile_means, sds = .profile_sds, seed = 1)
  expect_identical(
    simulate_lpa(n = 60, means = .profile_means, sds = .reverse_rows(.profile_sds), seed = 1),
    reference
  )
  expect_equal(
    as.data.frame(reference, what = "parameters")$sd,
    c(0.1, 3, 0.2, 4)
  )
  vector_reference <- simulate_lpa(n = 60, means = .profile_means,
                                   sds = c(y1 = 1, y2 = 2), seed = 1)
  expect_identical(
    simulate_lpa(n = 60, means = .profile_means, sds = c(y2 = 2, y1 = 1), seed = 1),
    vector_reference
  )
  correlations <- data.frame(
    profile = rep(c("low", "high"), each = 2),
    row = rep(c("y1", "y2"), 2), column = rep(c("y2", "y1"), 2),
    correlation = c(0.5, 0.5, -0.4, -0.4)
  )
  expect_identical(
    simulate_lpa(n = 60, means = .profile_means,
                 correlations = .reverse_rows(correlations), seed = 1),
    simulate_lpa(n = 60, means = .profile_means, correlations = correlations, seed = 1)
  )
})

test_that("simulate_ml_lpa() matches profile probabilities to profiles by name", {
  probabilities <- data.frame(
    cluster_class = rep(c("A", "B"), each = 2),
    profile = rep(c("low", "high"), 2),
    probability = c(0.9, 0.1, 0.2, 0.8)
  )
  reference <- simulate_ml_lpa(clusters = 6, cluster_size = 5, means = .profile_means,
                               profile_probabilities = probabilities, seed = 1)
  shuffled <- probabilities[c(2L, 1L, 4L, 3L), , drop = FALSE]
  expect_identical(
    simulate_ml_lpa(clusters = 6, cluster_size = 5, means = .profile_means,
                    profile_probabilities = shuffled, seed = 1),
    reference
  )
  table <- as.data.frame(reference, what = "profile_probabilities")
  expect_setequal(table$cluster_class, c("A", "B"))
  expect_equal(subset(table, cluster_class == "A" & profile == "low")$probability, 0.9)
})

test_that("simulate_clusters() matches sds to clusters by name", {
  centers <- data.frame(cluster = rep(c("c1", "c2"), each = 2),
                        variable = rep(c("x", "y"), 2), center = c(0, 0, 4, 4))
  sds <- data.frame(cluster = rep(c("c1", "c2"), each = 2),
                    variable = rep(c("x", "y"), 2), sd = c(0.1, 0.2, 2, 3))
  expect_identical(
    simulate_clusters(n = 40, centers = centers, sds = .reverse_rows(sds), seed = 1),
    simulate_clusters(n = 40, centers = centers, sds = sds, seed = 1)
  )
})

test_that("simulate_hmm() keeps self-transitions on the diagonal and matches emissions", {
  transition <- matrix(c(0.8, 0.2, 0.3, 0.7), 2, byrow = TRUE,
                       dimnames = list(c("x", "y"), c("x", "y")))
  emission <- matrix(c(0.95, 0.05, 0.1, 0.9), 2, byrow = TRUE,
                     dimnames = list(c("x", "y"), c("lo", "hi")))
  reference <- simulate_hmm(n = 20, transition = transition, chain_length = 6,
                            emission = emission, initial = c(x = 0.5, y = 0.5), seed = 1)
  # A tidy transition whose `to` column names states in another order than
  # its `from` column, and emissions listed with the second state first.
  tidy_transition <- data.frame(from = c("x", "x", "y", "y"), to = c("y", "x", "x", "y"),
                                probability = c(0.2, 0.8, 0.3, 0.7))
  tidy_emission <- data.frame(state = c("y", "y", "x", "x"), observation = c("hi", "lo", "hi", "lo"),
                              probability = c(0.9, 0.1, 0.05, 0.95))
  from_tables <- simulate_hmm(n = 20, transition = tidy_transition, chain_length = 6,
                              emission = tidy_emission, initial = c(y = 0.5, x = 0.5),
                              seed = 1)
  expect_identical(as.data.frame(from_tables, what = "transitions"),
                   as.data.frame(reference, what = "transitions"))
  expect_setequal(as.data.frame(from_tables, what = "emissions")$observation, c("lo", "hi"))
  expect_equal(
    subset(as.data.frame(from_tables, what = "emissions"), state == "x" & observation == "lo")$probability,
    0.95
  )
  expect_identical(unique(as.data.frame(reference)$state), c("x", "y")[unique(match(
    as.data.frame(reference)$state, c("x", "y")))])
})

test_that("simulate_irt() matches dimensions and discriminations to items by name", {
  difficulty <- c(a = -1, b = 0, c = 1)
  reference <- simulate_irt(n = 30, difficulty = difficulty,
                            discrimination = c(a = 0.5, b = 1, c = 2), seed = 1)
  expect_identical(
    simulate_irt(n = 30, difficulty = difficulty,
                 discrimination = c(c = 2, a = 0.5, b = 1), seed = 1),
    reference
  )
  expect_named(as.data.frame(reference), c("id", "a", "b", "c"))
  dimensions <- matrix(c(1, 0, 0, 1, 1, 1), 3, byrow = TRUE,
                       dimnames = list(c("a", "b", "c"), c("f1", "f2")))
  # Items (rows) follow `difficulty`; the dimensions (columns) are defined by
  # `dimensions` itself, so only the item order is permuted.
  expect_identical(
    simulate_irt(n = 30, difficulty = difficulty,
                 dimensions = dimensions[c("c", "a", "b"), , drop = FALSE], seed = 1),
    simulate_irt(n = 30, difficulty = difficulty, dimensions = dimensions, seed = 1)
  )
})

test_that("simulate_factors() matches the factor correlation and uniquenesses by name", {
  loadings <- matrix(c(0.8, 0.7, 0, 0, 0, 0, 0.6, 0.5), ncol = 2,
                     dimnames = list(c("i1", "i2", "i3", "i4"), c("f1", "f2")))
  correlation <- matrix(c(1, 0.3, 0.3, 1), 2, dimnames = list(c("f1", "f2"), c("f1", "f2")))
  uniquenesses <- c(i1 = 0.3, i2 = 0.4, i3 = 0.5, i4 = 0.6)
  expect_identical(
    simulate_factors(n = 30, loadings = loadings, factor_correlation = .reverse_matrix(correlation),
                     uniquenesses = .reverse_names(uniquenesses), seed = 1),
    simulate_factors(n = 30, loadings = loadings, factor_correlation = correlation,
                     uniquenesses = uniquenesses, seed = 1)
  )
})

test_that("simulate_regression() matches correlation and predictor sds by name", {
  coefficients <- c("(Intercept)" = 1, x1 = 0.5, x2 = -0.3, x3 = 0.2)
  correlation <- matrix(c(1, 0.6, 0, 0.6, 1, 0.2, 0, 0.2, 1), 3,
                        dimnames = list(c("x1", "x2", "x3"), c("x1", "x2", "x3")))
  reference <- simulate_regression(n = 30, coefficients = coefficients, correlation = correlation,
                                   predictor_sds = c(x1 = 1, x2 = 2, x3 = 3), seed = 1)
  expect_identical(
    simulate_regression(n = 30, coefficients = coefficients,
                        correlation = .reverse_matrix(correlation),
                        predictor_sds = c(x3 = 3, x1 = 1, x2 = 2), seed = 1),
    reference
  )
})

test_that("simulate_correlated(), simulate_ordinal() and simulate_copula() match correlations by name", {
  correlation <- matrix(c(1, 0.7, 0.1, 0.7, 1, 0.4, 0.1, 0.4, 1), 3,
                        dimnames = list(c("a", "b", "c"), c("a", "b", "c")))
  expect_identical(
    simulate_correlated(n = 30, means = c(a = 0, b = 0, c = 0), correlation = .reverse_matrix(correlation),
                        sds = c(c = 3, b = 2, a = 1), seed = 1),
    simulate_correlated(n = 30, means = c(a = 0, b = 0, c = 0), correlation = correlation,
                        sds = c(a = 1, b = 2, c = 3), seed = 1)
  )
  named_by_correlation <- simulate_correlated(n = 5, means = c(0, 0, 0), correlation = correlation, seed = 1)
  expect_named(as.data.frame(named_by_correlation), c("id", "a", "b", "c"))
  expect_identical(
    simulate_ordinal(n = 30, probabilities = c(0.3, 0.4, 0.3), n_variables = 3,
                     correlation = .reverse_matrix(correlation), variable_names = c("a", "b", "c"),
                     seed = 1),
    simulate_ordinal(n = 30, probabilities = c(0.3, 0.4, 0.3), n_variables = 3,
                     correlation = correlation, variable_names = c("a", "b", "c"), seed = 1)
  )
  specification <- define_variables(a = normal(0, 1), b = poisson(3), c = normal(5, 2))
  expect_identical(
    simulate_copula(n = 30, specification = specification,
                    correlation = .reverse_matrix(correlation), seed = 1),
    simulate_copula(n = 30, specification = specification, correlation = correlation, seed = 1)
  )
})

test_that("simulate_network() matches a named probability matrix to the nodes", {
  probability <- matrix(c(0, 0.9, 0.1, 0.9, 0, 0.1, 0.1, 0.1, 0), 3,
                        dimnames = list(c("n1", "n2", "n3"), c("n1", "n2", "n3")))
  expect_identical(
    simulate_network(nodes = c("n1", "n2", "n3"), probability = .reverse_matrix(probability), seed = 1),
    simulate_network(nodes = c("n1", "n2", "n3"), probability = probability, seed = 1)
  )
})

test_that("sequence simulators match named initial probabilities and grouped inputs", {
  transition <- matrix(c(0.7, 0.3, 0.4, 0.6), 2, byrow = TRUE,
                       dimnames = list(c("a", "b"), c("a", "b")))
  expect_identical(
    simulate_markov(n = 10, transition = transition, chain_length = 5,
                    initial = c(b = 0.9, a = 0.1), seed = 1),
    simulate_markov(n = 10, transition = transition, chain_length = 5,
                    initial = c(a = 0.1, b = 0.9), seed = 1)
  )
  expect_identical(
    simulate_sequences(n = 10, transition = transition, chain_length = 5,
                       initial = c(b = 0.9, a = 0.1), seed = 1),
    simulate_sequences(n = 10, transition = transition, chain_length = 5,
                       initial = c(a = 0.1, b = 0.9), seed = 1)
  )
  initial <- data.frame(group = rep(c("g1", "g2"), each = 2), state = rep(c("a", "b"), 2),
                        probability = c(1, 0, 0, 1))
  transitions <- list(g1 = transition, g2 = transition)
  grouped <- simulate_group_sequences(groups = 2, actors = 5, transitions = transitions,
                                      chain_length = 4, initial = .reverse_rows(initial), seed = 1)
  expect_identical(
    grouped,
    simulate_group_sequences(groups = 2, actors = 5, transitions = transitions,
                             chain_length = 4, initial = initial, seed = 1)
  )
  first_states <- subset(as.data.frame(grouped), period == 1)
  expect_setequal(subset(first_states, group == "g1")$state, "a")
  expect_setequal(subset(first_states, group == "g2")$state, "b")
  reordered <- transition[c("b", "a"), c("b", "a")]
  expect_identical(
    simulate_sequence_clusters(n = 10, transitions = list(k1 = transition, k2 = reordered),
                               chain_length = 5, seed = 1),
    simulate_sequence_clusters(n = 10, transitions = list(k1 = transition, k2 = transition),
                               chain_length = 5, seed = 1)
  )
})

test_that("simulate_longitudinal() matches covariances to the variables by name", {
  transition <- data.frame(from = c("m", "m", "s", "s"), to = c("m", "s", "m", "s"),
                           coefficient = c(0.5, -0.2, 0, 0.4))
  innovation <- matrix(c(1, 0.3, 0.3, 2), 2, dimnames = list(c("m", "s"), c("m", "s")))
  expect_identical(
    simulate_longitudinal(n = 3, occasions = 5, transition = transition,
                          innovation_covariance = .reverse_matrix(innovation),
                          grand_means = c(s = 10, m = 1), seed = 1),
    simulate_longitudinal(n = 3, occasions = 5, transition = transition,
                          innovation_covariance = innovation,
                          grand_means = c(m = 1, s = 10), seed = 1)
  )
})

test_that("a secondary input naming different things is a classed error", {
  wrong_sds <- data.frame(profile = rep(c("low", "top"), each = 2),
                          variable = rep(c("y1", "y2"), 2), sd = 1)
  expect_error(simulate_lpa(n = 20, means = .profile_means, sds = wrong_sds, seed = 1),
               class = "simulab_mismatched_names")
  expect_error(
    simulate_regression(n = 20, coefficients = c(x1 = 1, x2 = 1),
                        predictor_sds = c(x1 = 1, z = 2), seed = 1),
    class = "simulab_mismatched_names"
  )
})

test_that("labels come from the names given with the primary input", {
  probabilities <- array(c(0.2, 0.7, 0.8, 0.3), dim = c(2, 1, 2),
                         dimnames = list(c("engaged", "disengaged"), "attends", c("no", "yes")))
  lca <- simulate_lca(n = 30, probabilities = probabilities, seed = 1)
  expect_setequal(as.data.frame(lca)$latent_class, c("engaged", "disengaged"))
  expect_true(all(as.data.frame(lca)$attends %in% c("no", "yes")))
})
