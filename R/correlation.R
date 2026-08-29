.validate_correlation_matrix <- function(correlation) {
  stopifnot(
    "`correlation` must be a matrix" =
      is.matrix(correlation) &&
        is.numeric(correlation)
  )

  if (nrow(correlation) != ncol(correlation)) {
    stop("Correlation matrix must be square.", call. = FALSE)
  }
  if (!isTRUE(all.equal(correlation, t(correlation), tolerance = 1e-10))) {
    stop("Correlation matrix must be symmetric.", call. = FALSE)
  }
  if (any(abs(diag(correlation) - 1) > 1e-10)) {
    stop("Correlation matrix diagonal must equal one.", call. = FALSE)
  }
  if (min(eigen(correlation, symmetric = TRUE, only.values = TRUE)$values) < -1e-8) {
    stop("Correlation matrix must be positive semidefinite.", call. = FALSE)
  }
  correlation
}

# Resolve the correlation `structure` argument.
#
# `structure` defaults to "independent", which returns an identity matrix and
# discards `rho`. That made a supplied `rho` (or `tau`) silently inert: a call
# such as simulate_correlation(n, rho = 0.6) returned uncorrelated data with
# no warning, while `@param rho` documents it as "Correlation used when
# `correlation` is not supplied".
#
# The rule is now:
#   * `structure` left at its default -> pick the structure that honours the
#     arguments the caller did supply ("custom" if a matrix was given,
#     "exchangeable" if a non-zero rho/tau was given, "independent" otherwise).
#   * `structure` given explicitly as "independent" together with a non-zero
#     rho/tau -> a contradictory request, so raise a classed error rather than
#     silently returning uncorrelated data.
#
# `supplied` must be the caller's own `!missing(structure)`.
.resolve_correlation_structure <- function(structure, dependence_requested,
                                           correlation, supplied) {
  choices <- c("independent", "exchangeable", "ar1", "custom")

  if (!isTRUE(supplied)) {
    if (!is.null(correlation)) return("custom")
    return(if (isTRUE(dependence_requested)) "exchangeable" else "independent")
  }

  structure <- match.arg(structure, choices)
  if (identical(structure, "independent") && is.null(correlation) &&
      isTRUE(dependence_requested)) {
    stop(errorCondition(
      paste0("structure = \"independent\" produces uncorrelated variables, ",
             "so the requested `rho` or `tau` cannot be applied. Use ",
             "structure = \"exchangeable\" or \"ar1\", supply `correlation`, ",
             "or leave `structure` unset to have it chosen for you."),
      class = "simulab_contradictory_structure", call = NULL))
  }
  structure
}


.correlation_matrix <- function(n_variables, rho, structure, correlation = NULL) {
  stopifnot(
    "`n_variables` must be a single positive whole number" =
      is.numeric(n_variables) &&
        length(n_variables) == 1L &&
        all(n_variables >= 1) &&
        all(n_variables == as.integer(n_variables)),
    "`rho` must be a single finite number" =
      is.numeric(rho) &&
        length(rho) == 1L &&
        all(is.finite(rho)),
    "`structure` must be a single string" =
      is.character(structure) &&
        length(structure) == 1L
  )
  structure <- match.arg(structure, c("independent", "exchangeable", "ar1", "custom"))

  if (identical(structure, "custom")) {
    if (is.null(correlation)) {
      stop("A correlation matrix is required for structure = 'custom'.", call. = FALSE)
    }
    if (nrow(correlation) != n_variables) {
      stop("Correlation matrix dimensions do not match n_variables.", call. = FALSE)
    }
    return(.validate_correlation_matrix(correlation))
  }
  if (identical(structure, "independent")) {
    return(diag(n_variables))
  }
  if (abs(rho) > 1) stop("rho must be between -1 and 1.", call. = FALSE)
  if (identical(structure, "exchangeable")) {
    lower <- if (n_variables == 1L) -1 else -1 / (n_variables - 1)
    if (rho < lower) {
      stop(sprintf("Exchangeable rho must be at least %.6f.", lower), call. = FALSE)
    }
    result <- matrix(rho, nrow = n_variables, ncol = n_variables)
    diag(result) <- 1
    return(result)
  }
  indices <- seq_len(n_variables)
  rho^abs(outer(indices, indices, `-`))
}

