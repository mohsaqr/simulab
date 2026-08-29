## Distribution registry.
##
## Each entry names the sampler and its parameters in the order the sampler
## takes them, so a call may be written positionally or by name. Distributions
## are data here rather than branches of a switch(), which is what makes the
## catalogue extensible and listable.
##
## `sampler` is a function of (n, ...) taking the parameters by name. Anything
## not supplied by base R is built from a base sampler or an inverse CDF, so
## the catalogue costs no dependency.

.rgumbel      <- function(n, location = 0, scale = 1) location - scale * log(-log(stats::runif(n)))
.rlaplace     <- function(n, location = 0, scale = 1) {
  u <- stats::runif(n) - 0.5
  location - scale * sign(u) * log1p(-2 * abs(u))
}
.rpareto      <- function(n, shape, scale = 1) scale / stats::runif(n)^(1 / shape)
.rlomax       <- function(n, shape, scale = 1) scale * (stats::runif(n)^(-1 / shape) - 1)
.rrayleigh    <- function(n, scale = 1) scale * sqrt(-2 * log(stats::runif(n)))
.rgompertz    <- function(n, shape, rate = 1) log1p(-rate * log(stats::runif(n)) / shape) / rate
.rfrechet     <- function(n, shape, scale = 1) scale * (-log(stats::runif(n)))^(-1 / shape)
.rinvgamma    <- function(n, shape, rate = 1) 1 / stats::rgamma(n, shape = shape, rate = rate)
.rhalfnormal  <- function(n, sd = 1) abs(stats::rnorm(n, 0, sd))
.rhalfcauchy  <- function(n, scale = 1) abs(stats::rcauchy(n, 0, scale))
.rhalflogistic<- function(n, scale = 1) abs(stats::rlogis(n, 0, scale))
.rfoldednormal<- function(n, mean = 0, sd = 1) abs(stats::rnorm(n, mean, sd))
.rtruncnormal <- function(n, mean = 0, sd = 1, lower = -Inf, upper = Inf) {
  low <- stats::pnorm(lower, mean, sd)
  high <- stats::pnorm(upper, mean, sd)
  stats::qnorm(low + stats::runif(n) * (high - low), mean, sd)
}
.rtriangular  <- function(n, min = 0, max = 1, mode = (min + max) / 2) {
  u <- stats::runif(n)
  split <- (mode - min) / (max - min)
  ifelse(u < split,
         min + sqrt(u * (max - min) * (mode - min)),
         max - sqrt((1 - u) * (max - min) * (max - mode)))
}
.rgev <- function(n, location = 0, scale = 1, shape = 0) {
  u <- -log(stats::runif(n))
  if (isTRUE(all.equal(shape, 0))) location - scale * log(u)
  else location + scale * (u^(-shape) - 1) / shape
}
.rgpd <- function(n, location = 0, scale = 1, shape = 0) {
  u <- stats::runif(n)
  if (isTRUE(all.equal(shape, 0))) location - scale * log(u)
  else location + scale * ((1 - u)^(-shape) - 1) / shape
}
.rbetaprime <- function(n, shape1, shape2) {
  x <- stats::rbeta(n, shape1, shape2)
  x / (1 - x)
}
.rloguniform <- function(n, min = 1, max = exp(1)) exp(stats::runif(n, log(min), log(max)))
.rdiscreteuniform <- function(n, min = 0L, max = 1L) {
  min + floor(stats::runif(n) * (max - min + 1))
}
.rztpoisson <- function(n, lambda) {
  lower <- stats::ppois(0, lambda)
  stats::qpois(lower + stats::runif(n) * (1 - lower), lambda)
}
.rzipoisson <- function(n, lambda, zero = 0) {
  stats::rpois(n, lambda) * stats::rbinom(n, 1L, 1 - zero)
}
.rbetabinomial <- function(n, size, shape1, shape2) {
  stats::rbinom(n, size, stats::rbeta(n, shape1, shape2))
}
.rbernoulli <- function(n, prob) stats::rbinom(n, 1L, prob)
.rdeterministic <- function(n, value) rep_len(value, n)
.rtreatment <- function(n, groups = 2L) sample(rep(seq_len(groups), length.out = n))

