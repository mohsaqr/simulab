#' Simulate row-bootstrap synthetic data
#'
#' @param data Source base `data.frame`.
#' @param n Number of synthetic observations.
#' @param variables Variables to sample. `NULL` selects every non-identifier
#'   variable.
#' @param id Identifier variable in the result.
#' @param seed Optional random seed.
#'
#' @return A `simulab_sim` base `data.frame` with jointly resampled rows.
#' @export
#'
#' @examples
#' source_data <- data.frame(id = 1:100, x = stats::rnorm(100), y = stats::runif(100))
#' result <- simulate_synthetic(source_data, n = 50, seed = 1)
#' head(result)
simulate_synthetic <- function(data, n = nrow(data), variables = NULL,
                               id = "id", seed = NULL) {
  stopifnot(
    "`data` must be a data frame, with at least one row" =
      is.data.frame(data) &&
        nrow(data) >= 1L,
    "`n` must be a single positive whole number" =
      is.numeric(n) &&
        length(n) == 1L &&
        all(n >= 1) &&
        all(n == as.integer(n)),
    "`variables` must be NULL or a character vector" =
      is.null(variables) || is.character(variables),
    "`id` must be a single non-empty string" =
      is.character(id) &&
        length(id) == 1L &&
        all(nzchar(id)),
    "`seed` must be NULL or a single number" =
      is.null(seed) || (is.numeric(seed) && length(seed) == 1L)
  )
  source <- .as_result_data(data)
  if (is.null(variables)) variables <- setdiff(names(source), id)
  if (!all(variables %in% names(source))) {
    stop("Every synthetic variable must exist in source data.", call. = FALSE)
  }
  sampled_rows <- .with_seed(seed, sample.int(nrow(source), as.integer(n), replace = TRUE))
  result <- source[sampled_rows, variables, drop = FALSE]
  result[[id]] <- seq_len(as.integer(n))
  result <- result[, c(id, variables), drop = FALSE]
  rownames(result) <- NULL
  provenance <- data.frame(
    id = seq_len(as.integer(n)),
    source_row = sampled_rows,
    stringsAsFactors = FALSE,
    row.names = NULL
  )
  names(provenance)[1L] <- id
  .new_simulab_sim(result, type = "synthetic", seed = seed,
                   tables = list(provenance = provenance))
}

#' Add jointly resampled source variables to existing data
#'
#' @param data Destination base `data.frame`.
#' @param source Source base `data.frame`.
#' @param variables Variables to resample.
#' @param seed Optional random seed.
#'
#' @return A `simulab_sim` base `data.frame` with resampled variables added.
#' @export
#'
#' @examples
#' source_data <- data.frame(x = stats::rnorm(100))
#' data <- data.frame(id = 1:20)
#' result <- augment_synthetic(data, source = source_data, variables = "x", seed = 1)
#' head(result)
augment_synthetic <- function(data, source, variables = NULL, seed = NULL) {
  stopifnot(
    "`data` must be a data frame, with at least one row" =
      is.data.frame(data) &&
        nrow(data) >= 1L,
    "`source` must be a data frame, with at least one row" =
      is.data.frame(source) &&
        nrow(source) >= 1L,
    "`variables` must be NULL or a character vector" =
      is.null(variables) || is.character(variables),
    "`seed` must be NULL or a single number" =
      is.null(seed) || (is.numeric(seed) && length(seed) == 1L)
  )
  destination <- .as_result_data(data)
  source <- .as_result_data(source)
  if (is.null(variables)) variables <- names(source)
  if (!all(variables %in% names(source))) stop("Every variable must exist in source.", call. = FALSE)
  if (any(variables %in% names(destination))) {
    stop("Synthetic variables must not already exist in destination data.", call. = FALSE)
  }
  sampled_rows <- .with_seed(seed, sample.int(nrow(source), nrow(destination), replace = TRUE))
  result <- data.frame(
    destination,
    source[sampled_rows, variables, drop = FALSE],
    check.names = FALSE,
    row.names = NULL
  )
  provenance <- data.frame(
    observation = seq_len(nrow(destination)),
    source_row = sampled_rows,
    row.names = NULL
  )
  .new_simulab_sim(result, type = "augmented_synthetic", seed = seed,
                   tables = list(provenance = provenance))
}