.matrix_to_table <- function(matrix_value, value_name, row_names = NULL,
                             column_names = NULL, cluster = NULL) {
  stopifnot(
    "`matrix_value` must be a matrix" =
      is.matrix(matrix_value),
    "`value_name` must be a single string" =
      is.character(value_name) &&
        length(value_name) == 1L
  )

  if (is.null(row_names)) row_names <- rownames(matrix_value)
  if (is.null(column_names)) column_names <- colnames(matrix_value)
  if (is.null(row_names)) row_names <- sprintf("V%d", seq_len(nrow(matrix_value)))
  if (is.null(column_names)) column_names <- sprintf("V%d", seq_len(ncol(matrix_value)))

  indices <- expand.grid(
    row_index = seq_len(nrow(matrix_value)),
    column_index = seq_len(ncol(matrix_value)),
    KEEP.OUT.ATTRS = FALSE,
    stringsAsFactors = FALSE
  )
  result <- data.frame(
    row = row_names[indices$row_index],
    column = column_names[indices$column_index],
    value = as.vector(matrix_value),
    stringsAsFactors = FALSE,
    row.names = NULL
  )
  names(result)[3L] <- value_name
  if (!is.null(cluster)) result$cluster <- cluster
  result
}

#' Create a tidy correlation structure
#'
#' @param n_variables Number of variables.
#' @param rho Correlation coefficient used by exchangeable and AR(1)
#'   structures.
#' @param structure Correlation structure: one of `"independent"`,
#'   `"exchangeable"`, `"ar1"`, or `"custom"`. If left unset it is chosen from
#'   the other arguments: `"custom"` when `correlation` is supplied,
#'   `"exchangeable"` when a non-zero `rho` (or `tau`) is supplied, and
#'   `"independent"` otherwise. Passing `"independent"` together with a
#'   non-zero `rho` is a contradiction and raises an error.
#' @param correlation Custom correlation matrix.
#' @param variable_names Optional variable names.
#'
#' @return A base `data.frame` with one row per matrix cell and columns `row`,
#'   `column`, and `correlation`.
#' @export
#'
#' @examples
#' correlation_structure(
#'   n_variables = 3,
#'   rho = 0.5,
#'   structure = "ar1"
#' )
correlation_structure <- function(n_variables, rho = 0,
                                  structure = c("independent", "exchangeable", "ar1", "custom"),
                                  correlation = NULL,
                                  variable_names = NULL) {
  stopifnot(
    "`n_variables` must be a single positive whole number" =
      is.numeric(n_variables) &&
        length(n_variables) == 1L &&
        all(n_variables >= 1) &&
        all(n_variables == as.integer(n_variables)),
    "`rho` must be a single number" =
      is.numeric(rho) &&
        length(rho) == 1L,
    "`variable_names` must be NULL or a character vector" =
      is.null(variable_names) || is.character(variable_names)
  )
  structure <- .resolve_correlation_structure(
    structure, rho != 0, correlation, !missing(structure))
  n_variables <- as.integer(n_variables)
  if (is.null(variable_names)) variable_names <- sprintf("V%d", seq_len(n_variables))
  if (length(variable_names) != n_variables || anyDuplicated(variable_names)) {
    stop("variable_names must contain one unique name per variable.", call. = FALSE)
  }

  matrix_value <- .correlation_matrix(n_variables, rho, structure, correlation)
  .matrix_to_table(matrix_value, "correlation", variable_names, variable_names)
}

.table_to_square_matrix <- function(table, value, row = "row", column = "column") {
  stopifnot(
    "`table` must be a data frame" =
      is.data.frame(table),
    "`value`, `row` and `column` must name columns of `table`" =
      all(c(value, row, column) %in% names(table))
  )

  row_names <- unique(table[[row]])
  column_names <- unique(table[[column]])
  if (!setequal(row_names, column_names)) {
    stop("Correlation table row and column names must match.", call. = FALSE)
  }
  result <- matrix(
    NA_real_,
    nrow = length(row_names),
    ncol = length(column_names),
    dimnames = list(row_names, column_names)
  )
  row_index <- match(table[[row]], row_names)
  column_index <- match(table[[column]], column_names)
  result[cbind(row_index, column_index)] <- table[[value]]
  if (anyNA(result)) stop("Correlation table must contain every matrix cell.", call. = FALSE)
  .validate_correlation_matrix(result)
}

