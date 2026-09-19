.generator_long_form <- function(matrix, row, column, value) {
  grid <- expand.grid(row_index = seq_len(nrow(matrix)),
                      column_index = seq_len(ncol(matrix)))
  result <- data.frame(
    rownames(matrix)[grid$row_index],
    colnames(matrix)[grid$column_index],
    matrix[cbind(grid$row_index, grid$column_index)],
    stringsAsFactors = FALSE
  )
  names(result) <- c(row, column, value)
  result
}

test_that("multiplex generation covers probabilistic layers and rejects malformed controls", {
  probabilistic <- simulate_multiplex_network(
    nodes = 5, layers = 2, probability = c(0, 1), directed = FALSE, seed = 401
  )
  expect_equal(unique(probabilistic$layer), "Layer 2")
  expect_equal(nrow(probabilistic), choose(5, 2))

  expect_error(simulate_multiplex_network(4, layers = 1), "at least two")
  expect_error(simulate_multiplex_network(4, layers = c("x", "x")), "unique")
  expect_error(simulate_multiplex_network(4, layers = c("x", "y"),
                                          probability = c(0.2, 0.3, 0.4)),
               "probability must be scalar")
  expect_error(simulate_multiplex_network(4, layers = c("x", "y"), edges = 1.5),
               "non-negative integer")
})

test_that("prediction generation covers continuous-only and tidy categorical inputs", {
  continuous <- simulate_prediction(
    200, c("(Intercept)" = 1, x = 0.5), predictor_means = 2,
    predictor_sds = 0.5, seed = 410
  )
  expect_s3_class(continuous, "simulab_sim")
  expect_equal(names(continuous), c("id", "x", "outcome"))

  categories <- data.frame(
    variable = c("group", "group"), level = c("control", "treatment"),
    effect = c(0, 2), probability = c(0.25, 0.75)
  )
  categorical <- simulate_prediction(
    4000, c("(Intercept)" = 1), categorical_levels = categories,
    error_sd = 0.2, seed = 411
  )
  expect_equal(mean(categorical$group == "treatment"), 0.75, tolerance = 0.02)
  expect_equal(unname(diff(tapply(categorical$outcome, categorical$group, mean))),
               2, tolerance = 0.03)

  expect_error(simulate_prediction(10, c(x = 1), categorical_levels = list(c("a", "b")),
                                   categorical_effects = list(c(0, 1))),
               "named list")
  expect_error(simulate_prediction(10, c(x = 1),
                                   categorical_levels = list(g = c("a", "b")),
                                   categorical_effects = list(g = c(0, 1)),
                                   category_probabilities = list(g = c(0.2, 0.2))),
               "sum to one")
})

test_that("ordinal generation handles variable-specific probabilities and custom correlation", {
  probabilities <- matrix(c(0.7, 0.2, 0.1, 0.1, 0.3, 0.6), nrow = 2,
                          byrow = TRUE)
  correlation <- data.frame(
    row = c("first", "first", "second", "second"),
    column = c("first", "second", "first", "second"),
    correlation = c(1, 0.35, 0.35, 1)
  )
  result <- simulate_ordinal(
    10000, probabilities, correlation = correlation,
    labels = c("low", "middle", "high"),
    variable_names = c("first", "second"), seed = 420
  )
  observed <- proportions(table(result$first))[c("low", "middle", "high")]
  expect_equal(as.vector(observed), c(0.7, 0.2, 0.1), tolerance = 0.02)
  expect_equal(nrow(as.data.frame(result, what = "correlation")), 4L)

  one <- simulate_ordinal(20, c(0.4, 0.6), labels = c("a", "b"), seed = 421)
  expect_equal(names(one), c("id", "V1"))
  expect_error(simulate_ordinal(10, c(0.2, 0.2)), "sum to one")
  expect_error(simulate_ordinal(10, c(0.5, 0.5), labels = "only"),
               "one value per ordinal category")
  expect_error(simulate_ordinal(10, c(0.5, 0.5), n_variables = 2,
                                variable_names = c("same", "same")),
               "one unique name")
})

test_that("cluster generation supports each documented standard-deviation shape", {
  centers <- matrix(c(0, 0, 3, 3), 2, byrow = TRUE,
                    dimnames = list(c("a", "b"), c("x", "y")))
  per_variable <- simulate_clusters(1000, centers, sds = c(0.5, 1.5),
                                    labels = c("low", "high"), seed = 430)
  parameters <- as.data.frame(per_variable, what = "parameters")
  expect_equal(unique(parameters$sd[parameters$variable == "x"]), 0.5)
  expect_equal(unique(parameters$sd[parameters$variable == "y"]), 1.5)

  sd_matrix <- matrix(c(0.5, 1, 1.5, 2), 2, byrow = TRUE,
                      dimnames = dimnames(centers))
  matrix_result <- simulate_clusters(40, centers, sds = sd_matrix, seed = 431)
  expect_equal(as.data.frame(matrix_result, what = "parameters")$sd,
               as.vector(sd_matrix))

  tidy_sds <- .generator_long_form(sd_matrix, "cluster", "variable", "sd")
  expect_equal(
    as.data.frame(simulate_clusters(40, centers, sds = sd_matrix, seed = 432)),
    as.data.frame(simulate_clusters(40, centers, sds = tidy_sds, seed = 432))
  )
  expect_error(simulate_clusters(10, centers, proportions = c(1, 0)),
               "positive value")
  expect_error(simulate_clusters(10, centers, labels = c("x", "x")),
               "unique value")
  expect_error(simulate_clusters(10, centers, sds = 1:3),
               "scalar, per-variable")
  expect_error(simulate_clusters(10, centers, sds = -1), "must be positive")
})

test_that("latent-profile generation supports heterogeneous spread and correlation", {
  means <- matrix(c(0, 0, 3, 3), 2, byrow = TRUE,
                  dimnames = list(c("p1", "p2"), c("x", "y")))
  sds <- matrix(c(0.5, 1, 1.5, 2), 2, byrow = TRUE,
                dimnames = dimnames(means))
  correlations <- list(
    matrix(c(1, 0.4, 0.4, 1), 2),
    matrix(c(1, -0.3, -0.3, 1), 2)
  )
  result <- simulate_lpa(
    6000, means, sds = sds, proportions = c(0.5, 0.5),
    correlations = correlations, labels = c("first", "second"), seed = 440
  )
  parameters <- as.data.frame(result, what = "parameters")
  expect_equal(parameters$sd, as.vector(sds))
  observed <- split(result[c("x", "y")], result$profile)
  expect_equal(stats::cor(observed$first$x, observed$first$y), 0.4, tolerance = 0.04)
  expect_equal(stats::cor(observed$second$x, observed$second$y), -0.3, tolerance = 0.04)

  tidy_sds <- .generator_long_form(sds, "profile", "variable", "sd")
  expect_equal(
    as.data.frame(simulate_lpa(50, means, sds = sds, seed = 441)),
    as.data.frame(simulate_lpa(50, means, sds = tidy_sds, seed = 441))
  )
  expect_error(simulate_lpa(10, means, labels = c("x", "x")), "unique value")
  expect_error(simulate_lpa(10, means, sds = 1:3), "scalar, per-variable")
  expect_error(simulate_lpa(10, means, correlations = list(diag(2))),
               "one matrix per profile")
  expect_error(simulate_lpa(10, means, correlations = list(diag(3), diag(3))),
               "must match the variables")
})
