.require_tna <- function() {
  if (!requireNamespace("tna", quietly = TRUE)) {
    stop(errorCondition("TNA model fitting requires the suggested 'tna' package.",
                        class = "simulab_missing_tna", call = NULL))
  }
  invisible(TRUE)
}

.prepare_tna_sequences <- function(data, format, id, period, state, group) {
  stopifnot(
    "`data` must be a data frame" =
      is.data.frame(data),
    "`format` must be a single string" =
      is.character(format) &&
        length(format) == 1L
  )
  source <- .as_result_data(data)
  format <- if (format == "auto") {
    if (all(c(id, period, state) %in% names(source))) "long" else "wide"
  } else format
  if (format == "long") {
    if (!all(c(id, period, state) %in% names(source))) {
      stop("Long TNA data must contain id, period, and state columns.", call. = FALSE)
    }
    wide <- .wide_sequences(source, id, period, state, prefix = "S")
    if (!is.null(group)) {
      if (!group %in% names(source)) stop("The group column is missing.", call. = FALSE)
      mapping <- unique(source[, c(id, group), drop = FALSE])
      if (anyDuplicated(mapping[[id]])) {
        stop("Each sequence identifier must belong to exactly one group.", call. = FALSE)
      }
      wide <- merge(wide, mapping, by = id, all.x = TRUE, sort = FALSE)
    }
  } else {
    wide <- source
  }
  if (id %in% names(wide)) wide[[id]] <- NULL
  if (!is.null(group) && !group %in% names(wide)) {
    stop("Grouped TNA fitting requires the named group column.", call. = FALSE)
  }
  sequence_columns <- setdiff(names(wide), group)
  if (length(sequence_columns) < 2L) {
    stop("TNA fitting requires at least two sequence-position columns.", call. = FALSE)
  }
  wide
}

.tidy_one_tna <- function(model, group = NULL) {
  weights <- model[["weights"]]
  edges <- .matrix_to_table(weights, "weight")
  names(edges)[1:2] <- c("from", "to")
  if (!is.null(group)) edges <- data.frame(group = group, edges, row.names = NULL)
  labels <- model[["labels"]]
  inits <- model[["inits"]]
  initial <- data.frame(
    state = labels,
    probability = as.numeric(inits),
    stringsAsFactors = FALSE,
    row.names = NULL
  )
  if (!is.null(group)) initial <- data.frame(group = group, initial, row.names = NULL)
  list(edges = edges, initial = initial)
}

.tidy_tna <- function(model) {
  if (inherits(model, "group_tna")) {
    groups <- names(model)
    tables <- Map(.tidy_one_tna, unclass(model), group = groups)
    # unname() keeps rbind() from building "Group 1.1"-style row names.
    edges <- do.call(rbind, unname(lapply(tables, function(value) value$edges)))
    initial <- do.call(rbind, unname(lapply(tables, function(value) value$initial)))
    rownames(edges) <- NULL
    rownames(initial) <- NULL
    list(edges = edges, initial = initial, groups = groups)
  } else {
    tables <- .tidy_one_tna(model)
    list(edges = tables$edges, initial = tables$initial, groups = NA_character_)
  }
}

