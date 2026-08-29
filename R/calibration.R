#' Convert mean/dispersion parameterizations
#'
#' `calibrate_distribution()` inverts the mean and dispersion parameterization
#' used by the `formula`/`variance` specification columns into the shape
#' parameters base R's samplers take. For a mean and a *variance*, and for the
#' wider catalogue, use [calibrate_moments()].
#'
#' @param distribution Beta, gamma, or negative-binomial distribution.
#' @param mean Distribution mean.
#' @param dispersion Beta precision or gamma/negative-binomial dispersion.
#'
#' @return A base `data.frame` with one row per input value and parameter, and
#'   columns `distribution`, `mean`, `dispersion`, `parameter` and `value`.
#' @export
#'
#' @examples
#' calibrate_distribution("beta", mean = 0.4, dispersion = 8)
#' calibrate_distribution("gamma", mean = 10, dispersion = 0.5)
#' calibrate_distribution("negative_binomial", mean = 5, dispersion = 0.4)
calibrate_distribution <- function(distribution = c("beta", "gamma", "negative_binomial"),
                                   mean, dispersion) {
  stopifnot(
    "`mean` must be a finite numeric vector, with at least one element" =
      is.numeric(mean) &&
        length(mean) >= 1L &&
        all(is.finite(mean)),
    "`dispersion` must be a finite numeric vector, with at least one element" =
      is.numeric(dispersion) &&
        length(dispersion) >= 1L &&
        all(is.finite(dispersion))
  )
  distribution <- match.arg(distribution)
  recycled <- .recycle_targets(list(mean = mean, dispersion = dispersion))
  mean <- recycled$mean
  dispersion <- recycled$dispersion
  if (any(dispersion <= 0)) stop("dispersion must be positive.", call. = FALSE)

  parameters <- switch(
    distribution,
    beta = {
      if (any(mean <= 0 | mean >= 1)) stop("Beta means must lie strictly between zero and one.", call. = FALSE)
      list(shape1 = mean * dispersion, shape2 = (1 - mean) * dispersion)
    },
    gamma = {
      if (any(mean <= 0)) stop("Gamma means must be positive.", call. = FALSE)
      list(shape = 1 / dispersion, rate = 1 / (mean * dispersion))
    },
    negative_binomial = {
      if (any(mean < 0)) stop("Negative-binomial means cannot be negative.", call. = FALSE)
      list(size = 1 / dispersion, prob = 1 / (1 + mean * dispersion))
    }
  )
  .parameter_table(distribution, list(mean = mean, dispersion = dispersion),
                   parameters)
}

## Targets recycle against each other, so one mean may be paired with a vector
## of dispersions and the reverse.
.recycle_targets <- function(targets) {
  lengths <- vapply(targets, length, integer(1))
  output_length <- max(lengths)
  if (any(!lengths %in% c(1L, output_length))) {
    stop(errorCondition(
      sprintf("%s must have compatible lengths.",
              paste(sprintf("`%s`", names(targets)), collapse = " and ")),
      class = "simulab_incompatible_lengths", call = NULL
    ))
  }
  lapply(targets, rep, length.out = output_length)
}

## One row per target value and parameter, so the result is tidy and its
## `parameter` and `value` columns name what a distribution call would take.
.parameter_table <- function(distribution, targets, parameters) {
  rows <- Map(function(name, value) {
    data.frame(distribution = distribution, targets, parameter = name,
               value = value, stringsAsFactors = FALSE, row.names = NULL)
  }, names(parameters), parameters)
  result <- do.call(rbind, rows)
  ordering <- order(rep(seq_along(parameters[[1L]]), length(parameters)),
                    rep(seq_along(parameters), each = length(parameters[[1L]])))
  result <- result[ordering, , drop = FALSE]
  rownames(result) <- NULL
  result
}

