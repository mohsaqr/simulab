#' Simulate a prediction design with continuous and categorical predictors
#'
#' @param n Sample size.
#' @param coefficients Named continuous-predictor coefficients with optional
#'   `(Intercept)`.
#' @param categorical_levels Named list of levels for categorical predictors,
#'   or a tidy data frame with columns `variable` and `level`. Optional
#'   `effect` and `probability` columns in that table supply
#'   `categorical_effects` and `category_probabilities`, so one table replaces
#'   all three arguments.
#' @param categorical_effects Named list of level effects matching
#'   `categorical_levels`.
#' @param category_probabilities Optional named list of sampling probabilities.
#' @param predictor_means,predictor_sds Continuous-predictor parameters.
#' @param error_sd Residual standard deviation.
#' @param outcome Outcome-column name.
#' @param seed Optional random seed.
#'
#' @return A `simulab_sim` base `data.frame` with coefficient, categorical
#'   effect, and population R-squared tables.
#' @export
#'
#' @examples
#' result <- simulate_prediction(
#'   n = 200,
#'   coefficients = c("(Intercept)" = 0.5, x1 = 1, x2 = -1),
#'   seed = 1
#' )
#' head(result)
#' as.data.frame(result, what = "coefficients")
simulate_prediction <- function(n, coefficients,
                                categorical_levels = NULL,
                                categorical_effects = NULL,
                                category_probabilities = NULL,
                                predictor_means = 0, predictor_sds = 1,
                                error_sd = 1, outcome = "outcome",
                                seed = NULL) {
  if (.is_tidy_input(categorical_levels)) {
    ## One tidy table carries the levels, and optionally their effects and
    ## sampling probabilities, so three parallel lists collapse into one input.
    .require_columns(categorical_levels, c("variable", "level"), "categorical_levels")
    categories <- categorical_levels
    if (is.null(categorical_effects) && "effect" %in% names(categories)) {
      categorical_effects <- .tidy_to_vector_list(
        categories, "categorical_effects", "variable", "effect", name = "level")
    }
    if (is.null(category_probabilities) && "probability" %in% names(categories)) {
      category_probabilities <- .tidy_to_vector_list(
        categories, "category_probabilities", "variable", "probability",
        name = "level")
    }
    categorical_levels <- .tidy_to_vector_list(
      categories, "categorical_levels", "variable", "level")
  }
  stopifnot(
    "`n` must be a single whole number of at least 2" =
      is.numeric(n) &&
        length(n) == 1L &&
        all(n >= 2) &&
        all(n == as.integer(n)),
    "`coefficients` must be a named numeric vector" =
      is.numeric(coefficients) &&
        !is.null(names(coefficients)),
    "`categorical_levels` must be NULL or a list" =
      is.null(categorical_levels) || is.list(categorical_levels),
    "`categorical_effects` must be NULL or a list" =
      is.null(categorical_effects) || is.list(categorical_effects),
    "`category_probabilities` must be NULL or a list" =
      is.null(category_probabilities) || is.list(category_probabilities),
    "`error_sd` must be a single positive number" =
      is.numeric(error_sd) &&
        length(error_sd) == 1L &&
        all(error_sd > 0),
    "`outcome` must be a single non-empty string" =
      is.character(outcome) &&
        length(outcome) == 1L &&
        all(nzchar(outcome))
  )
  if (is.null(categorical_levels)) {
    return(simulate_regression(
      n, coefficients, predictor_means, predictor_sds,
      error_sd = error_sd, outcome = outcome, seed = seed
    ))
  }
  if (is.null(names(categorical_levels)) || any(!nzchar(names(categorical_levels)))) {
    stop("categorical_levels must be a named list.", call. = FALSE)
  }
  if (is.null(categorical_effects) ||
      !identical(names(categorical_effects), names(categorical_levels))) {
    stop("categorical_effects must match categorical_levels by name.", call. = FALSE)
  }
  valid_effects <- Map(function(levels, effects) {
    length(levels) >= 2L && length(levels) == length(effects) &&
      is.numeric(effects) && !anyDuplicated(levels)
  }, categorical_levels, categorical_effects)
  if (!all(unlist(valid_effects))) {
    stop("Every categorical predictor needs unique levels and one numeric effect per level.",
         call. = FALSE)
  }
  continuous_names <- setdiff(names(coefficients), "(Intercept)")
  intercept <- if ("(Intercept)" %in% names(coefficients)) coefficients[["(Intercept)"]] else 0
  slopes <- coefficients[continuous_names]
  if (length(predictor_means) == 1L) predictor_means <- rep(predictor_means, length(slopes))
  if (length(predictor_sds) == 1L) predictor_sds <- rep(predictor_sds, length(slopes))
  if (length(predictor_means) != length(slopes) ||
      length(predictor_sds) != length(slopes) || any(predictor_sds <= 0)) {
    stop("Continuous predictor parameters must match coefficients.", call. = FALSE)
  }
  probabilities <- if (is.null(category_probabilities)) {
    lapply(categorical_levels, function(levels) rep(1 / length(levels), length(levels)))
  } else category_probabilities
  if (!identical(names(probabilities), names(categorical_levels)) ||
      !all(unlist(Map(function(levels, probability) {
        is.numeric(probability) && length(probability) == length(levels) &&
          all(probability >= 0) && abs(sum(probability) - 1) <= 1e-8
      }, categorical_levels, probabilities)))) {
    stop("category_probabilities must match levels and sum to one.", call. = FALSE)
  }
  generated <- .with_seed(seed, {
    continuous <- if (length(slopes)) vapply(seq_along(slopes), function(index) {
      stats::rnorm(as.integer(n), predictor_means[index], predictor_sds[index])
    }, numeric(as.integer(n))) else matrix(numeric(0L), as.integer(n), 0L)
    categories <- Map(function(levels, probability) {
      sample(levels, as.integer(n), replace = TRUE, prob = probability)
    }, categorical_levels, probabilities)
    categorical_signal <- Reduce(`+`, Map(function(value, levels, effects) {
      effects[match(value, levels)]
    }, categories, categorical_levels, categorical_effects), init = rep(0, as.integer(n)))
    signal <- intercept + categorical_signal
    if (length(slopes)) signal <- signal + as.vector(continuous %*% slopes)
    response <- signal + stats::rnorm(as.integer(n), sd = error_sd)
    list(continuous = continuous, categories = categories,
         signal = signal, response = response)
  })
  continuous_data <- as.data.frame(generated$continuous, check.names = FALSE)
  names(continuous_data) <- continuous_names
  categorical_data <- as.data.frame(generated$categories, stringsAsFactors = FALSE,
                                    check.names = FALSE)
  data <- data.frame(id = seq_len(as.integer(n)), continuous_data, categorical_data,
                     response = generated$response, check.names = FALSE, row.names = NULL)
  names(data)[ncol(data)] <- outcome
  category_table <- do.call(rbind, Map(function(variable, levels, effects, probability) {
    data.frame(variable = variable, level = levels, effect = effects,
               probability = probability, stringsAsFactors = FALSE, row.names = NULL)
  }, names(categorical_levels), categorical_levels, categorical_effects, probabilities))
  coefficient_table <- data.frame(term = c("(Intercept)", continuous_names),
                                  coefficient = c(intercept, slopes), row.names = NULL)
  signal_variance <- stats::var(generated$signal)
  effects <- data.frame(signal_variance = signal_variance,
                        residual_variance = error_sd^2,
                        r_squared = signal_variance / (signal_variance + error_sd^2),
                        row.names = NULL)
  .new_simulab_sim(data, "prediction", seed,
                   list(coefficients = coefficient_table,
                        categorical_effects = category_table, effects = effects))
}