.draw_multivariate_normal <- function(n, means, sds, correlation) {
  stopifnot(
    "`means` must be a numeric vector, the same length as `sds`" =
      is.numeric(means) &&
        length(means) == length(sds),
    "`sds` must be a non-negative numeric vector" =
      is.numeric(sds) &&
        all(sds >= 0),
    "`n` must be a single number of at least 1" =
      is.numeric(n) &&
        length(n) == 1L &&
        all(n >= 1),
    "`correlation` must be a matrix" =
      is.matrix(correlation) &&
        nrow(correlation) == length(means)
  )

  covariance <- diag(sds) %*% correlation %*% diag(sds)
  eigen_result <- eigen(covariance, symmetric = TRUE)
  if (min(eigen_result$values) < -1e-8) {
    stop("Requested covariance matrix is not positive semidefinite.", call. = FALSE)
  }
  root <- eigen_result$vectors %*%
    diag(sqrt(pmax(eigen_result$values, 0)), nrow = length(means)) %*%
    t(eigen_result$vectors)
  standard <- matrix(stats::rnorm(as.integer(n) * length(means)), nrow = as.integer(n))
  sweep(standard %*% root, 2L, means, `+`)
}

#' Simulate correlated Gaussian variables
#'
#' @param n Number of observations.
#' @param means Variable means.
#' @param sds Variable standard deviations.
#' @param rho Correlation used when `correlation` is not supplied.
#' @param structure Correlation structure: one of `"independent"`,
#'   `"exchangeable"`, `"ar1"`, or `"custom"`. If left unset it is chosen from
#'   the other arguments: `"custom"` when `correlation` is supplied,
#'   `"exchangeable"` when a non-zero `rho` (or `tau`) is supplied, and
#'   `"independent"` otherwise. Passing `"independent"` together with a
#'   non-zero `rho` is a contradiction and raises an error.
#' @param correlation A custom correlation matrix or tidy table returned by
#'   `correlation_structure()`.
#' @param variable_names Optional variable names.
#' @param seed Optional random seed.
#'
#' @return A `simulab_sim` base `data.frame`. The requested correlation and
#'   covariance structures are available through `as.data.frame()` using
#'   `what = "correlation"` or `what = "covariance"`.
#' @export
#'
#' @examples
#' simulate_correlated(
#'   n = 100,
#'   means = c(0, 1, 2),
#'   sds = c(1, 2, 1),
#'   rho = 0.4,
#'   structure = "exchangeable",
#'   seed = 1
#' )
simulate_correlated <- function(n, means, sds = 1, rho = 0,
                                structure = c("independent", "exchangeable", "ar1", "custom"),
                                correlation = NULL,
                                variable_names = NULL,
                                seed = NULL) {
  stopifnot(
    "`n` must be a single positive whole number" =
      is.numeric(n) &&
        length(n) == 1L &&
        all(n >= 1) &&
        all(n == as.integer(n)),
    "`means` must be a finite numeric vector, with at least one element" =
      is.numeric(means) &&
        length(means) >= 1L &&
        all(is.finite(means)),
    "`sds` must be a finite numeric vector, with at least one element" =
      is.numeric(sds) &&
        length(sds) >= 1L &&
        all(is.finite(sds)),
    "`rho` must be a single number" =
      is.numeric(rho) &&
        length(rho) == 1L,
    "`variable_names` must be NULL or a character vector" =
      is.null(variable_names) || is.character(variable_names),
    "`seed` must be NULL or a single number" =
      is.null(seed) || (is.numeric(seed) && length(seed) == 1L)
  )
  structure <- .resolve_correlation_structure(
    structure, rho != 0, correlation, !missing(structure))
  if (length(sds) == 1L) sds <- rep(sds, length(means))
  if (length(sds) != length(means) || any(sds < 0)) {
    stop("sds must be non-negative and contain one value per mean.", call. = FALSE)
  }
  if (is.null(variable_names)) variable_names <- names(means)
  if (is.null(variable_names)) variable_names <- sprintf("V%d", seq_along(means))
  if (length(variable_names) != length(means) || anyDuplicated(variable_names)) {
    stop("variable_names must contain one unique name per variable.", call. = FALSE)
  }
  if (is.data.frame(correlation)) {
    correlation <- .table_to_square_matrix(correlation, "correlation")
  }
  if (!is.null(correlation)) structure <- "custom"
  correlation_matrix <- .correlation_matrix(length(means), rho, structure, correlation)
  dimnames(correlation_matrix) <- list(variable_names, variable_names)
  covariance_matrix <- diag(sds) %*% correlation_matrix %*% diag(sds)
  dimnames(covariance_matrix) <- list(variable_names, variable_names)

  values <- .with_seed(
    seed,
    .draw_multivariate_normal(as.integer(n), means, sds, correlation_matrix)
  )
  data <- data.frame(id = seq_len(as.integer(n)), values, check.names = FALSE, row.names = NULL)
  names(data) <- c("id", variable_names)
  parameters <- data.frame(
    variable = variable_names,
    mean = means,
    sd = sds,
    stringsAsFactors = FALSE,
    row.names = NULL
  )
  .new_simulab_sim(
    data,
    type = "correlated",
    seed = seed,
    tables = list(
      parameters = parameters,
      correlation = .matrix_to_table(correlation_matrix, "correlation"),
      covariance = .matrix_to_table(covariance_matrix, "covariance")
    )
  )
}