#' Fit a temporal network analysis model
#'
#' @param data Long- or wide-form sequence data.
#' @param model TNA, frequency TNA, co-occurrence TNA, or attention TNA.
#' @param format Input format. `auto` recognizes canonical long data.
#' @param id,period,state Canonical long-form column names.
#' @param group Optional grouping-column name. Supplying it fits a model per
#'   group through the corresponding grouped TNA estimator.
#' @param ... Additional arguments passed to the estimator in `tna`.
#'
#' @return A tidy edge-list `simulab_sim` base `data.frame` with one row per
#'   ordered state pair and columns `from`, `to`, and `weight`, prefixed by a
#'   `group` column when `group` is supplied. For `model = "tna"` the weights
#'   are the estimated transition probabilities and sum to one within each
#'   `from` state; the other estimators return their own (not row-stochastic)
#'   weights. `as.data.frame(x, what = )` also returns
#'   `initial_probabilities` (`state`, `probability`) and `model_info`
#'   (`model`, `grouped`, `group`, `observations`, `sequence_positions`).
#'   Use `as_tna_model()` when a native model object is required by `tna`
#'   plotting or inference functions.
#' @export
#'
#' @examples
#' data <- simulate_sequences(n = 40, n_states = 3, chain_length = 12, seed = 1)
#' if (requireNamespace("tna", quietly = TRUE)) {
#'   head(fit_tna(data, model = "tna"))
#' }
fit_tna <- function(data, model = c("tna", "ftna", "ctna", "atna"),
                    format = c("auto", "long", "wide"),
                    id = "id", period = "period", state = "state",
                    group = NULL, ...) {
  model <- match.arg(model)
  format <- match.arg(format)
  stopifnot(
    "`data` must be a data frame, with at least one row" =
      is.data.frame(data) &&
        nrow(data) >= 1L,
    "`id` must be a single string" =
      is.character(id) &&
        length(id) == 1L,
    "`period` must be a single string" =
      is.character(period) &&
        length(period) == 1L,
    "`state` must be a single string" =
      is.character(state) &&
        length(state) == 1L,
    "`group` must be NULL or a single string" =
      is.null(group) || (is.character(group) && length(group) == 1L)
  )
  .require_tna()
  prepared <- .prepare_tna_sequences(data, format, id, period, state, group)
  function_name <- if (is.null(group)) model else paste0("group_", model)
  estimator <- getExportedValue("tna", function_name)
  arguments <- c(list(prepared), if (!is.null(group)) list(group = group) else list(), list(...))
  fitted <- do.call(estimator, arguments)
  tidy <- .tidy_tna(fitted)
  model_info <- data.frame(
    model = model,
    grouped = !is.null(group),
    group = tidy$groups,
    observations = nrow(prepared),
    sequence_positions = length(setdiff(names(prepared), group)),
    stringsAsFactors = FALSE,
    row.names = NULL
  )
  result <- .new_simulab_sim(
    tidy$edges, "tna_model",
    tables = list(initial_probabilities = tidy$initial, model_info = model_info)
  )
  attr(result, "simulab_tna_models") <- fitted
  result
}

#' Convert a tidy simulab TNA result to a native tna model
#'
#' @param x A result from `fit_tna()` or `simulate_group_tna()`.
#' @param group Optional group name for a grouped model. When omitted, the
#'   complete native grouped model is returned.
#'
#' @return A native `tna` or `group_tna` model object. For a
#'   `compare_tna_models()` result the stored models are returned as a list
#'   named by model type instead.
#' @export
#'
#' @examples
#' data <- simulate_sequences(n = 40, n_states = 3, chain_length = 12, seed = 1)
#' if (requireNamespace("tna", quietly = TRUE)) {
#'   model <- as_tna_model(fit_tna(data, model = "tna"))
#'   class(model)
#' }
as_tna_model <- function(x, group = NULL) {
  if (inherits(x, "simulab_tna")) {
    class(x) <- setdiff(class(x), "simulab_tna")
    attr(x, "simulab_type") <- NULL
    attr(x, "simulab_seed") <- NULL
    attr(x, "simulab_tables") <- NULL
    return(x)
  }
  stopifnot(
    "`x` must be a `simulab_sim` object" =
      inherits(x, "simulab_sim"),
    "`group` must be NULL or a single string" =
      is.null(group) || (is.character(group) && length(group) == 1L)
  )
  model <- attr(x, "simulab_tna_models")
  if (is.null(model)) stop("This result does not contain a fitted TNA model.", call. = FALSE)
  if (is.null(group)) return(model)
  if (!inherits(model, "group_tna")) stop("group is only valid for grouped TNA models.", call. = FALSE)
  if (!group %in% names(model)) stop("Unknown TNA group.", call. = FALSE)
  model[[group]]
}

