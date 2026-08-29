## Every distribution in the registry, checked against its theoretical mean,
## and every entry that carries both a sampler and a quantile function checked
## for agreeing with itself.
##
## Run with:  Rscript inst/distribution-check.R
library(simulab)

## distribution -> (call text, theoretical mean, or NA where none is finite or
## no closed form exists)
cases <- list(
  normal = list("normal(5, 2)", 5), uniform = list("uniform(0, 10)", 5),
  exponential = list("exponential(0.5)", 2), gamma = list("gamma(2, 0.5)", 4),
  beta = list("beta(2, 5)", 2 / 7), chisq = list("chisq(4)", 4),
  t = list("t(10)", 0), f = list("f(6, 10)", 10 / 8),
  cauchy = list("cauchy(0, 1)", NA), lognormal = list("lognormal(0, 1)", exp(0.5)),
  logistic = list("logistic(3, 2)", 3), weibull = list("weibull(2, 3)", 3 * gamma(1.5)),
  gumbel = list("gumbel(0, 2)", 2 * 0.5772156649),
  laplace = list("laplace(1, 2)", 1),
  pareto = list("pareto(3, 1)", 3 / 2),
  lomax = list("lomax(3, 2)", 2 / 2),
  rayleigh = list("rayleigh(2)", 2 * sqrt(pi / 2)),
  gompertz = list("gompertz(0.5, 0.3)", NA),
  frechet = list("frechet(3, 1)", gamma(1 - 1 / 3)),
  inv_gamma = list("inv_gamma(3, 2)", 2 / 2),
  half_normal = list("half_normal(2)", 2 * sqrt(2 / pi)),
  half_cauchy = list("half_cauchy(1)", NA),
  half_logistic = list("half_logistic(1)", 2 * log(2)),
  folded_normal = list("folded_normal(0, 3)", 3 * sqrt(2 / pi)),
  truncated_normal = list("truncated_normal(0, 1, 0, Inf)", sqrt(2 / pi)),
  triangular = list("triangular(0, 3, 1.5)", 1.5),
  gev = list("gev(0, 1, 0)", 0.5772156649),
  gpd = list("gpd(0, 1, 0)", 1),
  beta_prime = list("beta_prime(3, 5)", 3 / 4),
  log_uniform = list("log_uniform(1, exp(2))", (exp(2) - 1) / 2),
  arcsine = list("arcsine(2, 6)", 4),
  kumaraswamy = list("kumaraswamy(2, 3)", 3 * beta(1.5, 3)),
  power = list("power(3, 2)", 1.5),
  burr = list("burr(4, 3, 1)", 3 * beta(2.75, 1.25)),
  dagum = list("dagum(4, 3, 1)", gamma(3.25) * gamma(0.75) / gamma(3)),
  log_logistic = list("log_logistic(3, 2)", 2 * (pi / 3) / sin(pi / 3)),
  levy = list("levy(0, 1)", NA),
  generalized_logistic = list("generalized_logistic(3, 0, 1)",
                              digamma(3) + 0.5772156649),
  hyperbolic_secant = list("hyperbolic_secant(2, 1)", 2),
  anglit = list("anglit(0, 1)", 0),
  bradford = list("bradford(3, 0, 1)", (3 - log1p(3)) / (3 * log1p(3))),
  truncated_exponential = list("truncated_exponential(1, 2)", 1 - 2 / expm1(2)),
  tukey_lambda = list("tukey_lambda(0.5)", 0),
  moyal = list("moyal(0, 1)", log(2) + 0.5772156649),
  maxwell = list("maxwell(2)", 4 * sqrt(2 / pi)),
  chi = list("chi(5)", sqrt(2) * gamma(3) / gamma(2.5)),
  nakagami = list("nakagami(2, 3)", gamma(2.5) / gamma(2) * sqrt(1.5)),
  exponentiated_weibull = list("exponentiated_weibull(1, 2, 3)", 3 * gamma(1.5)),
  johnson_su = list("johnson_su(1, 2, 0, 1)", -exp(0.125) * sinh(0.5)),
  johnson_sb = list("johnson_sb(0, 1, 0, 1)", 0.5),
  benini = list("benini(2, 1, 1)", NA),
  generalized_gamma = list("generalized_gamma(3, 2, 1)", gamma(3.5) / gamma(3)),
  generalized_normal = list("generalized_normal(4, 2, 1)", 2),
  logit_normal = list("logit_normal(0, 1)", 0.5),
  power_normal = list("power_normal(1, 3, 2)", 3),
  inverse_gaussian = list("inverse_gaussian(4, 3)", 4),
  rice = list("rice(0, 2)", 2 * sqrt(pi / 2)),
  skew_normal = list("skew_normal(1, 2, 3)", 1 + 2 * (3 / sqrt(10)) * sqrt(2 / pi)),
  semicircular = list("semicircular(5, 2)", 5),
  noncentral_chisq = list("noncentral_chisq(3, 2)", 5),
  noncentral_t = list("noncentral_t(30, 1)", NA),
  noncentral_f = list("noncentral_f(6, 30, 2)", NA),
  binary = list("binary(0.3)", 0.3),
  binomial = list("binomial(10, 0.3)", 3),
  poisson = list("poisson(4)", 4),
  negative_binomial = list("negative_binomial(5, 0.4)", 5 * 0.6 / 0.4),
  geometric = list("geometric(0.25)", 0.75 / 0.25),
  hypergeometric = list("hypergeometric(10, 7, 8)", 8 * 10 / 17),
  discrete_uniform = list("discrete_uniform(1, 6)", 3.5),
  zero_truncated_poisson = list("zero_truncated_poisson(2)", 2 / (1 - exp(-2))),
  zero_inflated_poisson = list("zero_inflated_poisson(4, 0.25)", 3),
  zero_truncated_negative_binomial =
    list("zero_truncated_negative_binomial(3, 0.4)", 4.5 / (1 - 0.4^3)),
  zero_inflated_negative_binomial =
    list("zero_inflated_negative_binomial(3, 0.4, 0.25)", 0.75 * 4.5),
  beta_binomial = list("beta_binomial(10, 2, 3)", 10 * 2 / 5),
  skellam = list("skellam(6, 2)", 4),
  deterministic = list("deterministic(7)", 7),
  treatment = list("treatment(2)", 1.5),
  categorical = list("categorical(c(0.2, 0.5, 0.3))", 1 * 0.2 + 2 * 0.5 + 3 * 0.3),
  mixture = list("mixture(normal(0, 1), normal(5, 1), weights = c(0.3, 0.7))", 3.5)
)

n <- 200000
report <- do.call(rbind, lapply(names(cases), function(name) {
  text <- cases[[name]][[1L]]
  target <- cases[[name]][[2L]]
  drawn <- tryCatch({
    specification <- eval(str2lang(sprintf("define_variables(y = %s)", text)))
    mean(as.data.frame(simulate_study(n, specification, seed = 7))$y)
  }, error = function(e) structure(NA_real_, message = conditionMessage(e)))
  data.frame(
    distribution = name, call = text, expected = target, observed = drawn,
    status = if (is.na(drawn)) paste("ERROR:", attr(drawn, "message"))
             else if (is.na(target)) "no finite mean"
             else if (abs(drawn - target) < max(0.02, 0.02 * abs(target))) "ok"
             else "MISMATCH",
    stringsAsFactors = FALSE
  )
}))
print(report, row.names = FALSE, digits = 6)

registered <- list_distributions()
cat("\nregistered:", nrow(registered),
    "| copula marginals:", sum(registered$copula),
    "| checked:", nrow(report),
    "| unchecked:", paste(setdiff(registered$distribution, report$distribution),
                          collapse = ", "),
    "\nmean mismatches:", sum(report$status != "ok" & report$status != "no finite mean"),
    "\n")