## The moment registry. Each entry states which targets it needs, the parameter
## values that attain them, and -- for a one-parameter family, whose variance
## the mean already determines -- the variance those parameters imply.
##
## Parameter names are the names the distribution takes in `list_distributions()`,
## so a calibrated row reads straight into a distribution call.
.simulab_moments <- list(
  normal = list(targets = c("mean", "variance"), solve = function(mean, variance)
    list(mean = mean, sd = sqrt(variance))),
  lognormal = list(targets = c("mean", "variance"), positive = TRUE,
                   solve = function(mean, variance) {
                     sdlog <- sqrt(log1p(variance / mean^2))
                     list(meanlog = log(mean) - sdlog^2 / 2, sdlog = sdlog)
                   }),
  gamma = list(targets = c("mean", "variance"), positive = TRUE,
               solve = function(mean, variance)
                 list(shape = mean^2 / variance, rate = mean / variance)),
  inv_gamma = list(targets = c("mean", "variance"), positive = TRUE,
                   solve = function(mean, variance) {
                     shape <- mean^2 / variance + 2
                     list(shape = shape, rate = mean * (shape - 1))
                   }),
  beta = list(targets = c("mean", "variance"), solve = function(mean, variance) {
    if (any(mean <= 0 | mean >= 1)) {
      stop(errorCondition("A beta mean must lie strictly between zero and one.",
                          class = "simulab_unattainable_moments", call = NULL))
    }
    if (any(variance >= mean * (1 - mean))) {
      stop(errorCondition(
        "A beta variance must be below mean * (1 - mean); no beta attains this pair.",
        class = "simulab_unattainable_moments", call = NULL))
    }
    precision <- mean * (1 - mean) / variance - 1
    list(shape1 = mean * precision, shape2 = (1 - mean) * precision)
  }),
  beta_prime = list(targets = c("mean", "variance"), positive = TRUE,
                    solve = function(mean, variance) {
                      shape2 <- 2 + mean * (mean + 1) / variance
                      list(shape1 = mean * (shape2 - 1), shape2 = shape2)
                    }),
  inverse_gaussian = list(targets = c("mean", "variance"), positive = TRUE,
                          solve = function(mean, variance)
                            list(mean = mean, shape = mean^3 / variance)),
  pareto = list(targets = c("mean", "variance"), positive = TRUE,
                solve = function(mean, variance) {
                  shape <- 1 + sqrt(1 + mean^2 / variance)
                  list(shape = shape, scale = mean * (shape - 1) / shape)
                }),
  weibull = list(targets = c("mean", "variance"), positive = TRUE,
                 solve = function(mean, variance) {
                   shape <- .solve_shape(variance / mean^2, .cv_weibull,
                                         c(0.06, 60), "the Weibull shape")
                   list(shape = shape, scale = mean / gamma(1 + 1 / shape))
                 }),
  gumbel = list(targets = c("mean", "variance"), solve = function(mean, variance) {
    scale <- sqrt(6 * variance) / pi
    list(location = mean - scale * .euler_mascheroni, scale = scale)
  }),
  laplace = list(targets = c("mean", "variance"), solve = function(mean, variance)
    list(location = mean, scale = sqrt(variance / 2))),
  logistic = list(targets = c("mean", "variance"), solve = function(mean, variance)
    list(location = mean, scale = sqrt(3 * variance) / pi)),
  uniform = list(targets = c("mean", "variance"), solve = function(mean, variance) {
    half_width <- sqrt(3 * variance)
    list(min = mean - half_width, max = mean + half_width)
  }),
  negative_binomial = list(targets = c("mean", "variance"), positive = TRUE,
                           solve = function(mean, variance) {
                             if (any(variance <= mean)) {
                               stop(errorCondition(paste0(
                                 "A negative-binomial variance must exceed its mean; ",
                                 "use poisson for equal mean and variance."),
                                 class = "simulab_unattainable_moments", call = NULL))
                             }
                             list(size = mean^2 / (variance - mean), prob = mean / variance)
                           }),
  lomax = list(targets = c("mean", "variance"), positive = TRUE,
               solve = function(mean, variance) {
                 squared_cv <- variance / mean^2
                 if (any(squared_cv <= 1)) {
                   stop(errorCondition(paste0(
                     "A Lomax variance must exceed its squared mean; no Lomax ",
                     "with a finite variance attains this pair."),
                     class = "simulab_unattainable_moments", call = NULL))
                 }
                 shape <- 2 * squared_cv / (squared_cv - 1)
                 list(shape = shape, scale = mean * (shape - 1))
               }),
  power = list(targets = c("mean", "variance"), positive = TRUE,
               solve = function(mean, variance) {
                 squared_cv <- variance / mean^2
                 shape <- sqrt(1 + 1 / squared_cv) - 1
                 list(shape = shape, scale = mean * (shape + 1) / shape)
               }),
  arcsine = list(targets = c("mean", "variance"), solve = function(mean, variance) {
    half_width <- sqrt(2 * variance)
    list(min = mean - half_width, max = mean + half_width)
  }),
  hyperbolic_secant = list(targets = c("mean", "variance"),
                           solve = function(mean, variance)
                             list(location = mean, scale = sqrt(variance))),
  anglit = list(targets = c("mean", "variance"), solve = function(mean, variance)
    list(location = mean, scale = sqrt(variance / (pi^2 / 16 - 0.5)))),
  moyal = list(targets = c("mean", "variance"), solve = function(mean, variance) {
    scale <- sqrt(2 * variance) / pi
    list(location = mean - scale * (log(2) + .euler_mascheroni), scale = scale)
  }),
  semicircular = list(targets = c("mean", "variance"), solve = function(mean, variance)
    list(location = mean, scale = 2 * sqrt(variance))),
  skellam = list(targets = c("mean", "variance"), solve = function(mean, variance) {
    if (any(variance <= abs(mean))) {
      stop(errorCondition(paste0(
        "A Skellam variance is the sum of its two rates and its mean their ",
        "difference, so the variance must exceed the absolute mean."),
        class = "simulab_unattainable_moments", call = NULL))
    }
    list(lambda1 = (variance + mean) / 2, lambda2 = (variance - mean) / 2)
  }),
  log_logistic = list(targets = c("mean", "variance"), positive = TRUE,
                      solve = function(mean, variance) {
                        shape <- .solve_shape(variance / mean^2, .cv_log_logistic,
                                              c(2.0001, 2000),
                                              "the log-logistic shape")
                        angle <- pi / shape
                        list(shape = shape, scale = mean * sin(angle) / angle)
                      }),
  frechet = list(targets = c("mean", "variance"), positive = TRUE,
                 solve = function(mean, variance) {
                   shape <- .solve_shape(variance / mean^2, .cv_frechet,
                                         c(2.0001, 500), "the Frechet shape")
                   list(shape = shape, scale = mean / gamma(1 - 1 / shape))
                 }),
  nakagami = list(targets = c("mean", "variance"), positive = TRUE,
                  solve = function(mean, variance) {
                    squared_cv <- variance / mean^2
                    if (any(squared_cv >= pi / 2 - 1)) {
                      stop(errorCondition(sprintf(paste0(
                        "A Nakagami squared coefficient of variation is at most ",
                        "%.4f, reached at shape 0.5; %.4f was asked for."),
                        pi / 2 - 1, max(squared_cv)),
                        class = "simulab_unattainable_moments", call = NULL))
                    }
                    shape <- .solve_shape(squared_cv, .cv_nakagami,
                                          c(0.5, 10000), "the Nakagami shape")
                    list(shape = shape, spread = variance + mean^2)
                  }),
  half_logistic = list(targets = "mean", positive = TRUE,
                       solve = function(mean) list(scale = mean / (2 * log(2))),
                       variance = function(mean)
                         (mean / (2 * log(2)))^2 * (pi^2 / 3 - 4 * log(2)^2)),
  maxwell = list(targets = "mean", positive = TRUE,
                 solve = function(mean) list(scale = mean / (2 * sqrt(2 / pi))),
                 variance = function(mean)
                   (mean / (2 * sqrt(2 / pi)))^2 * (3 - 8 / pi)),
  chi = list(targets = "mean", positive = TRUE,
             solve = function(mean) list(df = .solve_chi_df(mean)),
             variance = function(mean) .solve_chi_df(mean) - mean^2),
  zero_truncated_poisson = list(
    targets = "mean", positive = TRUE,
    solve = function(mean) list(lambda = .solve_truncated_poisson_rate(mean)),
    variance = function(mean) {
      rate <- .solve_truncated_poisson_rate(mean)
      mean * (1 + rate - mean)
    }),
  poisson = list(targets = "mean", positive = TRUE,
                 solve = function(mean) list(lambda = mean),
                 variance = function(mean) mean),
  exponential = list(targets = "mean", positive = TRUE,
                     solve = function(mean) list(rate = 1 / mean),
                     variance = function(mean) mean^2),
  chisq = list(targets = "mean", positive = TRUE,
               solve = function(mean) list(df = mean),
               variance = function(mean) 2 * mean),
  rayleigh = list(targets = "mean", positive = TRUE,
                  solve = function(mean) list(scale = mean / sqrt(pi / 2)),
                  variance = function(mean) (4 / pi - 1) * mean^2),
  half_normal = list(targets = "mean", positive = TRUE,
                     solve = function(mean) list(sd = mean / sqrt(2 / pi)),
                     variance = function(mean) (pi / 2 - 1) * mean^2),
  geometric = list(targets = "mean", positive = TRUE,
                   solve = function(mean) list(prob = 1 / (1 + mean)),
                   variance = function(mean) mean * (1 + mean)),
  binary = list(targets = "mean", solve = function(mean) {
    if (any(mean < 0 | mean > 1)) {
      stop(errorCondition("A binary mean is a probability, between zero and one.",
                          class = "simulab_unattainable_moments", call = NULL))
    }
    list(prob = mean)
  }, variance = function(mean) mean * (1 - mean))
)