#' Compare multiple TNA estimators on the same sequences
#'
#' @param data Sequence data accepted by `fit_tna()`.
#' @param models One or more TNA model types.
#' @param format,id,period,state,group Input arguments passed to `fit_tna()`.
#' @param ... Estimator arguments.
#'
#' @return A tidy edge-list `simulab_sim` base `data.frame` with one row per
#'   model/group/edge and columns `model`, `from`, `to`, and `weight`
#'   (with `group` inserted when `group` is supplied). A stacked `model_info`
#'   table, one row per fitted model and group, is available through
#'   `as.data.frame()`. The fitted native models are stored as a named list and
#'   returned by `as_tna_model()`.
#' @export
#'
#' @examples
#' data <- simulate_sequences(n = 40, n_states = 3, chain_length = 12, seed = 1)
#' if (requireNamespace("tna", quietly = TRUE)) {
#'   compare_tna_models(data, models = c("tna", "ftna"))
#' }
compare_tna_models <- function(data, models = c("tna", "ftna", "ctna", "atna"),
                               format = c("auto", "long", "wide"),
                               id = "id", period = "period", state = "state",
                               group = NULL, ...) {
  format <- match.arg(format)
  stopifnot(
    "`models` must be a character vector, with at least one element, naming one of `tna`, `ftna`, `ctna`, `atna`" =
      is.character(models) &&
        length(models) >= 1L &&
        all(models %in% c("tna", "ftna", "ctna", "atna"))
  )
  fitted <- lapply(models, function(model) {
    fit_tna(data, model = model, format = format, id = id, period = period,
            state = state, group = group, ...)
  })
  edges <- do.call(rbind, Map(function(result, model) {
    data.frame(model = model, .plain_data(result), check.names = FALSE, row.names = NULL)
  }, fitted, models))
  info <- do.call(rbind, lapply(fitted, as.data.frame, what = "model_info"))
  result <- .new_simulab_sim(edges, "tna_comparison", tables = list(model_info = info))
  attr(result, "simulab_tna_models") <- lapply(fitted, as_tna_model)
  names(attr(result, "simulab_tna_models")) <- models
  result
}

