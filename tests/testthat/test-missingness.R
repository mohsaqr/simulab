test_that("MCAR, MAR, and MNAR hit calibrated targets", {
  source <- data.frame(
    id = seq_len(50000),
    predictor = stats::rnorm(50000),
    outcome = stats::rnorm(50000),
    second = stats::rnorm(50000)
  )
  mcar <- inject_missingness(source, "MCAR", 0.2, "outcome", seed = 1)
  mar <- inject_missingness(source, "MAR", 0.2, "outcome", predictor = "predictor", seed = 1)
  mnar <- inject_missingness(source, "MNAR", 0.2, "outcome", seed = 1)

  expect_lt(abs(mean(is.na(mcar$outcome)) - 0.2), 0.01)
  expect_lt(abs(mean(is.na(mar$outcome)) - 0.2), 0.01)
  expect_lt(abs(mean(is.na(mnar$outcome)) - 0.2), 0.01)
  expect_gt(mean(source$predictor[is.na(mar$outcome)]),
            mean(source$predictor[!is.na(mar$outcome)]))
  expect_gt(mean(source$outcome[is.na(mnar$outcome)]),
            mean(source$outcome[!is.na(mnar$outcome)]))
})

test_that("definition masks support baseline and monotone longitudinal missingness", {
  source <- data.frame(
    id = rep(1:100, each = 5),
    period = rep(0:4, times = 100),
    baseline = stats::rnorm(500),
    outcome = stats::rnorm(500)
  )
  specification <- define_missingnesses(
    define_missingness("baseline", 0.2, baseline = TRUE),
    define_missingness("outcome", 0.2, monotone = TRUE)
  )
  mask <- missingness_matrix(
    source,
    specification,
    id = "id",
    period = "period",
    seed = 4
  )
  observed <- observed_data(source, mask, id = c("id", "period"))

  baseline_by_id <- aggregate(mask$baseline, by = list(mask$id), FUN = function(x) length(unique(x)))
  monotone_by_id <- split(mask$outcome, mask$id)
  monotone_valid <- vapply(monotone_by_id, function(flag) {
    !any(diff(as.integer(flag)) < 0)
  }, logical(1))
  expect_true(all(baseline_by_id$x == 1L))
  expect_true(all(monotone_valid))
  expect_equal(is.na(observed$baseline), mask$baseline)
  expect_equal(is.na(observed$outcome), mask$outcome)
})
