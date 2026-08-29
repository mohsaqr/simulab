test_that("correlation structures are tidy and valid", {
  exchangeable <- correlation_structure(4, rho = 0.3, structure = "exchangeable")
  ar1 <- correlation_structure(4, rho = 0.5, structure = "ar1")

  expect_s3_class(exchangeable, "data.frame")
  expect_equal(nrow(exchangeable), 16L)
  expect_equal(unique(exchangeable$correlation), c(1, 0.3))
  expect_equal(nrow(ar1), 16L)
  expect_error(correlation_structure(4, rho = -0.9, structure = "exchangeable"))
})

test_that("correlated Gaussian data recover means, deviations, and correlations", {
  result <- simulate_correlated(
    n = 50000,
    means = c(x = 1, y = 3, z = -2),
    sds = c(1, 2, 0.5),
    rho = 0.4,
    structure = "exchangeable",
    seed = 13
  )

  expect_equal(colMeans(result[, c("x", "y", "z")]),
               c(x = 1, y = 3, z = -2), tolerance = 0.025)
  expect_equal(vapply(result[, c("x", "y", "z")], stats::sd, numeric(1)),
               c(x = 1, y = 2, z = 0.5), tolerance = 0.025)
  observed <- stats::cor(result[, c("x", "y", "z")])
  expect_equal(observed[lower.tri(observed)], rep(0.4, 3), tolerance = 0.02)
  expect_named(as.data.frame(result, what = "correlation"),
               c("row", "column", "correlation"))
})

test_that("ordinal probabilities and latent correlations are represented", {
  result <- simulate_ordinal(
    n = 30000,
    probabilities = c(0.2, 0.3, 0.5),
    n_variables = 2,
    rho = 0.4,
    structure = "exchangeable",
    labels = c("low", "medium", "high"),
    seed = 4
  )

  observed <- proportions(table(result$V1))
  expect_equal(as.numeric(observed), c(0.5, 0.2, 0.3), tolerance = 0.015)
  expect_equal(nrow(as.data.frame(result, what = "probabilities")), 6L)
})

test_that("block correlation covers cross-sectional and cohort structures", {
  cross_sectional <- block_correlation(
    n_individuals = 2,
    n_periods = 3,
    within_period = 0.3,
    between_period = 0.1
  )
  cohort <- block_correlation(
    n_individuals = 2,
    n_periods = 3,
    within_period = 0.3,
    between_period = 0.1,
    within_individual = 0.5,
    design = "cohort"
  )
  decay <- block_correlation(
    n_individuals = 2,
    n_periods = 3,
    within_period = 0.3,
    decay = 0.6,
    design = "cohort"
  )

  expect_equal(nrow(cross_sectional), 36L)
  expect_equal(nrow(cohort), 36L)
  expect_equal(nrow(decay), 36L)
  expect_true(0.5 %in% cohort$correlation)
  expect_true(0.6 %in% decay$correlation)
})
