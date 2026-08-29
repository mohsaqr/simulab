test_that("statistical design simulators recover their population targets", {
  ttest <- simulate_ttest(20000, 20000, 0, 0.5, seed = 1)
  expect_equal(as.vector(diff(tapply(ttest$outcome, ttest$group, mean))), 0.5,
               tolerance = 0.03)
  anova <- simulate_anova(10000, c(0, 0.5, 1), seed = 2)
  expect_equal(as.vector(tapply(anova$outcome, anova$group, mean)), c(0, 0.5, 1),
               tolerance = 0.04)
  regression <- simulate_regression(30000, c("(Intercept)" = 1, x = 2), seed = 3)
  fit <- stats::coef(stats::lm(outcome ~ x, regression))
  expect_equal(unname(fit), c(1, 2), tolerance = 0.03)
  clusters <- simulate_clusters(1000, matrix(c(0, 3, 0, 3), 2L, byrow = TRUE), seed = 4)
  expect_equal(nrow(clusters), 1000L)
  correlation <- simulate_correlation(20000, means = c(0, 0), rho = 0.6,
                                      structure = "exchangeable", seed = 5)
  expect_equal(stats::cor(correlation$V1, correlation$V2), 0.6, tolerance = 0.03)
})

test_that("empirical, formula, spline, and calibration helpers are coherent", {
  source <- data.frame(id = 1:20, x = seq(-1, 1, length.out = 20), y = 1:20)
  synthetic <- simulate_synthetic(source, 50, seed = 1)
  expect_equal(nrow(synthetic), 50L)
  expect_equal(nrow(augment_synthetic(data.frame(id = 1:10), source, "x", seed = 2)), 10L)
  density <- simulate_density(1000, source$x, seed = 3)
  expect_equal(nrow(density), 1000L)
  expect_equal(nrow(augment_density(data.frame(id = 1:10), source$x, "z", seed = 4)), 10L)

  expect_s3_class(linear_formula(c(1, 2), "x"), "simulab_formula")
  expect_s3_class(mixture_formula(c("x", "y")), "simulab_formula")
  expect_s3_class(categorical_formula(categories = 3), "simulab_formula")
  expect_equal(length(unique(spline_basis(n = 20)$basis)), 7L)
  expect_equal(length(unique(spline_curves(rep(1, 7), n = 20)$curve)), 1L)
  spline <- simulate_spline(source, "x", "curve", rep(1, 7), seed = 5)
  expect_equal(nrow(spline), 20L)

  beta <- calibrate_distribution("beta", 0.25, 20)
  expect_equal(beta$value, c(5, 15))
  expect_equal(calibrate_icc(0.2, "binary")$random_effect_variance,
               (0.2 / 0.8) * pi^2 / 3)
  logistic <- calibrate_logistic(source, c(x = 1), prevalence = 0.3)
  probabilities <- stats::plogis(logistic$coefficient[logistic$term == "(Intercept)"] + source$x)
  expect_equal(mean(probabilities), 0.3, tolerance = 1e-7)
  auc_calibration <- calibrate_logistic(source, c(x = 1), prevalence = 0.3, auc = 0.7)
  expect_true(all(is.finite(auc_calibration$coefficient)))
  expect_s3_class(scenario_grid(a = 1:2, b = c("x", "y"), replications = 2), "data.frame")
})
