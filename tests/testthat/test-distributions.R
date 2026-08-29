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

test_that("distributions added as inverse CDFs recover their mean", {
  expect_mean("arcsine(2, 6)", 4)
  expect_mean("kumaraswamy(2, 3)", 3 * beta(1.5, 3))
  expect_mean("power(3, 2)", 1.5)
  expect_mean("burr(4, 3, 1)", 3 * beta(2.75, 1.25))
  expect_mean("dagum(4, 3, 1)", gamma(3.25) * gamma(0.75) / gamma(3))
  expect_mean("log_logistic(3, 2)", 2 * (pi / 3) / sin(pi / 3))
  expect_mean("generalized_logistic(3, 0, 1)", digamma(3) + 0.5772156649)
  expect_mean("hyperbolic_secant(2, 1)", 2)
  expect_mean("anglit(0, 1)", 0)
  expect_mean("bradford(3, 0, 1)", (3 - log1p(3)) / (3 * log1p(3)))
  expect_mean("truncated_exponential(1, 2)", 1 - 2 / expm1(2))
  expect_mean("tukey_lambda(0.5)", 0)
  expect_mean("moyal(0, 1)", log(2) + 0.5772156649)
  expect_mean("maxwell(2)", 4 * sqrt(2 / pi))
  expect_mean("chi(5)", sqrt(2) * gamma(3) / gamma(2.5))
  expect_mean("nakagami(2, 3)", gamma(2.5) / gamma(2) * sqrt(1.5))
  expect_mean("exponentiated_weibull(1, 2, 3)", 3 * gamma(1.5))
  expect_mean("johnson_su(1, 2, 0, 1)", -exp(0.125) * sinh(0.5))
  expect_mean("johnson_sb(0, 1, 0, 1)", 0.5)
  expect_mean("generalized_gamma(3, 2, 1)", gamma(3.5) / gamma(3))
  expect_mean("generalized_normal(4, 2, 1)", 2)
  expect_mean("logit_normal(0, 1)", 0.5)
  expect_mean("power_normal(1, 3, 2)", 3)
})

test_that("distributions added as samplers recover their mean", {
  # Each has no closed-form inverse CDF, so each is registered as a sampler.
  expect_mean("inverse_gaussian(4, 3)", 4)
  expect_mean("rice(0, 2)", 2 * sqrt(pi / 2))
  expect_mean("skew_normal(1, 2, 3)", 1 + 2 * (3 / sqrt(10)) * sqrt(2 / pi))
  expect_mean("semicircular(5, 2)", 5)
  expect_mean("skellam(6, 2)", 4)
})

test_that("zero-modified negative binomials recover their mean", {
  expect_mean("zero_truncated_negative_binomial(3, 0.4)", 4.5 / (1 - 0.4^3))
  expect_mean("zero_inflated_negative_binomial(3, 0.4, 0.25)", 0.75 * 4.5)
})

test_that("a sampler and a quantile function describe the same distribution", {
  # An entry that registers both is stating the same distribution twice, so the
  # two can drift apart. Compared at fixed probabilities rather than by mean,
  # because a mean cannot see a wrong tail.
  probabilities <- c(0.05, 0.25, 0.5, 0.75, 0.95)
  cases <- list(
    normal = list(mean = 3, sd = 2), uniform = list(min = -1, max = 4),
    exponential = list(rate = 0.4), gamma = list(shape = 2, rate = 0.5),
    beta = list(shape1 = 2, shape2 = 5), chisq = list(df = 4),
    lognormal = list(meanlog = 0, sdlog = 1), logistic = list(location = 1, scale = 2),
    weibull = list(shape = 2, scale = 3), poisson = list(lambda = 4),
    binomial = list(size = 10, prob = 0.3), geometric = list(prob = 0.25),
    negative_binomial = list(size = 5, prob = 0.4), binary = list(prob = 0.3),
    deterministic = list(value = 7)
  )
  set.seed(11)
  disagreements <- vapply(names(cases), function(name) {
    entry <- simulab:::.simulab_registry[[name]]
    drawn <- do.call(simulab:::.distribution_sampler(entry),
                     c(list(n = 200000L), cases[[name]]))
    stated <- do.call(entry$quantile, c(list(probabilities), cases[[name]]))
    max(abs(unname(stats::quantile(drawn, probabilities, type = 1)) - stated))
  }, numeric(1))
  # Sampled quantiles are discrete, so the bound is a sampling bound, not zero.
  expect_lt(max(disagreements), 0.05)
})

test_that("a distribution without a quantile function is not a copula marginal", {
  expect_false(list_distributions("^rice$")$copula)
  expect_error(
    simulate_copula(50, define_variables(x = normal(0, 1), y = rice(0, 1)), rho = 0.4),
    class = "simulab_no_quantile"
  )
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
               "arcsine","kumaraswamy","power","burr","dagum","log_logistic",
               "generalized_logistic","hyperbolic_secant","anglit","bradford",
               "truncated_exponential","tukey_lambda","moyal","maxwell","chi",
               "nakagami","exponentiated_weibull","johnson_su","johnson_sb",
               "generalized_gamma","generalized_normal","logit_normal",
               "power_normal","inverse_gaussian","rice","skew_normal",
               "semicircular","skellam","zero_truncated_negative_binomial",
               "zero_inflated_negative_binomial",
               # no finite mean, checked for drawing rather than for a value
               "t","cauchy","gompertz","half_cauchy","noncentral_t","noncentral_f",
               "levy","benini")
  expect_equal(sort(setdiff(registered, checked)), character(0))
})

test_that("heavy-tailed distributions still draw", {
  drawn <- vapply(c("t(10)", "cauchy(0, 1)", "gompertz(0.5, 0.3)", "half_cauchy(1)",
                    "noncentral_t(30, 1)", "noncentral_f(6, 30, 2)",
                    "levy(0, 1)", "benini(2, 1, 1)"), function(text) {
    specification <- eval(str2lang(sprintf("define_variables(y = %s)", text)))
    values <- as.data.frame(simulate_study(500, specification, seed = 1))$y
    length(values) == 500L && all(is.finite(values))
  }, logical(1))
  expect_true(all(drawn))
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
  expect_true(nrow(catalogue) >= 75L)
  expect_named(catalogue, c("distribution", "parameters", "n_parameters", "copula"))
  expect_equal(nrow(list_distributions("^normal$")), 1L)
  # The two copula halves partition the catalogue.
  expect_equal(nrow(list_distributions(copula = TRUE)) +
                 nrow(list_distributions(copula = FALSE)), nrow(catalogue))
  expect_true(all(list_distributions(copula = TRUE)$copula))
})