.sample_density <- function(n, values, use_limits, keep_missing) {
  stopifnot(
    "`n` must be a single number of at least 1" =
      is.numeric(n) &&
        length(n) == 1L &&
        all(n >= 1),
    "`values` must be a numeric vector with at least two elements" =
      is.numeric(values) &&
        length(values) >= 2L,
    "`use_limits` must be a single flag" =
      is.logical(use_limits) &&
        length(use_limits) == 1L,
    "`keep_missing` must be a single flag" =
      is.logical(keep_missing) &&
        length(keep_missing) == 1L
  )
  observed <- values[!is.na(values)]
  if (length(observed) < 2L || length(unique(observed)) < 2L) {
    stop("Density simulation requires at least two distinct observed values.", call. = FALSE)
  }
  estimate <- if (use_limits) {
    stats::density(observed, n = 10000L, from = min(observed), to = max(observed))
  } else {
    stats::density(observed, n = 10000L)
  }
  result <- sample(estimate$x, size = as.integer(n), replace = TRUE, prob = estimate$y)
  if (keep_missing && anyNA(values)) {
    missing_probability <- mean(is.na(values))
    result[stats::runif(as.integer(n)) < missing_probability] <- NA_real_
  }
  result
}

#' Simulate from an empirical kernel density
#'
#' @param n Number of observations.
#' @param values Numeric source values.
#' @param variable Output variable name.
#' @param use_limits Constrain draws to the observed range.
#' @param keep_missing Preserve the source missing-data proportion.
#' @param id Identifier variable name.
#' @param seed Optional random seed.
#'
#' @return A `simulab_sim` base `data.frame` with one generated density value
#'   per observation.
#' @export
#'
#' @examples
#' values <- stats::rnorm(200, mean = 5, sd = 2)
#' result <- simulate_density(n = 100, values = values, variable = "score", seed = 1)
#' head(result)
simulate_density <- function(n, values, variable = "value", use_limits = FALSE,
                             keep_missing = FALSE, id = "id", seed = NULL) {
  stopifnot(
    "`n` must be a single positive whole number" =
      is.numeric(n) &&
        length(n) == 1L &&
        all(n >= 1) &&
        all(n == as.integer(n)),
    "`values` must be a numeric vector with at least two elements" =
      is.numeric(values) &&
        length(values) >= 2L,
    "`variable` must be a single non-empty string" =
      is.character(variable) &&
        length(variable) == 1L &&
        all(nzchar(variable)),
    "`use_limits` must be a single flag" =
      is.logical(use_limits) &&
        length(use_limits) == 1L,
    "`keep_missing` must be a single flag" =
      is.logical(keep_missing) &&
        length(keep_missing) == 1L,
    "`id` must be a single non-empty string" =
      is.character(id) &&
        length(id) == 1L &&
        all(nzchar(id)),
    "`seed` must be NULL or a single number" =
      is.null(seed) || (is.numeric(seed) && length(seed) == 1L)
  )
  generated <- .with_seed(seed, .sample_density(n, values, use_limits, keep_missing))
  result <- data.frame(id_value = seq_len(as.integer(n)), generated, row.names = NULL)
  names(result) <- c(id, variable)
  source_summary <- data.frame(
    observations = length(values),
    observed = sum(!is.na(values)),
    missing_proportion = mean(is.na(values)),
    minimum = min(values, na.rm = TRUE),
    maximum = max(values, na.rm = TRUE),
    use_limits = use_limits,
    row.names = NULL
  )
  .new_simulab_sim(result, type = "density", seed = seed,
                   tables = list(source = source_summary))
}

#' Add an empirical-density variable to existing data
#'
#' @param data Destination base `data.frame`.
#' @param values Numeric source values.
#' @param variable Name of the new variable.
#' @param use_limits,keep_missing,seed Density-simulation arguments.
#'
#' @return A `simulab_sim` base `data.frame` with the density variable added.
#' @export
#'
#' @examples
#' values <- stats::rnorm(200, mean = 5, sd = 2)
#' data <- data.frame(id = 1:50)
#' result <- augment_density(data, values = values, variable = "score", seed = 1)
#' head(result)
augment_density <- function(data, values, variable,
                            use_limits = FALSE, keep_missing = FALSE,
                            seed = NULL) {
  stopifnot(
    "`data` must be a data frame, with at least one row" =
      is.data.frame(data) &&
        nrow(data) >= 1L,
    "`values` must be a numeric vector with at least two elements" =
      is.numeric(values) &&
        length(values) >= 2L,
    "`variable` must be a single non-empty string" =
      is.character(variable) &&
        length(variable) == 1L &&
        all(nzchar(variable)),
    "`use_limits` must be a single flag" =
      is.logical(use_limits) &&
        length(use_limits) == 1L,
    "`keep_missing` must be a single flag" =
      is.logical(keep_missing) &&
        length(keep_missing) == 1L,
    "`seed` must be NULL or a single number" =
      is.null(seed) || (is.numeric(seed) && length(seed) == 1L)
  )
  source <- .as_result_data(data)
  if (variable %in% names(source)) stop("Density variable already exists in data.", call. = FALSE)
  source[[variable]] <- .with_seed(
    seed,
    .sample_density(nrow(source), values, use_limits, keep_missing)
  )
  .new_simulab_sim(source, type = "augmented_density", seed = seed)
}