#' Simulate grouped actor sequences
#'
#' @param groups Number of groups, defaulting to `2`.
#' @param actors Actors per group, scalar or one value per group, defaulting
#'   to `50`.
#' @param transitions A common transition matrix, one matrix per group, or
#'   `NULL` for randomly generated matrices. A tidy data frame with columns
#'   `group`, `from`, `to` and `probability` gives one matrix per group.
#' @param chain_length Sequence length, defaulting to `20`.
#' @param initial Common initial probabilities, one vector per group, or
#'   `NULL`. A tidy data frame with columns `group`, `state` and `probability`
#'   gives one vector per group.
#' @param group_names Optional group labels.
#' @param states,n_states,state_categories State-space arguments passed to
#'   `simulate_sequences()`.
#' @param seed Optional random seed. Group-specific deterministic offsets are
#'   used without leaking RNG state.
#' @param ... Advanced sequence arguments passed to `simulate_sequences()`.
#'
#' @return A long-form `simulab_sim` base `data.frame` with one row per actor
#'   sequence position and columns `group`, `id`, `period`, and `state`. Actor
#'   identifiers are made unique across groups as `G<group>_A<actor>`.
#'   `as.data.frame(x, what = )` also returns `transitions` (`group`, `from`,
#'   `to`, `probability`), `wide` (one row per actor: `id`, `S1`, `S2`, ...,
#'   `group`), and `groups` (`group`, `actors`).
#' @inheritParams simulate_correlation
#' @export
#'
#' @examples
#' result <- simulate_group_sequences(
#'   groups = 2, actors = 20, chain_length = 12, n_states = 3, seed = 1
#' )
#' head(result)
#' components(result)
simulate_group_sequences <- function(groups = 2L, actors = 50L, transitions = NULL,
                                     chain_length = 20L, initial = NULL,
                                     group_names = NULL, states = NULL,
                                     n_states = 5L, state_categories = c("metacognitive", "cognitive"),
                                     seed = NULL, ...,
                                     batch = NULL) {
  if (!is.null(batch)) return(.simulate_batch(batch, seed))
  initial <- .tidy_to_vector_list(initial, "initial", "group", "probability",
                                  name = "state")
  transitions <- .tidy_to_matrix_list(
    transitions, "transitions", "group", "from", "to", "probability", square = TRUE
  )
  stopifnot(
    "`groups` must be a single whole number of at least 2" =
      is.numeric(groups) &&
        length(groups) == 1L &&
        all(groups >= 2) &&
        all(groups == as.integer(groups)),
    "`actors` must be a positive numeric vector, of whole numbers, with at least one element" =
      is.numeric(actors) &&
        length(actors) >= 1L &&
        all(actors >= 1) &&
        all(actors == as.integer(actors)),
    "`transitions` must be NULL or a matrix" =
      is.null(transitions) || is.matrix(transitions) || is.list(transitions),
    "`initial` must be NULL or a list" =
      is.null(initial) || is.atomic(initial) || is.list(initial),
    "`group_names` must be NULL or an atomic vector" =
      is.null(group_names) || is.atomic(group_names),
    "`seed` must be NULL or a single number" =
      is.null(seed) || (is.numeric(seed) && length(seed) == 1L)
  )
  groups <- as.integer(groups)
  if (length(actors) == 1L) actors <- rep(actors, groups)
  if (length(actors) != groups) stop("actors must be scalar or one value per group.", call. = FALSE)
  # Group names default to the names the tidy `transitions` or `initial`
  # table gives, and per-group inputs are matched to the groups by name.
  if (is.null(group_names)) {
    group_names <- (if (is.list(transitions)) names(transitions)) %||%
      (if (is.list(initial)) names(initial)) %||% sprintf("Group %d", seq_len(groups))
  }
  if (length(group_names) != groups || anyDuplicated(group_names)) {
    stop("group_names must contain one unique label per group.", call. = FALSE)
  }
  if (is.list(transitions)) transitions <- .align_list(transitions, group_names, "transitions")
  if (is.list(initial)) initial <- .align_list(initial, group_names, "initial")
  transition_list <- if (is.null(transitions) || is.matrix(transitions)) {
    rep(list(transitions), groups)
  } else transitions
  if (length(transition_list) != groups ||
      !all(vapply(transition_list, function(value) is.null(value) || is.matrix(value), logical(1)))) {
    stop("transitions must contain one matrix per group.", call. = FALSE)
  }
  initial_list <- if (is.list(initial)) initial else rep(list(initial), groups)
  if (length(initial_list) != groups) stop("initial must be common or one value per group.", call. = FALSE)
  # Learning-state labels are drawn once and shared, so every group has the
  # same state space; drawn per group, the groups would not be comparable.
  if (is.null(states) && !is.null(state_categories) &&
      all(vapply(transition_list, is.null, logical(1)))) {
    states <- sample_learning_states(n_states, state_categories, seed = seed)$state
  }
  simulations <- Map(function(index, label, actor_count, transition, group_initial) {
    simulate_sequences(
      n = actor_count, transition = transition, chain_length = chain_length,
      initial = group_initial, states = states, n_states = n_states,
      state_categories = state_categories,
      seed = if (is.null(seed)) NULL else seed + index - 1L, ...
    )
  }, seq_len(groups), group_names, as.integer(actors), transition_list, initial_list)
  data_sets <- Map(function(result, index, label) {
    data <- .plain_data(result)
    data$id <- sprintf("G%d_A%d", index, data$id)
    data.frame(group = label, data, check.names = FALSE, row.names = NULL)
  }, simulations, seq_len(groups), group_names)
  data <- do.call(rbind, data_sets)
  rownames(data) <- NULL
  transition_tables <- Map(function(result, label) {
    data.frame(group = label, as.data.frame(result, what = "transitions"),
               check.names = FALSE, row.names = NULL)
  }, simulations, group_names)
  transitions_table <- do.call(rbind, transition_tables)
  wide <- .wide_sequences(data, "id", "period", "state")
  group_map <- unique(data[, c("id", "group"), drop = FALSE])
  wide <- merge(wide, group_map, by = "id", all.x = TRUE, sort = FALSE)
  .new_simulab_sim(data, "group_sequences", seed,
                   list(transitions = transitions_table, wide = wide,
                        groups = data.frame(group = group_names,
                                            actors = as.integer(actors), row.names = NULL)))
}

