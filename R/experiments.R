#' Simulate repeated sequence datasets
#'
#' @param repetitions Number of datasets.
#' @param ... Arguments passed to `simulate_sequences()`.
#' @param seed Optional base seed. Each dataset uses a deterministic offset.
#'
#' @return A combined long-form `simulab_sim` with dataset identifiers and
#'   dataset-specific transition parameters.
#' @export
#'
#' @examples
#' result <- simulate_sequence_batches(
#'   repetitions = 3, n = 20, n_states = 3, chain_length = 10, seed = 1
#' )
#' head(result)
simulate_sequence_batches <- function(repetitions, ..., seed = NULL) {
  stopifnot(
    "`repetitions` must be a single positive whole number" =
      is.numeric(repetitions) &&
        length(repetitions) == 1L &&
        all(repetitions >= 1) &&
        all(repetitions == as.integer(repetitions)),
    "`seed` must be NULL or a single number" =
      is.null(seed) || (is.numeric(seed) && length(seed) == 1L)
  )
  simulations <- lapply(seq_len(as.integer(repetitions)), function(index) {
    simulate_sequences(..., seed = if (is.null(seed)) NULL else seed + index - 1L)
  })
  data <- do.call(rbind, Map(function(result, index) {
    data.frame(dataset = index, .plain_data(result), check.names = FALSE,
               row.names = NULL)
  }, simulations, seq_along(simulations)))
  transitions <- do.call(rbind, Map(function(result, index) {
    data.frame(dataset = index, as.data.frame(result, what = "transitions"),
               check.names = FALSE, row.names = NULL)
  }, simulations, seq_along(simulations)))
  initial <- do.call(rbind, Map(function(result, index) {
    data.frame(dataset = index,
               as.data.frame(result, what = "initial_probabilities"),
               check.names = FALSE, row.names = NULL)
  }, simulations, seq_along(simulations)))
  .new_simulab_sim(data, "sequence_batches", seed,
                   list(transitions = transitions,
                        initial_probabilities = initial))
}

#' Simulate and fit repeated TNA networks
#'
#' @param repetitions Number of fitted networks.
#' @param model TNA estimator.
#' @param ... Arguments passed to `simulate_sequences()`.
#' @param seed Optional base seed. Each dataset uses a deterministic offset.
#'
#' @return A tidy fitted-edge `simulab_sim` with network identifiers; generated
#'   sequences and true transitions are available as components.
#' @export
#'
#' @examples
#' if (requireNamespace("tna", quietly = TRUE)) {
#'   head(simulate_tna_batches(
#'     repetitions = 2, model = "tna", n = 20, n_states = 3, chain_length = 10, seed = 1
#'   ))
#' }
simulate_tna_batches <- function(repetitions, model = c("tna", "ftna", "ctna", "atna"),
                                 ..., seed = NULL) {
  model <- match.arg(model)
  sequences <- simulate_sequence_batches(repetitions, ..., seed = seed)
  datasets <- split(.plain_data(sequences), sequences$dataset)
  fitted <- lapply(datasets, function(value) {
    value$dataset <- NULL
    fit_tna(value, model = model, format = "long")
  })
  edges <- do.call(rbind, Map(function(result, dataset) {
    data.frame(network = as.integer(dataset), .plain_data(result),
               check.names = FALSE, row.names = NULL)
  }, fitted, names(fitted)))
  info <- do.call(rbind, Map(function(result, dataset) {
    data.frame(network = as.integer(dataset),
               as.data.frame(result, what = "model_info"),
               check.names = FALSE, row.names = NULL)
  }, fitted, names(fitted)))
  result <- .new_simulab_sim(
    edges, "tna_batches", seed,
    list(
      sequences = .plain_data(sequences),
      true_transitions = as.data.frame(sequences, what = "transitions"),
      model_info = info
    )
  )
  attr(result, "simulab_tna_models") <- lapply(fitted, as_tna_model)
  result
}

