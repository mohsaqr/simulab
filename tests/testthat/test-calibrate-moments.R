# Moment inversion. Every calibration is checked by integrating the quantile
# function it produced, which is independent of the algebra that produced it:
# mean = integral of Q(p) dp and E[X^2] likewise over (0, 1). A sampling check
# cannot do this job, because the sample variance of a heavy tail is still per
# cent-accurate at half a million draws.

moments_by_integration <- function(distribution, solved) {
  quantile_function <- .simulab_registry[[distribution]]$quantile
  parameters <- as.list(stats::setNames(solved$value, solved$parameter))
  quantile_at <- function(p) do.call(quantile_function, c(list(p), parameters))
  first <- stats::integrate(quantile_at, 0, 1,
                            subdivisions = 4000L, rel.tol = 1e-10)$value
  second <- stats::integrate(function(p) quantile_at(p)^2, 0, 1,
                             subdivisions = 4000L, rel.tol = 1e-10)$value
  c(mean = first, variance = second - first^2)
}

expect_moments <- function(distribution, mean, variance = NULL) {
  solved <- calibrate_moments(distribution, mean = mean, variance = variance)
  attained <- moments_by_integration(distribution, solved)
  expect_equal(attained[["mean"]], solved$mean[1L], tolerance = 1e-6)
  expect_equal(attained[["variance"]], solved$variance[1L], tolerance = 1e-6)
}

test_that("two-parameter families attain the mean and variance asked for", {
  expect_moments("normal", 10, 4)
  expect_moments("lognormal", 10, 25)
  expect_moments("gamma", 6, 9)
  expect_moments("inv_gamma", 4, 3)
  expect_moments("beta", 0.4, 0.02)
  expect_moments("beta_prime", 2, 5)
  expect_moments("pareto", 5, 40)
  expect_moments("weibull", 8, 9)
  expect_moments("gumbel", 2, 6)
  expect_moments("laplace", 1, 8)
  expect_moments("logistic", 3, 5)
  expect_moments("uniform", 0, 12)
})

test_that("scale families with a shape solved from the coefficient of variation attain both", {
  # The shape of each is found numerically from variance / mean^2, which does
  # not depend on the scale, and the scale then follows in closed form.
  expect_moments("weibull", 8, 9)
  expect_moments("log_logistic", 6, 9)
  expect_moments("frechet", 4, 6)
  expect_moments("nakagami", 2, 0.5)
  expect_moments("lomax", 4, 30)
  expect_moments("power", 3, 0.4)
})

test_that("location-scale families added attain the mean and variance asked for", {
  expect_moments("arcsine", 5, 2)
  expect_moments("hyperbolic_secant", 2, 9)
  expect_moments("anglit", 1, 0.4)
  expect_moments("moyal", 3, 20)
})

test_that("one-parameter families attain the mean and report the variance it fixes", {
  expect_moments("exponential", 2.5)
  expect_moments("chisq", 7)
  expect_moments("rayleigh", 3)
  expect_moments("half_normal", 2)
  expect_moments("half_logistic", 5)
  expect_moments("maxwell", 3)
  expect_moments("chi", 4)
})

test_that("families with no quantile function still calibrate, checked by drawing", {
  # semicircular, skellam and the zero-truncated Poisson have no closed-form
  # inverse CDF, so integration cannot check them.
  drawn <- function(distribution, mean, variance = NULL) {
    solved <- calibrate_moments(distribution, mean = mean, variance = variance)
    arguments <- paste(sprintf("%s = %.12g", solved$parameter, solved$value),
                       collapse = ", ")
    specification <- eval(str2lang(sprintf("define_variables(y = %s(%s))",
                                           distribution, arguments)))
    values <- as.data.frame(simulate_study(500000, specification, seed = 5))$y
    max(abs(mean(values) - solved$mean[1L]) / max(abs(solved$mean[1L]), 1),
        abs(stats::var(values) - solved$variance[1L]) / solved$variance[1L])
  }
  errors <- c(drawn("semicircular", 5, 1), drawn("skellam", 4, 9),
              drawn("zero_truncated_poisson", 2.5))
  expect_lt(max(errors), 0.01)
})

test_that("bounded families refuse moments outside the bound", {
  # A Nakagami squared coefficient of variation is at most pi/2 - 1, reached at
  # shape 0.5; a Lomax with a finite variance always has one above 1.
  expect_error(calibrate_moments("nakagami", mean = 2, variance = 4),
               class = "simulab_unattainable_moments")
  expect_error(calibrate_moments("lomax", mean = 4, variance = 4),
               class = "simulab_unattainable_moments")
  # A Skellam variance is the sum of two rates and its mean their difference.
  expect_error(calibrate_moments("skellam", mean = 4, variance = 3),
               class = "simulab_unattainable_moments")
  # Just inside the Nakagami bound still solves.
  expect_s3_class(calibrate_moments("nakagami", mean = 2, variance = 4 * 0.56),
                  "data.frame")
})

