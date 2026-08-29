test_that("simulab_sim is a data frame with tidy accessors", {
  specification <- define_variables(
    define_variable("x", 0, 1, "normal"),
    define_variable("y", 0.5, distribution = "binary")
  )
  result <- simulate_study(n = 20, specification = specification, seed = 11)

  expect_s3_class(result, "simulab_sim")
  expect_s3_class(result, "data.frame")
  expect_s3_class(as.data.frame(result), "data.frame")
  expect_false(inherits(as.data.frame(result), "simulab_sim"))
  expect_named(as.data.frame(result, what = "definitions"),
               c("variable", "distribution", "formula", "variance", "link"))
  expect_named(components(result), c("table", "rows", "columns"))
  expect_error(as.data.frame(result, what = "absent"), "Unknown table")
})

test_that("summary returns one tidy row per variable", {
  result <- simulate_study(
    n = 10,
    specification = define_variable("x", 0, 1, "normal"),
    seed = 2
  )

  result_summary <- summary(result)
  expect_s3_class(result_summary, "data.frame")
  expect_equal(nrow(result_summary), 2L)
  expect_named(
    result_summary,
    c("variable", "class", "observations", "missing", "unique",
      "mean", "sd", "minimum", "maximum")
  )
})