.euler_mascheroni <- -digamma(1)

## Several families have a shape whose squared coefficient of variation does not
## depend on the scale. The shape is then found from `variance / mean^2` alone
## and the scale follows in closed form. Every gamma ratio is taken in log
## space, because gamma() overflows long before the shape does.
.solve_shape <- function(squared_cv, objective, interval, what) {
  vapply(squared_cv, function(target)
    .solve_root(function(shape) objective(shape) - target,
                interval = interval, what = what),
    numeric(1))
}

.cv_weibull <- function(shape) exp(lgamma(1 + 2 / shape) - 2 * lgamma(1 + 1 / shape)) - 1
.cv_frechet <- function(shape) exp(lgamma(1 - 2 / shape) - 2 * lgamma(1 - 1 / shape)) - 1
.cv_nakagami <- function(shape) shape * exp(2 * (lgamma(shape) - lgamma(shape + 0.5))) - 1
.cv_log_logistic <- function(shape) tan(pi / shape) * shape / pi - 1

## Two one-parameter families invert their mean rather than their coefficient
## of variation, because the mean is the only target they take.
.solve_chi_df <- function(mean) {
  vapply(mean, function(target)
    .solve_root(function(df) sqrt(2) * exp(lgamma((df + 1) / 2) - lgamma(df / 2)) - target,
                interval = c(1e-4, 1e6), what = "the chi degrees of freedom"),
    numeric(1))
}

