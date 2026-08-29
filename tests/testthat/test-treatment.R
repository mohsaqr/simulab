test_that("balanced treatment assignment respects strata and ratios", {
  source <- data.frame(id = 1:120, stratum = rep(c("a", "b"), each = 60))
  result <- assign_treatment(
    source,
    groups = c("control", "active"),
    balanced = TRUE,
    strata = "stratum",
    ratios = c(1, 2),
    seed = 3
  )
  allocation <- as.data.frame(result, what = "allocation")

  expect_equal(nrow(result), 120L)
  expect_equal(allocation$observations[allocation$treatment == "control"], c(20L, 20L))
  expect_equal(allocation$observations[allocation$treatment == "active"], c(40L, 40L))
  expect_identical(result, assign_treatment(
    source,
    groups = c("control", "active"),
    balanced = TRUE,
    strata = "stratum",
    ratios = c(1, 2),
    seed = 3
  ))
})

test_that("observational treatment follows modeled probabilities", {
  source <- data.frame(id = 1:30000, x = stats::rnorm(30000))
  result <- observe_treatment(
    source,
    formulas = "-1 + x",
    link = "logit",
    labels = c("treated", "control"),
    seed = 2
  )

  expect_gt(mean(result$x[result$treatment == "treated"]),
            mean(result$x[result$treatment == "control"]))
  expect_equal(nrow(as.data.frame(result, what = "probabilities")), 60000L)
})

test_that("stepped-wedge assignment creates waves and transition lag", {
  source <- expand_periods(data.frame(cluster = 1:6), periods = 8, id = "cluster")
  result <- assign_stepped_wedge(
    source,
    cluster = "cluster",
    period = "period",
    waves = 3,
    wave_length = 2,
    start = 1,
    lag = 1,
    randomize = FALSE
  )
  schedule <- as.data.frame(result, what = "schedule")

  expect_equal(schedule$treatment_start, c(1, 1, 3, 3, 5, 5))
  expect_true(all(result$treatment %in% 0:1))
  expect_true(all(result$transition %in% 0:1))
})
