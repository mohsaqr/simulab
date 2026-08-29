.as_result_data <- function(data) {
  stopifnot(
    "`data` must be a data frame" =
      is.data.frame(data)
  )
  if (inherits(data, "simulab_sim")) .plain_data(data) else as.data.frame(data)
}

#' Expand cluster-level rows into unit-level rows
#'
#' @param data Cluster-level base `data.frame`.
#' @param cluster Name of the cluster identifier.
#' @param size Name of a cluster-size variable or a positive integer applied to
#'   every cluster.
#' @param unit Name of the new unit identifier.
#' @param include_cluster_data Include all cluster-level columns.
#'
#' @return A `simulab_sim` base `data.frame` with one row per unit.
#' @export
#'
#' @examples
#' clusters <- data.frame(cluster = 1:5, site = rep(c("north", "south"), length.out = 5))
#' result <- expand_clusters(clusters, cluster = "cluster", size = 4)
#' head(result)
expand_clusters <- function(data, cluster, size, unit = "id",
                            include_cluster_data = TRUE) {
  stopifnot(
    "`data` must be a data frame, with at least one row" =
      is.data.frame(data) &&
        nrow(data) >= 1L,
    "`cluster` must be a single string naming a column of `data`" =
      is.character(cluster) &&
        length(cluster) == 1L &&
        all(cluster %in% names(data)),
    "`size` must be a single number" =
      (is.character(size) && length(size) == 1L) || (is.numeric(size) && length(size) == 1L),
    "`unit` must be a single non-empty string" =
      is.character(unit) &&
        length(unit) == 1L &&
        all(nzchar(unit)),
    "`include_cluster_data` must be a single flag" =
      is.logical(include_cluster_data) &&
        length(include_cluster_data) == 1L
  )
  source <- .as_result_data(data)
  cluster_sizes <- if (is.character(size)) {
    if (!size %in% names(source)) {
      stop(sprintf("Cluster-size variable '%s' was not found.", size), call. = FALSE)
    }
    source[[size]]
  } else {
    rep(size, nrow(source))
  }
  if (any(!is.finite(cluster_sizes)) || any(cluster_sizes < 1) ||
      any(cluster_sizes != as.integer(cluster_sizes))) {
    stop("Cluster sizes must be positive integers.", call. = FALSE)
  }

  row_index <- rep(seq_len(nrow(source)), times = as.integer(cluster_sizes))
  result <- if (include_cluster_data) {
    source[row_index, , drop = FALSE]
  } else {
    source[row_index, cluster, drop = FALSE]
  }
  result[[unit]] <- seq_len(nrow(result))
  result <- result[, c(unit, setdiff(names(result), unit)), drop = FALSE]
  rownames(result) <- NULL
  cluster_table <- data.frame(
    cluster = source[[cluster]],
    size = as.integer(cluster_sizes),
    stringsAsFactors = FALSE,
    row.names = NULL
  )
  .new_simulab_sim(
    result,
    type = "clusters",
    tables = list(clusters = cluster_table)
  )
}

.resolve_row_parameter <- function(data, value, name, default = NULL) {
  stopifnot(
    "`data` must be a data frame" =
      is.data.frame(data),
    "`name` must be a single string" =
      is.character(name) &&
        length(name) == 1L
  )
  if (is.null(value)) return(default)
  result <- if (is.character(value) && length(value) == 1L) {
    if (!value %in% names(data)) {
      stop(sprintf("Variable '%s' for %s was not found.", value, name), call. = FALSE)
    }
    data[[value]]
  } else {
    value
  }
  if (length(result) == 1L) result <- rep(result, nrow(data))
  if (length(result) != nrow(data)) {
    stop(sprintf("%s must have length one or one value per input row.", name), call. = FALSE)
  }
  result
}

