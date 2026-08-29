.network_node_labels <- function(nodes, prefix = "Node", minimum = 2L) {
  stopifnot(
    "`minimum` must be a single positive whole number" =
      is.numeric(minimum) &&
        length(minimum) == 1L &&
        all(minimum >= 1) &&
        all(minimum == as.integer(minimum))
  )
  stopifnot(
    "`nodes` must be a single whole number" =
      (is.numeric(nodes) && length(nodes) == 1L && nodes >= minimum && nodes == as.integer(nodes)) || (is.atomic(nodes) && length(nodes) >= minimum)
  )
  labels <- if (is.numeric(nodes) && length(nodes) == 1L) {
    sprintf("%s %d", prefix, seq_len(as.integer(nodes)))
  } else as.character(nodes)
  if (anyNA(labels) || any(!nzchar(labels)) || anyDuplicated(labels)) {
    stop("Node labels must be non-missing, non-empty, and unique.", call. = FALSE)
  }
  labels
}

.network_weights <- function(n, distribution, mean, sd, range) {
  switch(
    distribution,
    binary = rep(1, n),
    uniform = stats::runif(n, range[1L], range[2L]),
    normal = stats::rnorm(n, mean, sd),
    poisson = stats::rpois(n, mean)
  )
}

.network_weight_arguments <- function(weight, weight_mean, weight_sd,
                                      weight_range) {
  weight <- match.arg(weight, c("binary", "uniform", "normal", "poisson"))
  stopifnot(
    "`weight_mean` must be a single finite number" =
      is.numeric(weight_mean) &&
        length(weight_mean) == 1L &&
        all(is.finite(weight_mean)),
    "`weight_sd` must be a single non-negative number" =
      is.numeric(weight_sd) &&
        length(weight_sd) == 1L &&
        all(weight_sd >= 0),
    "`weight_range` must be a finite numeric vector, of length 2" =
      is.numeric(weight_range) &&
        length(weight_range) == 2L &&
        all(is.finite(weight_range)) &&
        all(weight_range[2L] >= weight_range[1L])
  )
  if (weight == "poisson" && weight_mean < 0) {
    stop("Poisson weight_mean must be non-negative.", call. = FALSE)
  }
  list(weight = weight, mean = weight_mean, sd = weight_sd,
       range = weight_range)
}

#' Simulate a tidy network edge list
#'
#' @param nodes Number of nodes or unique node labels.
#' @param edges Optional exact number of edges.
#' @param probability Edge probability when `edges` is `NULL`.
#' @param directed Generate directed edges.
#' @param loops Permit self-loops.
#' @param weight Edge-weight distribution.
#' @param weight_mean,weight_sd,weight_range Weight parameters.
#' @param node_type Optional node type for each node.
#' @param edge_classes Optional number or labels of edge classes.
#' @param class_probabilities Optional edge-class probabilities.
#' @param seed Optional seed.
#'
#' @return A tidy `simulab_sim` with `from`, `to`, and `weight` columns; node,
#'   adjacency, and settings tables are components.
#' @export
#'
#' @examples
#' result <- simulate_edge_list(nodes = 40, probability = 0.08, seed = 1)
#' head(result)
#' components(result)
simulate_edge_list <- function(nodes, edges = NULL, probability = 0.1,
                               directed = TRUE, loops = FALSE,
                               weight = c("binary", "uniform", "normal", "poisson"),
                               weight_mean = 1, weight_sd = 1,
                               weight_range = c(0.1, 1), node_type = NULL,
                               edge_classes = NULL,
                               class_probabilities = NULL, seed = NULL) {
  labels <- .network_node_labels(nodes)
  weight <- match.arg(weight)
  .network_weight_arguments(weight, weight_mean, weight_sd, weight_range)
  stopifnot(
    "`directed` must be a single flag" =
      is.logical(directed) &&
        length(directed) == 1L,
    "`loops` must be a single flag" =
      is.logical(loops) &&
        length(loops) == 1L
  )
  possible <- if (directed) {
    length(labels) * (length(labels) - !loops)
  } else {
    choose(length(labels), 2L) + if (loops) length(labels) else 0L
  }
  if (!is.null(edges) && (length(edges) != 1L || edges < 0 ||
      edges != as.integer(edges) || edges > possible)) {
    stop("edges must be a non-negative integer within the possible dyads.",
         call. = FALSE)
  }
  result <- simulate_network(
    nodes = nodes, model = "bernoulli", probability = probability,
    edges = edges, directed = directed, loops = loops,
    weight = weight, weight_mean = weight_mean,
    weight_sd = weight_sd, weight_range = weight_range,
    node_type = node_type, edge_classes = edge_classes,
    class_probabilities = class_probabilities, seed = seed
  )
  .new_simulab_sim(.plain_data(result), "edge_list", seed,
                   attr(result, "simulab_tables"))
}

