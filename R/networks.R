#' Simulate basic or perturbed state sequences
#'
#' @param n Number of sequences.
#' @param transition Optional transition matrix. When `NULL`, a random matrix
#'   is generated.
#' @param chain_length Maximum sequence length.
#' @param initial Initial probabilities or a fixed starting state.
#' @param states State labels.
#' @param state_categories Optional learning-state categories used to name an
#'   automatically generated state space.
#' @param n_states Number of automatically generated states.
#' @param concentration Positive Dirichlet concentration used for automatic
#'   transition and initial probabilities.
#' @param missing_tail Number or range of trailing positions removed from each
#'   sequence.
#' @param stable_transitions Optional two-column data frame named `from` and
#'   `to` defining preferred transitions.
#' @param stability_probability Probability of following a preferred transition.
#' @param instability Instability mechanism for other transitions.
#' @param instability_probability Probability of applying that mechanism.
#' @param perturbation Multiplicative probability perturbation magnitude.
#' @param unlikely_threshold Maximum probability considered unlikely.
#' @param seed Optional random seed.
#'
#' @return A long-form `simulab_sim` base `data.frame`. Wide sequences,
#'   transition probabilities, initial probabilities, and settings are tidy
#'   components.
#' @export
#'
#' @examples
#' result <- simulate_sequences(n = 40, n_states = 4, chain_length = 20, seed = 1)
#' head(result)
#' components(result)
#'
#' # Preferred transitions followed with a given probability.
#' stable <- data.frame(
#'   from = sprintf("State %d", 1:4),
#'   to = sprintf("State %d", c(2, 3, 4, 1))
#' )
#' head(simulate_sequences(
#'   n = 40, n_states = 4, chain_length = 20,
#'   stable_transitions = stable, stability_probability = 0.85, seed = 1
#' ))
simulate_sequences <- function(n, transition = NULL, chain_length,
                               initial = NULL, states = NULL, n_states = 5L,
                               state_categories = NULL,
                               concentration = 1, missing_tail = c(0L, 0L),
                               stable_transitions = NULL,
                               stability_probability = 0.95,
                               instability = c("none", "random_jump", "perturb", "unlikely_jump"),
                               instability_probability = 0.4,
                               perturbation = 0.5, unlikely_threshold = 0.1,
                               seed = NULL) {
  instability <- match.arg(instability)
  stopifnot(
    "`n` must be a single positive whole number" =
      is.numeric(n) &&
        length(n) == 1L &&
        all(n >= 1) &&
        all(n == as.integer(n)),
    "`transition` must be NULL or a matrix or data frame" =
      is.null(transition) || is.matrix(transition) || is.data.frame(transition),
    "`chain_length` must be a single whole number of at least 2" =
      is.numeric(chain_length) &&
        length(chain_length) == 1L &&
        all(chain_length >= 2) &&
        all(chain_length == as.integer(chain_length)),
    "`initial` must be NULL or an atomic vector" =
      is.null(initial) || is.atomic(initial),
    "`states` must be NULL or an atomic vector" =
      is.null(states) || is.atomic(states),
    "`state_categories` must be NULL or a character vector" =
      is.null(state_categories) || is.character(state_categories),
    "`n_states` must be a single whole number of at least 2" =
      is.numeric(n_states) &&
        length(n_states) == 1L &&
        all(n_states >= 2) &&
        all(n_states == as.integer(n_states)),
    "`concentration` must be a single positive number" =
      is.numeric(concentration) &&
        length(concentration) == 1L &&
        all(concentration > 0),
    "`missing_tail` must be a non-negative numeric vector, of whole numbers, of length 1 or 2" =
      is.numeric(missing_tail) &&
        all(length(missing_tail) %in% c(1L, 2L)) &&
        all(missing_tail >= 0) &&
        all(missing_tail == as.integer(missing_tail)),
    "`stable_transitions` must be NULL or a data frame" =
      is.null(stable_transitions) || is.data.frame(stable_transitions),
    "`stability_probability` must be a single number between 0 and 1" =
      is.numeric(stability_probability) &&
        length(stability_probability) == 1L &&
        all(stability_probability >= 0) &&
        all(stability_probability <= 1),
    "`instability_probability` must be a single number between 0 and 1" =
      is.numeric(instability_probability) &&
        length(instability_probability) == 1L &&
        all(instability_probability >= 0) &&
        all(instability_probability <= 1),
    "`perturbation` must be a single number between 0 and 1" =
      is.numeric(perturbation) &&
        length(perturbation) == 1L &&
        all(perturbation >= 0) &&
        all(perturbation <= 1),
    "`unlikely_threshold` must be a single number between 0 and 1" =
      is.numeric(unlikely_threshold) &&
        length(unlikely_threshold) == 1L &&
        all(unlikely_threshold >= 0) &&
        all(unlikely_threshold <= 1),
    "`seed` must be NULL or a single number" =
      is.null(seed) || (is.numeric(seed) && length(seed) == 1L)
  )
  missing_tail <- if (length(missing_tail) == 1L) rep(missing_tail, 2L) else missing_tail
  if (missing_tail[1L] > missing_tail[2L] || missing_tail[2L] > chain_length - 2L) {
    stop("missing_tail must be ordered and leave at least two observed positions.", call. = FALSE)
  }
  generated <- .with_seed(seed, {
    if (is.null(transition)) {
      if (is.null(states)) {
        states <- if (is.null(state_categories)) {
          sprintf("State %d", seq_len(as.integer(n_states)))
        } else {
          sample_learning_states(n_states, state_categories)$state
        }
      }
      if (length(states) != n_states || anyDuplicated(states)) {
        stop("states must contain one unique label per generated state.", call. = FALSE)
      }
      raw <- matrix(stats::rgamma(n_states^2, shape = concentration), n_states, n_states)
      transition <- raw / rowSums(raw)
      dimnames(transition) <- list(states, states)
      if (is.null(initial)) {
        initial_raw <- stats::rgamma(n_states, shape = concentration)
        initial <- initial_raw / sum(initial_raw)
      }
    }
    resolved <- .transition_input(transition, states)
    states <- resolved$states
    initial_probabilities <- if (is.null(initial)) {
      c(1, rep(0, length(states) - 1L))
    } else if (length(initial) == 1L && initial %in% states) {
      as.numeric(states == initial)
    } else as.numeric(initial)
    if (length(initial_probabilities) != length(states) ||
        any(initial_probabilities < 0) ||
        abs(sum(initial_probabilities) - 1) > 1e-8) {
      stop("initial must be a state or one probability per state summing to one.", call. = FALSE)
    }
    if (!is.null(stable_transitions)) {
      if (!all(c("from", "to") %in% names(stable_transitions)) ||
          any(!stable_transitions$from %in% states) ||
          any(!stable_transitions$to %in% states) ||
          anyDuplicated(stable_transitions$from)) {
        stop("stable_transitions requires unique, valid from/to state pairs.", call. = FALSE)
      }
    }
    next_state <- function(current) {
      stable_location <- if (is.null(stable_transitions)) 0L else
        match(current, stable_transitions$from, nomatch = 0L)
      if (stable_location > 0L && stats::runif(1L) < stability_probability) {
        return(stable_transitions$to[stable_location])
      }
      probabilities <- resolved$matrix[match(current, states), ]
      if (instability != "none" && stats::runif(1L) < instability_probability) {
        probabilities <- switch(
          instability,
          random_jump = rep(1 / length(states), length(states)),
          perturb = {
            adjusted <- probabilities * stats::runif(
              length(states), 1 - perturbation, 1 + perturbation
            )
            adjusted / sum(adjusted)
          },
          unlikely_jump = {
            unlikely <- probabilities <= unlikely_threshold
            if (any(unlikely)) unlikely / sum(unlikely) else probabilities
          }
        )
      }
      sample(states, 1L, prob = probabilities)
    }
    chains <- lapply(seq_len(as.integer(n)), function(id_value) {
      start <- sample(states, 1L, prob = initial_probabilities)
      values <- unlist(Reduce(
        function(current, step) next_state(utils::tail(current, 1L)),
        seq_len(as.integer(chain_length) - 1L), init = start, accumulate = TRUE
      ), use.names = FALSE)
      removed <- if (missing_tail[2L] == 0L) 0L else
        sample(seq.int(missing_tail[1L], missing_tail[2L]), 1L)
      observed <- if (removed == 0L) values else utils::head(values, -removed)
      data.frame(id = id_value, period = seq_along(observed), state = observed,
                 stringsAsFactors = FALSE, row.names = NULL)
    })
    list(data = do.call(rbind, chains), transition = resolved$matrix,
         states = states, initial = initial_probabilities)
  })
  rownames(generated$data) <- NULL
  transitions <- .matrix_to_table(generated$transition, "probability")
  names(transitions)[1:2] <- c("from", "to")
  initial_table <- data.frame(state = generated$states,
                              probability = generated$initial, row.names = NULL)
  settings <- data.frame(
    instability = instability, stability_probability = stability_probability,
    instability_probability = instability_probability,
    perturbation = perturbation, unlikely_threshold = unlikely_threshold,
    minimum_missing_tail = missing_tail[1L], maximum_missing_tail = missing_tail[2L],
    row.names = NULL
  )
  .new_simulab_sim(
    generated$data, "sequences", seed,
    list(transitions = transitions, initial_probabilities = initial_table,
         wide = .wide_sequences(generated$data, "id", "period", "state"),
         settings = settings)
  )
}