#' Expand observations across periods
#'
#' @param data Base `data.frame` with one row per observational unit.
#' @param periods Number of periods, a variable containing counts, or `NULL`
#'   when `period_values` is supplied.
#' @param id Identifier variable.
#' @param period Name of the period column.
#' @param period_values Optional common period values.
#' @param interval_mean Optional constant or variable defining mean intervals.
#' @param interval_dispersion Optional constant or variable defining gamma
#'   interval dispersion.
#' @param time Name of the generated elapsed-time column.
#' @param time_variables Optional wide variables to gather by period.
#' @param value Name of the gathered time-varying value.
#' @param seed Optional random seed for irregular intervals.
#'
#' @return A `simulab_sim` base `data.frame` with one row per unit-period.
#' @export
#'
#' @examples
#' data <- data.frame(id = 1:10)
#' result <- expand_periods(data, periods = 4, id = "id", period = "period")
#' head(result)
expand_periods <- function(data, periods = NULL, id = "id", period = "period",
                           period_values = NULL, interval_mean = NULL,
                           interval_dispersion = 0, time = "time",
                           time_variables = NULL, value = "value",
                           seed = NULL) {
  stopifnot(
    "`data` must be a data frame, with at least one row" =
      is.data.frame(data) &&
        nrow(data) >= 1L,
    "`id` must be a single string naming a column of `data`" =
      is.character(id) &&
        length(id) == 1L &&
        all(id %in% names(data)),
    "`period` must be a single non-empty string" =
      is.character(period) &&
        length(period) == 1L &&
        all(nzchar(period)),
    "`period_values` must be NULL or an atomic vector" =
      is.null(period_values) || is.atomic(period_values),
    "`time_variables` must be NULL or a character vector" =
      is.null(time_variables) || is.character(time_variables),
    "`value` must be a single non-empty string" =
      is.character(value) &&
        length(value) == 1L &&
        all(nzchar(value)),
    "`seed` must be NULL or a single number" =
      is.null(seed) || (is.numeric(seed) && length(seed) == 1L)
  )
  source <- .as_result_data(data)
  if (!is.null(time_variables) && !all(time_variables %in% names(source))) {
    stop("Every time_variables entry must name an input variable.", call. = FALSE)
  }
  if (!is.null(period_values) && !is.null(periods)) {
    stop("Supply periods or period_values, not both.", call. = FALSE)
  }
  counts <- if (!is.null(period_values)) {
    rep(length(period_values), nrow(source))
  } else {
    .resolve_row_parameter(source, periods, "periods")
  }
  if (is.null(counts)) {
    stop("periods or period_values must be supplied.", call. = FALSE)
  }
  if (any(counts < 1) || any(counts != as.integer(counts))) {
    stop("Period counts must be positive integers.", call. = FALSE)
  }
  if (!is.null(time_variables) && any(counts != length(time_variables))) {
    stop("time_variables must contain one variable per period.", call. = FALSE)
  }

  interval_means <- .resolve_row_parameter(source, interval_mean, "interval_mean", 1)
  interval_dispersions <- .resolve_row_parameter(
    source,
    interval_dispersion,
    "interval_dispersion",
    0
  )
  if (any(interval_means <= 0) || any(interval_dispersions < 0)) {
    stop("Interval means must be positive and dispersions non-negative.", call. = FALSE)
  }
  row_index <- rep(seq_len(nrow(source)), times = as.integer(counts))
  period_index <- unlist(lapply(as.integer(counts), seq_len), use.names = FALSE)
  result <- source[row_index, , drop = FALSE]
  result[[period]] <- if (is.null(period_values)) period_index - 1L else period_values[period_index]

  elapsed <- .with_seed(seed, unlist(Map(
    function(count, mean_interval, dispersion) {
      stopifnot(
        "`count` must be at least 1" =
          all(count >= 1L),
        "`mean_interval` must be positive" =
          all(mean_interval > 0),
        "`dispersion` must be non-negative" =
          all(dispersion >= 0)
      )
      increments <- if (dispersion == 0) {
        rep(mean_interval, count - 1L)
      } else {
        stats::rgamma(
          count - 1L,
          shape = 1 / dispersion,
          rate = 1 / (mean_interval * dispersion)
        )
      }
      c(0, cumsum(increments))
    },
    as.integer(counts),
    interval_means,
    interval_dispersions
  ), use.names = FALSE))
  result[[time]] <- elapsed

  if (!is.null(time_variables)) {
    wide_values <- as.matrix(source[, time_variables, drop = FALSE])
    result[[value]] <- wide_values[cbind(row_index, period_index)]
    result <- result[, setdiff(names(result), time_variables), drop = FALSE]
  }
  rownames(result) <- NULL
  schedule <- data.frame(
    input_row = seq_len(nrow(source)),
    id = source[[id]],
    periods = as.integer(counts),
    interval_mean = interval_means,
    interval_dispersion = interval_dispersions,
    stringsAsFactors = FALSE,
    row.names = NULL
  )
  .new_simulab_sim(result, type = "periods", seed = seed,
                   tables = list(schedule = schedule))
}

