.transition_input <- function(transition, states = NULL) {
  stopifnot(
    "`transition` must be a matrix or data frame" =
      is.matrix(transition) || is.data.frame(transition)
  )
  if (is.data.frame(transition)) {
    required <- c("from", "to", "probability")
    if (!all(required %in% names(transition))) {
      stop("Tidy transitions require from, to, and probability columns.", call. = FALSE)
    }
    if (is.null(states)) states <- unique(c(transition$from, transition$to))
    matrix_value <- matrix(0, nrow = length(states), ncol = length(states),
                           dimnames = list(states, states))
    row_index <- match(transition$from, states)
    column_index <- match(transition$to, states)
    if (anyNA(row_index) || anyNA(column_index)) {
      stop("Every transition state must appear in states.", call. = FALSE)
    }
    matrix_value[cbind(row_index, column_index)] <- transition$probability
  } else {
    matrix_value <- transition
    if (nrow(matrix_value) != ncol(matrix_value)) {
      stop("Transition matrix must be square.", call. = FALSE)
    }
    if (is.null(states)) states <- rownames(matrix_value)
    if (is.null(states)) states <- seq_len(nrow(matrix_value))
    if (length(states) != nrow(matrix_value) || anyDuplicated(states)) {
      stop("states must contain one unique value per transition row.", call. = FALSE)
    }
    dimnames(matrix_value) <- list(states, states)
  }
  if (!is.numeric(matrix_value) || any(!is.finite(matrix_value)) || any(matrix_value < 0)) {
    stop("Transition probabilities must be finite and non-negative.", call. = FALSE)
  }
  if (any(abs(rowSums(matrix_value) - 1) > 1e-8)) {
    stop("Every transition row must sum to one.", call. = FALSE)
  }
  list(matrix = matrix_value, states = states)
}

.simulate_one_chain <- function(transition, states, chain_length, start) {
  stopifnot(
    "`states` must be an atomic vector" =
      is.atomic(states),
    "`transition` must be a matrix" =
      is.matrix(transition),
    "`chain_length` must be a single number of at least 1" =
      is.numeric(chain_length) &&
        length(chain_length) == 1L &&
        all(chain_length >= 1),
    "`start` must be a single value" =
      length(start) == 1L &&
        all(start %in% states)
  )
  if (chain_length == 1L) return(start)
  chain <- Reduce(
    function(current, step) {
      sample(states, size = 1L, prob = transition[match(current, states), ])
    },
    seq_len(as.integer(chain_length) - 1L),
    init = start,
    accumulate = TRUE
  )
  unlist(chain, use.names = FALSE)
}

.wide_sequences <- function(long_data, id, period, state, prefix = "S") {
  stopifnot(
    "`long_data` must be a data frame" =
      is.data.frame(long_data),
    "`id`, `period` and `state` must name columns of `long_data`" =
      all(c(id, period, state) %in% names(long_data)),
    "`prefix` must be a single string" =
      is.character(prefix) &&
        length(prefix) == 1L
  )
  ids <- unique(long_data[[id]])
  maximum <- max(long_data[[period]])
  rows <- lapply(ids, function(id_value) {
    values <- long_data[long_data[[id]] == id_value, , drop = FALSE]
    output <- rep(NA, maximum)
    output[values[[period]]] <- values[[state]]
    unname(output)
  })
  wide_values <- as.data.frame(do.call(rbind, rows), stringsAsFactors = FALSE)
  result <- data.frame(ids, wide_values, check.names = FALSE, row.names = NULL)
  names(result) <- c(id, sprintf("%s%d", prefix, seq_len(maximum)))
  rownames(result) <- NULL
  result
}