#' Simulate a temporal network as edge-activity spells
#'
#' @param nodes Number of nodes or unique node labels.
#' @param periods Number of discrete observation periods.
#' @param initial_probability Probability that a dyad is active initially.
#' @param formation_probability Probability that an inactive dyad forms at the
#'   next period.
#' @param dissolution_probability Probability that an active dyad dissolves at
#'   the next period.
#' @param directed Generate directed dyads.
#' @param loops Permit self-loops.
#' @param weight Edge-spell weight distribution.
#' @param weight_mean,weight_sd,weight_range Weight parameters.
#' @param node_type Optional node type for each node.
#' @param seed Optional seed.
#'
#' @return A tidy spell-level `simulab_sim` with `from`, `to`, `onset`,
#'   `terminus`, `weight`, and `censored`. Event and snapshot edge lists are
#'   available as components.
#' @export
#'
#' @examples
#' result <- simulate_temporal_network(
#'   nodes = 20, periods = 4, initial_probability = 0.1, seed = 1
#' )
#' head(result)
#' components(result)
simulate_temporal_network <- function(nodes, periods,
                                      initial_probability = 0.1,
                                      formation_probability = 0.05,
                                      dissolution_probability = 0.1,
                                      directed = TRUE, loops = FALSE,
                                      weight = c("binary", "uniform", "normal", "poisson"),
                                      weight_mean = 1, weight_sd = 1,
                                      weight_range = c(0.1, 1),
                                      node_type = NULL, seed = NULL) {
  labels <- .network_node_labels(nodes)
  weight_arguments <- .network_weight_arguments(
    weight, weight_mean, weight_sd, weight_range
  )
  stopifnot(
    "`periods` must be a single whole number of at least 2" =
      is.numeric(periods) &&
        length(periods) == 1L &&
        all(periods >= 2) &&
        all(periods == as.integer(periods)),
    "`initial_probability` must be a single number between 0 and 1" =
      is.numeric(initial_probability) &&
        length(initial_probability) == 1L &&
        all(initial_probability >= 0) &&
        all(initial_probability <= 1),
    "`formation_probability` must be a single number between 0 and 1" =
      is.numeric(formation_probability) &&
        length(formation_probability) == 1L &&
        all(formation_probability >= 0) &&
        all(formation_probability <= 1),
    "`dissolution_probability` must be a single number between 0 and 1" =
      is.numeric(dissolution_probability) &&
        length(dissolution_probability) == 1L &&
        all(dissolution_probability >= 0) &&
        all(dissolution_probability <= 1),
    "`directed` must be a single flag" =
      is.logical(directed) &&
        length(directed) == 1L,
    "`loops` must be a single flag" =
      is.logical(loops) &&
        length(loops) == 1L,
    "`node_type` must have the same length as `labels`" =
      is.null(node_type) || length(node_type) == length(labels),
    "`seed` must be NULL or a single number" =
      is.null(seed) || (is.numeric(seed) && length(seed) == 1L)
  )
  if (is.null(node_type)) node_type <- rep("node", length(labels))
  candidates <- expand.grid(
    from_index = seq_along(labels), to_index = seq_along(labels),
    KEEP.OUT.ATTRS = FALSE
  )
  if (!loops) {
    candidates <- candidates[candidates$from_index != candidates$to_index, , drop = FALSE]
  }
  if (!directed) {
    candidates <- candidates[candidates$from_index < candidates$to_index, , drop = FALSE]
  }
  generated <- .with_seed(seed, {
    initial <- stats::rbinom(nrow(candidates), 1L, initial_probability) == 1L
    states <- Reduce(function(previous, period) {
      remains <- stats::runif(length(previous)) >= dissolution_probability
      forms <- stats::runif(length(previous)) < formation_probability
      ifelse(previous, remains, forms)
    }, seq_len(as.integer(periods) - 1L), init = initial, accumulate = TRUE)
    activity <- do.call(rbind, states)
    spell_indices <- lapply(seq_len(ncol(activity)), function(dyad) {
      runs <- rle(activity[, dyad])
      endings <- cumsum(runs$lengths)
      beginnings <- endings - runs$lengths + 1L
      active <- runs$values
      data.frame(
        dyad = rep(dyad, sum(active)), onset = beginnings[active],
        terminus = endings[active] + 1L,
        stringsAsFactors = FALSE, row.names = NULL
      )
    })
    spells <- do.call(rbind, spell_indices)
    if (is.null(spells)) {
      spells <- data.frame(dyad = integer(0L), onset = integer(0L),
                           terminus = integer(0L))
    }
    spells$weight <- .network_weights(
      nrow(spells), weight_arguments$weight, weight_arguments$mean,
      weight_arguments$sd, weight_arguments$range
    )
    list(activity = activity, spells = spells)
  })
  spells <- generated$spells
  spell_data <- data.frame(
    from = labels[candidates$from_index[spells$dyad]],
    to = labels[candidates$to_index[spells$dyad]],
    onset = spells$onset, terminus = spells$terminus,
    weight = spells$weight,
    censored = spells$terminus == as.integer(periods) + 1L,
    stringsAsFactors = FALSE, row.names = NULL
  )
  snapshot_rows <- lapply(seq_len(nrow(spell_data)), function(index) {
    data.frame(
      period = seq.int(spell_data$onset[index], spell_data$terminus[index] - 1L),
      from = spell_data$from[index], to = spell_data$to[index],
      weight = spell_data$weight[index], stringsAsFactors = FALSE,
      row.names = NULL
    )
  })
  snapshots <- if (!length(snapshot_rows)) {
    data.frame(period = integer(0L), from = character(0L),
               to = character(0L), weight = numeric(0L))
  } else do.call(rbind, snapshot_rows)
  formation_events <- data.frame(
    from = spell_data$from, to = spell_data$to, time = spell_data$onset,
    event = rep("formation", nrow(spell_data)), weight = spell_data$weight,
    stringsAsFactors = FALSE, row.names = NULL
  )
  dissolved <- !spell_data$censored
  dissolution_events <- data.frame(
    from = spell_data$from[dissolved], to = spell_data$to[dissolved],
    time = spell_data$terminus[dissolved],
    event = rep("dissolution", sum(dissolved)),
    weight = spell_data$weight[dissolved], stringsAsFactors = FALSE,
    row.names = NULL
  )
  events <- rbind(formation_events, dissolution_events)
  if (nrow(events)) events <- events[order(events$time, events$event), , drop = FALSE]
  rownames(events) <- NULL
  nodes_table <- data.frame(node = labels, type = node_type,
                            stringsAsFactors = FALSE, row.names = NULL)
  settings <- data.frame(
    periods = as.integer(periods), directed = directed, loops = loops,
    initial_probability = initial_probability,
    formation_probability = formation_probability,
    dissolution_probability = dissolution_probability,
    weight = weight_arguments$weight, stringsAsFactors = FALSE, row.names = NULL
  )
  .new_simulab_sim(spell_data, "temporal_network", seed,
                   list(events = events, snapshots = snapshots,
                        nodes = nodes_table, settings = settings))
}