#' Simulate sequences from a mixture of transition systems
#'
#' @param n Number of sequences.
#' @param transitions List of transition matrices, or a tidy data frame with
#'   columns `cluster`, `from`, `to` and `probability`.
#' @param chain_length Sequence length.
#' @param proportions Cluster proportions.
#' @param initial Optional common initial probabilities.
#' @param labels Optional sequence-cluster labels.
#' @param states Optional state labels.
#' @param seed Optional random seed.
#'
#' @return A long-form `simulab_sim` base `data.frame` with true sequence
#'   cluster and tidy transition parameters.
#' @export
#'
#' @examples
#' # One transition matrix per latent cluster.
#' result <- simulate_sequence_clusters(
#'   n = 60,
#'   transitions = list(
#'     matrix(c(0.8, 0.2, 0.3, 0.7), nrow = 2, byrow = TRUE),
#'     matrix(c(0.3, 0.7, 0.6, 0.4), nrow = 2, byrow = TRUE)
#'   ),
#'   chain_length = 12,
#'   seed = 1
#' )
#' head(result)
#' components(result)
simulate_sequence_clusters <- function(n, transitions, chain_length,
                                       proportions = NULL, initial = NULL,
                                       labels = NULL, states = NULL,
                                       seed = NULL) {
  transitions <- .tidy_to_matrix_list(
    transitions, "transitions", "cluster", "from", "to", "probability"
  )
  stopifnot(
    "`n` must be a single whole number of at least 2" =
      is.numeric(n) &&
        length(n) == 1L &&
        all(n >= 2) &&
        all(n == as.integer(n)),
    "`transitions` must be a list of at least two matrices" =
      is.list(transitions) &&
        length(transitions) >= 2L &&
        all(vapply(transitions, is.matrix, logical(1))),
    "`chain_length` must be a single positive whole number" =
      is.numeric(chain_length) &&
        length(chain_length) == 1L &&
        all(chain_length >= 1) &&
        all(chain_length == as.integer(chain_length)),
    "`seed` must be NULL or a single number" =
      is.null(seed) || (is.numeric(seed) && length(seed) == 1L)
  )
  clusters <- length(transitions)
  proportions <- .normalize_proportions(proportions, clusters)
  resolved <- lapply(transitions, .transition_input, states = states)
  state_sets <- lapply(resolved, function(value) value$states)
  if (!all(vapply(state_sets, identical, logical(1), state_sets[[1L]]))) {
    stop("Every transition system must use the same states.", call. = FALSE)
  }
  states <- state_sets[[1L]]
  if (is.null(labels)) labels <- sprintf("Sequence cluster %d", seq_len(clusters))
  if (length(labels) != clusters || anyDuplicated(labels)) {
    stop("labels must contain one unique value per sequence cluster.", call. = FALSE)
  }
  if (is.null(initial)) initial <- c(1, rep(0, length(states) - 1L))
  if (length(initial) != length(states) || any(initial < 0) || abs(sum(initial) - 1) > 1e-8) {
    stop("initial must contain one probability per state.", call. = FALSE)
  }
  generated <- .with_seed(seed, {
    membership <- sample(seq_len(clusters), as.integer(n), TRUE, proportions)
    chains <- Map(function(id, cluster) {
      start <- sample(states, 1L, prob = initial)
      values <- .simulate_one_chain(resolved[[cluster]]$matrix, states,
                                    as.integer(chain_length), start)
      data.frame(id = id, period = seq_along(values), state = values,
                 sequence_cluster = labels[cluster], stringsAsFactors = FALSE,
                 row.names = NULL)
    }, seq_len(as.integer(n)), membership)
    do.call(rbind, chains)
  })
  transition_tables <- Map(function(value, label) {
    table <- .matrix_to_table(value$matrix, "probability")
    names(table)[1:2] <- c("from", "to")
    data.frame(sequence_cluster = label, table, check.names = FALSE, row.names = NULL)
  }, resolved, labels)
  parameters <- do.call(rbind, transition_tables)
  rownames(generated) <- NULL
  .new_simulab_sim(generated, "sequence_clusters", seed,
                   list(transitions = parameters))
}

