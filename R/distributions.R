## Distribution registry.
##
## Each entry names the parameters a distribution takes, in the order a
## positional call supplies them, together with one or both of:
##
##   `sampler`  a function of (n, <parameters>) returning n draws;
##   `quantile` a function of (p, <parameters>) returning the inverse CDF.
##
## A quantile function is the more useful of the two. It yields a sampler for
## free -- `quantile(runif(n), ...)` -- and it is exactly what a Gaussian
## copula needs to turn a correlated uniform margin into the target marginal.
## A distribution added as a quantile therefore reaches `simulate_study()` and
## `simulate_copula()` in one definition.
##
## A distribution that has both is stating the same thing twice, so the two can
## drift apart; a test asserts that they agree. Only base R's own samplers are
## registered alongside a quantile function, because they are R's tuned
## implementations. Everything simulab defines itself is defined once, as a
## quantile function, and `.distribution_sampler()` derives the sampler.
##
## Distributions are data here rather than branches of a switch(), which is
## what makes the catalogue extensible and listable. Everything is built on
## base R, so the catalogue costs no dependency.

## ---------------------------------------------------------------------------
## Samplers for distributions with no closed-form quantile function.

.rfoldednormal<- function(n, mean = 0, sd = 1) abs(stats::rnorm(n, mean, sd))
.rbetabinomial <- function(n, size, shape1, shape2) {
  stats::rbinom(n, size, stats::rbeta(n, shape1, shape2))
}
.rbernoulli <- function(n, prob) stats::rbinom(n, 1L, prob)
.rdeterministic <- function(n, value) rep_len(value, n)
.rtreatment <- function(n, groups = 2L) sample(rep(seq_len(groups), length.out = n))

## Michael, Schucany and Haas (1976), the exact inverse-Gaussian sampler.
.rinvgaussian <- function(n, mean = 1, shape = 1) {
  y <- stats::rnorm(n)^2
  candidate <- mean + mean^2 * y / (2 * shape) -
    mean / (2 * shape) * sqrt(4 * mean * shape * y + mean^2 * y^2)
  ifelse(stats::runif(n) <= mean / (mean + candidate),
         candidate, mean^2 / candidate)
}

.rrice <- function(n, location = 0, scale = 1) {
  sqrt(stats::rnorm(n, location, scale)^2 + stats::rnorm(n, 0, scale)^2)
}

## Azzalini (1985). The sign of the first standard normal selects the branch.
.rskewnormal <- function(n, location = 0, scale = 1, shape = 0) {
  delta <- shape / sqrt(1 + shape^2)
  first <- stats::rnorm(n)
  second <- delta * first + sqrt(1 - delta^2) * stats::rnorm(n)
  location + scale * ifelse(first >= 0, second, -second)
}

## Wigner's semicircle is a shifted, scaled Beta(3/2, 3/2).
.rsemicircular <- function(n, location = 0, scale = 1) {
  location + 2 * scale * (stats::rbeta(n, 1.5, 1.5) - 0.5)
}

.rskellam <- function(n, lambda1, lambda2) {
  stats::rpois(n, lambda1) - stats::rpois(n, lambda2)
}

## ---------------------------------------------------------------------------
## Quantile functions. Each is the inverse CDF of the named distribution, so
## `q(runif(n), ...)` is an exact sampler and `q(pnorm(z), ...)` is a copula
## margin.

