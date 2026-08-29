# The distribution registry. Each sampler is checked against the theoretical
# mean of the distribution it claims to be, because a sampler that runs and
# returns numbers of the right length can still be the wrong distribution.

draw_mean <- function(text, n = 200000, seed = 7) {
  specification <- eval(str2lang(sprintf("define_variables(y = %s)", text)))
  mean(as.data.frame(simulate_study(n, specification, seed = seed))$y)
}
expect_mean <- function(text, target, tolerance = NULL) {
  tolerance <- tolerance %||% max(0.02, 0.02 * abs(target))
  expect_lt(abs(draw_mean(text) - target), tolerance)
}
`%||%` <- function(x, y) if (is.null(x)) y else x

test_that("continuous base-R distributions recover their mean", {
  expect_mean("normal(5, 2)", 5)
  expect_mean("uniform(0, 10)", 5)
  expect_mean("exponential(0.5)", 2)
  expect_mean("gamma(2, 0.5)", 4)
  expect_mean("beta(2, 5)", 2 / 7)
  expect_mean("chisq(4)", 4)
  expect_mean("f(6, 10)", 10 / 8)
  expect_mean("lognormal(0, 1)", exp(0.5))
  expect_mean("logistic(3, 2)", 3)
  expect_mean("weibull(2, 3)", 3 * gamma(1.5))
})

test_that("derived continuous distributions recover their mean", {
  expect_mean("gumbel(0, 2)", 2 * 0.5772156649)
  expect_mean("laplace(1, 2)", 1)
  expect_mean("pareto(3, 1)", 1.5)
  expect_mean("lomax(3, 2)", 1)
  expect_mean("rayleigh(2)", 2 * sqrt(pi / 2))
  expect_mean("frechet(3, 1)", gamma(1 - 1 / 3))
  expect_mean("inv_gamma(3, 2)", 1)
  expect_mean("half_normal(2)", 2 * sqrt(2 / pi))
  expect_mean("half_logistic(1)", 2 * log(2))
  expect_mean("folded_normal(0, 3)", 3 * sqrt(2 / pi))
  expect_mean("truncated_normal(0, 1, 0, Inf)", sqrt(2 / pi))
  expect_mean("triangular(0, 3, 1.5)", 1.5)
  expect_mean("gev(0, 1, 0)", 0.5772156649)
  expect_mean("gpd(0, 1, 0)", 1)
  expect_mean("beta_prime(3, 5)", 0.75)
  expect_mean("log_uniform(1, exp(2))", (exp(2) - 1) / 2)
})

test_that("discrete distributions recover their mean", {
  expect_mean("binary(0.3)", 0.3)
  expect_mean("binomial(10, 0.3)", 3)
  expect_mean("poisson(4)", 4)
  expect_mean("negative_binomial(5, 0.4)", 5 * 0.6 / 0.4)
  expect_mean("geometric(0.25)", 3)
  expect_mean("hypergeometric(10, 7, 8)", 8 * 10 / 17)
  expect_mean("discrete_uniform(1, 6)", 3.5)
  expect_mean("zero_truncated_poisson(2)", 2 / (1 - exp(-2)))
  expect_mean("zero_inflated_poisson(4, 0.25)", 3)
  expect_mean("beta_binomial(10, 2, 3)", 4)
})

test_that("non-central distributions use ncp", {
  expect_mean("noncentral_chisq(3, 2)", 5)
})

test_that("simulab-specific distributions behave", {
  expect_mean("deterministic(7)", 7)
  expect_mean("treatment(2)", 1.5)
  expect_mean("categorical(c(0.2, 0.5, 0.3))", 2.1)
  expect_mean("mixture(normal(0, 1), normal(5, 1), weights = c(0.3, 0.7))", 3.5)
})

test_that("every registered distribution is exercised above", {
  # Guards against a distribution being added without a mean check.
  registered <- names(simulab:::.simulab_registry)
  checked <- c("normal","uniform","exponential","gamma","beta","chisq","f","lognormal",
               "logistic","weibull","gumbel","laplace","pareto","lomax","rayleigh",
               "frechet","inv_gamma","half_normal","half_logistic","folded_normal",
               "truncated_normal","triangular","gev","gpd","beta_prime","log_uniform",
               "binary","binomial","poisson","negative_binomial","geometric",
               "hypergeometric","discrete_uniform","zero_truncated_poisson",
               "zero_inflated_poisson","beta_binomial","noncentral_chisq",
               "deterministic","treatment","categorical","mixture",
               # no finite mean, checked for drawing rather than for a value
               "t","cauchy","gompertz","half_cauchy","noncentral_t","noncentral_f")
  expect_equal(sort(setdiff(registered, checked)), character(0))
})

