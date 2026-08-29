# The distribution-call lane reaching the simulators beyond simulate_study().
# Each simulator is checked against what its specification says it should
# produce, not merely for running.

test_that("augment_study generates a call specification into existing data", {
  base <- data.frame(id = seq_len(20000), treated = rep(0:1, each = 10000))
  result <- as.data.frame(augment_study(
    base,
    specification = define_variables(
      outcome = normal(mean = 3 + 2 * treated, sd = 1),
      visits  = poisson(lambda = exp(0.2 * outcome))
    ),
    seed = 2
  ))
  # A parameter may refer to a column that was already there, and to one
  # defined earlier in the same specification.
  expect_lt(max(abs(tapply(result$outcome, result$treated, mean) - c(3, 5))), 0.05)
  expect_lt(abs(mean(result$visits) - mean(exp(0.2 * result$outcome))), 0.05)
})

test_that("a parameter outside its distribution's support names the variable", {
  # rpois() returns NA and warns for a negative rate; the lane raises instead.
  expect_error(
    simulate_study(100, define_variables(x = normal(mean = 0, sd = 1),
                                         y = poisson(lambda = x)), seed = 1),
    class = "simulab_invalid_parameter"
  )
  # The message names the variable and the parameters that put it out of range.
  expect_error(
    simulate_study(100, define_variables(y = poisson(lambda = -1)), seed = 1),
    regexp = "`y` drew 100 missing values from `poisson`"
  )
})

test_that("augment_study refuses to overwrite a column that already exists", {
  base <- data.frame(id = 1:10, outcome = 0)
  expect_error(
    augment_study(base, define_variables(outcome = normal(mean = 0, sd = 1))),
    class = "simulab_existing_variable"
  )
})

test_that("augment_study on a bare identifier agrees with simulate_study", {
  specification <- define_variables(a = normal(0, 1), b = poisson(3))
  expect_equal(
    as.data.frame(augment_study(data.frame(id = 1:500), specification, seed = 5)),
    as.data.frame(simulate_study(500, specification, seed = 5))
  )
})

test_that("simulate_copula takes a call specification and keeps its marginals", {
  result <- as.data.frame(simulate_copula(
    n = 40000,
    specification = define_variables(
      score  = normal(mean = 10, sd = 2),
      visits = poisson(lambda = 4),
      rate   = beta(shape1 = 2, shape2 = 5)
    ),
    rho = 0.6, seed = 1
  ))
  expect_lt(abs(mean(result$score) - 10), 0.05)
  expect_lt(abs(mean(result$visits) - 4), 0.05)
  expect_lt(abs(mean(result$rate) - 2 / 7), 0.01)
  # A Gaussian copula attenuates the latent correlation through a discrete or
  # skewed margin, so the induced correlation is positive but below rho.
  induced <- stats::cor(result$score, result$visits)
  expect_gt(induced, 0.4)
  expect_lt(induced, 0.6)
})

test_that("simulate_copula accepts a distribution added as an inverse CDF", {
  result <- as.data.frame(simulate_copula(
    n = 40000,
    specification = define_variables(
      wait = log_logistic(shape = 3, scale = 2),
      size = gumbel(location = 0, scale = 2)
    ),
    rho = 0.5, seed = 3
  ))
  expect_lt(abs(mean(result$wait) - 2 * (pi / 3) / sin(pi / 3)), 0.05)
  expect_lt(abs(mean(result$size) - 2 * 0.5772156649), 0.05)
  expect_gt(stats::cor(result$wait, result$size), 0.4)
})

test_that("a marginal the column lane lacks is pointed at the call lane", {
  # `deterministic` is a column-lane distribution with no copula branch. The
  # call lane carries a quantile function for it, so the message says so.
  specification <- define_variables(
    variable = "x", formula = "1", variance = "0", distribution = "deterministic")
  expect_error(simulate_copula(50, specification, rho = 0.4),
               class = "simulab_no_quantile")
  expect_error(simulate_copula(50, specification, rho = 0.4),
               regexp = "distribution calls")
})

