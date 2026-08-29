test_that("definitions combine, repeat, and update", {
  specification <- define_variables(
    define_variable("x", 0, 1, "normal"),
    repeat_variables(2, "item", 0.5, distribution = "binary")
  )

  expect_s3_class(specification, "simulab_spec")
  expect_equal(nrow(specification), 3L)
  expect_equal(specification$variable, c("x", "item1", "item2"))

  updated <- update_definition(specification, "x", formula = 5, variance = 4)
  expect_equal(updated$formula, c("5", "0.5", "0.5"))
  expect_equal(updated$variance, c("4", "0", "0"))
})

test_that("invalid definitions fail early", {
  expect_error(define_variable("x", 0, distribution = "unknown"))
  expect_error(
    define_variables(
      define_variable("x", 0),
      define_variable("x", 1)
    ),
    "unique"
  )
})