#' Simulate correlated ordinal variables
#'
#' @param n Number of observations.
#' @param probabilities A numeric vector used for every variable or a matrix
#'   with one row per variable and one column per category.
#' @param n_variables Number of variables when `probabilities` is a vector.
#' @param rho,structure,correlation Correlation arguments for the latent
#'   normal variables. `structure` follows the same resolution rule as
#'   [simulate_correlated()]: leaving it unset selects `"exchangeable"` when a
#'   non-zero `rho` is given. Passed to the latent
#'   Gaussian generator.
#' @param labels Optional category labels.
#' @param variable_names Optional variable names.
#' @param seed Optional random seed.
#'
#' @return A `simulab_sim` base `data.frame` with one row per observation.
#' @export
#'
#' @examples
#' result <- simulate_ordinal(
#'   n = 200, probabilities = c(0.2, 0.5, 0.3), n_variables = 2, rho = 0.4, seed = 1
#' )
#' head(result)
#' as.data.frame(result, what = "probabilities")
simulate_ordinal <- function(n, probabilities, n_variables = 1L, rho = 0,
                             structure = c("independent", "exchangeable", "ar1", "custom"),
                             correlation = NULL, labels = NULL,
                             variable_names = NULL, seed = NULL) {
  stopifnot(
    "`n` must be a single positive whole number" =
      is.numeric(n) &&
        length(n) == 1L &&
        all(n >= 1) &&
        all(n == as.integer(n)),
    "`probabilities` must be a finite numeric vector" =
      is.numeric(probabilities) &&
        all(is.finite(probabilities)),
    "`n_variables` must be a single positive whole number" =
      is.numeric(n_variables) &&
        length(n_variables) == 1L &&
        all(n_variables >= 1) &&
        all(n_variables == as.integer(n_variables)),
    "`labels` must be NULL or an atomic vector" =
      is.null(labels) || is.atomic(labels),
    "`variable_names` must be NULL or a character vector" =
      is.null(variable_names) || is.character(variable_names),
    "`seed` must be NULL or a single number" =
      is.null(seed) || (is.numeric(seed) && length(seed) == 1L)
  )
  structure <- .resolve_correlation_structure(
    structure, rho != 0, correlation, !missing(structure))
  if (is.vector(probabilities)) {
    probabilities <- matrix(
      rep(probabilities, each = as.integer(n_variables)),
      nrow = as.integer(n_variables)
    )
  } else {
    n_variables <- nrow(probabilities)
  }
  if (any(probabilities < 0) || any(abs(rowSums(probabilities) - 1) > 1e-8)) {
    stop("Each ordinal probability row must be non-negative and sum to one.", call. = FALSE)
  }
  if (is.null(labels)) labels <- seq_len(ncol(probabilities))
  if (length(labels) != ncol(probabilities)) {
    stop("labels must contain one value per ordinal category.", call. = FALSE)
  }
  if (is.null(variable_names)) variable_names <- sprintf("V%d", seq_len(n_variables))
  if (length(variable_names) != n_variables || anyDuplicated(variable_names)) {
    stop("variable_names must contain one unique name per variable.", call. = FALSE)
  }
  if (is.data.frame(correlation)) {
    correlation <- .table_to_square_matrix(correlation, "correlation")
  }
  if (!is.null(correlation)) structure <- "custom"
  correlation_matrix <- .correlation_matrix(n_variables, rho, structure, correlation)
  dimnames(correlation_matrix) <- list(variable_names, variable_names)

  latent <- .with_seed(
    seed,
    .draw_multivariate_normal(as.integer(n), rep(0, n_variables), rep(1, n_variables), correlation_matrix)
  )
  ordinal <- vapply(seq_len(n_variables), function(index) {
    thresholds <- stats::qnorm(cumsum(probabilities[index, ]))
    category <- findInterval(latent[, index], thresholds) + 1L
    labels[pmin(category, length(labels))]
  }, FUN.VALUE = labels[rep(1L, as.integer(n))])
  if (is.vector(ordinal)) ordinal <- matrix(ordinal, ncol = 1L)
  data <- data.frame(id = seq_len(as.integer(n)), ordinal, check.names = FALSE, row.names = NULL)
  names(data) <- c("id", variable_names)
  probability_table <- data.frame(
    variable = rep(variable_names, each = ncol(probabilities)),
    category = rep(labels, times = n_variables),
    probability = as.vector(t(probabilities)),
    stringsAsFactors = FALSE,
    row.names = NULL
  )
  .new_simulab_sim(
    data,
    type = "ordinal",
    seed = seed,
    tables = list(
      probabilities = probability_table,
      correlation = .matrix_to_table(correlation_matrix, "correlation")
    )
  )
}

