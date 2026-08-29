#' Define a survival process
#'
#' @param event Name of the event-time variable.
#' @param formula Log-hazard formula.
#' @param scale Positive Weibull scale formula.
#' @param shape Positive Weibull shape formula in the simstudy parameterization.
#' @param transition Time at which this hazard specification begins.
#'
#' @return A one-row `simulab_survival_spec` base `data.frame`.
#' @export
#'
#' @examples
#' define_survival("time", formula = -8, shape = 0.3)
define_survival <- function(event, formula = 0, scale = 1, shape = 1,
                            transition = 0) {
  stopifnot(
    "`event` must be a single non-empty string" =
      is.character(event) &&
        length(event) == 1L &&
        all(nzchar(event)),
    "`formula` must have at least one element" =
      length(formula) >= 1L,
    "`scale` must have at least one element" =
      length(scale) >= 1L,
    "`shape` must have at least one element" =
      length(shape) >= 1L,
    "`transition` must be a single finite non-negative number" =
      is.numeric(transition) &&
        length(transition) == 1L &&
        all(is.finite(transition)) &&
        all(transition >= 0)
  )
  result <- data.frame(
    event = event,
    formula = .definition_text(formula),
    scale = .definition_text(scale),
    shape = .definition_text(shape),
    transition = transition,
    stringsAsFactors = FALSE,
    row.names = NULL
  )
  class(result) <- c("simulab_survival_spec", "data.frame")
  result
}

#' Combine survival definitions
#'
#' @param ... Objects created by `define_survival()`.
#'
#' @return A `simulab_survival_spec` base `data.frame` with one row per hazard
#'   segment.
#' @export
#'
#' @examples
#' define_survivals(
#'   define_survival("time_relapse", formula = -8, shape = 0.3),
#'   define_survival("time_death", formula = -9, shape = 0.3)
#' )
define_survivals <- function(...) {
  definitions <- list(...)
  stopifnot(
    "`definitions` must be a list of `simulab_survival_spec` objects, with at least one element" =
      length(definitions) >= 1L &&
        all(vapply(definitions, inherits, logical(1), what = "simulab_survival_spec"))
  )
  result <- do.call(rbind, lapply(definitions, as.data.frame))
  event_groups <- split(result$transition, result$event)
  invalid <- vapply(event_groups, function(transitions) {
    transitions[1L] != 0 || is.unsorted(transitions, strictly = TRUE)
  }, logical(1))
  if (any(invalid)) {
    stop("Each event must begin at transition zero and have increasing transitions.", call. = FALSE)
  }
  class(result) <- c("simulab_survival_spec", "data.frame")
  rownames(result) <- NULL
  result
}

.draw_piecewise_survival <- function(data, definition, envir) {
  stopifnot(
    "`data` must be a data frame, with at least one row" =
      is.data.frame(data) &&
        nrow(data) >= 1L,
    "`definition` must be a `simulab_survival_spec` object" =
      inherits(definition, "simulab_survival_spec") || is.data.frame(definition) &&
        length(unique(definition$event)) == 1L,
    "`envir` must be an environment" =
      is.environment(envir)
  )
  n <- nrow(data)
  segment_count <- nrow(definition)
  linear_predictors <- .eval_definitions(definition$formula, data, n, envir)
  scales <- .eval_definitions(definition$scale, data, n, envir)
  shapes <- .eval_definitions(definition$shape, data, n, envir)
  if (any(scales <= 0) || any(shapes <= 0)) {
    stop("Survival scales and shapes must be positive.", call. = FALSE)
  }
  if (segment_count > 1L &&
      (any(abs(scales - scales[, 1L]) > 1e-12) ||
       any(abs(shapes - shapes[, 1L]) > 1e-12))) {
    stop("Scale and shape must remain constant across transitions for an event.", call. = FALSE)
  }
  transitions <- definition$transition
  event_budget <- -log(stats::runif(n))

  vapply(seq_len(n), function(observation) {
    shape <- shapes[observation, 1L]
    scale <- scales[observation, 1L]
    rates <- exp(linear_predictors[observation, ]) / scale
    transformed_starts <- transitions^(1 / shape)
    transformed_ends <- c(transformed_starts[-1L], Inf)
    capacity <- rates * (transformed_ends - transformed_starts)
    cumulative <- cumsum(capacity)
    segment <- which(event_budget[observation] <= cumulative)[1L]
    spent <- if (segment == 1L) 0 else cumulative[segment - 1L]
    transformed_time <- transformed_starts[segment] +
      (event_budget[observation] - spent) / rates[segment]
    transformed_time^shape
  }, numeric(1))
}

