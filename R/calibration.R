#' Convert mean/dispersion parameterizations
#'
#' @param distribution Beta, gamma, or negative-binomial distribution.
#' @param mean Distribution mean.
#' @param dispersion Beta precision or gamma/negative-binomial dispersion.
#'
#' @return A base `data.frame` with one row per input value and the corresponding
#'   base-R distribution parameters.
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
  output_length <- max(length(mean), length(dispersion))
  if (!length(mean) %in% c(1L, output_length) ||
      !length(dispersion) %in% c(1L, output_length)) {
    stop("mean and dispersion must have compatible lengths.", call. = FALSE)
  }
  mean <- rep(mean, length.out = output_length)
  dispersion <- rep(dispersion, length.out = output_length)
  if (any(dispersion <= 0)) stop("dispersion must be positive.", call. = FALSE)

  switch(
    distribution,
    beta = {
      if (any(mean <= 0 | mean >= 1)) stop("Beta means must lie strictly between zero and one.", call. = FALSE)
      data.frame(
        distribution = distribution,
        mean = mean,
        dispersion = dispersion,
        parameter_1 = "shape1",
        value_1 = mean * dispersion,
        parameter_2 = "shape2",
        value_2 = (1 - mean) * dispersion,
        stringsAsFactors = FALSE,
        row.names = NULL
      )
    },
    gamma = {
      if (any(mean <= 0)) stop("Gamma means must be positive.", call. = FALSE)
      data.frame(
        distribution = distribution,
        mean = mean,
        dispersion = dispersion,
        parameter_1 = "shape",
        value_1 = 1 / dispersion,
        parameter_2 = "rate",
        value_2 = 1 / (mean * dispersion),
        stringsAsFactors = FALSE,
        row.names = NULL
      )
    },
    negative_binomial = {
      if (any(mean < 0)) stop("Negative-binomial means cannot be negative.", call. = FALSE)
      data.frame(
        distribution = distribution,
        mean = mean,
        dispersion = dispersion,
        parameter_1 = "size",
        value_1 = 1 / dispersion,
        parameter_2 = "probability",
        value_2 = 1 / (1 + mean * dispersion),
        stringsAsFactors = FALSE,
        row.names = NULL
      )
    }
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