#' Simulate sequences and fit a grouped TNA model
#'
#' @param model TNA model type.
#' @inheritParams simulate_group_sequences
#' @param ... Advanced sequence arguments.
#'
#' @return A long-form `simulab_sim` base `data.frame` of grouped sequences with
#'   columns `group`, `id`, `period`, and `state`.
#'   `as.data.frame(x, what = )` also returns `true_transitions` (the
#'   generating probabilities), `estimated_edges` (the fitted TNA weights),
#'   `model_info`, `wide`, and `groups`. The native `group_tna` model is
#'   accessible through `as_tna_model()`. Requires the suggested `tna` package.
#' @inheritParams simulate_correlation
#' @export
#'
#' @examples
#' if (requireNamespace("tna", quietly = TRUE)) {
#'   result <- simulate_group_tna(
#'     groups = 2, actors = 20, chain_length = 12, n_states = 3, seed = 1
#'   )
#'   head(result)
#'   components(result)
#'
#'   # With no arguments, one transition matrix per group is drawn and fitted.
#'   drawn <- simulate_group_tna(seed = 1)
#'   as.data.frame(drawn, what = "true_transitions")
#' }
simulate_group_tna <- function(groups = 2L, actors = 50L, transitions = NULL,
                               chain_length = 20L, initial = NULL,
                               group_names = NULL, states = NULL,
                               n_states = 5L, state_categories = c("metacognitive", "cognitive"),
                               model = c("tna", "ftna", "ctna", "atna"),
                               seed = NULL, ...,
                               batch = NULL) {
  if (!is.null(batch)) return(.simulate_batch(batch, seed))
  initial <- .tidy_to_vector_list(initial, "initial", "group", "probability",
                                  name = "state")
  transitions <- .tidy_to_matrix_list(
    transitions, "transitions", "group", "from", "to", "probability", square = TRUE
  )
  model <- match.arg(model)
  sequences <- simulate_group_sequences(
    groups = groups, actors = actors, transitions = transitions,
    chain_length = chain_length, initial = initial,
    group_names = group_names, states = states, n_states = n_states,
    state_categories = state_categories,
    seed = seed, ...
  )
  fitted <- fit_tna(sequences, model = model, format = "long", group = "group")
  result <- .new_simulab_sim(
    .plain_data(sequences), "group_tna", seed,
    tables = list(
      true_transitions = as.data.frame(sequences, what = "transitions"),
      estimated_edges = .plain_data(fitted),
      model_info = as.data.frame(fitted, what = "model_info"),
      wide = as.data.frame(sequences, what = "wide"),
      groups = as.data.frame(sequences, what = "groups")
    )
  )
  attr(result, "simulab_tna_models") <- as_tna_model(fitted)
  result
}

#' Simulate one transition network
#'
#' Takes or draws a transition matrix, generates sequences from it with
#' [simulate_sequences()], and fits one transition network to the sequences
#' with the `tna` package, all in one call.
#'
#' @param n Number of sequences, defaulting to `100`.
#' @param transition Generating transition matrix, or a tidy data frame with
#'   columns `from`, `to` and `probability`. `NULL` (the default) draws one
#'   over `n_states` states from a Dirichlet distribution.
#' @param chain_length Sequence length, defaulting to `20`.
#' @param state_categories Learning-state categories the labels of a drawn
#'   matrix come from, defaulting to `c("metacognitive", "cognitive")`; see
#'   [learning_state_categories()]. `NULL` labels the states
#'   `State 1`, `State 2`, and so on. Ignored when `transition` or `states`
#'   names the states.
#' @param model TNA estimator, one of `"tna"` (the default), `"ftna"`,
#'   `"ctna"` or `"atna"`.
#' @param ... Further arguments passed to [simulate_sequences()], such as
#'   `concentration` or `missing_tail`.
#' @inheritParams simulate_sequences
#' @inheritParams simulate_correlation
#'
#' @return The fitted network as a native `tna` model, of class
#'   `c("simulab_tna", "tna")`, so every `tna` function (`plot()`,
#'   `centralities()`, `summary()` and the rest) applies to it. Printing it
#'   shows the native `tna` print, then the generating transition matrix and
#'   initial probabilities. Tidy tables come from [as.data.frame()][as.data.frame.simulab_tna]:
#'   the fitted `edges` (the default; columns `from`, `to` and `weight`), the
#'   generating `transitions` (columns `from`, `to` and `probability`),
#'   `initial_probabilities`, the generated `sequences` in long form, `wide`
#'   and `model_info`. Requires the suggested `tna` package, and raises
#'   `simulab_missing_tna` without it.
#' @export
#'
#' @examples
#' if (requireNamespace("tna", quietly = TRUE)) {
#'   # With no arguments: a drawn 5-state system, 100 sequences, one network.
#'   network <- simulate_tna(seed = 1)
#'   network
#'   validate_recovery(network, network, term = "to", estimate = "weight")
#'
#'   # From a given transition matrix.
#'   transition <- data.frame(
#'     from = rep(c("plan", "act"), each = 2),
#'     to = rep(c("plan", "act"), times = 2),
#'     probability = c(0.3, 0.7, 0.6, 0.4)
#'   )
#'   simulate_tna(n = 200, transition = transition, seed = 1)
#' }
simulate_tna <- function(n = 100L, transition = NULL, chain_length = 20L,
                         initial = NULL, states = NULL, n_states = 5L,
                         state_categories = c("metacognitive", "cognitive"),
                         model = c("tna", "ftna", "ctna", "atna"),
                         seed = NULL, ..., batch = NULL) {
  if (!is.null(batch)) return(.simulate_batch(batch, seed))
  model <- match.arg(model)
  .require_tna()
  sequences <- simulate_sequences(
    n = n, transition = transition, chain_length = chain_length,
    initial = initial, states = states, n_states = n_states,
    state_categories = state_categories, seed = seed, ...
  )
  fitted <- fit_tna(.plain_data(sequences), model = model, format = "long")
  # The result is the native `tna` model, so tna's print, plot, centralities
  # and the rest apply unchanged; the generating values ride along as tables.
  result <- as_tna_model(fitted)
  attr(result, "simulab_type") <- "tna"
  attr(result, "simulab_seed") <- seed
  attr(result, "simulab_tables") <- list(
    transitions = as.data.frame(sequences, what = "transitions"),
    initial_probabilities = as.data.frame(sequences, what = "initial_probabilities"),
    edges = .plain_data(fitted),
    sequences = .plain_data(sequences),
    wide = as.data.frame(sequences, what = "wide"),
    model_info = as.data.frame(fitted, what = "model_info")
  )
  class(result) <- c("simulab_tna", class(result))
  result
}