#' Add one or more survival processes to data
#'
#' @param data Baseline base `data.frame`.
#' @param specification Definitions from `define_survivals()`.
#' @param seed Optional random seed.
#' @param digits Optional number of decimal places.
#' @param envir Formula evaluation environment.
#'
#' @return A `simulab_sim` base `data.frame` with one event-time variable per
#'   process.
#' @export
#'
#' @examples
#' data <- data.frame(id = 1:100, treatment = rep(0:1, each = 50))
#'
#' result <- augment_survival(
#'   data,
#'   specification = define_survivals(
#'     define_survival("time", formula = "-8 + 0.5 * treatment", shape = 0.3)
#'   ),
#'   seed = 1
#' )
#' head(result)
augment_survival <- function(data, specification, seed = NULL, digits = NULL,
                             envir = parent.frame()) {
  stopifnot(
    "`data` must be a data frame, with at least one row" =
      is.data.frame(data) &&
        nrow(data) >= 1L,
    "`specification` must be a `simulab_survival_spec` object" =
      inherits(specification, "simulab_survival_spec"),
    "`seed` must be NULL or a single number" =
      is.null(seed) || (is.numeric(seed) && length(seed) == 1L),
    "`digits` must be NULL or a single non-negative whole number" =
      is.null(digits) || (is.numeric(digits) && length(digits) == 1L && digits >= 0 && digits == as.integer(digits)),
    "`envir` must be an environment" =
      is.environment(envir)
  )
  source <- .as_result_data(data)
  events <- unique(specification$event)
  if (any(events %in% names(source))) {
    stop("Survival event names must not already exist in data.", call. = FALSE)
  }
  event_definitions <- lapply(events, function(event) {
    specification[specification$event == event, , drop = FALSE]
  })
  event_times <- .with_seed(seed, lapply(event_definitions, function(definition) {
    .draw_piecewise_survival(source, definition, envir)
  }))
  if (!is.null(digits)) event_times <- lapply(event_times, round, digits = as.integer(digits))
  names(event_times) <- events
  result <- data.frame(source, event_times, check.names = FALSE, row.names = NULL)
  definitions <- as.data.frame(specification)
  class(definitions) <- "data.frame"
  .new_simulab_sim(result, type = "survival", seed = seed,
                   tables = list(survival_definitions = definitions))
}

#' Combine competing event times
#'
#' @param data Base `data.frame` containing event-time variables.
#' @param events Event-time variable names.
#' @param censor Optional censoring-event variable.
#' @param time Name of the observed-time variable.
#' @param event Name of the integer event-code variable.
#' @param type Name of the event-type variable.
#' @param keep_events Retain the component event-time variables.
#'
#' @return A `simulab_sim` base `data.frame` with observed time, event code,
#'   and event type.
#' @export
#'
#' @examples
#' data <- data.frame(id = 1:100, treatment = rep(0:1, each = 50))
#' data <- augment_survival(
#'   data,
#'   specification = define_survivals(
#'     define_survival("time_relapse", formula = -8, shape = 0.3),
#'     define_survival("time_death", formula = -9, shape = 0.3)
#'   ),
#'   seed = 1
#' )
#'
#' result <- combine_competing_risks(
#'   data, events = c("time_relapse", "time_death")
#' )
#' head(result)
combine_competing_risks <- function(data, events, censor = NULL,
                                    time = "time", event = "event",
                                    type = "event_type", keep_events = FALSE) {
  stopifnot(
    "`data` must be a data frame, with at least one row" =
      is.data.frame(data) &&
        nrow(data) >= 1L,
    "`events` must be a character vector naming at least two columns of `data`" =
      is.character(events) &&
        length(events) >= 2L &&
        all(events %in% names(data)),
    "`censor` must be NULL or a single string" =
      is.null(censor) || (is.character(censor) && length(censor) == 1L),
    "`time` must be a single string" =
      is.character(time) &&
        length(time) == 1L,
    "`event` must be a single string" =
      is.character(event) &&
        length(event) == 1L,
    "`type` must be a single string" =
      is.character(type) &&
        length(type) == 1L,
    "`keep_events` must be a single flag" =
      is.logical(keep_events) &&
        length(keep_events) == 1L
  )
  if (!is.null(censor) && !censor %in% events) {
    stop("censor must name one of the competing events.", call. = FALSE)
  }
  source <- .as_result_data(data)
  event_matrix <- as.matrix(source[, events, drop = FALSE])
  if (!is.numeric(event_matrix) || anyNA(event_matrix)) {
    stop("Competing event times must be complete numeric values.", call. = FALSE)
  }
  selected <- max.col(-event_matrix, ties.method = "first")
  selected_type <- events[selected]
  codes <- match(selected_type, setdiff(events, censor))
  if (!is.null(censor)) codes[selected_type == censor] <- 0L
  source[[time]] <- event_matrix[cbind(seq_len(nrow(source)), selected)]
  source[[event]] <- as.integer(codes)
  source[[type]] <- selected_type
  if (!keep_events) source <- source[, setdiff(names(source), events), drop = FALSE]
  codebook <- data.frame(
    event_type = c(if (!is.null(censor)) censor else character(0L), setdiff(events, censor)),
    event_code = c(if (!is.null(censor)) 0L else integer(0L), seq_along(setdiff(events, censor))),
    censoring = c(if (!is.null(censor)) TRUE else logical(0L), rep(FALSE, length(setdiff(events, censor)))),
    stringsAsFactors = FALSE,
    row.names = NULL
  )
  .new_simulab_sim(source, type = "competing_risks", tables = list(events = codebook))
}

