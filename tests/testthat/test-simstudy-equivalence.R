test_that("core declarative distributions agree with simstudy 0.9.2", {
  skip_if_not_installed("simstudy", minimum_version = "0.9.2")

  reference <- simstudy::defData(
    varname = "normal", formula = 5, variance = 4, dist = "normal"
  )
  reference <- simstudy::defData(
    reference, varname = "binary", formula = 0.3, dist = "binary"
  )
  reference <- simstudy::defData(
    reference, varname = "gamma", formula = 3, variance = 0.4, dist = "gamma"
  )
  specification <- define_variables(
    define_variable("normal", 5, 4, "normal"),
    define_variable("binary", 0.3, distribution = "binary"),
    define_variable("gamma", 3, 0.4, "gamma")
  )

  set.seed(918)
  expected <- as.data.frame(simstudy::genData(100, reference))
  actual <- simulate_study(100, specification, seed = 918)
  expect_equal(actual$normal, expected$normal)
  expect_equal(actual$binary, expected$binary)
  expect_equal(actual$gamma, expected$gamma)
})

test_that("parameter conversions agree with simstudy 0.9.2", {
  skip_if_not_installed("simstudy", minimum_version = "0.9.2")

  # calibrate_distribution() reports one row per parameter, in the order
  # list_distributions() gives them, so each `value` column is compared whole.
  beta <- calibrate_distribution("beta", 0.3, 12)
  reference_beta <- simstudy::betaGetShapes(0.3, 12)
  expect_equal(beta$parameter, c("shape1", "shape2"))
  expect_equal(beta$value, c(reference_beta$shape1, reference_beta$shape2))

  gamma <- calibrate_distribution("gamma", 4, 0.25)
  reference_gamma <- simstudy::gammaGetShapeRate(4, 0.25)
  expect_equal(gamma$parameter, c("shape", "rate"))
  expect_equal(gamma$value, c(reference_gamma$shape, reference_gamma$rate))

  negative_binomial <- calibrate_distribution("negative_binomial", 8, 0.5)
  reference_nb <- simstudy::negbinomGetSizeProb(8, 0.5)
  expect_equal(negative_binomial$parameter, c("size", "prob"))
  expect_equal(negative_binomial$value, c(reference_nb$size, reference_nb$prob))
})