#' Print a simulated transition network
#'
#' Prints the fitted network with the native `tna` print method, then the
#' transition matrix and initial probabilities that generated the sequences,
#' in the same format, then the names of the other stored tables.
#'
#' @param x A `simulab_tna` result of [simulate_tna()].
#' @param digits Digits for the generating probabilities, default `3`.
#' @param ... Passed to the `tna` print method.
#'
#' @return `x`, invisibly.
#' @export
#'
#' @examples
#' if (requireNamespace("tna", quietly = TRUE)) {
#'   print(simulate_tna(n = 30, n_states = 3, seed = 1))
#' }
print.simulab_tna <- function(x, digits = 3L, ...) {
  NextMethod()
  tables <- attr(x, "simulab_tables")
  # The truth is laid out in the fitted model's state order, so the two
  # matrices line up row for row and column for column.
  truth <- .tidy_to_square(tables$transitions, "transitions", "from", "to",
                           "probability", levels = x$labels)
  initial <- stats::setNames(tables$initial_probabilities$probability,
                             tables$initial_probabilities$state)[x$labels]
  cat("\nGenerating Transition Probability Matrix (truth) :\n\n")
  print(round(truth, digits))
  cat("\nGenerating Initial Probabilities (truth) :\n\n")
  print(round(initial, digits))
  others <- setdiff(names(tables), c("transitions", "initial_probabilities"))
  cat(sprintf(
    "\nOther tables: %s. Read one with as.data.frame(x, what = \"%s\").\n",
    paste(others, collapse = ", "), others[1L]
  ))
  invisible(x)
}

#' Tidy tables of a simulated transition network
#'
#' @param x A `simulab_tna` result of [simulate_tna()].
#' @param row.names,optional Ignored; present for the generic.
#' @param what Table to return: `"edges"` (the default, the fitted network),
#'   `"transitions"`, `"initial_probabilities"`, `"sequences"`, `"wide"` or
#'   `"model_info"`.
#' @param ... Ignored.
#'
#' @return A base `data.frame`. `"edges"` has one row per edge with columns
#'   `from`, `to` and `weight`; `"transitions"` one row per edge with columns
#'   `from`, `to` and `probability`; `"initial_probabilities"` one row per
#'   state with columns `state` and `probability`; `"sequences"` one row per
#'   sequence and position with columns `id`, `period` and `state`.
#' @export
#'
#' @examples
#' if (requireNamespace("tna", quietly = TRUE)) {
#'   network <- simulate_tna(n = 30, n_states = 3, seed = 1)
#'   as.data.frame(network)
#'   as.data.frame(network, what = "transitions")
#' }
as.data.frame.simulab_tna <- function(x, row.names = NULL, optional = FALSE,
                                      what = "edges", ...) {
  stopifnot(
    "`what` must be a single string that is not NA" =
      is.character(what) && length(what) == 1L && !is.na(what)
  )
  tables <- attr(x, "simulab_tables")
  if (!what %in% names(tables)) {
    stop(sprintf("Unknown table '%s'. Available tables: %s.", what,
                 paste(names(tables), collapse = ", ")), call. = FALSE)
  }
  tables[[what]]
}

