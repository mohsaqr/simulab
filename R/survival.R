#' Define a survival process
#'
#' Records one Weibull hazard segment for one event time. The simstudy
#' parameterization is used throughout: an event time drawn from this segment
#' has survival function `S(t) = exp(-exp(formula) * t^(1 / shape) / scale)`, so
#' `shape` is the *reciprocal* of the textbook Weibull shape, and
#' `exp(formula)` multiplies the whole cumulative hazard. A coefficient inside
#' `formula` is therefore a log hazard ratio, while `formula` itself equals the
#' log hazard only when `shape` and `scale` are both 1.
#'
#' @param event Name of the event-time variable. A single non-empty string.
#' @param formula Linear predictor on the log scale, given as a number, a
#'   string, or an unquoted expression over the covariate columns (for example
#'   `"-8 + 0.5 * treatment"`). Defaults to `0`. It is stored as text and
#'   evaluated row by row against the data.
#' @param scale Positive Weibull scale, as a number, a string, or an expression
#'   over the covariates. Defaults to `1`. It divides the cumulative hazard.
#' @param shape Positive Weibull shape in the simstudy parameterization (the
#'   exponent applied to the transformed time, so the hazard is constant when
#'   `shape` is 1 and decreasing when `shape` is above 1). Defaults to `1`.
#' @param transition Time at which this hazard segment begins. A single finite
#'   non-negative number, defaulting to `0`. The first segment of an event must
#'   start at `0`.
#'
#' @return A one-row `simulab_survival_spec` base `data.frame` with columns
#'   `event`, `formula`, `scale` and `shape` (all character, the stored
#'   definition text) and the numeric column `transition`.
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

#' Combine survival definitions into a specification
#'
#' @param ... One of three forms.
#'
#'   **Hazard calls.** `time = hazard(log_rate = -8 + 0.5 * treatment, shape = 0.3)`
#'   names the event with the argument name and states its hazard as a call.
#'   `log_rate` is the linear predictor on the log scale, the `formula` of
#'   [define_survival()], so a coefficient inside it is a log hazard ratio. It
#'   may be any expression over the covariates; `shape` and `scale` default to 1
#'   and `from`, the time at which the segment begins, to 0. Arguments may be
#'   positional, in the order `log_rate`, `shape`, `scale`, `from`, or named,
#'   and repeating the argument name gives one event several segments, which is
#'   a piecewise hazard.
#'
#'   **Specification columns** given as named vectors (`event`, `formula`,
#'   `scale`, `shape`, `transition`).
#'
#'   **Objects** created by [define_survival()].
#'
#'   The forms cannot be mixed in one call.
#'
#'   In the column form, `event` and `formula` are required. A column given as
#'   a single value is recycled across every row. `scale` and `shape` default
#'   to 1 and `transition` to 0. Two rows for one event with different
#'   `transition` times give a piecewise hazard.
#'
#' @return A `simulab_survival_spec` base `data.frame` with one row per hazard
#'   segment and the columns of [define_survival()]: `event`, `formula`,
#'   `scale`, `shape` and `transition`. Rows written by the column form and by
#'   the hazard-call form are ordered by `event` and then `transition`.
#' @export
#'
#' @examples
#' # One call, named arguments, one row per event.
#' define_survivals(
#'   event   = c("time_relapse", "time_death"),
#'   formula = c(-8, -9),
#'   shape   = 0.3
#' )
#'
#' # A piecewise hazard is two rows for one event.
#' define_survivals(
#'   event      = c("time", "time"),
#'   formula    = c(-8, -6),
#'   shape      = 0.3,
#'   transition = c(0, 50)
#' )
#'
#' # Definitions built one at a time are still accepted.
#' define_survivals(
#'   define_survival("time_relapse", formula = -8, shape = 0.3),
#'   define_survival("time_death", formula = -9, shape = 0.3)
#' )
#'
#' # Hazard calls. The log rate is an expression over the covariates.
#' define_survivals(
#'   time_relapse = hazard(log_rate = -8 + 0.5 * treatment, shape = 0.3),
#'   time_death   = hazard(log_rate = -9, shape = 0.3)
#' )
#'
#' # A repeated event name is a piecewise hazard: the rate rises after day 60.
#' define_survivals(
#'   time = hazard(log_rate = -8, shape = 0.3),
#'   time = hazard(log_rate = -5, shape = 0.3, from = 60)
#' )
define_survivals <- function(...) {
  ## The hazard lane is detected before evaluation, because a log-rate is an
  ## expression over covariates rather than a value the caller can supply.
  captured <- as.list(substitute(list(...)))[-1L]
  if (.is_hazard_call_lane(captured)) {
    result <- .hazard_calls_to_specification(captured, parent.frame())
    result <- result[order(result$event, result$transition), , drop = FALSE]
    return(.validate_survival_specification(result))
  }

  definitions <- list(...)
  stopifnot(
    "`...` must contain at least one definition or one specification column" =
      length(definitions) >= 1L
  )

  from_constructor <- vapply(definitions, inherits, logical(1),
                             what = "simulab_survival_spec")
  if (all(from_constructor)) {
    result <- do.call(rbind, lapply(definitions, as.data.frame))
  } else if (any(from_constructor)) {
    stop(errorCondition(
      paste0("Give either specification columns or objects from ",
             "define_survival(), not both in one call."),
      class = "simulab_mixed_specification", call = NULL
    ))
  } else {
    result <- .spec_from_columns(
      definitions,
      required = c("event", "formula"),
      defaults = list(scale = "1", shape = "1", transition = 0),
      coerce = list(transition = .as_number)
    )
    result <- result[order(result$event, result$transition), , drop = FALSE]
  }

  .validate_survival_specification(result)
}

