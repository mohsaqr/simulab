#' Generate a transition system
#'
#' @param n_states Number of states.
#' @param states Optional state labels.
#' @param concentration Dirichlet concentration for off-diagonal transitions.
#' @param diagonal_concentration Optional additional self-transition
#'   concentration.
#' @param state_categories Optional learning-state categories.
#' @param seed Optional random seed.
#'
#' @return A tidy transition-edge `simulab_sim` with initial probabilities as a
#'   component.
#' @export
#'
#' @examples
#' result <- generate_transition_system(n_states = 3, seed = 1)
#' result
generate_transition_system <- function(n_states = 8L, states = NULL,
                                       concentration = 1,
                                       diagonal_concentration = 0,
                                       state_categories = NULL, seed = NULL) {
  stopifnot(
    "`n_states` must be a single whole number of at least 2" =
      is.numeric(n_states) &&
        length(n_states) == 1L &&
        all(n_states >= 2) &&
        all(n_states == as.integer(n_states)),
    "`states` must be NULL or an atomic vector" =
      is.null(states) || is.atomic(states),
    "`concentration` must be a single positive number" =
      is.numeric(concentration) &&
        length(concentration) == 1L &&
        all(concentration > 0),
    "`diagonal_concentration` must be a single non-negative number" =
      is.numeric(diagonal_concentration) &&
        length(diagonal_concentration) == 1L &&
        all(diagonal_concentration >= 0),
    "`state_categories` must be NULL or a character vector" =
      is.null(state_categories) || is.character(state_categories),
    "`seed` must be NULL or a single number" =
      is.null(seed) || (is.numeric(seed) && length(seed) == 1L)
  )
  n_states <- as.integer(n_states)
  if (is.null(states)) {
    states <- if (is.null(state_categories)) sprintf("State %d", seq_len(n_states)) else
      sample_learning_states(n_states, state_categories, seed)$state
  }
  if (length(states) != n_states || anyDuplicated(states)) {
    stop("states must contain one unique label per state.", call. = FALSE)
  }
  generated <- .with_seed(seed, {
    shape <- matrix(concentration, n_states, n_states)
    diag(shape) <- diag(shape) + diagonal_concentration
    raw <- matrix(stats::rgamma(n_states^2, shape = as.vector(shape)), n_states, n_states)
    transition <- raw / rowSums(raw)
    initial_raw <- stats::rgamma(n_states, shape = concentration)
    list(transition = transition, initial = initial_raw / sum(initial_raw))
  })
  dimnames(generated$transition) <- list(states, states)
  edges <- .matrix_to_table(generated$transition, "probability")
  names(edges)[1:2] <- c("from", "to")
  initial <- data.frame(state = states, probability = generated$initial, row.names = NULL)
  .new_simulab_sim(edges, "transition_system", seed,
                   list(initial_probabilities = initial))
}

#' One-hot encode long-form sequence states
#'
#' @param data Long-form sequence data.
#' @param id,period,state Column names.
#' @param prefix Generated state-column prefix.
#'
#' @return A `simulab_sim` base `data.frame` with identifiers and one column per
#'   state.
#' @export
#'
#' @examples
#' data <- simulate_sequences(n = 10, n_states = 3, chain_length = 5, seed = 1)
#' head(encode_sequences(data))
encode_sequences <- function(data, id = "id", period = "period", state = "state",
                             prefix = "state_") {
  stopifnot(
    "`data` must be a data frame" =
      is.data.frame(data),
    "`id`, `period` and `state` must name columns of `data`" =
      all(c(id, period, state) %in% names(data)),
    "`prefix` must be a single string" =
      is.character(prefix) &&
        length(prefix) == 1L
  )
  source <- .as_result_data(data)
  state_values <- sort(unique(source[[state]]))
  encoded <- vapply(state_values, function(value) {
    as.integer(source[[state]] == value)
  }, integer(nrow(source)))
  encoded <- as.data.frame(encoded, check.names = FALSE)
  names(encoded) <- paste0(prefix, make.names(state_values, unique = TRUE))
  identifiers <- source[, setdiff(names(source), state), drop = FALSE]
  mapping <- data.frame(state = state_values, column = names(encoded), row.names = NULL)
  .new_simulab_sim(data.frame(identifiers, encoded, check.names = FALSE, row.names = NULL),
                   "one_hot_sequences", tables = list(mapping = mapping))
}