.qgumbel      <- function(p, location = 0, scale = 1) location - scale * log(-log(p))
.qlaplace     <- function(p, location = 0, scale = 1) {
  centred <- p - 0.5
  location - scale * sign(centred) * log1p(-2 * abs(centred))
}
.qpareto      <- function(p, shape, scale = 1) scale / (1 - p)^(1 / shape)
.qlomax       <- function(p, shape, scale = 1) scale * ((1 - p)^(-1 / shape) - 1)
.qrayleigh    <- function(p, scale = 1) scale * sqrt(-2 * log1p(-p))
.qgompertz    <- function(p, shape, rate = 1) log1p(-rate * log1p(-p) / shape) / rate
.qfrechet     <- function(p, shape, scale = 1) scale * (-log(p))^(-1 / shape)
.qinvgamma    <- function(p, shape, rate = 1) 1 / stats::qgamma(1 - p, shape = shape, rate = rate)
.qhalfnormal  <- function(p, sd = 1) stats::qnorm((1 + p) / 2, 0, sd)
.qhalfcauchy  <- function(p, scale = 1) stats::qcauchy((1 + p) / 2, 0, scale)
.qhalflogistic<- function(p, scale = 1) stats::qlogis((1 + p) / 2, 0, scale)
.qtruncnormal <- function(p, mean = 0, sd = 1, lower = -Inf, upper = Inf) {
  low <- stats::pnorm(lower, mean, sd)
  high <- stats::pnorm(upper, mean, sd)
  stats::qnorm(low + p * (high - low), mean, sd)
}
.qtriangular  <- function(p, min = 0, max = 1, mode = (min + max) / 2) {
  split <- (mode - min) / (max - min)
  ifelse(p < split,
         min + sqrt(p * (max - min) * (mode - min)),
         max - sqrt((1 - p) * (max - min) * (max - mode)))
}
.qgev <- function(p, location = 0, scale = 1, shape = 0) {
  depth <- -log(p)
  if (isTRUE(all.equal(shape, 0))) location - scale * log(depth)
  else location + scale * (depth^(-shape) - 1) / shape
}
.qgpd <- function(p, location = 0, scale = 1, shape = 0) {
  if (isTRUE(all.equal(shape, 0))) location - scale * log1p(-p)
  else location + scale * ((1 - p)^(-shape) - 1) / shape
}
.qbetaprime <- function(p, shape1, shape2) {
  x <- stats::qbeta(p, shape1, shape2)
  x / (1 - x)
}
.qloguniform <- function(p, min = 1, max = exp(1)) exp(stats::qunif(p, log(min), log(max)))
.qdiscreteuniform <- function(p, min = 0L, max = 1L) {
  min + pmin(floor(p * (max - min + 1)), max - min)
}
.qztpoisson <- function(p, lambda) {
  lower <- stats::ppois(0, lambda)
  stats::qpois(lower + p * (1 - lower), lambda)
}
## `ifelse()` evaluates both arms across the whole vector, so the rescaled
## probability is clamped into [0, 1] rather than left negative where the zero
## arm is the one selected. Without the clamp qpois() is handed a negative
## probability and warns.
.qzipoisson <- function(p, lambda, zero = 0) {
  rescaled <- pmin(pmax((p - zero) / (1 - zero), 0), 1)
  ifelse(p <= zero, 0, stats::qpois(rescaled, lambda))
}
.qztnbinom <- function(p, size, prob) {
  lower <- stats::pnbinom(0, size = size, prob = prob)
  stats::qnbinom(lower + p * (1 - lower), size = size, prob = prob)
}
.qzinbinom <- function(p, size, prob, zero = 0) {
  rescaled <- pmin(pmax((p - zero) / (1 - zero), 0), 1)
  ifelse(p <= zero, 0, stats::qnbinom(rescaled, size = size, prob = prob))
}
.qbernoulli <- function(p, prob) stats::qbinom(p, 1L, prob)
.qdeterministic <- function(p, value) rep_len(value, length(p))

## New tranche: closed-form inverse CDFs.