## A piecewise hazard must cover time from zero onwards without a gap or a
## repeat, whichever lane wrote it.
.validate_survival_specification <- function(result) {
  event_groups <- split(result$transition, result$event)
  invalid <- vapply(event_groups, function(transitions) {
    transitions[1L] != 0 || is.unsorted(transitions, strictly = TRUE)
  }, logical(1))
  if (any(invalid)) {
    stop(errorCondition(
      "Each event must begin at transition zero and have increasing transitions.",
      class = "simulab_bad_transition", call = NULL
    ))
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
#' Draws one latent event time per process for every row of `data`, from the
#' Weibull hazard of [define_survival()]. The times are uncensored: censoring
#' and competing-risk coding are applied afterwards, for example with
#' [combine_competing_risks()]. An event with several rows in `specification`
#' has a piecewise hazard, whose `scale` and `shape` must stay constant across
#' its segments.
#'
#' @param data Baseline base `data.frame`, or a `simulab_sim`, with at least one
#'   row. Its columns are the covariates the formulas may refer to, and none of
#'   them may already carry an event name.
#' @param specification Definitions from [define_survivals()], a
#'   `simulab_survival_spec` object.
#' @param seed Optional random seed. A single number, or `NULL` (the default) to
#'   leave the stream untouched.
#' @param digits Optional number of decimal places the event times are rounded
#'   to. A single non-negative whole number, or `NULL` (the default) for
#'   unrounded times.
#' @param envir Environment the formulas are evaluated in after the data
#'   columns. Defaults to the caller's environment.
#'
#' @return A `simulab_sim` base `data.frame` with the columns of `data` followed
#'   by one numeric event-time column per process, named by its `event`, and one
#'   row per input row. The component `survival_definitions`, reached with
#'   `as.data.frame(x, what = "survival_definitions")`, is the specification as
#'   a plain `data.frame`.
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
#' Reduces several latent event times to the one observed first: the observed
#' time is their row-wise minimum and the event code says which process won.
#' Naming one of them in `censor` turns that process into censoring, so its code
#' is `0` and the remaining processes are coded `1, 2, ...` in the order they
#' appear in `events`. Without `censor` every row is an event and no code is
#' `0`. Ties are broken in favor of the earlier entry of `events`.
#'
#' @param data Base `data.frame`, or a `simulab_sim`, containing the event-time
#'   variables, with at least one row.
#' @param events Event-time variable names. A character vector of at least two
#'   names, all present in `data`, holding complete numeric times.
#' @param censor Optional name of the one entry of `events` that represents
#'   censoring rather than an event. A single string, or `NULL` (the default)
#'   when every process is an event.
#' @param time Name of the observed-time variable. A single string, defaulting
#'   to `"time"`.
#' @param event Name of the integer event-code variable. A single string,
#'   defaulting to `"event"`. The code is `0` for the process named in `censor`
#'   and `1, 2, ...` for the other entries of `events`, in their given order.
#' @param type Name of the character event-type variable, holding the winning
#'   process name. A single string, defaulting to `"event_type"`.
#' @param keep_events Retain the component event-time variables. A single flag,
#'   defaulting to `FALSE`, which drops them.
#'
#' @return A `simulab_sim` base `data.frame` with one row per input row: the
#'   columns of `data` (without the entries of `events` unless `keep_events` is
#'   `TRUE`) followed by `time`, `event` and `type` under the names given by
#'   those arguments. The component `events`, reached with
#'   `as.data.frame(x, what = "events")`, is the codebook, one row per process
#'   with columns `event_type`, `event_code` and the logical `censoring`.
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
#' Finds the `formula` and `shape` whose simstudy Weibull curve,
#' `S(t) = exp(-exp(formula) * t^(1 / shape))` with `scale` fixed at 1, passes
#' as closely as possible through the supplied points. The fit is a
#' least-squares fit of `log(time)` on `log(-log(survival))`, run with
#' `L-BFGS-B`, and the returned `formula` and `shape` can be handed straight to
#' [define_survival()] or [survival_curve()].
#'
#' @param time Increasing positive times. A finite numeric vector of at least
#'   two strictly increasing values, the same length as `survival`.
#' @param survival Survival probabilities at those times. A finite numeric
#'   vector strictly inside `(0, 1)` and strictly decreasing.
#'
#' @return A one-row base `data.frame` with the calibrated numeric `formula` and
#'   `shape`, the `optim()` `convergence` code (always `0`, since a
#'   non-converged fit raises an error), and `rmse`, the root mean squared
#'   residual **on the log-time scale**.
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
#' Evaluates the simstudy Weibull curve of [define_survival()],
#' `S(t) = exp(-exp(formula) * t^(1 / shape) / scale)`, at `n` survival
#' probabilities spread evenly from `1 - 1 / n` down to `1 / n`, inverting it
#' for the matching times. The points are therefore equally spaced in survival
#' probability, not in time.
#'
#' @param formula Intercept of the linear predictor on the log scale. A single
#'   finite number. `exp(formula)` multiplies the cumulative hazard, and equals
#'   the hazard only when `shape` and `scale` are both 1.
#' @param shape Positive Weibull shape in the simstudy parameterization, the
#'   exponent applied to the transformed time. A single positive number.
#' @param scale Positive Weibull scale, dividing the cumulative hazard. A single
#'   positive number, defaulting to `1`.
#' @param n Number of curve points. A single whole number of at least 2,
#'   defaulting to `100`.
#' @param time_limits Optional inclusive time range, as an increasing
#'   non-negative numeric vector of length 2, that the curve is restricted to.
#'   Defaults to `NULL`, the whole curve. Points outside the range are dropped,
#'   so fewer than `n` rows are returned.
#'
#' @return A base `data.frame` with one row per retained curve point, in
#'   increasing time order, and columns `time` and `survival`.
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