.solve_truncated_poisson_rate <- function(mean) {
  vapply(mean, function(target)
    .solve_root(function(rate) rate / -expm1(-rate) - target,
                interval = c(1e-9, 1e7),
                what = "the zero-truncated Poisson rate"),
    numeric(1))
}

#' Solve a distribution's parameters from a target mean and variance
#'
#' `calibrate_moments()` inverts the moments of a distribution into the
#' parameters that attain them, so a target mean and variance can be stated
#' directly and turned into a distribution call. A one-parameter family takes
#' `mean` alone, because its mean already fixes its variance; the reported
#' `variance` is then the one those parameters imply.
#'
#' Most inversions are closed form. For a scale family whose shape is fixed by
#' the coefficient of variation alone -- Weibull, log-logistic, Frechet,
#' Nakagami -- the shape is found by root finding and the scale then follows
#' exactly. Some families cannot reach every pair: a Nakagami squared
#' coefficient of variation is at most `pi / 2 - 1`, a Lomax with a finite
#' variance always has one above 1, and a beta variance is below
#' `mean * (1 - mean)`. Those are refused rather than approximated.
#'
#' @param distribution Distribution name. `calibrate_moments()` with no
#'   arguments reports the distributions it can invert.
#' @param mean Target mean, or a vector of target means.
#' @param variance Target variance, for a two-parameter family. Omitted for a
#'   one-parameter family, whose variance its mean determines.
#'
#' @return A base `data.frame` with one row per target and parameter, and
#'   columns `distribution`, `mean`, `variance`, `parameter` and `value`. The
#'   `parameter` names are those [list_distributions()] reports, so the result
#'   states a distribution call.
#'
#' @section Conditions:
#' `simulab_unattainable_moments` when no member of the family has the
#' requested moments, such as a beta variance at or above `mean * (1 - mean)`;
#' `simulab_no_moment_solution` when the distribution has no implemented
#' inversion; `simulab_incompatible_lengths` when `mean` and `variance` are
#' vectors of different, non-recyclable lengths.
#' @export
#'
#' @examples
#' # The 36 distributions that can be inverted, and the targets each takes.
#' calibrate_moments()
#'
#' # A lognormal with mean 10 and variance 25.
#' calibrate_moments("lognormal", mean = 10, variance = 25)
#'
#' # A one-parameter family takes the mean alone and reports the variance
#' # that follows from it.
#' calibrate_moments("poisson", mean = 4)
#'
#' # Targets recycle, so a sweep is one call.
#' calibrate_moments("gamma", mean = c(5, 10, 20), variance = 9)
calibrate_moments <- function(distribution = NULL, mean = NULL, variance = NULL) {
  if (is.null(distribution)) return(.moment_catalogue())
  stopifnot(
    "`distribution` must be a single string" =
      is.character(distribution) && length(distribution) == 1L,
    "`mean` must be a finite numeric vector, with at least one element" =
      is.numeric(mean) && length(mean) >= 1L && all(is.finite(mean)),
    "`variance` must be NULL or a finite positive numeric vector, with at least one element" =
      is.null(variance) ||
        (is.numeric(variance) && length(variance) >= 1L &&
           all(is.finite(variance)) && all(variance > 0))
  )
  entry <- .simulab_moments[[distribution]]
  if (is.null(entry)) {
    stop(errorCondition(
      sprintf(paste0("No moment inversion is implemented for '%s'. Use ",
                     "calibrate_moments() to see the distributions that can be inverted."),
              distribution),
      class = "simulab_no_moment_solution", call = NULL
    ))
  }
  needs_variance <- "variance" %in% entry$targets
  if (needs_variance && is.null(variance)) {
    stop(errorCondition(
      sprintf("`%s` has two parameters, so it needs both `mean` and `variance`.",
              distribution),
      class = "simulab_no_moment_solution", call = NULL
    ))
  }
  if (!needs_variance && !is.null(variance)) {
    stop(errorCondition(
      sprintf(paste0("`%s` has one parameter, so its mean already fixes its ",
                     "variance. Supply `mean` alone."), distribution),
      class = "simulab_no_moment_solution", call = NULL
    ))
  }
  if (isTRUE(entry$positive) && any(mean <= 0)) {
    stop(errorCondition(
      sprintf("A %s mean must be positive.", distribution),
      class = "simulab_unattainable_moments", call = NULL
    ))
  }

  if (needs_variance) {
    recycled <- .recycle_targets(list(mean = mean, variance = variance))
    parameters <- entry$solve(recycled$mean, recycled$variance)
  } else {
    recycled <- list(mean = mean, variance = entry$variance(mean))
    parameters <- entry$solve(mean)
  }
  parameters <- lapply(parameters, rep, length.out = length(recycled$mean))
  .parameter_table(distribution, recycled, parameters)
}