test_that("a shape solve that cannot bracket a root is reported, not approximated", {
  # A zero-truncated Poisson mean is above one by construction.
  expect_error(calibrate_moments("zero_truncated_poisson", mean = 0.5),
               class = "simulab_no_solution")
})

test_that("discrete calibrations attain their moments when drawn", {
  # The discrete families have step quantile functions, so they are checked by
  # drawing rather than by integration.
  drawn <- function(distribution, mean, variance = NULL) {
    solved <- calibrate_moments(distribution, mean = mean, variance = variance)
    arguments <- paste(sprintf("%s = %.12g", solved$parameter, solved$value),
                       collapse = ", ")
    specification <- eval(str2lang(sprintf("define_variables(y = %s(%s))",
                                           distribution, arguments)))
    values <- as.data.frame(simulate_study(200000, specification, seed = 4))$y
    c(mean = mean(values), variance = stats::var(values),
      target_mean = solved$mean[1L], target_variance = solved$variance[1L])
  }
  checks <- list(drawn("poisson", 4), drawn("geometric", 3), drawn("binary", 0.35),
                 drawn("negative_binomial", 4, 9))
  errors <- vapply(checks, function(x)
    max(abs(x[["mean"]] - x[["target_mean"]]) / max(x[["target_mean"]], 1),
        abs(x[["variance"]] - x[["target_variance"]]) / x[["target_variance"]]),
    numeric(1))
  expect_lt(max(errors), 0.02)
})

test_that("the result is tidy and names the parameters a call would take", {
  solved <- calibrate_moments("lognormal", mean = 10, variance = 25)
  expect_named(solved, c("distribution", "mean", "variance", "parameter", "value"))
  # The parameter names are the ones a lognormal() call takes.
  expect_equal(solved$parameter, c("meanlog", "sdlog"))
  expect_equal(list_distributions("^lognormal$")$parameters, "meanlog, sdlog")
  expect_equal(nrow(solved), 2L)
})

test_that("targets recycle, one row per target and parameter", {
  solved <- calibrate_moments("gamma", mean = c(5, 10, 20), variance = 9)
  expect_equal(nrow(solved), 6L)
  expect_equal(solved$mean, rep(c(5, 10, 20), each = 2))
  expect_equal(solved$variance, rep(9, 6))
  expect_error(calibrate_moments("gamma", mean = c(1, 2), variance = c(1, 2, 3)),
               class = "simulab_incompatible_lengths")
})

test_that("moments no member of the family attains are refused", {
  # A beta variance is bounded above by mean * (1 - mean).
  expect_error(calibrate_moments("beta", mean = 0.4, variance = 0.25),
               class = "simulab_unattainable_moments")
  expect_error(calibrate_moments("beta", mean = 1.4, variance = 0.01),
               class = "simulab_unattainable_moments")
  # A negative binomial is overdispersed relative to a Poisson by definition.
  expect_error(calibrate_moments("negative_binomial", mean = 4, variance = 3),
               class = "simulab_unattainable_moments")
  expect_error(calibrate_moments("gamma", mean = -1, variance = 1),
               class = "simulab_unattainable_moments")
  expect_error(calibrate_moments("binary", mean = 1.5),
               class = "simulab_unattainable_moments")
})

test_that("the number of targets must match the number of parameters", {
  expect_error(calibrate_moments("gamma", mean = 4),
               class = "simulab_no_moment_solution")
  expect_error(calibrate_moments("poisson", mean = 4, variance = 4),
               class = "simulab_no_moment_solution")
  expect_error(calibrate_moments("cauchy", mean = 0, variance = 1),
               class = "simulab_no_moment_solution")
})

test_that("calibrate_moments with no arguments reports what it can invert", {
  catalogue <- calibrate_moments()
  expect_named(catalogue, c("distribution", "parameters", "targets"))
  expect_true(nrow(catalogue) >= 35L)
  # Every distribution it claims is registered, and its parameter names agree.
  expect_equal(setdiff(catalogue$distribution, list_distributions()$distribution),
               character(0))
})

test_that("calibrate_distribution returns one row per parameter", {
  solved <- calibrate_distribution("beta", mean = 0.4, dispersion = 8)
  expect_named(solved, c("distribution", "mean", "dispersion", "parameter", "value"))
  expect_equal(solved$parameter, c("shape1", "shape2"))
  expect_equal(solved$value, c(3.2, 4.8))
  expect_equal(nrow(calibrate_distribution("gamma", mean = c(5, 10),
                                           dispersion = 0.5)), 4L)
  expect_error(calibrate_distribution("gamma", mean = c(1, 2), dispersion = c(1, 2, 3)),
               class = "simulab_incompatible_lengths")
})

test_that("the mean/dispersion and mean/variance parameterizations agree", {
  # A gamma with dispersion d has variance d * mean^2, so the two verbs must
  # solve to the same shape and rate.
  by_dispersion <- calibrate_distribution("gamma", mean = 10, dispersion = 0.5)
  by_moments <- calibrate_moments("gamma", mean = 10, variance = 0.5 * 100)
  expect_equal(by_moments$value, by_dispersion$value)
  expect_equal(by_moments$parameter, by_dispersion$parameter)
})
