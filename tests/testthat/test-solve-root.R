test_that(".solve_root returns an accurate root", {
  root <- simulab:::.solve_root(function(x) x - 0.3, c(-1, 1), what = "a test root")
  expect_equal(root, 0.3, tolerance = 1e-10)
})

test_that(".solve_root refuses a bracket that contains no root", {
  expect_error(
    simulab:::.solve_root(function(x) x^2 + 1, c(-1, 1), what = "a test root"),
    class = "simulab_no_solution"
  )
})

test_that(".solve_root refuses a non-finite objective at the bounds", {
  expect_error(
    simulab:::.solve_root(function(x) 1 / x - 1, c(0, 1), what = "a test root"),
    class = "simulab_no_solution"
  )
})

test_that(".solve_root refuses a root found before convergence", {
  # One iteration cannot bracket this root, so the residual stays far outside
  # tolerance and the unconverged value must not be returned.
  expect_error(
    simulab:::.solve_root(function(x) x - 0.3, c(-1e6, 1e6),
                          what = "a test root", maxiter = 1L),
    class = "simulab_no_convergence"
  )
})

test_that("the error names the quantity being solved for", {
  expect_error(
    simulab:::.solve_root(function(x) x^2 + 1, c(-1, 1),
                          what = "the calibrated intercept"),
    regexp = "the calibrated intercept"
  )
})

test_that("calibrated censoring hits its target", {
  result <- simulate_proportional_survival(
    n = 4000, coefficients = c(x1 = 0.5), censoring = 0.3, seed = 2
  )
  # Monte Carlo SE of an event proportion at n = 4000 is about 0.0072.
  expect_lt(abs(mean(as.data.frame(result)$status) - 0.7), 0.03)
})

test_that("calibrated missingness hits its target", {
  data <- data.frame(id = seq_len(4000), x = stats::rnorm(4000),
                     y = stats::rnorm(4000))
  result <- inject_missingness(
    data, mechanism = "MAR", proportion = 0.3,
    variables = "y", predictor = "x", seed = 4
  )
  # expect_equal tolerance is relative; assert the absolute deviation instead.
  # Monte Carlo SE at n = 4000 is about 0.0072, so 0.03 is roughly 4 SE.
  expect_lt(abs(mean(is.na(as.data.frame(result)$y)) - 0.3), 0.03)
})

test_that("calibrate_logistic reaches every calibration target", {
  set.seed(1)
  covariates <- data.frame(x1 = stats::rnorm(500), x2 = stats::rnorm(500))
  design <- as.matrix(covariates)

  fitted <- calibrate_logistic(
    covariates, coefficients = c(x1 = 0.5, x2 = -0.3), prevalence = 0.2
  )
  score <- as.vector(design %*% c(0.5, -0.3))
  intercept <- fitted$coefficient[fitted$term == "(Intercept)"]
  expect_equal(mean(stats::plogis(intercept + score)), 0.2, tolerance = 1e-8)

  scaled <- calibrate_logistic(
    covariates, coefficients = c(x1 = 0.5, x2 = -0.3),
    prevalence = 0.2, auc = 0.75
  )
  expect_gt(scaled$coefficient_scale[1L], 1)
})

test_that("an unattainable risk difference is refused, not approximated", {
  set.seed(1)
  covariates <- data.frame(x1 = stats::rnorm(200))
  expect_error(
    calibrate_logistic(
      covariates, coefficients = c(x1 = 0.5), prevalence = 0.2,
      risk_difference = 0.9, treatment = "trt", treatment_prevalence = 0.5
    ),
    class = "simulab_no_solution"
  )
})
