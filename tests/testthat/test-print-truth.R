# Printing a result shows its generating values under the data, so the truth
# is visible without an accessor call.

test_that("print shows the truth table of a regression", {
  output <- capture.output(print(simulate_regression(n = 5, seed = 1)))
  expect_true("Truth (coefficients):" %in% output)
  expect_true(any(grepl("^Other tables: effects, predictor_correlation", output)))
})

test_that("print picks the truth table by precedence", {
  expect_identical(.truth_table_name(c("effects", "parameters")), "parameters")
  expect_identical(.truth_table_name(c("parameters", "coefficients")), "coefficients")
  expect_identical(.truth_table_name(c("wide", "true_transitions")), "true_transitions")
  expect_null(.truth_table_name(c("provenance")))
})

test_that("a result without generating values prints no truth section", {
  synthetic <- simulate_synthetic(data.frame(id = 1:5, x = c(1, 2, 3, 4, 5)), n = 3, seed = 1)
  output <- capture.output(print(synthetic))
  expect_false(any(grepl("^Truth", output)))
})

test_that("a long truth table is cut at 10 rows with a count", {
  output <- capture.output(print(simulate_sequences(n = 5, chain_length = 4, n_states = 4, seed = 1)))
  expect_true("Truth (transitions):" %in% output)
  expect_true("... 6 more rows" %in% output)
})

test_that("print output is stable", {
  expect_snapshot(print(simulate_regression(n = 3, seed = 1)))
})