.simulab_registry <- list(
  ## continuous, base R
  normal            = list(sampler = stats::rnorm,   params = c("mean", "sd")),
  uniform           = list(sampler = stats::runif,   params = c("min", "max")),
  exponential       = list(sampler = stats::rexp,    params = "rate"),
  gamma             = list(sampler = stats::rgamma,  params = c("shape", "rate")),
  beta              = list(sampler = stats::rbeta,   params = c("shape1", "shape2")),
  chisq             = list(sampler = stats::rchisq,  params = "df"),
  t                 = list(sampler = stats::rt,      params = "df"),
  f                 = list(sampler = stats::rf,      params = c("df1", "df2")),
  cauchy            = list(sampler = stats::rcauchy, params = c("location", "scale")),
  lognormal         = list(sampler = stats::rlnorm,  params = c("meanlog", "sdlog")),
  logistic          = list(sampler = stats::rlogis,  params = c("location", "scale")),
  weibull           = list(sampler = stats::rweibull, params = c("shape", "scale")),
  ## continuous, derived
  gumbel            = list(sampler = .rgumbel,       params = c("location", "scale")),
  laplace           = list(sampler = .rlaplace,      params = c("location", "scale")),
  pareto            = list(sampler = .rpareto,       params = c("shape", "scale")),
  lomax             = list(sampler = .rlomax,        params = c("shape", "scale")),
  rayleigh          = list(sampler = .rrayleigh,     params = "scale"),
  gompertz          = list(sampler = .rgompertz,     params = c("shape", "rate")),
  frechet           = list(sampler = .rfrechet,      params = c("shape", "scale")),
  inv_gamma         = list(sampler = .rinvgamma,     params = c("shape", "rate")),
  half_normal       = list(sampler = .rhalfnormal,   params = "sd"),
  half_cauchy       = list(sampler = .rhalfcauchy,   params = "scale"),
  half_logistic     = list(sampler = .rhalflogistic, params = "scale"),
  folded_normal     = list(sampler = .rfoldednormal, params = c("mean", "sd")),
  truncated_normal  = list(sampler = .rtruncnormal,  params = c("mean", "sd", "lower", "upper")),
  triangular        = list(sampler = .rtriangular,   params = c("min", "max", "mode")),
  gev               = list(sampler = .rgev,          params = c("location", "scale", "shape")),
  gpd               = list(sampler = .rgpd,          params = c("location", "scale", "shape")),
  beta_prime        = list(sampler = .rbetaprime,    params = c("shape1", "shape2")),
  log_uniform       = list(sampler = .rloguniform,   params = c("min", "max")),
  ## non-central
  noncentral_chisq  = list(sampler = stats::rchisq,  params = c("df", "ncp")),
  noncentral_t      = list(sampler = stats::rt,      params = c("df", "ncp")),
  noncentral_f      = list(sampler = stats::rf,      params = c("df1", "df2", "ncp")),
  ## discrete
  binary            = list(sampler = .rbernoulli,    params = "prob"),
  binomial          = list(sampler = stats::rbinom,  params = c("size", "prob")),
  poisson           = list(sampler = stats::rpois,   params = "lambda"),
  negative_binomial = list(sampler = stats::rnbinom, params = c("size", "prob")),
  geometric         = list(sampler = stats::rgeom,   params = "prob"),
  hypergeometric    = list(sampler = stats::rhyper,  params = c("m", "n", "k"),
                           count_argument = "nn"),
  discrete_uniform  = list(sampler = .rdiscreteuniform, params = c("min", "max")),
  zero_truncated_poisson = list(sampler = .rztpoisson,  params = "lambda"),
  zero_inflated_poisson  = list(sampler = .rzipoisson,  params = c("lambda", "zero")),
  beta_binomial     = list(sampler = .rbetabinomial, params = c("size", "shape1", "shape2")),
  ## simulab-specific
  deterministic     = list(sampler = .rdeterministic, params = "value"),
  treatment         = list(sampler = .rtreatment,     params = "groups"),
  categorical       = list(special = "categorical",   params = "probs"),
  mixture           = list(special = "mixture",       params = "weights")
)

#' List the distributions a specification may use
#'
#' `list_distributions()` reports the distribution catalogue. Each row names one
#' distribution and the parameters it takes, in the order a positional call
#' supplies them.
#'
#' @param pattern Optional regular expression matched against distribution
#'   names.
#'
#' @return A base `data.frame` with one row per distribution and columns
#'   `distribution`, `parameters` and `n_parameters`.
#' @export
#'
#' @examples
#' head(list_distributions())
#'
#' # Distributions whose name mentions normal.
#' list_distributions("normal")
list_distributions <- function(pattern = NULL) {
  stopifnot(
    "`pattern` must be NULL or a single string" =
      is.null(pattern) || (is.character(pattern) && length(pattern) == 1L)
  )

  names_all <- names(.simulab_registry)
  if (!is.null(pattern)) names_all <- grep(pattern, names_all, value = TRUE)
  result <- data.frame(
    distribution = names_all,
    parameters = vapply(names_all, function(nm)
      paste(.simulab_registry[[nm]]$params, collapse = ", "), character(1)),
    n_parameters = vapply(names_all, function(nm)
      length(.simulab_registry[[nm]]$params), integer(1)),
    stringsAsFactors = FALSE, row.names = NULL
  )
  result[order(result$distribution), , drop = FALSE]
}
