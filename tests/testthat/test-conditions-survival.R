test_that("conditional rules apply sequentially and return their definitions", {
  source <- data.frame(id = 1:6, group = rep(c("A", "B"), each = 3))
  rules <- define_conditions(
    define_condition("score", "group == 'A'", 10, distribution = "deterministic"),
    define_condition("score", "group == 'B'", 20, distribution = "deterministic")
  )
  result <- apply_conditions(source, rules, seed = 8)
  expect_s3_class(result, "simulab_sim")
  expect_equal(result$score, rep(c(10, 20), each = 3))
  expect_equal(nrow(as.data.frame(result, what = "conditions")), 2L)
})

test_that("survival generation is calibrated and competing risks are tidy", {
  specification <- define_survivals(
    define_survival("event_a", formula = 0, scale = 2, shape = 1),
    define_survival("event_b", formula = -0.5, scale = 2, shape = 1),
    define_survival("censor", formula = -1, scale = 2, shape = 1)
  )
  result <- simulate_survival(20000, specification, seed = 10)
  expect_equal(mean(result$event_a), 2, tolerance = 0.05)
  combined <- combine_competing_risks(result, c("event_a", "event_b", "censor"),
                                      censor = "censor")
  expect_true(all(combined$event %in% 0:2))
  expect_equal(nrow(as.data.frame(combined, what = "events")), 3L)

  piecewise <- define_survivals(
    define_survival("event", 0, transition = 0),
    define_survival("event", 1, transition = 2)
  )
  expect_s3_class(augment_survival(data.frame(id = 1:10), piecewise, seed = 1),
                  "simulab_sim")
  calibrated <- calibrate_survival(c(1, 2, 4), exp(-c(1, 2, 4)))
  expect_lt(calibrated$rmse, 1e-5)
  expect_equal(nrow(survival_curve(0, 1, n = 25)), 25L)
})