#' Simulate grouped educational event logs
#'
#' @param groups Number of groups.
#' @param actors Actors per group.
#' @param courses Number or labels of courses.
#' @param states,n_states,state_categories State-space options.
#' @param sequence_length Fixed length or minimum/maximum range.
#' @param achievement_levels Achievement labels.
#' @param achievement_probabilities Achievement probabilities.
#' @param start_time Initial timestamp.
#' @param interval_range Minimum and maximum seconds between events.
#' @param transitions Common matrix, one matrix per group, or `NULL`.
#' @param initial Initial probabilities.
#' @param seed Optional random seed.
#' @param ... Advanced options passed to `simulate_group_sequences()`.
#'
#' @return A long-form `simulab_sim` event log with wide, one-hot, transition,
#'   actor, and group tables as components.
#' @export
#'
#' @examples
#' result <- simulate_event_log(groups = 2, actors = 10, sequence_length = 8, seed = 1)
#' head(result)
#' components(result)
simulate_event_log <- function(groups = 5L, actors = 10L, courses = 1L,
                               states = NULL, n_states = 8L,
                               state_categories = "all",
                               sequence_length = c(10L, 30L),
                               achievement_levels = c("low", "medium", "high"),
                               achievement_probabilities = NULL,
                               start_time = as.POSIXct("2020-01-01", tz = "UTC"),
                               interval_range = c(60, 600),
                               transitions = NULL, initial = NULL,
                               seed = NULL, ...) {
  stopifnot(
    "`groups` must be a single number of at least 2" =
      is.numeric(groups) &&
        length(groups) == 1L &&
        all(groups >= 2),
    "`actors` must be a numeric vector, with at least one element" =
      is.numeric(actors) &&
        length(actors) >= 1L,
    "`courses` must be a single number of at least 1" =
      (is.numeric(courses) && length(courses) == 1L && courses >= 1) || is.atomic(courses),
    "`sequence_length` must be a numeric vector, of whole numbers, of length 1 or 2, each at least 2" =
      is.numeric(sequence_length) &&
        all(length(sequence_length) %in% c(1L, 2L)) &&
        all(sequence_length >= 2) &&
        all(sequence_length == as.integer(sequence_length)),
    "`achievement_levels` must be an atomic vector, with at least one element" =
      is.atomic(achievement_levels) &&
        length(achievement_levels) >= 1L,
    "`achievement_probabilities` must be NULL or a numeric vector" =
      is.null(achievement_probabilities) || is.numeric(achievement_probabilities),
    "`start_time` must be a `POSIXct` object" =
      inherits(start_time, "POSIXct") || inherits(start_time, "Date") || is.character(start_time),
    "`interval_range` must be a non-negative numeric vector of length 2, in increasing order" =
      is.numeric(interval_range) &&
        length(interval_range) == 2L &&
        all(interval_range[1L] >= 0) &&
        all(interval_range[2L] >= interval_range[1L])
  )
  sequence_length <- if (length(sequence_length) == 1L) rep(sequence_length, 2L) else sequence_length
  course_labels <- if (is.numeric(courses) && length(courses) == 1L) {
    sprintf("Course %d", seq_len(as.integer(courses)))
  } else as.character(courses)
  if (is.null(achievement_probabilities)) {
    achievement_probabilities <- rep(1 / length(achievement_levels), length(achievement_levels))
  }
  if (length(achievement_probabilities) != length(achievement_levels) ||
      any(achievement_probabilities < 0) ||
      abs(sum(achievement_probabilities) - 1) > 1e-8) {
    stop("achievement_probabilities must match levels and sum to one.", call. = FALSE)
  }
  maximum <- sequence_length[2L]
  sequences <- simulate_group_sequences(
    groups = groups, actors = actors, transitions = transitions,
    chain_length = maximum, initial = initial, states = states,
    n_states = n_states, state_categories = state_categories, seed = seed, ...
  )
  source <- .plain_data(sequences)
  actor_ids <- unique(source$id)
  actor_table <- .with_seed(if (is.null(seed)) NULL else seed + 100000L, data.frame(
    id = actor_ids,
    course = sample(course_labels, length(actor_ids), replace = TRUE),
    achievement = sample(achievement_levels, length(actor_ids), replace = TRUE,
                         prob = achievement_probabilities),
    retained_length = sample(seq.int(sequence_length[1L], sequence_length[2L]),
                             length(actor_ids), replace = TRUE),
    stringsAsFactors = FALSE, row.names = NULL
  ))
  source <- merge(source, actor_table, by = "id", all.x = TRUE, sort = FALSE)
  source <- source[source$period <= source$retained_length, , drop = FALSE]
  source <- source[order(source$id, source$period), , drop = FALSE]
  interval_seed <- if (is.null(seed)) NULL else seed + 200000L
  intervals <- .with_seed(interval_seed, stats::runif(
    nrow(source), interval_range[1L], interval_range[2L]
  ))
  grouped_intervals <- split(intervals, source$id)
  elapsed <- unlist(lapply(grouped_intervals, function(value) cumsum(c(0, utils::head(value, -1L)))),
                    use.names = FALSE)
  source$timestamp <- as.POSIXct(start_time, tz = "UTC") + elapsed
  source$retained_length <- NULL
  source <- source[, c("group", "id", "course", "achievement", "period", "state", "timestamp"),
                   drop = FALSE]
  rownames(source) <- NULL
  one_hot <- .plain_data(encode_sequences(source))
  wide <- .wide_sequences(source, "id", "period", "state")
  actor_metadata <- unique(source[, c("group", "id", "course", "achievement"), drop = FALSE])
  wide <- merge(wide, actor_metadata, by = "id", all.x = TRUE, sort = FALSE)
  .new_simulab_sim(
    source, "event_log", seed,
    tables = list(
      transitions = as.data.frame(sequences, what = "transitions"),
      actors = actor_metadata,
      groups = as.data.frame(sequences, what = "groups"),
      wide = wide,
      one_hot = one_hot
    )
  )
}