.one_block_correlation <- function(n_individuals, n_periods, within_period,
                                   between_period, within_individual, decay,
                                   design) {
  stopifnot(
    "`n_periods` must be a single number" =
      is.numeric(n_periods) &&
        length(n_periods) == 1L,
    "`n_individuals` must be a positive numeric vector, of whole numbers" =
      is.numeric(n_individuals) &&
        length(n_individuals) == n_periods &&
        all(n_individuals >= 1) &&
        all(n_individuals == as.integer(n_individuals)),
    "`within_period` must be a single number" =
      is.numeric(within_period) &&
        length(within_period) == 1L,
    "`between_period` must be a single number" =
      is.numeric(between_period) &&
        length(between_period) == 1L,
    "`within_individual` must be NULL or a numeric vector" =
      is.null(within_individual) || is.numeric(within_individual),
    "`decay` must be NULL or a numeric vector" =
      is.null(decay) || is.numeric(decay),
    "`design` must be a single string" =
      is.character(design) &&
        length(design) == 1L
  )

  period <- rep(seq_len(n_periods), times = n_individuals)
  person <- if (identical(design, "cohort")) {
    unlist(lapply(n_individuals, seq_len), use.names = FALSE)
  } else {
    seq_along(period)
  }
  period_gap <- abs(outer(period, period, `-`))
  same_period <- outer(period, period, `==`)
  same_person <- outer(person, person, `==`)

  if (is.null(decay)) {
    result <- matrix(between_period, nrow = length(period), ncol = length(period))
    result[same_period] <- within_period
    if (identical(design, "cohort")) {
      result[same_person & !same_period] <- within_individual
    }
  } else {
    result <- within_period * decay^period_gap
    if (identical(design, "cohort")) {
      result[same_person & !same_period] <- decay^period_gap[same_person & !same_period]
    }
  }
  diag(result) <- 1
  labels <- sprintf("period_%d_unit_%d", period, person)
  dimnames(result) <- list(labels, labels)
  .validate_correlation_matrix(result)
}

