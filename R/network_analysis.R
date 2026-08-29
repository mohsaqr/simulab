.network_edge_data <- function(x) {
  if (inherits(x, "simulab_sim") || is.data.frame(x)) {
    data <- if (inherits(x, "simulab_sim")) .plain_data(x) else x
    if (!all(c("from", "to") %in% names(data))) {
      stop("Network data require from and to columns.", call. = FALSE)
    }
    if (!"weight" %in% names(data)) data$weight <- 1
    return(data[, c("from", "to", "weight"), drop = FALSE])
  }
  if (is.matrix(x)) {
    table <- .matrix_to_table(x, "weight")
    names(table)[1:2] <- c("from", "to")
    return(table[table$weight != 0, , drop = FALSE])
  }
  if (inherits(x, "tna")) {
    table <- .matrix_to_table(x[["weights"]], "weight")
    names(table)[1:2] <- c("from", "to")
    return(table)
  }
  if (inherits(x, "igraph")) {
    endpoints <- igraph::as_edgelist(x, names = TRUE)
    weights <- igraph::edge_attr(x, "weight")
    if (is.null(weights)) weights <- rep(1, nrow(endpoints))
    return(data.frame(from = endpoints[, 1L], to = endpoints[, 2L],
                      weight = weights, row.names = NULL))
  }
  stop("Unsupported network representation.", call. = FALSE)
}

#' Convert tidy network data to an igraph object
#'
#' @param x A simulab network, tidy edge list, matrix, or native TNA model.
#' @param directed Whether the resulting graph is directed.
#'
#' @return A native `igraph` object.
#' @export
#'
#' @examples
#' network <- simulate_network(nodes = 30, model = "bernoulli", probability = 0.1, seed = 1)
#' if (requireNamespace("igraph", quietly = TRUE)) {
#'   graph <- as_igraph(network)
#'   igraph::vcount(graph)
#' }
as_igraph <- function(x, directed = TRUE) {
  stopifnot(
    "`directed` must be a single flag" =
      is.logical(directed) &&
        length(directed) == 1L
  )
  if (!requireNamespace("igraph", quietly = TRUE)) {
    stop("Conversion requires the suggested 'igraph' package.", call. = FALSE)
  }
  edges <- .network_edge_data(x)
  nodes <- if (inherits(x, "simulab_sim") &&
               "nodes" %in% components(x)$table) {
    as.data.frame(x, what = "nodes")$node
  } else unique(c(edges$from, edges$to))
  igraph::graph_from_data_frame(edges, directed = directed,
                                vertices = data.frame(name = nodes))
}

#' Calculate tidy network centralities
#'
#' @param network A supported network representation.
#' @param measures Centrality measures.
#' @param directed Treat edges as directed.
#'
#' @return A tidy base `data.frame` with one node/measure/value row.
#' @export
#'
#' @examples
#' network <- simulate_network(nodes = 30, model = "bernoulli", probability = 0.1, seed = 1)
#' head(network_centrality(network, measures = c("degree", "strength")))
network_centrality <- function(network,
                               measures = c("degree", "strength", "betweenness",
                                            "closeness", "eigenvector", "pagerank"),
                               directed = TRUE) {
  stopifnot(
    "`measures` must be a character vector, with at least one element, naming one of `degree`, `strength`, `betweenness`, `closeness`, `eigenvector`, `pagerank`" =
      is.character(measures) &&
        length(measures) >= 1L &&
        all(measures %in% c("degree", "strength", "betweenness", "closeness", "eigenvector", "pagerank"))
  )
  graph <- as_igraph(network, directed = directed)
  weights <- igraph::edge_attr(graph, "weight")
  distances <- if (is.null(weights)) NA else 1 / pmax(abs(weights), .Machine$double.eps)
  values <- lapply(measures, function(measure) switch(
    measure,
    degree = igraph::degree(graph, mode = "all"),
    strength = igraph::strength(graph, mode = "all", weights = weights),
    betweenness = igraph::betweenness(graph, directed = directed, weights = distances),
    closeness = igraph::closeness(graph, mode = "all", weights = distances,
                                  normalized = TRUE),
    eigenvector = igraph::eigen_centrality(graph, directed = directed,
                                            weights = weights)$vector,
    pagerank = igraph::page_rank(graph, directed = directed, weights = weights)$vector
  ))
  do.call(rbind, Map(function(measure, value) {
    data.frame(node = names(value), measure = measure, value = as.numeric(value),
               stringsAsFactors = FALSE, row.names = NULL)
  }, measures, values))
}