.qarcsine <- function(p, min = 0, max = 1) min + (max - min) * sin(pi * p / 2)^2
.qkumaraswamy <- function(p, shape1, shape2) {
  (1 - (1 - p)^(1 / shape2))^(1 / shape1)
}
.qpower <- function(p, shape, scale = 1) scale * p^(1 / shape)
.qburr <- function(p, shape1, shape2, scale = 1) {
  scale * ((1 - p)^(-1 / shape2) - 1)^(1 / shape1)
}
.qdagum <- function(p, shape1, shape2, scale = 1) {
  scale * (p^(-1 / shape2) - 1)^(-1 / shape1)
}
.qloglogistic <- function(p, shape, scale = 1) scale * (p / (1 - p))^(1 / shape)
.qlevy <- function(p, location = 0, scale = 1) {
  location + scale / stats::qnorm(1 - p / 2)^2
}
.qgenlogistic <- function(p, shape, location = 0, scale = 1) {
  location - scale * log(p^(-1 / shape) - 1)
}
.qhypsecant <- function(p, location = 0, scale = 1) {
  location + scale * (2 / pi) * log(tan(pi * p / 2))
}
.qanglit <- function(p, location = 0, scale = 1) {
  location + scale * (asin(sqrt(p)) - pi / 4)
}
.qbradford <- function(p, shape, min = 0, max = 1) {
  min + (max - min) * ((1 + shape)^p - 1) / shape
}
.qtruncexponential <- function(p, rate = 1, upper = Inf) {
  -log1p(p * expm1(-rate * upper)) / rate
}
.qtukeylambda <- function(p, shape) {
  if (isTRUE(all.equal(shape, 0))) stats::qlogis(p)
  else (p^shape - (1 - p)^shape) / shape
}
.qmoyal <- function(p, location = 0, scale = 1) {
  location - 2 * scale * log(stats::qnorm(1 - p / 2))
}
.qmaxwell <- function(p, scale = 1) scale * sqrt(stats::qchisq(p, 3))
.qchi <- function(p, df) sqrt(stats::qchisq(p, df))
.qnakagami <- function(p, shape, spread = 1) {
  sqrt(stats::qgamma(p, shape = shape, rate = shape / spread))
}
.qexponweibull <- function(p, shape1, shape2, scale = 1) {
  scale * (-log1p(-p^(1 / shape1)))^(1 / shape2)
}
.qjohnsonsu <- function(p, shape1, shape2, location = 0, scale = 1) {
  location + scale * sinh((stats::qnorm(p) - shape1) / shape2)
}
.qjohnsonsb <- function(p, shape1, shape2, location = 0, scale = 1) {
  location + scale * stats::plogis((stats::qnorm(p) - shape1) / shape2)
}
.qbenini <- function(p, shape1, shape2, scale = 1) {
  depth <- -log1p(-p)
  scale * exp((-shape1 + sqrt(shape1^2 + 4 * shape2 * depth)) / (2 * shape2))
}
.qgengamma <- function(p, shape1, shape2, scale = 1) {
  scale * stats::qgamma(p, shape = shape1)^(1 / shape2)
}
.qgennormal <- function(p, shape, location = 0, scale = 1) {
  centred <- p - 0.5
  radius <- stats::qgamma(2 * abs(centred), shape = 1 / shape)^(1 / shape)
  location + scale * sign(centred) * radius
}
.qlogitnormal <- function(p, mean = 0, sd = 1) {
  stats::plogis(stats::qnorm(p, mean, sd))
}
.qpowernormal <- function(p, shape, location = 0, scale = 1) {
  location - scale * stats::qnorm((1 - p)^(1 / shape))
}

## ---------------------------------------------------------------------------