#' Simulate Markov chains
#'
#' @param n Number of chains.
#' @param transition Square transition matrix or tidy transition table.
#' @param chain_length Chain length.
#' @param initial Starting-state probabilities or a single fixed start state.
#' @param states Optional state labels.
#' @param trim_state Optional terminal state. Later observations are removed.
#' @param id,period,state Output variable names.
#' @param seed Optional random seed.
#'
#' @return A long-form `simulab_sim` base `data.frame` with one row per chain
#'   position. Wide chains, transitions, and initial probabilities are available
#'   through `as.data.frame()`.
#' @export
#'
#' @examples
#' transition <- matrix(c(0.7, 0.3, 0.4, 0.6), nrow = 2, byrow = TRUE)
#'
#' result <- simulate_markov(
#'   n = 50, transition = transition, chain_length = 20,
#'   states = c("A", "B"), seed = 1
#' )
#' head(result)
#' summarize_transitions(result, normalize = TRUE)
#'
#' # Transitions may also be given as a tidy from/to/probability table.
#' tidy_transitions <- data.frame(
#'   from = c("A", "A", "B", "B"),
#'   to = c("A", "B", "A", "B"),
#'   probability = c(0.7, 0.3, 0.4, 0.6)
#' )
#' head(simulate_markov(
#'   n = 50, transition = tidy_transitions, chain_length = 20, seed = 1
#' ))
simulate_markov <- function(n, transition, chain_length, initial = NULL,
                            states = NULL, trim_state = NULL,
                            id = "id", period = "period", state = "state",
                            seed = NULL) {
  stopifnot(
    "`n` must be a single positive whole number" =
      is.numeric(n) &&
        length(n) == 1L &&
        all(n >= 1) &&
        all(n == as.integer(n)),
    "`transition` must be a matrix or data frame" =
      is.matrix(transition) || is.data.frame(transition),
    "`chain_length` must be a single positive whole number" =
      is.numeric(chain_length) &&
        length(chain_length) == 1L &&
        all(chain_length >= 1) &&
        all(chain_length == as.integer(chain_length)),
    "`initial` must be NULL or an atomic vector" =
      is.null(initial) || is.atomic(initial),
    "`states` must be NULL or an atomic vector" =
      is.null(states) || is.atomic(states),
    "`trim_state` must be NULL or a single value" =
      is.null(trim_state) || length(trim_state) == 1L,
    "`id` must be a single string" =
      is.character(id) &&
        length(id) == 1L,
    "`period` must be a single string" =
      is.character(period) &&
        length(period) == 1L,
    "`state` must be a single string" =
      is.character(state) &&
        length(state) == 1L,
    "`seed` must be NULL or a single number" =
      is.null(seed) || (is.numeric(seed) && length(seed) == 1L)
  )
  resolved <- .transition_input(transition, states)
  transition_matrix <- resolved$matrix
  states <- resolved$states
  initial_probabilities <- if (is.null(initial)) {
    c(1, rep(0, length(states) - 1L))
  } else if (length(initial) == 1L && initial %in% states) {
    as.numeric(states == initial)
  } else {
    as.numeric(initial)
  }
  if (length(initial_probabilities) != length(states) ||
      any(initial_probabilities < 0) ||
      abs(sum(initial_probabilities) - 1) > 1e-8) {
    stop("initial must be a state or one probability per state summing to one.", call. = FALSE)
  }
  if (!is.null(trim_state) && !trim_state %in% states) {
    stop("trim_state must be one of states.", call. = FALSE)
  }

  chains <- .with_seed(seed, lapply(seq_len(as.integer(n)), function(chain) {
    start <- sample(states, size = 1L, prob = initial_probabilities)
    values <- .simulate_one_chain(transition_matrix, states, as.integer(chain_length), start)
    if (!is.null(trim_state) && any(values == trim_state)) {
      values <- utils::head(values, which(values == trim_state)[1L])
    }
    data.frame(
      chain = chain,
      position = seq_along(values),
      value = values,
      stringsAsFactors = FALSE,
      row.names = NULL
    )
  }))
  data <- do.call(rbind, chains)
  names(data) <- c(id, period, state)
  rownames(data) <- NULL
  transition_table <- .matrix_to_table(transition_matrix, "probability")
  names(transition_table)[1:2] <- c("from", "to")
  initial_table <- data.frame(
    state = states,
    probability = initial_probabilities,
    stringsAsFactors = FALSE,
    row.names = NULL
  )
  wide <- .wide_sequences(data, id, period, state)
  .new_simulab_sim(
    data,
    type = "markov",
    seed = seed,
    tables = list(
      transitions = transition_table,
      initial_probabilities = initial_table,
      wide = wide
    )
  )
}