#' Count observed transitions in sequence data
#'
#' @param data Long-form sequence data.
#' @param id,period,state Column names.
#' @param normalize Return row-conditional transition proportions.
#'
#' @return A tidy base `data.frame` with `from`, `to`, count, and probability.
#' @export
#'
#' @examples
#' data <- simulate_markov(
#'   n = 40,
#'   transition = matrix(c(0.7, 0.3, 0.4, 0.6), nrow = 2, byrow = TRUE),
#'   chain_length = 20, states = c("A", "B"), seed = 1
#' )
#' summarize_transitions(data, normalize = TRUE)
summarize_transitions <- function(data, id = "id", period = "period",
                                  state = "state", normalize = TRUE) {
  stopifnot(
    "`data` must be a data frame" =
      is.data.frame(data),
    "`id`, `period` and `state` must name columns of `data`" =
      all(c(id, period, state) %in% names(data)),
    "`normalize` must be a single flag" =
      is.logical(normalize) &&
        length(normalize) == 1L
  )
  source <- .as_result_data(data)
  groups <- split(source, source[[id]])
  pairs <- lapply(groups, function(group) {
    ordered <- group[order(group[[period]]), , drop = FALSE]
    if (nrow(ordered) < 2L) return(data.frame(from = character(0L), to = character(0L)))
    data.frame(from = utils::head(ordered[[state]], -1L),
               to = utils::tail(ordered[[state]], -1L), stringsAsFactors = FALSE)
  })
  all_pairs <- do.call(rbind, pairs)
  if (!nrow(all_pairs)) return(data.frame(from = character(0L), to = character(0L),
                                          count = integer(0L), probability = numeric(0L)))
  counts <- aggregate(rep(1L, nrow(all_pairs)), all_pairs, sum)
  names(counts)[3L] <- "count"
  totals <- ave(counts$count, counts$from, FUN = sum)
  counts$probability <- if (normalize) counts$count / totals else NA_real_
  counts[order(counts$from, counts$to), , drop = FALSE]
}