#' Simulate repeated networks
#'
#' @param repetitions Number of networks.
#' @param ... Arguments passed to `simulate_network()`.
#' @param seed Optional base seed. Each network uses a deterministic offset.
#'
#' @return A combined tidy edge-list `simulab_sim` with network identifiers.
#' @export
#'
#' @examples
#' result <- simulate_network_batches(
#'   repetitions = 3, nodes = 20, model = "bernoulli", probability = 0.1, seed = 1
#' )
#' head(result)
simulate_network_batches <- function(repetitions, ..., seed = NULL) {
  stopifnot(
    "`repetitions` must be a single positive whole number" =
      is.numeric(repetitions) &&
        length(repetitions) == 1L &&
        all(repetitions >= 1) &&
        all(repetitions == as.integer(repetitions)),
    "`seed` must be NULL or a single number" =
      is.null(seed) || (is.numeric(seed) && length(seed) == 1L)
  )
  simulations <- lapply(seq_len(as.integer(repetitions)), function(index) {
    simulate_network(..., seed = if (is.null(seed)) NULL else seed + index - 1L)
  })
  data <- do.call(rbind, Map(function(result, index) {
    data.frame(network = index, .plain_data(result), check.names = FALSE,
               row.names = NULL)
  }, simulations, seq_along(simulations)))
  settings <- do.call(rbind, Map(function(result, index) {
    data.frame(network = index, as.data.frame(result, what = "settings"),
               check.names = FALSE, row.names = NULL)
  }, simulations, seq_along(simulations)))
  .new_simulab_sim(data, "network_batches", seed, list(settings = settings))
}

.normalize_network_rows <- function(edges) {
  totals <- ave(abs(edges$weight), edges$from, FUN = sum)
  edges$weight <- ifelse(totals == 0, 0, edges$weight / totals)
  edges
}

#' Evaluate TNA estimation against generated truth
#'
#' @param repetitions Number of simulation replications.
#' @param n Number of sequences per replication.
#' @param chain_length Sequence length.
#' @param n_states Number of states.
#' @param models TNA estimators to evaluate.
#' @param concentration,diagonal_concentration Transition-system parameters.
#' @param missing_tail Trailing missing positions passed to
#'   `simulate_sequences()`.
#' @param threshold Edge-presence threshold for recovery metrics.
#' @param seed Optional base seed.
#' @param ... Arguments passed to `fit_tna()`.
#'
#' @return A tidy `simulab_sim` of replication/model agreement metrics, with
#'   generated truth and estimated edges as components.
#' @export
#'
#' @examples
#' if (requireNamespace("tna", quietly = TRUE)) {
#'   evaluate_tna_estimation(
#'     repetitions = 2, n = 30, chain_length = 10, n_states = 3,
#'     models = "tna", seed = 1
#'   )
#' }
evaluate_tna_estimation <- function(repetitions = 100L, n = 200L,
                                    chain_length = 25L, n_states = 6L,
                                    models = c("tna", "ftna", "ctna", "atna"),
                                    concentration = 1,
                                    diagonal_concentration = 0,
                                    missing_tail = c(0L, 5L), threshold = 0,
                                    seed = NULL, ...) {
  stopifnot(
    "`repetitions` must be a single positive whole number" =
      is.numeric(repetitions) &&
        length(repetitions) == 1L &&
        all(repetitions >= 1) &&
        all(repetitions == as.integer(repetitions)),
    "`n` must be a single whole number of at least 2" =
      is.numeric(n) &&
        length(n) == 1L &&
        all(n >= 2) &&
        all(n == as.integer(n)),
    "`chain_length` must be a single whole number of at least 2" =
      is.numeric(chain_length) &&
        length(chain_length) == 1L &&
        all(chain_length >= 2) &&
        all(chain_length == as.integer(chain_length)),
    "`n_states` must be a single whole number of at least 2" =
      is.numeric(n_states) &&
        length(n_states) == 1L &&
        all(n_states >= 2) &&
        all(n_states == as.integer(n_states)),
    "`models` must be a character vector, with at least one element, naming one of `tna`, `ftna`, `ctna`, `atna`" =
      is.character(models) &&
        length(models) >= 1L &&
        all(models %in% c("tna", "ftna", "ctna", "atna")),
    "`threshold` must be a single non-negative number" =
      is.numeric(threshold) &&
        length(threshold) == 1L &&
        all(threshold >= 0)
  )
  experiments <- lapply(seq_len(as.integer(repetitions)), function(iteration) {
    iteration_seed <- if (is.null(seed)) NULL else seed + iteration - 1L
    system <- generate_transition_system(
      n_states, concentration = concentration,
      diagonal_concentration = diagonal_concentration, seed = iteration_seed
    )
    truth <- .plain_data(system)
    names(truth)[3L] <- "weight"
    transition <- stats::xtabs(weight ~ from + to, truth)
    initial_table <- as.data.frame(system, what = "initial_probabilities")
    initial <- stats::setNames(initial_table$probability, initial_table$state)
    sequences <- simulate_sequences(
      n, transition = as.matrix(transition), chain_length = chain_length,
      initial = initial, missing_tail = missing_tail,
      seed = if (is.null(iteration_seed)) NULL else iteration_seed + 100000L
    )
    fitted <- lapply(models, function(model) fit_tna(sequences, model = model, ...))
    metrics <- do.call(rbind, Map(function(result, model) {
      estimate <- .normalize_network_rows(.plain_data(result))
      comparison <- compare_networks(truth, estimate, threshold)
      recovery <- as.data.frame(evaluate_edge_recovery(truth, estimate, threshold),
                                what = "summary")
      data.frame(iteration = iteration, model = model, comparison, recovery,
                 check.names = FALSE, row.names = NULL)
    }, fitted, models))
    estimated <- do.call(rbind, Map(function(result, model) {
      data.frame(iteration = iteration, model = model,
                 .normalize_network_rows(.plain_data(result)),
                 check.names = FALSE, row.names = NULL)
    }, fitted, models))
    list(metrics = metrics,
         truth = data.frame(iteration = iteration, truth, row.names = NULL),
         estimated = estimated)
  })
  metrics <- do.call(rbind, lapply(experiments, function(value) value$metrics))
  truth <- do.call(rbind, lapply(experiments, function(value) value$truth))
  estimated <- do.call(rbind, lapply(experiments, function(value) value$estimated))
  .new_simulab_sim(metrics, "tna_estimation", seed,
                   list(truth = truth, estimated_edges = estimated))
}

