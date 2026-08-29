# The column form is the tidy surface: one call, named arguments, one row per
# variable. The constructor form is kept for back compatibility and must stay
# equivalent.

test_that("the column form and the constructor form agree", {
  columns <- define_variables(
    variable     = c("age", "treated"),
    formula      = c("40", "0.5"),
    variance     = c("100", "0"),
    distribution = c("normal", "binary")
  )
  constructors <- define_variables(
    define_variable("age", formula = 40, variance = 100, distribution = "normal"),
    define_variable("treated", formula = 0.5, distribution = "binary")
  )
  expect_equal(as.data.frame(columns), as.data.frame(constructors))
})

test_that("a column given once is recycled", {
  specification <- define_variables(
    variable = c("x1", "x2", "x3"), formula = "0", variance = "1"
  )
  expect_equal(nrow(specification), 3L)
  expect_equal(unique(specification$variance), "1")
  expect_equal(unique(specification$distribution), "normal")
})

test_that("a column-specified study generates and recovers its formula", {
  specification <- define_variables(
    variable     = c("baseline", "treatment", "outcome"),
    formula      = c("0", "0.5", "0.4 * baseline + 0.8 * treatment"),
    variance     = c("1", "0", "1"),
    distribution = c("normal", "binary", "normal")
  )
  data <- as.data.frame(simulate_study(20000, specification, seed = 42))
  estimate <- coef(stats::lm(outcome ~ baseline + treatment, data = data))
  expect_lt(max(abs(unname(estimate) - c(0, 0.4, 0.8))), 0.05)
})

test_that("required columns are enforced", {
  expect_error(define_variables(variable = "a"),
               class = "simulab_incomplete_specification")
  expect_error(define_variables(formula = "0"),
               class = "simulab_incomplete_specification")
})

test_that("unknown columns and values are refused", {
  expect_error(define_variables(variable = "a", formula = "0", sd = "1"),
               class = "simulab_unknown_column")
  expect_error(define_variables(variable = "a", formula = "0", distribution = "wishart"),
               class = "simulab_unknown_distribution")
  expect_error(define_variables(variable = "a", formula = "0", link = "probit"),
               class = "simulab_unknown_link")
})

test_that("a column of the wrong length is refused", {
  expect_error(define_variables(variable = c("a", "b"), formula = c("0", "1", "2")),
               class = "simulab_column_length")
})

test_that("unnamed columns are refused", {
  expect_error(define_variables(c("a", "b")),
               class = "simulab_unnamed_specification")
})

test_that("the two forms cannot be mixed", {
  expect_error(
    define_variables(variable = "a", formula = "0", define_variable("b", formula = "0")),
    class = "simulab_mixed_specification"
  )
})

test_that("duplicate variables are refused in the column form", {
  expect_error(define_variables(variable = c("a", "a"), formula = "0"),
               class = "simulab_duplicate_variable")
})

test_that("define_survivals accepts columns and stays equivalent", {
  columns <- define_survivals(event = c("time_death", "time_relapse"),
                              formula = c(-9, -8), shape = 0.3)
  constructors <- define_survivals(
    define_survival("time_death", formula = -9, shape = 0.3),
    define_survival("time_relapse", formula = -8, shape = 0.3)
  )
  expect_equal(as.data.frame(columns), as.data.frame(constructors))
  expect_s3_class(simulate_survival(50, columns, seed = 1), "simulab_sim")
})

test_that("a piecewise hazard is expressible as two rows", {
  specification <- define_survivals(
    event = c("time", "time"), formula = c(-8, -6),
    shape = 0.3, transition = c(0, 50)
  )
  expect_equal(nrow(specification), 2L)
  expect_equal(specification$transition, c(0, 50))
})

test_that("a hazard not starting at transition zero is refused", {
  expect_error(
    define_survivals(event = c("time", "time"), formula = c(-8, -6),
                     transition = c(10, 50)),
    class = "simulab_bad_transition"
  )
})

test_that("define_missingnesses accepts columns and stays equivalent", {
  columns <- define_missingnesses(variable = c("baseline", "outcome"),
                                  formula = c("0.1", "0.2"))
  constructors <- define_missingnesses(
    define_missingness("baseline", formula = "0.1"),
    define_missingness("outcome", formula = "0.2")
  )
  expect_equal(as.data.frame(columns), as.data.frame(constructors))
})

test_that("logical missingness columns must be logical", {
  expect_error(
    define_missingnesses(variable = "a", formula = "0.2", monotone = "yes"),
    class = "simulab_column_type"
  )
})

test_that("define_conditions accepts columns and stays equivalent", {
  columns <- define_conditions(
    variable = c("outcome", "outcome"),
    condition = c("group == 1", "group == 0"),
    formula = c("2", "0"), variance = "1"
  )
  constructors <- define_conditions(
    define_condition("outcome", condition = "group == 1",
                     formula = "2", variance = "1", distribution = "normal"),
    define_condition("outcome", condition = "group == 0",
                     formula = "0", variance = "1", distribution = "normal")
  )
  expect_equal(as.data.frame(columns), as.data.frame(constructors))
})

test_that("column-specified conditions generate the requested group means", {
  specification <- define_conditions(
    variable = c("outcome", "outcome"),
    condition = c("group == 1", "group == 0"),
    formula = c("2", "0"), variance = "1"
  )
  data <- data.frame(id = seq_len(8000), group = rep(0:1, each = 4000))
  result <- as.data.frame(apply_conditions(data, specification, seed = 1))
  means <- unname(tapply(result$outcome, result$group, mean))
  expect_lt(max(abs(means - c(0, 2))), 0.05)
})