#' Add a Markov chain to each input row
#'
#' @param data Base `data.frame` with a unique identifier.
#' @param transition,chain_length,states,trim_state Markov-chain arguments.
#' @param initial Starting-state probabilities or the name of an input variable
#'   containing each row's starting state.
#' @param id,period,state Output variable names.
#' @param seed Optional random seed.
#'
#' @return A long-form `simulab_sim` base `data.frame` combining input variables
#'   with one row per chain position.
#' @export
#'
#' @examples
#' data <- data.frame(id = 1:20, group = rep(c("a", "b"), each = 10))
#'
#' result <- augment_markov(
#'   data,
#'   transition = matrix(c(0.7, 0.3, 0.4, 0.6), nrow = 2, byrow = TRUE),
#'   chain_length = 10,
#'   states = c("A", "B"),
#'   seed = 1
#' )
#' head(result)
augment_markov <- function(data, transition, chain_length, initial = NULL,
                           states = NULL, trim_state = NULL,
                           id = "id", period = "period", state = "state",
                           seed = NULL) {
  stopifnot(
    "`data` must be a data frame, with at least one row" =
      is.data.frame(data) &&
        nrow(data) >= 1L,
    "`id` must be a single string naming a column of `data`" =
      is.character(id) &&
        length(id) == 1L &&
        all(id %in% names(data)),
    "`transition` must be a matrix or data frame" =
      is.matrix(transition) || is.data.frame(transition),
    "`chain_length` must be a single positive whole number" =
      is.numeric(chain_length) &&
        length(chain_length) == 1L &&
        all(chain_length >= 1) &&
        all(chain_length == as.integer(chain_length)),
    "`initial` must be NULL or an atomic vector" =
      is.null(initial) || is.atomic(initial),
    "`states` must be NULL or an atomic vector" =
      is.null(states) || is.atomic(states),
    "`trim_state` must be NULL or a single value" =
      is.null(trim_state) || length(trim_state) == 1L,
    "`period` must be a single string" =
      is.character(period) &&
        length(period) == 1L,
    "`state` must be a single string" =
      is.character(state) &&
        length(state) == 1L,
    "`seed` must be NULL or a single number" =
      is.null(seed) || (is.numeric(seed) && length(seed) == 1L)
  )
  source <- .as_result_data(data)
  if (anyDuplicated(source[[id]])) stop("Input identifiers must be unique.", call. = FALSE)
  resolved <- .transition_input(transition, states)
  states <- resolved$states
  starts <- if (is.character(initial) && length(initial) == 1L && initial %in% names(source)) {
    source[[initial]]
  } else {
    NULL
  }
  chain_result <- if (is.null(starts)) {
    simulate_markov(
      n = nrow(source), transition = resolved$matrix, chain_length = chain_length,
      initial = initial, states = states, trim_state = trim_state,
      id = ".row", period = period, state = state, seed = seed
    )
  } else {
    chains <- .with_seed(seed, lapply(seq_len(nrow(source)), function(index) {
      values <- .simulate_one_chain(resolved$matrix, states, as.integer(chain_length), starts[index])
      if (!is.null(trim_state) && any(values == trim_state)) {
        values <- utils::head(values, which(values == trim_state)[1L])
      }
      data.frame(.row = index, position = seq_along(values), value = values,
                 stringsAsFactors = FALSE, row.names = NULL)
    }))
    long <- do.call(rbind, chains)
    names(long) <- c(".row", period, state)
    .new_simulab_sim(long, type = "markov", seed = seed)
  }
  long <- .plain_data(chain_result)
  long[[id]] <- source[[id]][long$.row]
  baseline <- source[long$.row, setdiff(names(source), id), drop = FALSE]
  result <- data.frame(
    long[, c(id, period, state), drop = FALSE],
    baseline,
    check.names = FALSE,
    row.names = NULL
  )
  transition_table <- .matrix_to_table(resolved$matrix, "probability")
  names(transition_table)[1:2] <- c("from", "to")
  .new_simulab_sim(result, type = "augmented_markov", seed = seed,
                   tables = list(transitions = transition_table))
}