test_that("a conditional rule draws its own distribution for its own rows", {
  rules <- define_conditions(
    outcome = when(group == 1, normal(mean = 5, sd = 1)),
    outcome = when(group == 0, poisson(lambda = 2)),
    bonus   = when(group == 1, gamma(shape = 2, rate = 0.5))
  )
  expect_s3_class(rules, "simulab_condition_spec")
  data <- data.frame(id = seq_len(20000), group = rep(0:1, each = 10000))
  result <- as.data.frame(apply_conditions(data, rules, seed = 1))
  expect_lt(max(abs(tapply(result$outcome, result$group, mean) - c(2, 5))), 0.05)
  # A rule writes only the rows its condition selects; the rest stay missing.
  expect_equal(sum(is.na(result$bonus)), 10000L)
  expect_lt(abs(mean(result$bonus, na.rm = TRUE) - 4), 0.1)
})

test_that("later conditional rules replace values earlier rules wrote", {
  rules <- define_conditions(
    outcome = when(TRUE, deterministic(value = 1)),
    outcome = when(id > 5, deterministic(value = 2))
  )
  result <- as.data.frame(apply_conditions(data.frame(id = 1:10), rules, seed = 1))
  expect_equal(result$outcome, c(rep(1, 5), rep(2, 5)))
})

test_that("a conditional rule states a condition and a distribution", {
  expect_error(define_conditions(outcome = when(group == 1)),
               class = "simulab_bad_condition_call")
  expect_error(define_conditions(outcome = when(group == 1, normal(0, 1), 3)),
               class = "simulab_bad_condition_call")
  expect_error(define_conditions(when(group == 1, normal(0, 1))),
               class = "simulab_unnamed_specification")
  expect_error(define_conditions(outcome = when(group == 1, wishart(df = 3))),
               class = "simulab_unknown_distribution")
})

test_that("a condition must be a complete logical vector over the data", {
  rules <- define_conditions(outcome = when(group + 1, normal(mean = 0, sd = 1)))
  expect_error(
    apply_conditions(data.frame(id = 1:10, group = rep(0:1, 5)), rules),
    class = "simulab_bad_condition"
  )
})

test_that("a condition specification round-trips through a data frame", {
  rules <- define_conditions(
    outcome = when(group == 1, normal(mean = 5, sd = 1)),
    outcome = when(group == 0, poisson(lambda = 2))
  )
  restored <- as.data.frame(rules)
  class(restored) <- c("simulab_condition_spec", "data.frame")
  data <- data.frame(id = 1:200, group = rep(0:1, 100))
  expect_equal(as.data.frame(apply_conditions(data, rules, seed = 3)),
               as.data.frame(apply_conditions(data, restored, seed = 3)))
})

test_that("a hazard call states the same process as the survival columns", {
  # The hazard lane is a front end on the columns define_survival() writes, so
  # the two must produce the same specification and the same event times.
  calls <- define_survivals(time = hazard(log_rate = -8 + 0.5 * treatment, shape = 0.3))
  columns <- define_survivals(event = "time", formula = "-8 + 0.5 * treatment",
                              shape = "0.3")
  expect_equal(as.data.frame(calls), as.data.frame(columns))

  covariates <- data.frame(id = 1:500, treatment = rep(0:1, each = 250))
  expect_equal(
    as.data.frame(simulate_survival(500, calls, covariates = covariates, seed = 1)),
    as.data.frame(simulate_survival(500, columns, covariates = covariates, seed = 1))
  )
})

test_that("a hazard raises the event rate it is given", {
  covariates <- data.frame(id = seq_len(20000), treatment = rep(0:1, each = 10000))
  result <- as.data.frame(simulate_survival(
    20000,
    specification = define_survivals(
      time = hazard(log_rate = -8 + 0.5 * treatment, shape = 0.3)),
    covariates = covariates, seed = 1
  ))
  medians <- tapply(result$time, result$treatment, stats::median)
  expect_lt(medians[["1"]], medians[["0"]])
})

test_that("a repeated event name is a piecewise hazard", {
  specification <- define_survivals(
    time = hazard(log_rate = -8, shape = 0.3),
    time = hazard(log_rate = -5, shape = 0.3, from = 60)
  )
  expect_equal(nrow(specification), 2L)
  expect_equal(specification$transition, c(0, 60))
  expect_error(define_survivals(time = hazard(log_rate = -8, from = 10)),
               class = "simulab_bad_transition")
})

test_that("a hazard call is matched by name and position like a distribution", {
  expect_equal(as.data.frame(define_survivals(time = hazard(-8, 0.3))),
               as.data.frame(define_survivals(
                 time = hazard(shape = 0.3, log_rate = -8))))
  expect_error(define_survivals(time = hazard(rate = -8)),
               class = "simulab_unknown_parameter")
  expect_error(define_survivals(hazard(log_rate = -8)),
               class = "simulab_unnamed_specification")
})