#' Create clustered-period correlation structures
#'
#' @param n_individuals Individuals per period. Supply one value, one value per
#'   cluster, or one value per cluster-period combination.
#' @param n_periods Number of periods.
#' @param within_period Correlation between different individuals in the same
#'   period.
#' @param between_period Correlation between different individuals in different
#'   periods for an exchangeable structure.
#' @param within_individual Correlation for the same individual across periods
#'   in a cohort design.
#' @param decay Optional period-to-period correlation decay. Supplying this
#'   selects a decay structure.
#' @param design Cross-sectional or closed-cohort design.
#' @param n_clusters Number of cluster-specific structures.
#'
#' @return A base `data.frame` with one row per cluster and correlation-matrix
#'   cell.
#' @export
#'
#' @examples
#' block_correlation(
#'   n_individuals = 3,
#'   n_periods = 4,
#'   within_period = 0.3,
#'   between_period = 0.1,
#'   design = "cross_sectional"
#' )
block_correlation <- function(n_individuals, n_periods, within_period,
                              between_period = 0,
                              within_individual = NULL,
                              decay = NULL,
                              design = c("cross_sectional", "cohort"),
                              n_clusters = 1L) {
  stopifnot(
    "`n_individuals` must be a positive numeric vector, of whole numbers, with at least one element" =
      is.numeric(n_individuals) &&
        length(n_individuals) >= 1L &&
        all(n_individuals >= 1) &&
        all(n_individuals == as.integer(n_individuals)),
    "`n_periods` must be a single whole number of at least 2" =
      is.numeric(n_periods) &&
        length(n_periods) == 1L &&
        all(n_periods >= 2) &&
        all(n_periods == as.integer(n_periods)),
    "`within_period` must be a numeric vector, with at least one element" =
      is.numeric(within_period) &&
        length(within_period) >= 1L,
    "`between_period` must be a numeric vector, with at least one element" =
      is.numeric(between_period) &&
        length(between_period) >= 1L,
    "`within_individual` must be NULL or a numeric vector" =
      is.null(within_individual) || is.numeric(within_individual),
    "`decay` must be NULL or a numeric vector" =
      is.null(decay) || is.numeric(decay),
    "`n_clusters` must be a single positive whole number" =
      is.numeric(n_clusters) &&
        length(n_clusters) == 1L &&
        all(n_clusters >= 1) &&
        all(n_clusters == as.integer(n_clusters))
  )
  design <- match.arg(design)
  n_periods <- as.integer(n_periods)
  n_clusters <- as.integer(n_clusters)
  if (!is.null(decay) && any(decay < 0 | decay > 1)) {
    stop("decay must be between zero and one.", call. = FALSE)
  }
  if (any(abs(within_period) > 1) || any(abs(between_period) > 1)) {
    stop("Correlations must be between -1 and 1.", call. = FALSE)
  }
  if (identical(design, "cohort") && is.null(decay) && is.null(within_individual)) {
    stop("within_individual is required for an exchangeable cohort design.", call. = FALSE)
  }

  sizes <- if (length(n_individuals) == 1L) {
    matrix(n_individuals, nrow = n_clusters, ncol = n_periods)
  } else if (length(n_individuals) == n_clusters) {
    matrix(rep(n_individuals, each = n_periods), nrow = n_clusters, byrow = TRUE)
  } else if (length(n_individuals) == n_clusters * n_periods) {
    if (identical(design, "cohort")) {
      stop("Cohort sizes must be constant across periods within a cluster.", call. = FALSE)
    }
    matrix(n_individuals, nrow = n_clusters, byrow = TRUE)
  } else {
    stop(
      "n_individuals must have length one, n_clusters, or n_clusters * n_periods.",
      call. = FALSE
    )
  }
  recycle_cluster <- function(value, name, allow_null = FALSE) {
    stopifnot(
      "`name` must be a single string" =
        is.character(name) &&
          length(name) == 1L,
      "`allow_null` must be a logical vector" =
        is.logical(allow_null)
    )
    if (is.null(value) && allow_null) return(rep(NA_real_, n_clusters))
    if (length(value) == 1L) value <- rep(value, n_clusters)
    if (length(value) != n_clusters) {
      stop(sprintf("%s must have length one or n_clusters.", name), call. = FALSE)
    }
    value
  }
  within_period <- recycle_cluster(within_period, "within_period")
  between_period <- recycle_cluster(between_period, "between_period")
  within_individual <- recycle_cluster(within_individual, "within_individual", TRUE)
  decay <- recycle_cluster(decay, "decay", TRUE)

  matrices <- lapply(seq_len(n_clusters), function(cluster) {
    .one_block_correlation(
      n_individuals = sizes[cluster, ],
      n_periods = n_periods,
      within_period = within_period[cluster],
      between_period = between_period[cluster],
      within_individual = if (is.na(within_individual[cluster])) NULL else within_individual[cluster],
      decay = if (is.na(decay[cluster])) NULL else decay[cluster],
      design = design
    )
  })
  tables <- Map(
    function(matrix_value, cluster) {
      .matrix_to_table(matrix_value, "correlation", cluster = cluster)
    },
    matrices,
    seq_len(n_clusters)
  )
  result <- do.call(rbind, tables)
  rownames(result) <- NULL
  result
}