#' Create a full factorial design
#'
#' @param factors Named integer vector giving the number of levels per factor.
#' @param replications Number of replications per factor combination.
#' @param coding Numeric coding for factor levels.
#' @param id Identifier-column name.
#'
#' @return A `simulab_sim` base `data.frame` with one row per replicated factor
#'   combination.
#' @export
#'
#' @examples
#' factorial_design(factors = c(dose = 3L, timing = 2L), replications = 2)
factorial_design <- function(factors, replications = 1L,
                             coding = c("dummy", "effect", "level"),
                             id = "id") {
  stopifnot(
    "`factors` must be a named numeric vector, of whole numbers, with at least one element, each at least 2" =
      is.numeric(factors) &&
        length(factors) >= 1L &&
        !is.null(names(factors)) &&
        all(nzchar(names(factors))) &&
        all(factors >= 2) &&
        all(factors == as.integer(factors)),
    "`replications` must be a single positive whole number" =
      is.numeric(replications) &&
        length(replications) == 1L &&
        all(replications >= 1) &&
        all(replications == as.integer(replications)),
    "`id` must be a single non-empty string" =
      is.character(id) &&
        length(id) == 1L &&
        all(nzchar(id))
  )
  coding <- match.arg(coding)
  levels <- lapply(as.integer(factors), seq_len)
  names(levels) <- names(factors)
  combinations <- expand.grid(levels, KEEP.OUT.ATTRS = FALSE, stringsAsFactors = FALSE)
  combinations <- combinations[rep(seq_len(nrow(combinations)), each = replications), , drop = FALSE]
  encoded <- switch(
    coding,
    level = combinations,
    dummy = as.data.frame(lapply(combinations, function(column) column - 1L)),
    effect = as.data.frame(Map(
      function(column, n_levels) {
        if (n_levels == 2L) ifelse(column == 1L, -1L, 1L) else column - 1L
      },
      combinations,
      as.integer(factors)
    ))
  )
  data <- data.frame(sequence = seq_len(nrow(encoded)), encoded, row.names = NULL)
  names(data)[1L] <- id
  definitions <- data.frame(
    factor = names(factors),
    levels = as.integer(factors),
    coding = coding,
    stringsAsFactors = FALSE,
    row.names = NULL
  )
  .new_simulab_sim(data, type = "factorial", tables = list(factors = definitions))
}

#' Encode categorical variables
#'
#' @param data Base `data.frame`.
#' @param variables Categorical variables to encode.
#' @param coding Factor, dummy, or effect coding.
#' @param labels Optional labels for factor coding.
#' @param prefix Prefix for generated variables.
#' @param replace Remove source variables after encoding.
#'
#' @return A `simulab_sim` base `data.frame` with encoded variables.
#' @export
#'
#' @examples
#' data <- data.frame(id = 1:6, arm = rep(c("a", "b", "c"), each = 2))
#' encode_factors(data, variables = "arm", coding = "dummy")
encode_factors <- function(data, variables,
                           coding = c("factor", "dummy", "effect"),
                           labels = NULL, prefix = "f_", replace = FALSE) {
  stopifnot(
    "`data` must be a data frame" =
      is.data.frame(data),
    "`variables` must be a character vector, with at least one element, naming columns of `data`" =
      is.character(variables) &&
        length(variables) >= 1L &&
        all(variables %in% names(data)),
    "`labels` must be NULL or a list" =
      is.null(labels) || is.atomic(labels) || is.list(labels),
    "`prefix` must be a single string" =
      is.character(prefix) &&
        length(prefix) == 1L,
    "`replace` must be a single flag" =
      is.logical(replace) &&
        length(replace) == 1L
  )
  coding <- match.arg(coding)
  source <- .as_result_data(data)
  label_list <- if (is.null(labels)) {
    rep(list(NULL), length(variables))
  } else if (is.list(labels)) {
    labels
  } else {
    rep(list(labels), length(variables))
  }
  if (length(label_list) != length(variables)) {
    stop("labels must be shared or contain one entry per variable.", call. = FALSE)
  }

  encoded_sets <- Map(function(variable, variable_labels) {
    input <- source[[variable]]
    factor_value <- if (is.null(variable_labels)) factor(input) else factor(input, labels = variable_labels)
    if (identical(coding, "factor")) {
      result <- data.frame(factor_value, stringsAsFactors = TRUE)
      names(result) <- sprintf("%s%s", prefix, variable)
      return(result)
    }
    matrix_value <- stats::model.matrix(~ factor_value - 1)
    if (identical(coding, "effect") && ncol(matrix_value) >= 2L) {
      matrix_value <- matrix_value[, -ncol(matrix_value), drop = FALSE]
      matrix_value[factor_value == levels(factor_value)[length(levels(factor_value))], ] <- -1
    }
    result <- as.data.frame(matrix_value)
    names(result) <- sprintf("%s%s_%s", prefix, variable, levels(factor_value)[seq_len(ncol(result))])
    result
  }, variables, label_list)
  encoded <- do.call(cbind, unname(encoded_sets))
  if (replace) source <- source[, setdiff(names(source), variables), drop = FALSE]
  result <- data.frame(source, encoded, check.names = FALSE, row.names = NULL)
  map <- data.frame(
    source = rep(variables, vapply(encoded_sets, ncol, integer(1))),
    encoded = names(encoded),
    coding = coding,
    stringsAsFactors = FALSE,
    row.names = NULL
  )
  .new_simulab_sim(result, type = "encoded_factors", tables = list(encoding = map))
}