.moment_catalogue <- function() {
  names_all <- sort(names(.simulab_moments))
  data.frame(
    distribution = names_all,
    parameters = vapply(names_all, function(nm)
      paste(.simulab_registry[[nm]]$params, collapse = ", "), character(1)),
    targets = vapply(names_all, function(nm)
      paste(.simulab_moments[[nm]]$targets, collapse = ", "), character(1)),
    stringsAsFactors = FALSE, row.names = NULL
  )
}

#' Calibrate random-effect variance for a target ICC
#'
#' @param icc Target intraclass correlations.
#' @param distribution Outcome distribution.
#' @param total_variance Total normal-outcome variance.
#' @param within_variance Within-cluster normal-outcome variance.
#' @param mean Poisson or negative-binomial mean.
#' @param dispersion Gamma or negative-binomial dispersion.
#'
#' @return A base `data.frame` with one row per target ICC and the required
#'   random-effect variance.
#' @export
#'
#' @examples
#' calibrate_icc(icc = 0.1, distribution = "normal", total_variance = 1)
#' calibrate_icc(icc = c(0.05, 0.1), distribution = "binary")
calibrate_icc <- function(icc,
                          distribution = c("normal", "binary", "poisson", "gamma", "negative_binomial"),
                          total_variance = NULL, within_variance = NULL,
                          mean = NULL, dispersion = NULL) {
  stopifnot(
    "`icc` must be a numeric vector of correlations strictly between 0 and 1, with at least one element" =
      is.numeric(icc) &&
        length(icc) >= 1L &&
        all(is.finite(icc)) &&
        all(icc > 0 & icc < 1),
    "`total_variance` must be NULL or a numeric vector" =
      is.null(total_variance) || is.numeric(total_variance),
    "`within_variance` must be NULL or a numeric vector" =
      is.null(within_variance) || is.numeric(within_variance),
    "`mean` must be NULL or a numeric vector" =
      is.null(mean) || is.numeric(mean),
    "`dispersion` must be NULL or a numeric vector" =
      is.null(dispersion) || is.numeric(dispersion)
  )
  distribution <- match.arg(distribution)
  residual_variance <- switch(
    distribution,
    normal = {
      if (!is.null(total_variance) && !is.null(within_variance)) {
        stop("Supply total_variance or within_variance, not both.", call. = FALSE)
      }
      if (is.null(total_variance) && is.null(within_variance)) {
        stop("Normal calibration requires total_variance or within_variance.", call. = FALSE)
      }
      if (!is.null(total_variance)) return(data.frame(
        icc = icc,
        distribution = distribution,
        random_effect_variance = icc * total_variance,
        row.names = NULL
      ))
      within_variance
    },
    binary = pi^2 / 3,
    poisson = {
      if (is.null(mean) || any(mean <= 0)) stop("Poisson calibration requires a positive mean.", call. = FALSE)
      log(1 + 1 / mean)
    },
    gamma = {
      if (is.null(dispersion) || any(dispersion <= 0)) stop("Gamma calibration requires positive dispersion.", call. = FALSE)
      trigamma(1 / dispersion)
    },
    negative_binomial = {
      if (is.null(mean) || any(mean <= 0) || is.null(dispersion) || any(dispersion <= 0)) {
        stop("Negative-binomial calibration requires positive mean and dispersion.", call. = FALSE)
      }
      trigamma((1 / mean + dispersion)^(-1))
    }
  )
  data.frame(
    icc = icc,
    distribution = distribution,
    random_effect_variance = (icc / (1 - icc)) * residual_variance,
    row.names = NULL
  )
}