#' Simulate proportional-hazards survival data with calibrated censoring
#'
#' @param n Sample size.
#' @param coefficients Covariate log-hazard coefficients.
#' @param baseline Weibull, exponential, or Gompertz baseline.
#' @param rate Positive baseline rate.
#' @param shape Positive Weibull/Gompertz shape.
#' @param censoring Target censoring fraction.
#' @param covariate_distribution Normal or binary covariates.
#' @param seed Optional random seed.
#'
#' @return A `simulab_sim` base `data.frame` with observed time, status,
#'   covariates, and tidy parameters.
#' @export
#'
#' @examples
#' result <- simulate_proportional_survival(
#'   n = 200,
#'   coefficients = c(x1 = 0.7),
#'   shape = 1.5,
#'   censoring = 0.2,
#'   seed = 1
#' )
#' head(result)
#' as.data.frame(result, what = "parameters")
simulate_proportional_survival <- function(n, coefficients,
                                           baseline = c("weibull", "exponential", "gompertz"),
                                           rate = 0.1, shape = 1,
                                           censoring = 0.3,
                                           covariate_distribution = c("normal", "binary"),
                                           seed = NULL) {
  baseline <- match.arg(baseline)
  covariate_distribution <- match.arg(covariate_distribution)
  stopifnot(
    "`n` must be a single whole number of at least 5" =
      is.numeric(n) &&
        length(n) == 1L &&
        all(n >= 5) &&
        all(n == as.integer(n)),
    "`coefficients` must be a numeric vector, with at least one element" =
      is.numeric(coefficients) &&
        length(coefficients) >= 1L,
    "`rate` must be a single positive number" =
      is.numeric(rate) &&
        length(rate) == 1L &&
        all(rate > 0),
    "`shape` must be a single positive number" =
      is.numeric(shape) &&
        length(shape) == 1L &&
        all(shape > 0),
    "`censoring` must be a single number in [0, 1)" =
      is.numeric(censoring) &&
        length(censoring) == 1L &&
        all(censoring >= 0) &&
        all(censoring < 1)
  )
  if (is.null(names(coefficients))) names(coefficients) <- sprintf("X%d", seq_along(coefficients))
  generated <- .with_seed(seed, {
    x <- matrix(if (covariate_distribution == "binary") {
      stats::rbinom(as.integer(n) * length(coefficients), 1L, 0.5)
    } else stats::rnorm(as.integer(n) * length(coefficients)),
    nrow = as.integer(n))
    eta <- as.vector(x %*% coefficients)
    budget <- -log(stats::runif(as.integer(n)))
    event_time <- switch(
      baseline,
      weibull = (budget / (rate * exp(eta)))^(1 / shape),
      exponential = budget / (rate * exp(eta)),
      gompertz = log1p(shape * budget / (rate * exp(eta))) / shape
    )
    censor_rate <- if (censoring == 0) 0 else .solve_root(
      function(value) mean(1 - exp(-value * event_time)) - censoring,
      c(.Machine$double.eps, 1e8),
      what = "the censoring rate matching the target censoring proportion"
    )
    censor_time <- if (censoring == 0) rep(Inf, as.integer(n)) else
      stats::rexp(as.integer(n), censor_rate)
    list(x = x, event_time = event_time, censor_time = censor_time,
         censor_rate = censor_rate)
  })
  data <- data.frame(
    id = seq_len(as.integer(n)),
    time = pmin(generated$event_time, generated$censor_time),
    status = as.integer(generated$event_time <= generated$censor_time),
    generated$x, check.names = FALSE, row.names = NULL
  )
  names(data) <- c("id", "time", "status", names(coefficients))
  parameters <- data.frame(
    term = c(names(coefficients), "baseline_rate", "shape", "censoring_rate"),
    value = c(coefficients, rate, shape, generated$censor_rate), row.names = NULL
  )
  diagnostics <- data.frame(target_censoring = censoring,
                            realized_censoring = mean(data$status == 0L),
                            baseline = baseline, row.names = NULL)
  .new_simulab_sim(data, "proportional_survival", seed,
                   list(parameters = parameters, diagnostics = diagnostics))
}