#' Simulate a network matrix
#'
#' @param nodes Number of nodes or unique node labels.
#' @param type Matrix type.
#' @param probability Probability of a non-zero dyad.
#' @param directed Generate an asymmetric matrix where applicable.
#' @param loops Permit non-zero diagonal entries.
#' @param weighted Generate weighted adjacency/co-occurrence values.
#' @param weight_range Range for continuous weights.
#' @param frequency_mean Mean positive count for frequency matrices.
#' @param seed Optional seed.
#'
#' @return A tidy full matrix table with `from`, `to`, and `value`; non-zero
#'   edges, nodes, and a wide matrix are components.
#' @export
#'
#' @examples
#' result <- simulate_network_matrix(nodes = 8, type = "adjacency", seed = 1)
#' head(result)
#' components(result)
simulate_network_matrix <- function(nodes,
                                    type = c("adjacency", "transition", "frequency",
                                             "cooccurrence"),
                                    probability = 0.2, directed = TRUE,
                                    loops = FALSE, weighted = TRUE,
                                    weight_range = c(0.1, 1),
                                    frequency_mean = 10, seed = NULL) {
  type <- match.arg(type)
  labels <- .network_node_labels(nodes)
  stopifnot(
    "`probability` must be a single number between 0 and 1" =
      is.numeric(probability) &&
        length(probability) == 1L &&
        all(probability >= 0) &&
        all(probability <= 1),
    "`directed` must be a single flag" =
      is.logical(directed) &&
        length(directed) == 1L,
    "`loops` must be a single flag" =
      is.logical(loops) &&
        length(loops) == 1L,
    "`weighted` must be a single flag" =
      is.logical(weighted) &&
        length(weighted) == 1L,
    "`weight_range` must be a numeric vector, of length 2" =
      is.numeric(weight_range) &&
        length(weight_range) == 2L &&
        all(weight_range[2L] >= weight_range[1L]),
    "`frequency_mean` must be a single number of at least 1" =
      is.numeric(frequency_mean) &&
        length(frequency_mean) == 1L &&
        all(frequency_mean >= 1),
    "`seed` must be NULL or a single number" =
      is.null(seed) || (is.numeric(seed) && length(seed) == 1L)
  )
  if (type == "transition" && !directed) {
    stop("Transition matrices must be directed.", call. = FALSE)
  }
  if (type == "transition" && weight_range[2L] <= 0) {
    stop("Transition weight_range must contain positive values.", call. = FALSE)
  }
  symmetric <- type == "cooccurrence" || !directed
  generated <- .with_seed(seed, {
    count <- length(labels)
    candidates <- expand.grid(from = seq_len(count), to = seq_len(count))
    if (!loops) candidates <- candidates[candidates$from != candidates$to, , drop = FALSE]
    if (symmetric) candidates <- candidates[candidates$from < candidates$to, , drop = FALSE]
    present <- stats::rbinom(nrow(candidates), 1L, probability) == 1L
    selected <- candidates[present, , drop = FALSE]
    values <- if (type == "frequency") {
      1L + stats::rpois(nrow(selected), frequency_mean - 1)
    } else if (!weighted && type != "transition") {
      rep(1, nrow(selected))
    } else stats::runif(nrow(selected), weight_range[1L], weight_range[2L])
    matrix_value <- matrix(0, count, count, dimnames = list(labels, labels))
    if (nrow(selected)) {
      matrix_value[cbind(selected$from, selected$to)] <- values
      if (symmetric) matrix_value[cbind(selected$to, selected$from)] <- values
    }
    if (type == "transition") {
      empty <- which(rowSums(matrix_value) == 0)
      if (length(empty)) {
        targets <- vapply(empty, function(from) {
          available <- if (loops) seq_len(count) else setdiff(seq_len(count), from)
          sample(available, 1L)
        }, integer(1))
        matrix_value[cbind(empty, targets)] <- stats::runif(
          length(empty), weight_range[1L], weight_range[2L]
        )
      }
      matrix_value <- matrix_value / rowSums(matrix_value)
    }
    matrix_value
  })
  long <- .matrix_to_table(generated, "value")
  names(long)[1:2] <- c("from", "to")
  edges <- long[long$value != 0, , drop = FALSE]
  wide <- data.frame(from = rownames(generated), generated,
                     check.names = FALSE, row.names = NULL)
  nodes_table <- data.frame(node = labels, row.names = NULL)
  settings <- data.frame(type = type, directed = !symmetric, loops = loops,
                         weighted = weighted, row.names = NULL)
  .new_simulab_sim(long, paste0("network_matrix_", type), seed,
                   list(edges = edges, nodes = nodes_table,
                        matrix = wide, settings = settings))
}

