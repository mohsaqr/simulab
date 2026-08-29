test_that("study engine is reproducible and restores caller RNG", {
  specification <- define_variables(
    define_variable("x", 0, 1, "normal"),
    define_variable("p", "x", distribution = "deterministic", link = "logit"),
    define_variable("y", "-1 + 0.5 * x", distribution = "binary", link = "logit")
  )

  set.seed(919)
  before <- .Random.seed
  first <- simulate_study(n = 100, specification = specification, seed = 7)
  after <- .Random.seed
  second <- simulate_study(n = 100, specification = specification, seed = 7)

  expect_identical(before, after)
  expect_identical(first, second)
  expect_true(all(first$p > 0 & first$p < 1))
})

test_that("core distributions recover their parameters", {
  specification <- define_variables(
    define_variable("normal", 5, 4, "normal"),
    define_variable("binary", 0.3, distribution = "binary"),
    define_variable("poisson", 3, distribution = "poisson"),
    define_variable("gamma", 4, 0.5, "gamma"),
    define_variable("beta", 0.4, 20, "beta"),
    define_variable("negative_binomial", 5, 0.2, "negative_binomial"),
    define_variable("uniform", "2;6", distribution = "uniform"),
    define_variable("uniform_integer", "2;6", distribution = "uniform_integer")
  )
  result <- simulate_study(n = 50000, specification = specification, seed = 5)

  expect_lt(abs(mean(result$normal) - 5), 0.04)
  expect_lt(abs(stats::var(result$normal) - 4), 0.08)
  expect_lt(abs(mean(result$binary) - 0.3), 0.01)
  expect_lt(abs(mean(result$poisson) - 3), 0.03)
  expect_lt(abs(mean(result$gamma) - 4), 0.06)
  expect_lt(abs(mean(result$beta) - 0.4), 0.01)
  expect_lt(abs(mean(result$negative_binomial) - 5), 0.08)
  expect_true(all(result$uniform >= 2 & result$uniform <= 6))
  expect_true(all(result$uniform_integer %in% 2:6))
})

test_that("categorical and mixture definitions are calibrated", {
  specification <- define_variables(
    define_variable("category", "0.2;0.3;0.5", "a;b;c", "categorical"),
    define_variable("a", 10, distribution = "deterministic"),
    define_variable("b", 20, distribution = "deterministic"),
    define_variable("mixed", "a | 0.25 + b | 0.75", distribution = "mixture")
  )
  result <- simulate_study(n = 30000, specification = specification, seed = 15)

  category_rates <- proportions(table(result$category))
  expect_equal(as.numeric(category_rates), c(0.2, 0.3, 0.5), tolerance = 0.015)
  expect_lt(abs(mean(result$mixed == 20) - 0.75), 0.015)
})

test_that("augment_study preserves existing observations", {
  source <- data.frame(id = 1:5, x = seq_len(5))
  result <- augment_study(
    data = source,
    specification = define_variable("y", "2 * x", distribution = "deterministic"),
    seed = 1
  )

  expect_equal(result$x, source$x)
  expect_equal(result$y, 2 * source$x)
})