.simulab_registry <- list(
  ## continuous, base R
  normal            = list(sampler = stats::rnorm,   quantile = stats::qnorm,
                           params = c("mean", "sd")),
  uniform           = list(sampler = stats::runif,   quantile = stats::qunif,
                           params = c("min", "max")),
  exponential       = list(sampler = stats::rexp,    quantile = stats::qexp,
                           params = "rate"),
  gamma             = list(sampler = stats::rgamma,  quantile = stats::qgamma,
                           params = c("shape", "rate")),
  beta              = list(sampler = stats::rbeta,   quantile = stats::qbeta,
                           params = c("shape1", "shape2")),
  chisq             = list(sampler = stats::rchisq,  quantile = stats::qchisq,
                           params = "df"),
  t                 = list(sampler = stats::rt,      quantile = stats::qt,
                           params = "df"),
  f                 = list(sampler = stats::rf,      quantile = stats::qf,
                           params = c("df1", "df2")),
  cauchy            = list(sampler = stats::rcauchy, quantile = stats::qcauchy,
                           params = c("location", "scale")),
  lognormal         = list(sampler = stats::rlnorm,  quantile = stats::qlnorm,
                           params = c("meanlog", "sdlog")),
  logistic          = list(sampler = stats::rlogis,  quantile = stats::qlogis,
                           params = c("location", "scale")),
  weibull           = list(sampler = stats::rweibull, quantile = stats::qweibull,
                           params = c("shape", "scale")),
  ## continuous, derived
  gumbel            = list(quantile = .qgumbel,      params = c("location", "scale")),
  laplace           = list(quantile = .qlaplace,     params = c("location", "scale")),
  pareto            = list(quantile = .qpareto,      params = c("shape", "scale")),
  lomax             = list(quantile = .qlomax,       params = c("shape", "scale")),
  rayleigh          = list(quantile = .qrayleigh,    params = "scale"),
  gompertz          = list(quantile = .qgompertz,    params = c("shape", "rate")),
  frechet           = list(quantile = .qfrechet,     params = c("shape", "scale")),
  inv_gamma         = list(quantile = .qinvgamma,    params = c("shape", "rate")),
  half_normal       = list(quantile = .qhalfnormal,  params = "sd"),
  half_cauchy       = list(quantile = .qhalfcauchy,  params = "scale"),
  half_logistic     = list(quantile = .qhalflogistic, params = "scale"),
  folded_normal     = list(sampler = .rfoldednormal, params = c("mean", "sd")),
  truncated_normal  = list(quantile = .qtruncnormal,
                           params = c("mean", "sd", "lower", "upper")),
  triangular        = list(quantile = .qtriangular,  params = c("min", "max", "mode")),
  gev               = list(quantile = .qgev,         params = c("location", "scale", "shape")),
  gpd               = list(quantile = .qgpd,         params = c("location", "scale", "shape")),
  beta_prime        = list(quantile = .qbetaprime,   params = c("shape1", "shape2")),
  log_uniform       = list(quantile = .qloguniform,  params = c("min", "max")),
  ## continuous, added as inverse CDFs
  arcsine           = list(quantile = .qarcsine,     params = c("min", "max")),
  kumaraswamy       = list(quantile = .qkumaraswamy, params = c("shape1", "shape2")),
  power             = list(quantile = .qpower,       params = c("shape", "scale")),
  burr              = list(quantile = .qburr,        params = c("shape1", "shape2", "scale")),
  dagum             = list(quantile = .qdagum,       params = c("shape1", "shape2", "scale")),
  log_logistic      = list(quantile = .qloglogistic, params = c("shape", "scale")),
  levy              = list(quantile = .qlevy,        params = c("location", "scale")),
  generalized_logistic = list(quantile = .qgenlogistic,
                              params = c("shape", "location", "scale")),
  hyperbolic_secant = list(quantile = .qhypsecant,   params = c("location", "scale")),
  anglit            = list(quantile = .qanglit,      params = c("location", "scale")),
  bradford          = list(quantile = .qbradford,    params = c("shape", "min", "max")),
  truncated_exponential = list(quantile = .qtruncexponential,
                               params = c("rate", "upper")),
  tukey_lambda      = list(quantile = .qtukeylambda, params = "shape"),
  moyal             = list(quantile = .qmoyal,       params = c("location", "scale")),
  maxwell           = list(quantile = .qmaxwell,     params = "scale"),
  chi               = list(quantile = .qchi,         params = "df"),
  nakagami          = list(quantile = .qnakagami,    params = c("shape", "spread")),
  exponentiated_weibull = list(quantile = .qexponweibull,
                               params = c("shape1", "shape2", "scale")),
  johnson_su        = list(quantile = .qjohnsonsu,
                           params = c("shape1", "shape2", "location", "scale")),
  johnson_sb        = list(quantile = .qjohnsonsb,
                           params = c("shape1", "shape2", "location", "scale")),
  benini            = list(quantile = .qbenini,      params = c("shape1", "shape2", "scale")),
  generalized_gamma = list(quantile = .qgengamma,    params = c("shape1", "shape2", "scale")),
  generalized_normal = list(quantile = .qgennormal,  params = c("shape", "location", "scale")),
  logit_normal      = list(quantile = .qlogitnormal, params = c("mean", "sd")),
  power_normal      = list(quantile = .qpowernormal, params = c("shape", "location", "scale")),
  ## continuous, sampler only: no closed-form inverse CDF
  inverse_gaussian  = list(sampler = .rinvgaussian,  params = c("mean", "shape")),
  rice              = list(sampler = .rrice,         params = c("location", "scale")),
  skew_normal       = list(sampler = .rskewnormal,
                           params = c("location", "scale", "shape")),
  semicircular      = list(sampler = .rsemicircular, params = c("location", "scale")),
  ## non-central
  noncentral_chisq  = list(sampler = stats::rchisq,  quantile = stats::qchisq,
                           params = c("df", "ncp")),
  noncentral_t      = list(sampler = stats::rt,      quantile = stats::qt,
                           params = c("df", "ncp")),
  noncentral_f      = list(sampler = stats::rf,      quantile = stats::qf,
                           params = c("df1", "df2", "ncp")),
  ## discrete
  binary            = list(sampler = .rbernoulli,    quantile = .qbernoulli,
                           params = "prob"),
  binomial          = list(sampler = stats::rbinom,  quantile = stats::qbinom,
                           params = c("size", "prob")),
  poisson           = list(sampler = stats::rpois,   quantile = stats::qpois,
                           params = "lambda"),
  negative_binomial = list(sampler = stats::rnbinom, quantile = stats::qnbinom,
                           params = c("size", "prob")),
  geometric         = list(sampler = stats::rgeom,   quantile = stats::qgeom,
                           params = "prob"),
  hypergeometric    = list(sampler = stats::rhyper,  quantile = stats::qhyper,
                           params = c("m", "n", "k"), count_argument = "nn"),
  discrete_uniform  = list(quantile = .qdiscreteuniform, params = c("min", "max")),
  zero_truncated_poisson = list(quantile = .qztpoisson, params = "lambda"),
  zero_inflated_poisson  = list(quantile = .qzipoisson,
                                params = c("lambda", "zero")),
  zero_truncated_negative_binomial = list(quantile = .qztnbinom,
                                          params = c("size", "prob")),
  zero_inflated_negative_binomial  = list(quantile = .qzinbinom,
                                          params = c("size", "prob", "zero")),
  beta_binomial     = list(sampler = .rbetabinomial,
                           params = c("size", "shape1", "shape2")),
  skellam           = list(sampler = .rskellam,      params = c("lambda1", "lambda2")),
  ## simulab-specific
  deterministic     = list(sampler = .rdeterministic, quantile = .qdeterministic,
                           params = "value"),
  treatment         = list(sampler = .rtreatment,     params = "groups"),
  categorical       = list(special = "categorical",   params = "probs"),
  mixture           = list(special = "mixture",       params = "weights")
)