#' Simulate a grouped TNA transition network
#'
#' @param groups Number of node groups.
#' @param nodes_per_group Nodes per group, scalar or vector.
#' @param group_names Optional group names.
#' @param within_probability,between_probability Edge probabilities within and
#'   between node groups.
#' @param loops Permit self transitions when drawing the underlying edges. A
#'   node left with no outgoing edge is nevertheless given a self transition of
#'   probability one, so self-loops can appear even when `loops` is `FALSE`.
#' @param seed Optional random seed.
#'
#' @return A tidy `simulab_sim` base `data.frame` holding the non-zero
#'   transitions only, one row per edge, with columns `from`, `to`, and
#'   `probability`. `as.data.frame(x, what = )` also returns `nodes`
#'   (`node`, `group`), `adjacency` (the long `row`/`column`/`weight` table of
#'   the underlying directed Bernoulli graph), and `transitions` (the full
#'   `nodes^2`-row transition table including zeros). The transition matrix is
#'   row-stochastic: every `from` node's probabilities sum to one.
#' @inheritParams simulate_correlation
#' @export
#'
#' @examples
#' result <- simulate_tna_network(groups = 3, nodes_per_group = 4, seed = 1)
#' head(result)
#' components(result)
simulate_tna_network <- function(groups, nodes_per_group,
                                 group_names = NULL,
                                 within_probability = 0.4,
                                 between_probability = 0.15,
                                 loops = FALSE, seed = NULL,
                                 batch = NULL) {
  if (!is.null(batch)) return(.simulate_batch(batch, seed))
  stopifnot(
    "`groups` must be a single whole number of at least 2" =
      is.numeric(groups) &&
        length(groups) == 1L &&
        all(groups >= 2) &&
        all(groups == as.integer(groups)),
    "`nodes_per_group` must be a positive numeric vector, of whole numbers, with at least one element" =
      is.numeric(nodes_per_group) &&
        length(nodes_per_group) >= 1L &&
        all(nodes_per_group >= 1) &&
        all(nodes_per_group == as.integer(nodes_per_group)),
    "`within_probability` must be a single number between 0 and 1" =
      is.numeric(within_probability) &&
        length(within_probability) == 1L &&
        all(within_probability >= 0) &&
        all(within_probability <= 1),
    "`between_probability` must be a single number between 0 and 1" =
      is.numeric(between_probability) &&
        length(between_probability) == 1L &&
        all(between_probability >= 0) &&
        all(between_probability <= 1),
    "`loops` must be a single flag" =
      is.logical(loops) &&
        length(loops) == 1L
  )
  groups <- as.integer(groups)
  if (length(nodes_per_group) == 1L) nodes_per_group <- rep(nodes_per_group, groups)
  if (length(nodes_per_group) != groups) {
    stop("nodes_per_group must be scalar or one value per group.", call. = FALSE)
  }
  if (is.null(group_names)) group_names <- sprintf("Group %d", seq_len(groups))
  if (length(group_names) != groups || anyDuplicated(group_names)) {
    stop("group_names must contain one unique name per group.", call. = FALSE)
  }
  node_type <- rep(group_names, times = as.integer(nodes_per_group))
  nodes <- unlist(Map(function(index, count) {
    sprintf("G%d_N%d", index, seq_len(count))
  }, seq_len(groups), as.integer(nodes_per_group)), use.names = FALSE)
  probability <- matrix(between_probability, groups, groups)
  diag(probability) <- within_probability
  network <- simulate_network(nodes, probability = probability, directed = TRUE,
                              loops = loops, node_type = node_type, seed = seed)
  adjacency_table <- as.data.frame(network, what = "adjacency")
  adjacency <- matrix(adjacency_table$weight, nrow = length(nodes), ncol = length(nodes),
                      dimnames = list(nodes, nodes))
  totals <- rowSums(adjacency)
  empty <- totals == 0
  if (any(empty)) {
    adjacency[cbind(which(empty), which(empty))] <- 1
    totals <- rowSums(adjacency)
  }
  transition <- adjacency / totals
  dimnames(transition) <- list(nodes, nodes)
  transition_table <- .matrix_to_table(transition, "probability")
  names(transition_table)[1:2] <- c("from", "to")
  edges <- transition_table[transition_table$probability > 0, , drop = FALSE]
  nodes_table <- data.frame(node = nodes, group = node_type, row.names = NULL)
  .new_simulab_sim(edges, "tna_network", seed,
                   list(nodes = nodes_table, adjacency = adjacency_table,
                        transitions = transition_table))
}