.aligned_network_edges <- function(x, y) {
  x_edges <- .network_edge_data(x)
  y_edges <- .network_edge_data(y)
  names(x_edges)[3L] <- "weight_x"
  names(y_edges)[3L] <- "weight_y"
  merged <- merge(x_edges, y_edges, by = c("from", "to"), all = TRUE)
  merged$weight_x[is.na(merged$weight_x)] <- 0
  merged$weight_y[is.na(merged$weight_y)] <- 0
  merged
}

#' Compare two weighted networks
#'
#' @param x,y Supported network representations.
#' @param threshold Absolute weight threshold for edge presence.
#'
#' @return A one-row base `data.frame` with weight and edge-overlap metrics.
#' @export
#'
#' @examples
#' a <- simulate_network(nodes = 30, model = "bernoulli", probability = 0.1, seed = 1)
#' b <- simulate_network(nodes = 30, model = "bernoulli", probability = 0.1, seed = 2)
#' compare_networks(a, b)
compare_networks <- function(x, y, threshold = 0) {
  stopifnot(
    "`threshold` must be a single non-negative number" =
      is.numeric(threshold) &&
        length(threshold) == 1L &&
        all(threshold >= 0)
  )
  aligned <- .aligned_network_edges(x, y)
  present_x <- abs(aligned$weight_x) > threshold
  present_y <- abs(aligned$weight_y) > threshold
  union <- sum(present_x | present_y)
  denominator <- sqrt(sum(aligned$weight_x^2) * sum(aligned$weight_y^2))
  data.frame(
    pearson = if (stats::sd(aligned$weight_x) == 0 ||
                   stats::sd(aligned$weight_y) == 0) NA_real_ else
      stats::cor(aligned$weight_x, aligned$weight_y),
    cosine = if (denominator == 0) NA_real_ else
      sum(aligned$weight_x * aligned$weight_y) / denominator,
    mae = mean(abs(aligned$weight_x - aligned$weight_y)),
    rmse = sqrt(mean((aligned$weight_x - aligned$weight_y)^2)),
    jaccard = if (union == 0) 1 else sum(present_x & present_y) / union,
    edges_x = sum(present_x), edges_y = sum(present_y), row.names = NULL
  )
}

#' Compare node centralities between two networks
#'
#' @param x,y Supported network representations.
#' @param measures Centralities passed to `network_centrality()`.
#' @param method Correlation method.
#' @param directed Treat networks as directed.
#'
#' @return A tidy base `data.frame` with one comparison per measure.
#' @export
#'
#' @examples
#' a <- simulate_network(nodes = 30, model = "bernoulli", probability = 0.1, seed = 1)
#' b <- simulate_network(nodes = 30, model = "bernoulli", probability = 0.1, seed = 2)
#' compare_centralities(a, b, measures = "degree")
compare_centralities <- function(x, y, measures = c("degree", "betweenness", "closeness"),
                                 method = c("pearson", "spearman", "kendall"),
                                 directed = TRUE) {
  method <- match.arg(method)
  first <- network_centrality(x, measures, directed)
  second <- network_centrality(y, measures, directed)
  aligned <- merge(first, second, by = c("node", "measure"), all = TRUE,
                   suffixes = c("_x", "_y"))
  aligned$value_x[is.na(aligned$value_x)] <- 0
  aligned$value_y[is.na(aligned$value_y)] <- 0
  groups <- split(aligned, aligned$measure)
  do.call(rbind, lapply(groups, function(values) data.frame(
    measure = values$measure[1L], method = method,
    correlation = if (stats::sd(values$value_x) == 0 ||
                         stats::sd(values$value_y) == 0) NA_real_ else
      stats::cor(values$value_x, values$value_y, method = method),
    mae = mean(abs(values$value_x - values$value_y)),
    nodes = nrow(values), stringsAsFactors = FALSE, row.names = NULL
  )))
}