## A registered sampler wins over one derived from the quantile function, so
## base R's tuned samplers are used where they exist.
.distribution_sampler <- function(entry) {
  if (!is.null(entry$sampler)) return(entry$sampler)
  quantile_function <- entry$quantile
  function(n, ...) quantile_function(stats::runif(n), ...)
}

.distribution_quantile <- function(entry) entry$quantile

#' List the distributions a specification may use
#'
#' `list_distributions()` reports the distribution catalogue. Each row names one
#' distribution, the parameters it takes in the order a positional call supplies
#' them, and whether it carries a quantile function. Only a distribution with a
#' quantile function can be a marginal in [simulate_copula()].
#'
#' @param pattern Optional regular expression matched against distribution
#'   names.
#' @param copula If `TRUE`, keep only distributions usable as copula marginals;
#'   if `FALSE`, keep only those that are not. `NULL`, the default, keeps every
#'   distribution.
#'
#' @return A base `data.frame` with one row per distribution and columns
#'   `distribution`, `parameters`, `n_parameters` and `copula`.
#' @export
#'
#' @examples
#' head(list_distributions())
#'
#' # Distributions whose name mentions normal.
#' list_distributions("normal")
#'
#' # Distributions that cannot be a copula marginal.
#' list_distributions(copula = FALSE)
list_distributions <- function(pattern = NULL, copula = NULL) {
  stopifnot(
    "`pattern` must be NULL or a single string" =
      is.null(pattern) || (is.character(pattern) && length(pattern) == 1L),
    "`copula` must be NULL, TRUE or FALSE" =
      is.null(copula) || (is.logical(copula) && length(copula) == 1L && !is.na(copula))
  )

  names_all <- names(.simulab_registry)
  if (!is.null(pattern)) names_all <- grep(pattern, names_all, value = TRUE)
  result <- data.frame(
    distribution = names_all,
    parameters = vapply(names_all, function(nm)
      paste(.simulab_registry[[nm]]$params, collapse = ", "), character(1)),
    n_parameters = vapply(names_all, function(nm)
      length(.simulab_registry[[nm]]$params), integer(1)),
    copula = vapply(names_all, function(nm)
      !is.null(.simulab_registry[[nm]]$quantile), logical(1)),
    stringsAsFactors = FALSE, row.names = NULL
  )
  if (!is.null(copula)) result <- result[result$copula == copula, , drop = FALSE]
  result[order(result$distribution), , drop = FALSE]
}