#' Assess split-half TNA reliability
#'
#' @param data Sequence data accepted by `fit_tna()`.
#' @param model TNA estimator.
#' @param iterations Number of random split halves.
#' @param split Fraction assigned to the first half.
#' @param format,id,period,state Input-format arguments.
#' @param seed Optional seed.
#' @param ... Arguments passed to `fit_tna()`.
#'
#' @return A tidy base `data.frame` with one row of network agreement metrics
#'   per split.
#' @export
#'
#' @examples
#' data <- simulate_sequences(n = 40, n_states = 3, chain_length = 12, seed = 1)
#' if (requireNamespace("tna", quietly = TRUE)) {
#'   assess_tna_reliability(data, model = "tna", iterations = 2, seed = 1)
#' }
assess_tna_reliability <- function(data, model = c("tna", "ftna", "ctna", "atna"),
                                   iterations = 100L, split = 0.5,
                                   format = c("auto", "long", "wide"),
                                   id = "id", period = "period", state = "state",
                                   seed = NULL, ...) {
  model <- match.arg(model)
  format <- match.arg(format)
  stopifnot(
    "`data` must be a data frame, with at least 4 rows" =
      is.data.frame(data) &&
        nrow(data) >= 4L,
    "`iterations` must be a single whole number of at least 2" =
      is.numeric(iterations) &&
        length(iterations) == 1L &&
        all(iterations >= 2) &&
        all(iterations == as.integer(iterations)),
    "`split` must be a single number strictly between 0 and 1" =
      is.numeric(split) &&
        length(split) == 1L &&
        all(split > 0) &&
        all(split < 1)
  )
  prepared <- .prepare_tna_sequences(data, format, id, period, state, group = NULL)
  first_size <- floor(nrow(prepared) * split)
  if (first_size < 2L || nrow(prepared) - first_size < 2L) {
    stop("Each reliability half must contain at least two sequences.", call. = FALSE)
  }
  results <- .with_seed(seed, lapply(seq_len(as.integer(iterations)), function(iteration) {
    first_rows <- sample.int(nrow(prepared), first_size, replace = FALSE)
    first <- fit_tna(prepared[first_rows, , drop = FALSE], model,
                     format = "wide", ...)
    second <- fit_tna(prepared[-first_rows, , drop = FALSE], model,
                      format = "wide", ...)
    data.frame(iteration = iteration, model = model,
               compare_networks(first, second), row.names = NULL)
  }))
  result <- do.call(rbind, results)
  rownames(result) <- NULL
  result
}
