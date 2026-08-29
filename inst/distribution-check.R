## Every distribution in the registry, checked against its theoretical mean.
## Run with:  Rscript inst/distribution-check.R
library(simulab)
# distribution -> (call text, theoretical mean or NA)
cases <- list(
  normal=list("normal(5, 2)", 5), uniform=list("uniform(0, 10)", 5),
  exponential=list("exponential(0.5)", 2), gamma=list("gamma(2, 0.5)", 4),
  beta=list("beta(2, 5)", 2/7), chisq=list("chisq(4)", 4),
  t=list("t(10)", 0), f=list("f(6, 10)", 10/8),
  cauchy=list("cauchy(0, 1)", NA), lognormal=list("lognormal(0, 1)", exp(0.5)),
  logistic=list("logistic(3, 2)", 3), weibull=list("weibull(2, 3)", 3*gamma(1.5)),
  gumbel=list("gumbel(0, 2)", 2*0.5772156649),
  laplace=list("laplace(1, 2)", 1),
  pareto=list("pareto(3, 1)", 3/2),
  lomax=list("lomax(3, 2)", 2/2),
  rayleigh=list("rayleigh(2)", 2*sqrt(pi/2)),
  gompertz=list("gompertz(0.5, 0.3)", NA),
  frechet=list("frechet(3, 1)", gamma(1 - 1/3)),
  inv_gamma=list("inv_gamma(3, 2)", 2/2),
  half_normal=list("half_normal(2)", 2*sqrt(2/pi)),
  half_cauchy=list("half_cauchy(1)", NA),
  half_logistic=list("half_logistic(1)", 2*log(2)),
  folded_normal=list("folded_normal(0, 3)", 3*sqrt(2/pi)),
  truncated_normal=list("truncated_normal(0, 1, 0, Inf)", sqrt(2/pi)),
  triangular=list("triangular(0, 3, 1.5)", 1.5),
  gev=list("gev(0, 1, 0)", 0.5772156649),
  gpd=list("gpd(0, 1, 0)", 1),
  beta_prime=list("beta_prime(3, 5)", 3/4),
  log_uniform=list("log_uniform(1, exp(2))", (exp(2)-1)/2),
  noncentral_chisq=list("noncentral_chisq(3, 2)", 5),
  noncentral_t=list("noncentral_t(30, 1)", NA),
  noncentral_f=list("noncentral_f(6, 30, 2)", NA),
  binary=list("binary(0.3)", 0.3),
  binomial=list("binomial(10, 0.3)", 3),
  poisson=list("poisson(4)", 4),
  negative_binomial=list("negative_binomial(5, 0.4)", 5*0.6/0.4),
  geometric=list("geometric(0.25)", 0.75/0.25),
  hypergeometric=list("hypergeometric(10, 7, 8)", 8*10/17),
  discrete_uniform=list("discrete_uniform(1, 6)", 3.5),
  zero_truncated_poisson=list("zero_truncated_poisson(2)", 2/(1-exp(-2))),
  zero_inflated_poisson=list("zero_inflated_poisson(4, 0.25)", 3),
  beta_binomial=list("beta_binomial(10, 2, 3)", 10*2/5),
  deterministic=list("deterministic(7)", 7),
  treatment=list("treatment(2)", 1.5),
  categorical=list("categorical(c(0.2, 0.5, 0.3))", 1*0.2+2*0.5+3*0.3),
  mixture=list("mixture(normal(0, 1), normal(5, 1), weights = c(0.3, 0.7))", 3.5)
)
n <- 200000; fails <- 0L
cat(sprintf("%-24s %-42s %10s %10s %s\n", "distribution", "call", "expected", "observed", ""))
for (nm in names(cases)) {
  txt <- cases[[nm]][[1]]; target <- cases[[nm]][[2]]
  out <- tryCatch({
    spec <- eval(str2lang(sprintf("define_variables(y = %s)", txt)))
    mean(as.data.frame(simulate_study(n, spec, seed = 7))$y)
  }, error = function(e) structure(conditionMessage(e), class = "err"))
  if (inherits(out, "err")) {
    fails <- fails + 1L
    cat(sprintf("%-24s %-42s %10s %10s ERROR: %s\n", nm, txt, "", "", out)); next
  }
  if (is.na(target)) { cat(sprintf("%-24s %-42s %10s %10.4f  (no finite mean)\n", nm, txt, "-", out)); next }
  ok <- abs(out - target) < max(0.02, 0.02 * abs(target))
  if (!ok) fails <- fails + 1L
  cat(sprintf("%-24s %-42s %10.4f %10.4f  %s\n", nm, txt, target, out, if (ok) "" else "**MISMATCH**"))
}
cat("\nfailures:", fails, "of", length(cases), "\n")