#' Build a replicated scenario grid
#'
#' @param ... Named vectors of scenario values.
#' @param replications Replications per scenario combination.
#' @param id Name of the scenario identifier.
#'
#' @return A base `data.frame` with one row per scenario replication.
#' @export
#'
#' @examples
#' scenario_grid(mean_b = c(0, 0.5), n_b = c(20, 40), replications = 2)
scenario_grid <- function(..., replications = 1L, id = "scenario_id") {
  values <- list(...)
  stopifnot(
    "`values` must have at least one element and names" =
      length(values) >= 1L &&
        !is.null(names(values)) &&
        all(nzchar(names(values))),
    "`replications` must be a single positive whole number" =
      is.numeric(replications) &&
        length(replications) == 1L &&
        all(replications >= 1) &&
        all(replications == as.integer(replications)),
    "`id` must be a single non-empty string" =
      is.character(id) &&
        length(id) == 1L &&
        all(nzchar(id))
  )
  grid <- expand.grid(values, KEEP.OUT.ATTRS = FALSE, stringsAsFactors = FALSE)
  grid <- grid[rep(seq_len(nrow(grid)), each = as.integer(replications)), , drop = FALSE]
  grid[[id]] <- rep(seq_len(nrow(grid) / replications), each = as.integer(replications))
  grid$replication <- rep(seq_len(as.integer(replications)), times = nrow(grid) / replications)
  grid <- grid[, c(id, "replication", names(values)), drop = FALSE]
  rownames(grid) <- NULL
  grid
}

#' Merge study data by identifiers
#'
#' @param x,y Base data frames.
#' @param by Identifier variables shared by both inputs.
#' @param join Join type.
#'
#' @return A `simulab_sim` base `data.frame` containing the merged data.
#' @export
#'
#' @examples
#' x <- data.frame(id = 1:5, baseline = 1:5)
#' y <- data.frame(id = 1:5, outcome = 6:10)
#' merge_studies(x, y, by = "id")
merge_studies <- function(x, y, by, join = c("inner", "full", "left")) {
  stopifnot(
    "`x` must be a data frame" =
      is.data.frame(x),
    "`y` must be a data frame" =
      is.data.frame(y),
    "`by` must be a character vector, with at least one element, naming columns of `x`" =
      is.character(by) &&
        length(by) >= 1L &&
        all(by %in% names(x)) &&
        all(by %in% names(y))
  )
  join <- match.arg(join)
  result <- switch(
    join,
    inner = merge(.as_result_data(x), .as_result_data(y), by = by),
    full = merge(.as_result_data(x), .as_result_data(y), by = by, all = TRUE),
    left = merge(.as_result_data(x), .as_result_data(y), by = by, all.x = TRUE)
  )
  .new_simulab_sim(result, type = "merged_studies")
}

#' Select or remove study variables
#'
#' @param data Base `data.frame`.
#' @param keep Variables to retain.
#' @param drop Variables to remove.
#'
#' @return A `simulab_sim` base `data.frame` with the requested variables.
#' @export
#'
#' @examples
#' data <- data.frame(id = 1:5, keep_me = 1:5, drop_me = 6:10)
#' select_variables(data, keep = c("id", "keep_me"))
#' select_variables(data, drop = "drop_me")
select_variables <- function(data, keep = NULL, drop = NULL) {
  stopifnot(
    "`data` must be a data frame" =
      is.data.frame(data),
    "`keep` must be NULL or a character vector" =
      is.null(keep) || is.character(keep),
    "`drop` must be NULL or a character vector" =
      is.null(drop) || is.character(drop)
  )
  if (!is.null(keep) && !is.null(drop)) {
    stop("Supply keep or drop, not both.", call. = FALSE)
  }
  source <- .as_result_data(data)
  variables <- if (!is.null(keep)) keep else setdiff(names(source), drop)
  if (!all(variables %in% names(source))) {
    stop("Every selected variable must exist in data.", call. = FALSE)
  }
  .new_simulab_sim(source[, variables, drop = FALSE], type = "selected_variables")
}
