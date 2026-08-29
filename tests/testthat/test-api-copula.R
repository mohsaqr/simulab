test_that("copula marginals and latent dependence are calibrated", {
  specification <- define_variables(
    define_variable("normal", 2, 4, "normal"),
    define_variable("count", 3, distribution = "poisson"),
    define_variable("flag", 0.3, distribution = "binary")
  )
  result <- simulate_copula(30000, specification, rho = 0.4,
                            structure = "exchangeable", seed = 1)
  expect_equal(mean(result$normal), 2, tolerance = 0.04)
  expect_equal(stats::sd(result$normal), 2, tolerance = 0.04)
  expect_equal(mean(result$count), 3, tolerance = 0.04)
  expect_equal(mean(result$flag), 0.3, tolerance = 0.01)
  augmented <- augment_correlated(data.frame(id = 1:50), specification[1:2, ],
                                  rho = 0.2, structure = "exchangeable", seed = 2)
  expect_equal(nrow(augmented), 50L)
})

test_that("unified catalogue dispatches and recovery validation is tidy", {
  catalogue <- list_simulators()
  expect_true(all(c("study", "lpa", "network") %in% catalogue$simulator))
  result <- simulate_data("ttest", n_a = 10, n_b = 10, mean_a = 0, mean_b = 1,
                          seed = 3)
  expect_s3_class(result, "simulab_sim")
  recovery <- validate_recovery(
    data.frame(term = c("a", "b"), estimate = c(1.01, 1.8)),
    data.frame(term = c("a", "b"), truth = c(1, 2)), tolerance = 0.1
  )
  expect_equal(recovery$recovered, c(TRUE, FALSE))
  factorial <- augment_factorial(data.frame(id = 1:3), c(a = 2, b = 2))
  expect_equal(nrow(factorial), 12L)
  scenarios <- scenario_grid(mean_b = c(0, 1), replications = 2)
  batch <- simulate_scenarios(
    scenarios, "ttest", n_a = 5, n_b = 5, mean_a = 0, seed = 10
  )
  expect_equal(nrow(batch), 40L)
  expect_equal(nrow(as.data.frame(batch, what = "scenarios")), 4L)
})