#' Simulate a network from common graph models
#'
#' @param nodes Number of nodes or node labels.
#' @param model Graph model.
#' @param probability Bernoulli edge probability, node matrix, or type matrix.
#'   A matrix may instead be given as a tidy data frame with columns `from`,
#'   `to` and `probability`.
#' @param edges Exact edge count for the fixed-edge Bernoulli model.
#' @param directed Generate directed edges.
#' @param loops Permit self-loops.
#' @param weight Edge-weight distribution.
#' @param weight_mean,weight_sd,weight_range Weight parameters.
#' @param node_type Optional type label for each node.
#' @param edge_classes Optional number or labels of edge classes.
#' @param class_probabilities Optional edge-class probabilities.
#' @param attachment,power Preferential-attachment parameters.
#' @param neighbors,rewire Small-world parameters.
#' @param blocks,within_probability,between_probability Block-model parameters.
#' @param degree Regular-graph degree.
#' @param radius Geometric-graph connection radius.
#' @param forward_probability,backward_probability Forest-fire parameters.
#' @param seed Optional random seed.
#'
#' @return A tidy edge-list `simulab_sim`; nodes, adjacency, and generation
#'   settings are components. Use `as_igraph()` for native graph workflows.
#' @export
#'
#' @examples
#' result <- simulate_network(
#'   nodes = 60, model = "bernoulli", probability = 0.06, seed = 1
#' )
#' head(result)
#' components(result)
#'
#' # Other generators: barabasi_albert, small_world, block, regular,
#' # geometric and forest_fire.
#' head(simulate_network(nodes = 60, model = "small_world", neighbors = 2, seed = 1))
simulate_network <- function(nodes,
                             model = c("bernoulli", "barabasi_albert", "small_world",
                                       "block", "regular", "geometric", "forest_fire"),
                             probability = 0.1, edges = NULL,
                             directed = TRUE, loops = FALSE,
                             weight = c("binary", "uniform", "normal", "poisson"),
                             weight_mean = 1, weight_sd = 1,
                             weight_range = c(0.1, 1), node_type = NULL,
                             edge_classes = NULL, class_probabilities = NULL,
                             attachment = 2L, power = 1,
                             neighbors = 2L, rewire = 0.05,
                             blocks = 3L, within_probability = 0.3,
                             between_probability = 0.05, degree = 4L,
                             radius = 0.25, forward_probability = 0.35,
                             backward_probability = 0.32, seed = NULL) {
  probability <- .tidy_to_matrix(probability, "probability", "from", "to",
                                 "probability")
  model <- match.arg(model)
  weight <- match.arg(weight)
  stopifnot(
    "`nodes` must be a single whole number of at least 2" =
      (is.numeric(nodes) && length(nodes) == 1L && nodes >= 2 && nodes == as.integer(nodes)) || (is.atomic(nodes) && length(nodes) >= 2L),
    "`probability` must be a numeric vector" =
      is.numeric(probability),
    "`edges` must be NULL or a numeric vector" =
      is.null(edges) || is.numeric(edges),
    "`directed` must be a single flag" =
      is.logical(directed) &&
        length(directed) == 1L,
    "`loops` must be a single flag" =
      is.logical(loops) &&
        length(loops) == 1L,
    "`weight_mean` must be a single number" =
      is.numeric(weight_mean) &&
        length(weight_mean) == 1L,
    "`weight_sd` must be a single non-negative number" =
      is.numeric(weight_sd) &&
        length(weight_sd) == 1L &&
        all(weight_sd >= 0),
    "`weight_range` must be a numeric vector, of length 2" =
      is.numeric(weight_range) &&
        length(weight_range) == 2L &&
        all(weight_range[2L] >= weight_range[1L]),
    "`node_type` must be NULL or an atomic vector" =
      is.null(node_type) || is.atomic(node_type),
    "`edge_classes` must be NULL or an atomic vector" =
      is.null(edge_classes) || is.atomic(edge_classes),
    "`class_probabilities` must be NULL or a numeric vector" =
      is.null(class_probabilities) || is.numeric(class_probabilities),
    "`attachment` must be a single number of at least 1" =
      is.numeric(attachment) &&
        length(attachment) == 1L &&
        all(attachment >= 1),
    "`power` must be a single positive number" =
      is.numeric(power) &&
        length(power) == 1L &&
        all(power > 0),
    "`neighbors` must be a single number of at least 1" =
      is.numeric(neighbors) &&
        length(neighbors) == 1L &&
        all(neighbors >= 1),
    "`rewire` must be a single number between 0 and 1" =
      is.numeric(rewire) &&
        length(rewire) == 1L &&
        all(rewire >= 0) &&
        all(rewire <= 1),
    "`blocks` must be a single number of at least 2" =
      is.numeric(blocks) &&
        length(blocks) == 1L &&
        all(blocks >= 2),
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
    "`degree` must be a single number of at least 1" =
      is.numeric(degree) &&
        length(degree) == 1L &&
        all(degree >= 1),
    "`radius` must be a single positive number" =
      is.numeric(radius) &&
        length(radius) == 1L &&
        all(radius > 0),
    "`forward_probability` must be a single number strictly between 0 and 1" =
      is.numeric(forward_probability) &&
        length(forward_probability) == 1L &&
        all(forward_probability > 0) &&
        all(forward_probability < 1),
    "`backward_probability` must be a single number in [0, 1)" =
      is.numeric(backward_probability) &&
        length(backward_probability) == 1L &&
        all(backward_probability >= 0) &&
        all(backward_probability < 1),
    "`seed` must be NULL or a single number" =
      is.null(seed) || (is.numeric(seed) && length(seed) == 1L)
  )
  labels <- if (length(nodes) == 1L && is.numeric(nodes)) seq_len(as.integer(nodes)) else nodes
  count <- length(labels)
  if (anyDuplicated(labels)) stop("Node labels must be unique.", call. = FALSE)
  if (is.null(node_type)) node_type <- rep("node", count)
  if (length(node_type) != count) stop("node_type must contain one value per node.", call. = FALSE)
  types <- unique(node_type)
  generated <- .with_seed(seed, {
    selected <- if (model == "bernoulli") {
      probability_matrix <- if (length(probability) == 1L) {
        matrix(probability, count, count)
      } else if (is.matrix(probability) && all(dim(probability) == count)) {
        probability
      } else if (is.matrix(probability) && all(dim(probability) == length(types))) {
        type_index <- match(node_type, types)
        probability[type_index, type_index, drop = FALSE]
      } else stop("probability must be scalar, node-by-node, or type-by-type.", call. = FALSE)
      if (any(probability_matrix < 0 | probability_matrix > 1)) {
        stop("Edge probabilities must be between zero and one.", call. = FALSE)
      }
      candidates <- expand.grid(from_index = seq_len(count), to_index = seq_len(count))
      if (!loops) candidates <- candidates[candidates$from_index != candidates$to_index, , drop = FALSE]
      if (!directed) {
        candidates <- candidates[
          if (loops) candidates$from_index <= candidates$to_index else
            candidates$from_index < candidates$to_index,
          , drop = FALSE
        ]
      }
      if (is.null(edges)) {
        present <- stats::rbinom(
          nrow(candidates), 1L,
          probability_matrix[cbind(candidates$from_index, candidates$to_index)]
        ) == 1L
        candidates[present, , drop = FALSE]
      } else {
        requested <- min(as.integer(edges), nrow(candidates))
        candidates[sample.int(nrow(candidates), requested, replace = FALSE), , drop = FALSE]
      }
    } else {
      if (!requireNamespace("igraph", quietly = TRUE)) {
        stop("Non-Bernoulli network models require the suggested 'igraph' package.", call. = FALSE)
      }
      graph <- switch(
        model,
        barabasi_albert = igraph::sample_pa(
          count, power = power, m = min(as.integer(attachment), count - 1L),
          directed = directed
        ),
        small_world = igraph::sample_smallworld(
          1L, count, min(as.integer(neighbors), floor((count - 1L) / 2L)), rewire
        ),
        block = {
          block_index <- if (length(types) > 1L) match(node_type, types) else
            rep(seq_len(as.integer(blocks)), length.out = count)
          block_sizes <- as.integer(table(block_index))
          preference <- matrix(between_probability, length(block_sizes), length(block_sizes))
          diag(preference) <- within_probability
          igraph::sample_sbm(count, preference, block_sizes, directed = directed, loops = loops)
        },
        regular = igraph::sample_k_regular(
          count, min(as.integer(degree), count - 1L), directed = directed
        ),
        geometric = igraph::sample_grg(count, radius, torus = FALSE),
        forest_fire = igraph::sample_forestfire(
          count, forward_probability,
          backward_probability / forward_probability, directed = directed
        )
      )
      graph <- igraph::simplify(graph, remove.multiple = TRUE, remove.loops = !loops)
      edge_matrix <- igraph::as_edgelist(graph, names = FALSE)
      if (!length(edge_matrix)) matrix(integer(0L), 0L, 2L) else edge_matrix
    }
    selected <- as.data.frame(selected, stringsAsFactors = FALSE)
    names(selected) <- c("from_index", "to_index")
    edge_count <- nrow(selected)
    weights <- switch(weight,
      binary = rep(1, edge_count),
      uniform = stats::runif(edge_count, weight_range[1L], weight_range[2L]),
      normal = stats::rnorm(edge_count, weight_mean, weight_sd),
      poisson = stats::rpois(edge_count, weight_mean)
    )
    class_labels <- if (is.null(edge_classes)) character(0L) else if (
      is.numeric(edge_classes) && length(edge_classes) == 1L
    ) sprintf("Class %d", seq_len(as.integer(edge_classes))) else as.character(edge_classes)
    if (length(class_labels) && !is.null(class_probabilities) &&
        (length(class_probabilities) != length(class_labels) ||
         any(class_probabilities < 0) || abs(sum(class_probabilities) - 1) > 1e-8)) {
      stop("class_probabilities must match edge classes and sum to one.", call. = FALSE)
    }
    edge_class <- if (!length(class_labels)) character(0L) else sample(
      class_labels, edge_count, replace = TRUE, prob = class_probabilities
    )
    list(selected = selected, weights = weights, edge_class = edge_class)
  })
  selected <- generated$selected
  actual_directed <- directed && !model %in% c("small_world", "geometric")
  edges <- data.frame(from = labels[selected$from_index], to = labels[selected$to_index],
                      weight = generated$weights, row.names = NULL)
  if (length(generated$edge_class)) edges$edge_class <- generated$edge_class
  nodes_table <- data.frame(node = labels, type = node_type, row.names = NULL)
  adjacency <- matrix(0, count, count, dimnames = list(labels, labels))
  if (nrow(edges)) {
    adjacency[cbind(selected$from_index, selected$to_index)] <- edges$weight
    if (!actual_directed) {
      adjacency[cbind(selected$to_index, selected$from_index)] <- edges$weight
    }
  }
  adjacency_table <- .matrix_to_table(adjacency, "weight")
  settings <- data.frame(model = model, directed = actual_directed, loops = loops,
                         weight = weight, nodes = count, edges = nrow(edges),
                         stringsAsFactors = FALSE, row.names = NULL)
  .new_simulab_sim(edges, "network", seed,
                   list(nodes = nodes_table, adjacency = adjacency_table,
                        settings = settings))
}