#' Trim longitudinal records at an event occurrence
#'
#' @param data Long-form base `data.frame`.
#' @param id Unit identifier.
#' @param period Ordered period variable.
#' @param event Event indicator variable.
#' @param occurrence Event occurrence at which to stop.
#' @param event_value Value identifying an event.
#'
#' @return A `simulab_sim` base `data.frame` retaining observations through the
#'   requested event, or all observations when it never occurs.
#' @export
#'
#' @examples
#' # A long-form event log: `simulate_until_event()` generates the indicator,
#' # `trim_events()` then keeps records through its first occurrence.
#' data <- simulate_until_event(
#'   expand_periods(data.frame(id = 1:20), periods = 10,
#'                  id = "id", period = "period"),
#'   definition = define_variable("event", formula = "0.25",
#'                                distribution = "binary"),
#'   seed = 1
#' )
#'
#' result <- trim_events(
#'   data, id = "id", period = "period", event = "event", occurrence = 1
#' )
#' head(result)
trim_events <- function(data, id, period, event, occurrence = 1L,
                        event_value = 1) {
  stopifnot(
    "`data` must be a data frame, with at least one row" =
      is.data.frame(data) &&
        nrow(data) >= 1L,
    "`id` must be a single string naming a column of `data`" =
      is.character(id) &&
        length(id) == 1L &&
        all(id %in% names(data)),
    "`period` must be a single string naming a column of `data`" =
      is.character(period) &&
        length(period) == 1L &&
        all(period %in% names(data)),
    "`event` must be a single string naming a column of `data`" =
      is.character(event) &&
        length(event) == 1L &&
        all(event %in% names(data)),
    "`occurrence` must be a single positive whole number" =
      is.numeric(occurrence) &&
        length(occurrence) == 1L &&
        all(occurrence >= 1) &&
        all(occurrence == as.integer(occurrence)),
    "`event_value` must be a single value" =
      length(event_value) == 1L
  )
  source <- .as_result_data(data)
  groups <- split(seq_len(nrow(source)), source[[id]])
  retained <- lapply(groups, function(indices) {
    ordered <- indices[order(source[[period]][indices])]
    event_positions <- which(source[[event]][ordered] == event_value)
    if (length(event_positions) < occurrence) ordered else utils::head(ordered, event_positions[occurrence])
  })
  result <- source[unlist(retained, use.names = FALSE), , drop = FALSE]
  result <- result[order(result[[id]], result[[period]]), , drop = FALSE]
  rownames(result) <- NULL
  .new_simulab_sim(result, type = "trimmed_events")
}

#' Simulate events and retain records through the nth event
#'
#' @param data Long-form base `data.frame`.
#' @param definition One binary variable definition from `define_variable()`.
#' @param occurrence,id,period Event trimming arguments.
#' @param seed Optional random seed.
#' @param envir Formula evaluation environment.
#'
#' @return A `simulab_sim` base `data.frame` with the generated event indicator
#'   and records through the requested occurrence.
#' @export
#'
#' @examples
#' # Long-form input: one row per unit per period.
#' data <- expand_periods(data.frame(id = 1:30), periods = 8,
#'                        id = "id", period = "period")
#'
#' result <- simulate_until_event(
#'   data,
#'   definition = define_variable("event", formula = "0.3", distribution = "binary"),
#'   occurrence = 1,
#'   seed = 1
#' )
#' head(result)
simulate_until_event <- function(data, definition, occurrence = 1L,
                                 id = "id", period = "period", seed = NULL,
                                 envir = parent.frame()) {
  stopifnot(
    "`data` must be a data frame" =
      is.data.frame(data),
    "`definition` must be a `simulab_spec` object, with exactly one row" =
      inherits(definition, "simulab_spec") &&
        nrow(definition) == 1L &&
        all(definition$distribution == "binary"),
    "`occurrence` must be a single number" =
      is.numeric(occurrence) &&
        length(occurrence) == 1L,
    "`id` must be a single string" =
      is.character(id) &&
        length(id) == 1L,
    "`period` must be a single string" =
      is.character(period) &&
        length(period) == 1L,
    "`seed` must be NULL or a single number" =
      is.null(seed) || (is.numeric(seed) && length(seed) == 1L),
    "`envir` must be an environment" =
      is.environment(envir)
  )
  augmented <- augment_study(data, definition, seed = seed, envir = envir)
  trim_events(
    augmented,
    id = id,
    period = period,
    event = definition$variable,
    occurrence = occurrence,
    event_value = 1
  )
}