#' Simulate a bipartite network
#'
#' @param actors Number or labels of primary-mode nodes.
#' @param events Number or labels of secondary-mode nodes.
#' @param edges Optional exact number of cross-mode edges.
#' @param probability Cross-mode edge probability when `edges` is `NULL`.
#' @param weight Edge-weight distribution.
#' @param weight_mean,weight_sd,weight_range Weight parameters.
#' @param seed Optional seed.
#'
#' @return A tidy cross-mode edge-list `simulab_sim`; nodes and the
#'   actor-by-event incidence matrix are components.
#' @export
#'
#' @examples
#' result <- simulate_bipartite_network(actors = 20, events = 6, probability = 0.3, seed = 1)
#' head(result)
#' components(result)
simulate_bipartite_network <- function(actors, events, edges = NULL,
                                       probability = 0.1,
                                       weight = c("binary", "uniform", "normal", "poisson"),
                                       weight_mean = 1, weight_sd = 1,
                                       weight_range = c(0.1, 1), seed = NULL) {
  actor_labels <- .network_node_labels(actors, "Actor", minimum = 1L)
  event_labels <- .network_node_labels(events, "Event", minimum = 1L)
  if (length(intersect(actor_labels, event_labels))) {
    stop("Actor and event labels must be distinct.", call. = FALSE)
  }
  weight_arguments <- .network_weight_arguments(
    weight, weight_mean, weight_sd, weight_range
  )
  stopifnot(
    "`edges` must be NULL or a single non-negative whole number" =
      is.null(edges) || (is.numeric(edges) && length(edges) == 1L && edges >= 0 && edges == as.integer(edges)),
    "`probability` must be a single number between 0 and 1" =
      is.numeric(probability) &&
        length(probability) == 1L &&
        all(probability >= 0) &&
        all(probability <= 1),
    "`seed` must be NULL or a single number" =
      is.null(seed) || (is.numeric(seed) && length(seed) == 1L)
  )
  candidates <- expand.grid(
    from_index = seq_along(actor_labels), to_index = seq_along(event_labels),
    KEEP.OUT.ATTRS = FALSE
  )
  if (!is.null(edges) && edges > nrow(candidates)) {
    stop("edges exceeds the number of possible actor-event pairs.", call. = FALSE)
  }
  generated <- .with_seed(seed, {
    selected <- if (is.null(edges)) {
      candidates[stats::rbinom(nrow(candidates), 1L, probability) == 1L, , drop = FALSE]
    } else if (edges == 0L) candidates[0L, , drop = FALSE] else
      candidates[sample.int(nrow(candidates), as.integer(edges)), , drop = FALSE]
    weights <- .network_weights(
      nrow(selected), weight_arguments$weight, weight_arguments$mean,
      weight_arguments$sd, weight_arguments$range
    )
    list(selected = selected, weights = weights)
  })
  data <- data.frame(
    from = actor_labels[generated$selected$from_index],
    to = event_labels[generated$selected$to_index],
    weight = generated$weights, from_mode = "actor", to_mode = "event",
    stringsAsFactors = FALSE, row.names = NULL
  )
  incidence <- matrix(0, length(actor_labels), length(event_labels),
                      dimnames = list(actor_labels, event_labels))
  if (nrow(data)) {
    incidence[cbind(generated$selected$from_index,
                    generated$selected$to_index)] <- data$weight
  }
  nodes_table <- data.frame(
    node = c(actor_labels, event_labels),
    mode = rep(c("actor", "event"), c(length(actor_labels), length(event_labels))),
    stringsAsFactors = FALSE, row.names = NULL
  )
  incidence_table <- data.frame(actor = rownames(incidence), incidence,
                                check.names = FALSE, row.names = NULL)
  settings <- data.frame(probability = probability, weight = weight_arguments$weight,
                         actors = length(actor_labels), events = length(event_labels),
                         stringsAsFactors = FALSE, row.names = NULL)
  .new_simulab_sim(data, "bipartite_network", seed,
                   list(nodes = nodes_table, incidence = incidence_table,
                        settings = settings))
}