#' Calibrate logistic coefficients to prevalence and treatment contrast
#'
#' @param data Covariate data.
#' @param coefficients Named covariate coefficients.
#' @param prevalence Target population prevalence.
#' @param risk_ratio Optional treated/control risk ratio.
#' @param risk_difference Optional treated-control risk difference.
#' @param treatment Name for the optional treatment coefficient.
#' @param treatment_prevalence Treatment prevalence used for calibration.
#' @param auc Optional target population area under the ROC curve. Covariate
#'   coefficients are proportionally scaled to reach this target.
#' @param tolerance Numerical root tolerance.
#'
#' @return A base `data.frame` with one row per calibrated coefficient.
#' @export
#'
#' @examples
#' set.seed(1)
#' covariates <- data.frame(x1 = stats::rnorm(200), x2 = stats::rnorm(200))
#'
#' calibrate_logistic(
#'   covariates, coefficients = c(x1 = 0.5, x2 = -0.3), prevalence = 0.2
#' )
#'
#' # Scale the coefficients to hit a target discrimination instead.
#' calibrate_logistic(
#'   covariates, coefficients = c(x1 = 0.5, x2 = -0.3),
#'   prevalence = 0.2, auc = 0.75
#' )
calibrate_logistic <- function(data, coefficients, prevalence,
                               risk_ratio = NULL, risk_difference = NULL,
                               treatment = "treatment",
                               treatment_prevalence = 0.5,
                               auc = NULL,
                               tolerance = 1e-8) {
  stopifnot(
    "`data` must be a data frame, with at least one row" =
      is.data.frame(data) &&
        nrow(data) >= 1L,
    "`coefficients` must be a named numeric vector" =
      is.numeric(coefficients) &&
        !is.null(names(coefficients)) &&
        all(names(coefficients) %in% names(data)),
    "`prevalence` must be a single number strictly between 0 and 1" =
      is.numeric(prevalence) &&
        length(prevalence) == 1L &&
        all(prevalence > 0) &&
        all(prevalence < 1),
    "`risk_ratio` must be NULL or a single number" =
      is.null(risk_ratio) || (is.numeric(risk_ratio) && length(risk_ratio) == 1L),
    "`risk_difference` must be NULL or a single number" =
      is.null(risk_difference) || (is.numeric(risk_difference) && length(risk_difference) == 1L),
    "`treatment` must be a single non-empty string" =
      is.character(treatment) &&
        length(treatment) == 1L &&
        all(nzchar(treatment)),
    "`treatment_prevalence` must be a single number strictly between 0 and 1" =
      is.numeric(treatment_prevalence) &&
        length(treatment_prevalence) == 1L &&
        all(treatment_prevalence > 0) &&
        all(treatment_prevalence < 1),
    "`auc` must be NULL or a single number in [0.5, 1)" =
      is.null(auc) || (is.numeric(auc) && length(auc) == 1L && auc >= 0.5 && auc < 1),
    "`tolerance` must be a single positive number" =
      is.numeric(tolerance) &&
        length(tolerance) == 1L &&
        all(tolerance > 0)
  )
  if (!is.null(risk_ratio) && !is.null(risk_difference)) {
    stop("Supply risk_ratio or risk_difference, not both.", call. = FALSE)
  }
  design <- as.matrix(data[, names(coefficients), drop = FALSE])
  if (!is.numeric(design) || anyNA(design)) stop("Calibration covariates must be complete numeric data.", call. = FALSE)
  expected_auc <- function(score, probabilities) {
    ordered <- order(score)
    score <- score[ordered]
    probabilities <- probabilities[ordered]
    controls <- 1 - probabilities
    groups <- split(seq_along(score), score)
    control_before <- cumsum(c(
      0,
      vapply(groups, function(indices) sum(controls[indices]), numeric(1))
    ))
    contribution <- Map(function(indices, before) {
      sum(probabilities[indices]) * (before + 0.5 * sum(controls[indices]))
    }, groups, utils::head(control_before, -1L))
    sum(unlist(contribution)) / (sum(probabilities) * sum(controls))
  }
  coefficient_scale <- 1
  if (!is.null(auc)) {
    unscaled_score <- as.vector(design %*% coefficients)
    auc_objective <- function(scale) {
      score <- scale * unscaled_score
      intercept <- .solve_root(
        function(value) mean(stats::plogis(value + score)) - prevalence,
        c(-max(score) - 50, -min(score) + 50),
        what = "the intercept matching the target prevalence", tol = tolerance
      )
      expected_auc(score, stats::plogis(intercept + score)) - auc
    }
    if (auc_objective(100) < 0) {
      stop(errorCondition(
        "Target auc is not attainable with the supplied covariates.",
        class = "simulab_no_solution", call = NULL
      ))
    }
    coefficient_scale <- .solve_root(
      auc_objective, c(0, 100),
      what = "the coefficient scale matching the target auc", tol = tolerance
    )
    coefficients <- coefficients * coefficient_scale
  }
  base_score <- as.vector(design %*% coefficients)
  solve_intercept <- function(treatment_coefficient = 0) {
    objective <- function(intercept) {
      untreated <- stats::plogis(intercept + base_score)
      treated <- stats::plogis(intercept + base_score + treatment_coefficient)
      (1 - treatment_prevalence) * mean(untreated) +
        treatment_prevalence * mean(treated) - prevalence
    }
    bounds <- c(
      -max(base_score + max(0, treatment_coefficient)) - 50,
      -min(base_score + min(0, treatment_coefficient)) + 50
    )
    .solve_root(objective, bounds,
                what = "the intercept matching the target prevalence", tol = tolerance)
  }
  treatment_coefficient <- 0
  target_type <- if (is.null(auc)) "prevalence" else "auc"
  if (!is.null(risk_ratio) || !is.null(risk_difference)) {
    target_type <- if (is.null(risk_ratio)) "risk_difference" else "risk_ratio"
    target <- if (is.null(risk_ratio)) risk_difference else risk_ratio
    contrast <- function(beta) {
      intercept <- solve_intercept(beta)
      risk_control <- mean(stats::plogis(intercept + base_score))
      risk_treated <- mean(stats::plogis(intercept + base_score + beta))
      observed <- if (identical(target_type, "risk_ratio")) {
        risk_treated / risk_control
      } else {
        risk_treated - risk_control
      }
      observed - target
    }
    treatment_coefficient <- .solve_root(
      contrast, c(-40, 40),
      what = sprintf("the treatment coefficient matching the target %s",
                     sub("_", " ", target_type)),
      tol = tolerance
    )
  }
  intercept <- solve_intercept(treatment_coefficient)
  has_treatment <- !is.null(risk_ratio) || !is.null(risk_difference)
  result <- data.frame(
    term = c("(Intercept)", if (has_treatment) treatment else character(0L), names(coefficients)),
    coefficient = c(intercept, if (has_treatment) treatment_coefficient else numeric(0L), coefficients),
    calibration = target_type,
    coefficient_scale = coefficient_scale,
    stringsAsFactors = FALSE,
    row.names = NULL
  )
  result
}