#' Calibrate a Weibull survival curve to target points
#'
#' @param time Increasing positive times.
#' @param survival Decreasing survival probabilities.
#'
#' @return A one-row base `data.frame` with calibrated `formula`, `shape`,
#'   convergence code, and root mean squared error.
#' @export
#'
#' @examples
#' calibrate_survival(time = c(50, 100, 150), survival = c(0.9, 0.7, 0.4))
calibrate_survival <- function(time, survival) {
  stopifnot(
    "`survival` must be a finite, strictly decreasing numeric vector of probabilities between 0 and 1" =
      is.numeric(survival) &&
        all(is.finite(survival)) &&
        all(survival > 0 & survival < 1) &&
        !is.unsorted(-survival, strictly = TRUE),
    "`time` must be a finite positive numeric vector, the same length as `survival`" =
      is.numeric(time) &&
        length(time) == length(survival) &&
        length(time) >= 2L &&
        all(is.finite(time)) &&
        all(time > 0) &&
        !is.unsorted(time, strictly = TRUE)
  )
  loss <- function(parameters) {
    predicted_log_time <- parameters[2L] * (log(-log(survival)) - parameters[1L])
    sum((predicted_log_time - log(time))^2)
  }
  fit <- stats::optim(
    par = c(1, 1),
    fn = loss,
    method = "L-BFGS-B",
    lower = c(-Inf, sqrt(.Machine$double.eps)),
    upper = c(Inf, Inf)
  )
  if (fit$convergence != 0L) stop("Survival calibration did not converge.", call. = FALSE)
  data.frame(
    formula = fit$par[1L],
    shape = fit$par[2L],
    convergence = fit$convergence,
    rmse = sqrt(fit$value / length(time)),
    row.names = NULL
  )
}

#' Compute a tidy Weibull survival curve
#'
#' @param formula Log-hazard intercept.
#' @param shape Positive shape parameter.
#' @param scale Positive scale parameter.
#' @param n Number of curve points.
#' @param time_limits Optional time range.
#'
#' @return A base `data.frame` with one row per curve point and columns `time`
#'   and `survival`.
#' @export
#'
#' @examples
#' curve <- survival_curve(formula = -8, shape = 0.3, n = 10)
#' head(curve)
survival_curve <- function(formula, shape, scale = 1, n = 100L,
                           time_limits = NULL) {
  stopifnot(
    "`formula` must be a single finite number" =
      is.numeric(formula) &&
        length(formula) == 1L &&
        all(is.finite(formula)),
    "`shape` must be a single positive number" =
      is.numeric(shape) &&
        length(shape) == 1L &&
        all(shape > 0),
    "`scale` must be a single positive number" =
      is.numeric(scale) &&
        length(scale) == 1L &&
        all(scale > 0),
    "`n` must be a single whole number of at least 2" =
      is.numeric(n) &&
        length(n) == 1L &&
        all(n >= 2) &&
        all(n == as.integer(n)),
    "`time_limits` must be NULL or a non-negative numeric vector of length 2, in increasing order" =
      is.null(time_limits) || (is.numeric(time_limits) && length(time_limits) == 2L && time_limits[1L] >= 0 && time_limits[2L] > time_limits[1L])
  )
  probabilities <- seq(1 - 1 / n, 1 / n, length.out = as.integer(n))
  time <- (-log(probabilities) * scale / exp(formula))^shape
  result <- data.frame(time = time, survival = probabilities, row.names = NULL)
  if (!is.null(time_limits)) {
    result <- result[
      result$time >= time_limits[1L] & result$time <= time_limits[2L],
      , drop = FALSE
    ]
    rownames(result) <- NULL
  }
  result
}