test_that("heavy-tailed distributions still draw", {
  for (text in c("t(10)", "cauchy(0, 1)", "gompertz(0.5, 0.3)", "half_cauchy(1)",
                 "noncentral_t(30, 1)", "noncentral_f(6, 30, 2)")) {
    specification <- eval(str2lang(sprintf("define_variables(y = %s)", text)))
    values <- as.data.frame(simulate_study(500, specification, seed = 1))$y
    expect_length(values, 500L)
    expect_true(all(is.finite(values)))
  }
})

test_that("positional, named and mixed calls agree exactly", {
  positional <- simulate_study(500, define_variables(y = normal(5, 1)), seed = 1)
  named <- simulate_study(500, define_variables(y = normal(mean = 5, sd = 1)), seed = 1)
  mixed <- simulate_study(500, define_variables(y = normal(5, sd = 1)), seed = 1)
  expect_equal(as.data.frame(positional), as.data.frame(named))
  expect_equal(as.data.frame(positional), as.data.frame(mixed))
})

test_that("a parameter may be an expression over earlier variables", {
  specification <- define_variables(
    age = normal(mean = 50, sd = 10),
    treated = binary(prob = 0.5),
    outcome = normal(mean = 10 + 0.2 * age + 2 * treated, sd = 2)
  )
  data <- as.data.frame(simulate_study(20000, specification, seed = 42))
  estimate <- unname(stats::coef(stats::lm(outcome ~ age + treated, data = data)))
  expect_lt(max(abs(estimate - c(10, 0.2, 2))), 0.05)
})

test_that("a distribution head never reaches the base function of that name", {
  # gamma, beta, t and f are base or stats functions; here they are names.
  expect_silent(define_variables(g = gamma(2, 1), b = beta(2, 5), s = t(10)))
})

test_that("an undefined variable is named, not left to base R", {
  # `t` is a function, so without value-position checking `2 * t` reaches
  # stats::t and fails with "non-numeric argument to binary operator".
  expect_error(
    simulate_study(10, define_variables(y = normal(mean = 2 * t, sd = 1))),
    class = "simulab_undefined_variable"
  )
  expect_error(
    simulate_study(10, define_variables(y = normal(mean = age, sd = 1))),
    regexp = "`age`"
  )
})

test_that("a variable named like a base function works once defined", {
  data <- as.data.frame(simulate_study(
    2000, define_variables(t = normal(mean = 5, sd = 1),
                           y = normal(mean = 2 * t, sd = 1)), seed = 1))
  expect_lt(abs(mean(data$y) - 10), 0.1)
})

test_that("unknown distributions and parameters are refused", {
  expect_error(define_variables(y = wishart(df = 3)),
               class = "simulab_unknown_distribution")
  expect_error(define_variables(y = normal(meen = 5)),
               class = "simulab_unknown_parameter")
  expect_error(define_variables(y = normal(1, 2, 3)),
               class = "simulab_unknown_parameter")
})

test_that("partial parameter matching is rejected", {
  # A specification is saved and re-run; an abbreviation that is unique today
  # becomes ambiguous when a parameter is added later.
  expect_error(define_variables(y = normal(m = 5, s = 1)),
               class = "simulab_unknown_parameter")
})

test_that("variables must be named and unique", {
  expect_error(define_variables(normal(0, 1)),
               class = "simulab_unnamed_specification")
  expect_error(define_variables(y = normal(0, 1), y = normal(1, 1)),
               class = "simulab_duplicate_variable")
})

test_that("mixture requires one weight per component", {
  expect_error(
    simulate_study(10, define_variables(
      m = mixture(normal(0, 1), normal(5, 1), weights = c(0.3, 0.3, 0.4)))),
    class = "simulab_mixture_mismatch"
  )
})

test_that("a call specification round-trips through a data frame", {
  specification <- define_variables(a = normal(0, 1), b = poisson(3))
  restored <- as.data.frame(specification)
  class(restored) <- c("simulab_spec", "data.frame")
  expect_equal(as.data.frame(simulate_study(200, specification, seed = 3)),
               as.data.frame(simulate_study(200, restored, seed = 3)))
})

test_that("list_distributions reports the catalogue", {
  catalogue <- list_distributions()
  expect_true(nrow(catalogue) >= 45L)
  expect_named(catalogue, c("distribution", "parameters", "n_parameters"))
  expect_equal(nrow(list_distributions("^normal$")), 1L)
})