#' Evaluate edge recovery against a known network
#'
#' @param truth,estimate Supported network representations.
#' @param threshold Absolute threshold defining a recovered edge.
#'
#' @return A tidy edge-level `simulab_sim` with recovery metrics as a component.
#' @export
#'
#' @examples
#' truth <- simulate_network(nodes = 25, model = "bernoulli", probability = 0.15, seed = 1)
#' estimate <- simulate_network(nodes = 25, model = "bernoulli", probability = 0.15, seed = 2)
#' evaluate_edge_recovery(truth, estimate)
evaluate_edge_recovery <- function(truth, estimate, threshold = 0) {
  stopifnot(
    "`threshold` must be a single non-negative number" =
      is.numeric(threshold) &&
        length(threshold) == 1L &&
        all(threshold >= 0)
  )
  aligned <- .aligned_network_edges(truth, estimate)
  aligned$truth_present <- abs(aligned$weight_x) > threshold
  aligned$estimate_present <- abs(aligned$weight_y) > threshold
  aligned$recovered <- aligned$truth_present & aligned$estimate_present
  aligned$false_positive <- !aligned$truth_present & aligned$estimate_present
  aligned$false_negative <- aligned$truth_present & !aligned$estimate_present
  true_positive <- sum(aligned$recovered)
  precision <- true_positive / max(1, sum(aligned$estimate_present))
  recall <- true_positive / max(1, sum(aligned$truth_present))
  summary <- data.frame(
    precision = precision, recall = recall,
    f1 = if (precision + recall == 0) 0 else 2 * precision * recall / (precision + recall),
    true_positive = true_positive,
    false_positive = sum(aligned$false_positive),
    false_negative = sum(aligned$false_negative), row.names = NULL
  )
  names(aligned)[3:4] <- c("truth_weight", "estimate_weight")
  .new_simulab_sim(aligned, "edge_recovery", tables = list(summary = summary))
}

#' Summarize multiple networks
#'
#' @param networks Named list of supported networks.
#' @param threshold Edge-presence threshold.
#' @param directed Treat networks as directed.
#'
#' @return A tidy base `data.frame` with one summary row per network.
#' @export
#'
#' @examples
#' networks <- list(
#'   first = simulate_network(nodes = 25, model = "bernoulli", probability = 0.1, seed = 1),
#'   second = simulate_network(nodes = 25, model = "bernoulli", probability = 0.2, seed = 2)
#' )
#' summarize_networks(networks)
summarize_networks <- function(networks, threshold = 0, directed = TRUE) {
  stopifnot(
    "`networks` must be a list, with at least one element" =
      is.list(networks) &&
        length(networks) >= 1L,
    "`threshold` must be a single number" =
      is.numeric(threshold) &&
        length(threshold) == 1L
  )
  labels <- names(networks)
  if (is.null(labels)) labels <- sprintf("Network %d", seq_along(networks))
  do.call(rbind, Map(function(network, label) {
    graph <- as_igraph(network, directed)
    edges <- .network_edge_data(network)
    present <- abs(edges$weight) > threshold
    data.frame(
      network = label, nodes = igraph::vcount(graph), edges = sum(present),
      density = igraph::edge_density(graph, loops = FALSE),
      mean_weight = if (any(present)) mean(edges$weight[present]) else NA_real_,
      components = igraph::components(igraph::as_undirected(graph))$no,
      stringsAsFactors = FALSE, row.names = NULL
    )
  }, networks, labels))
}