#' Simulate a multiplex network
#'
#' @param nodes Number of nodes or unique labels shared across layers.
#' @param layers Number of layers or unique layer labels.
#' @param edges Optional exact edge count, scalar or one value per layer.
#' @param probability Edge probability, scalar or one value per layer.
#' @param directed Generate directed edges.
#' @param loops Permit self-loops.
#' @param weight Edge-weight distribution.
#' @param weight_mean,weight_sd,weight_range Weight parameters.
#' @param node_type Optional node type for each node.
#' @param seed Optional base seed; layers use deterministic offsets.
#'
#' @return A tidy layered edge-list `simulab_sim` with `layer`, `from`, `to`,
#'   and `weight`; nodes, layers, adjacency, and settings are components.
#' @export
#'
#' @examples
#' result <- simulate_multiplex_network(nodes = 25, layers = 3, probability = 0.1, seed = 1)
#' head(result)
#' components(result)
simulate_multiplex_network <- function(nodes, layers, edges = NULL,
                                       probability = 0.1,
                                       directed = TRUE, loops = FALSE,
                                       weight = c("binary", "uniform", "normal", "poisson"),
                                       weight_mean = 1, weight_sd = 1,
                                       weight_range = c(0.1, 1),
                                       node_type = NULL, seed = NULL) {
  weight_distribution <- match.arg(weight)
  .network_weight_arguments(
    weight_distribution, weight_mean, weight_sd, weight_range
  )
  node_labels <- .network_node_labels(nodes)
  layer_labels <- if (is.numeric(layers) && length(layers) == 1L &&
                         layers >= 2 && layers == as.integer(layers)) {
    sprintf("Layer %d", seq_len(as.integer(layers)))
  } else as.character(layers)
  if (length(layer_labels) < 2L || anyNA(layer_labels) ||
      any(!nzchar(layer_labels)) || anyDuplicated(layer_labels)) {
    stop("layers must define at least two unique, non-missing labels.", call. = FALSE)
  }
  if (length(probability) == 1L) probability <- rep(probability, length(layer_labels))
  if (length(probability) != length(layer_labels) ||
      any(probability < 0 | probability > 1)) {
    stop("probability must be scalar or one value from zero to one per layer.", call. = FALSE)
  }
  if (!is.null(edges) && length(edges) == 1L) edges <- rep(edges, length(layer_labels))
  if (!is.null(edges) && (length(edges) != length(layer_labels) ||
      any(edges < 0) || any(edges != as.integer(edges)))) {
    stop("edges must be scalar or one non-negative integer per layer.", call. = FALSE)
  }
  simulations <- Map(function(index, layer, layer_probability) {
    simulate_edge_list(
      node_labels, edges = if (is.null(edges)) NULL else edges[index],
      probability = layer_probability, directed = directed, loops = loops,
      weight = weight_distribution, weight_mean = weight_mean,
      weight_sd = weight_sd, weight_range = weight_range,
      node_type = node_type,
      seed = if (is.null(seed)) NULL else seed + index - 1L
    )
  }, seq_along(layer_labels), layer_labels, probability)
  data <- do.call(rbind, Map(function(result, layer) {
    data.frame(layer = layer, .plain_data(result), check.names = FALSE,
               row.names = NULL)
  }, simulations, layer_labels))
  adjacency <- do.call(rbind, Map(function(result, layer) {
    data.frame(layer = layer, as.data.frame(result, what = "adjacency"),
               check.names = FALSE, row.names = NULL)
  }, simulations, layer_labels))
  nodes_table <- as.data.frame(simulations[[1L]], what = "nodes")
  layers_table <- data.frame(layer = layer_labels, probability = probability,
                             stringsAsFactors = FALSE, row.names = NULL)
  settings <- data.frame(
    layers = length(layer_labels), directed = directed, loops = loops,
    weight = weight_distribution, stringsAsFactors = FALSE, row.names = NULL
  )
  .new_simulab_sim(data, "multiplex_network", seed,
                   list(nodes = nodes_table, layers = layers_table,
                        adjacency = adjacency, settings = settings))
}
