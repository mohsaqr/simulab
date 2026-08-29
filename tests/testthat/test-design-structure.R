test_that("cluster expansion preserves cluster data and sizes", {
  clusters <- data.frame(cluster = c("a", "b"), size = c(2L, 3L), effect = c(1, 2))
  result <- expand_clusters(clusters, cluster = "cluster", size = "size", unit = "person")

  expect_equal(nrow(result), 5L)
  expect_equal(result$cluster, c("a", "a", "b", "b", "b"))
  expect_equal(result$person, seq_len(5))
  expect_equal(nrow(as.data.frame(result, what = "clusters")), 2L)
})

test_that("period expansion handles fixed, irregular, and wide outcomes", {
  source <- data.frame(id = 1:2, y1 = c(1, 4), y2 = c(2, 5), y3 = c(3, 6))
  fixed <- expand_periods(source, periods = 3, id = "id")
  gathered <- expand_periods(
    source,
    period_values = c(0, 2, 5),
    id = "id",
    time_variables = c("y1", "y2", "y3"),
    value = "outcome"
  )
  irregular <- expand_periods(
    data.frame(id = 1:2, count = c(2, 3), mean_interval = c(2, 4)),
    periods = "count",
    id = "id",
    interval_mean = "mean_interval",
    interval_dispersion = 0.1,
    seed = 4
  )

  expect_equal(nrow(fixed), 6L)
  expect_equal(gathered$outcome, c(1, 2, 3, 4, 5, 6))
  expect_equal(nrow(irregular), 5L)
  expect_equal(irregular$time[c(1, 3)], c(0, 0))
})

test_that("factorial designs and encoders have predictable rows", {
  design <- factorial_design(c(A = 2, B = 3), replications = 2, coding = "level")
  factor_encoded <- encode_factors(design, variables = c("A", "B"), coding = "factor")
  dummy_encoded <- encode_factors(design, variables = "A", coding = "dummy")
  effect_encoded <- encode_factors(design, variables = "A", coding = "effect")

  expect_equal(nrow(design), 12L)
  expect_true(is.factor(factor_encoded$f_A))
  expect_true(all(c("f_A_1", "f_A_2") %in% names(dummy_encoded)))
  expect_equal(sort(unique(effect_encoded$f_A_1)), c(-1, 1))
})

test_that("scenario, merge, and selection verbs return tidy frames", {
  scenarios <- scenario_grid(n = c(50, 100), effect = c(0, 0.5), replications = 2)
  x <- data.frame(id = 1:3, x = 4:6)
  y <- data.frame(id = 2:4, y = 7:9)

  expect_equal(nrow(scenarios), 8L)
  expect_equal(nrow(merge_studies(x, y, by = "id", join = "inner")), 2L)
  expect_equal(nrow(merge_studies(x, y, by = "id", join = "full")), 4L)
  expect_named(select_variables(x, keep = c("id", "x")), c("id", "x"))
  expect_named(select_variables(x, drop = "x"), "id")
})

