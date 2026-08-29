#' Simulate a two-group design
#'
#' @param n_a,n_b Group sample sizes.
#' @param mean_a,mean_b Group means.
#' @param sd_a,sd_b Positive group standard deviations.
#' @param labels Two group labels.
#' @param outcome Name of the outcome variable.
#' @param seed Optional random seed.
#'
#' @return A `simulab_sim` base `data.frame` with one row per observation and
#'   tidy group/effect parameter tables.
#' @export
#'
#' @examples
#' result <- simulate_ttest(n_a = 40, n_b = 40, mean_a = 0, mean_b = 0.6, seed = 1)
#' head(result)
#' as.data.frame(result, what = "parameters")
simulate_ttest <- function(n_a, n_b, mean_a, mean_b, sd_a = 1, sd_b = 1,
                           labels = c("A", "B"), outcome = "outcome",
                           seed = NULL) {
  stopifnot(
    "`n_a` must be a single whole number of at least 2" =
      is.numeric(n_a) &&
        length(n_a) == 1L &&
        all(n_a >= 2) &&
        all(n_a == as.integer(n_a)),
    "`n_b` must be a single whole number of at least 2" =
      is.numeric(n_b) &&
        length(n_b) == 1L &&
        all(n_b >= 2) &&
        all(n_b == as.integer(n_b)),
    "`mean_a` must be a single finite number" =
      is.numeric(mean_a) &&
        length(mean_a) == 1L &&
        all(is.finite(mean_a)),
    "`mean_b` must be a single finite number" =
      is.numeric(mean_b) &&
        length(mean_b) == 1L &&
        all(is.finite(mean_b)),
    "`sd_a` must be a single positive number" =
      is.numeric(sd_a) &&
        length(sd_a) == 1L &&
        all(sd_a > 0),
    "`sd_b` must be a single positive number" =
      is.numeric(sd_b) &&
        length(sd_b) == 1L &&
        all(sd_b > 0),
    "`labels` must be an unique atomic vector, of length 2" =
      is.atomic(labels) &&
        length(labels) == 2L &&
        !anyDuplicated(labels),
    "`outcome` must be a single non-empty string" =
      is.character(outcome) &&
        length(outcome) == 1L &&
        all(nzchar(outcome)),
    "`seed` must be NULL or a single number" =
      is.null(seed) || (is.numeric(seed) && length(seed) == 1L)
  )
  values <- .with_seed(seed, c(
    stats::rnorm(as.integer(n_a), mean_a, sd_a),
    stats::rnorm(as.integer(n_b), mean_b, sd_b)
  ))
  data <- data.frame(
    id = seq_along(values),
    group = rep(labels, times = c(as.integer(n_a), as.integer(n_b))),
    value = values,
    stringsAsFactors = FALSE,
    row.names = NULL
  )
  names(data)[3L] <- outcome
  pooled_sd <- sqrt(
    ((n_a - 1) * sd_a^2 + (n_b - 1) * sd_b^2) /
      (n_a + n_b - 2)
  )
  parameters <- data.frame(
    group = labels,
    n = c(as.integer(n_a), as.integer(n_b)),
    mean = c(mean_a, mean_b),
    sd = c(sd_a, sd_b),
    stringsAsFactors = FALSE,
    row.names = NULL
  )
  effects <- data.frame(
    contrast = sprintf("%s - %s", labels[2L], labels[1L]),
    mean_difference = mean_b - mean_a,
    pooled_sd = pooled_sd,
    cohens_d = (mean_b - mean_a) / pooled_sd,
    stringsAsFactors = FALSE,
    row.names = NULL
  )
  .new_simulab_sim(data, type = "ttest", seed = seed,
                   tables = list(parameters = parameters, effects = effects))
}

#' Simulate a one-way group design
#'
#' @param n Group sample size or one size per group.
#' @param means Group means.
#' @param sds Group standard deviations.
#' @param labels Optional group labels.
#' @param outcome Name of the outcome variable.
#' @param seed Optional random seed.
#'
#' @return A `simulab_sim` base `data.frame` with group parameters and the
#'   population eta-squared effect.
#' @export
#'
#' @examples
#' result <- simulate_anova(n = 90, means = c(0, 0.4, 0.9), seed = 1)
#' head(result)
#' as.data.frame(result, what = "parameters")
simulate_anova <- function(n, means, sds = 1, labels = NULL,
                           outcome = "outcome", seed = NULL) {
  stopifnot(
    "`n` must be a numeric vector, of whole numbers, with at least one element, each at least 2" =
      is.numeric(n) &&
        length(n) >= 1L &&
        all(n >= 2) &&
        all(n == as.integer(n)),
    "`means` must be a finite numeric vector with at least two elements" =
      is.numeric(means) &&
        length(means) >= 2L &&
        all(is.finite(means)),
    "`sds` must be a finite positive numeric vector, with at least one element" =
      is.numeric(sds) &&
        length(sds) >= 1L &&
        all(is.finite(sds)) &&
        all(sds > 0),
    "`labels` must be NULL or an atomic vector" =
      is.null(labels) || is.atomic(labels),
    "`outcome` must be a single non-empty string" =
      is.character(outcome) &&
        length(outcome) == 1L &&
        all(nzchar(outcome)),
    "`seed` must be NULL or a single number" =
      is.null(seed) || (is.numeric(seed) && length(seed) == 1L)
  )
  groups <- length(means)
  if (length(n) == 1L) n <- rep(n, groups)
  if (length(sds) == 1L) sds <- rep(sds, groups)
  if (length(n) != groups || length(sds) != groups) {
    stop("n, means, and sds must describe the same number of groups.", call. = FALSE)
  }
  if (is.null(labels)) labels <- sprintf("Group %d", seq_len(groups))
  if (length(labels) != groups || anyDuplicated(labels)) {
    stop("labels must contain one unique value per group.", call. = FALSE)
  }
  values <- .with_seed(seed, unlist(Map(
    function(size, mean, sd) stats::rnorm(as.integer(size), mean, sd),
    n, means, sds
  ), use.names = FALSE))
  data <- data.frame(
    id = seq_along(values),
    group = rep(labels, times = as.integer(n)),
    value = values,
    stringsAsFactors = FALSE,
    row.names = NULL
  )
  names(data)[3L] <- outcome
  grand_mean <- sum(n * means) / sum(n)
  between <- sum(n * (means - grand_mean)^2)
  within <- sum((n - 1) * sds^2)
  parameters <- data.frame(
    group = labels,
    n = as.integer(n),
    mean = means,
    sd = sds,
    stringsAsFactors = FALSE,
    row.names = NULL
  )
  effects <- data.frame(
    grand_mean = grand_mean,
    between_sum_squares = between,
    within_sum_squares = within,
    eta_squared = between / (between + within),
    row.names = NULL
  )
  .new_simulab_sim(data, type = "anova", seed = seed,
                   tables = list(parameters = parameters, effects = effects))
}

#' Simulate a linear regression design
#'
#' @param n Sample size.
#' @param coefficients Named coefficients including optional `(Intercept)`.
#' @param predictor_means,predictor_sds Predictor means and standard deviations.
#' @param correlation Optional predictor correlation matrix or tidy table.
#' @param error_sd Positive residual standard deviation.
#' @param outcome Name of the outcome variable.
#' @param seed Optional random seed.
#'
#' @return A `simulab_sim` base `data.frame` with coefficient, predictor, and
#'   population R-squared tables.
#' @export
#'
#' @examples
#' # `coefficients` must be named; "(Intercept)" is optional.
#' result <- simulate_regression(
#'   n = 200,
#'   coefficients = c("(Intercept)" = 1, x1 = 0.5, x2 = -0.3),
#'   seed = 1
#' )
#' head(result)
#' as.data.frame(result, what = "coefficients")
#' as.data.frame(result, what = "effects")
simulate_regression <- function(n, coefficients, predictor_means = 0,
                                predictor_sds = 1, correlation = NULL,
                                error_sd = 1, outcome = "outcome",
                                seed = NULL) {
  stopifnot(
    "`n` must be a single whole number of at least 2" =
      is.numeric(n) &&
        length(n) == 1L &&
        all(n >= 2) &&
        all(n == as.integer(n)),
    "`coefficients` must be a named numeric vector, with at least one element" =
      is.numeric(coefficients) &&
        length(coefficients) >= 1L &&
        !is.null(names(coefficients)) &&
        all(nzchar(names(coefficients))),
    "`predictor_means` must be a numeric vector" =
      is.numeric(predictor_means),
    "`predictor_sds` must be a numeric vector" =
      is.numeric(predictor_sds),
    "`correlation` must be NULL or a matrix or data frame" =
      is.null(correlation) || is.matrix(correlation) || is.data.frame(correlation),
    "`error_sd` must be a single positive number" =
      is.numeric(error_sd) &&
        length(error_sd) == 1L &&
        all(error_sd > 0),
    "`outcome` must be a single non-empty string" =
      is.character(outcome) &&
        length(outcome) == 1L &&
        all(nzchar(outcome)),
    "`seed` must be NULL or a single number" =
      is.null(seed) || (is.numeric(seed) && length(seed) == 1L)
  )
  intercept <- if ("(Intercept)" %in% names(coefficients)) coefficients["(Intercept)"] else 0
  slopes <- coefficients[names(coefficients) != "(Intercept)"]
  if (!length(slopes)) stop("At least one predictor coefficient is required.", call. = FALSE)
  predictor_names <- names(slopes)
  if (length(predictor_means) == 1L) predictor_means <- rep(predictor_means, length(slopes))
  if (length(predictor_sds) == 1L) predictor_sds <- rep(predictor_sds, length(slopes))
  if (length(predictor_means) != length(slopes) ||
      length(predictor_sds) != length(slopes) || any(predictor_sds <= 0)) {
    stop("Predictor means and standard deviations must match coefficients.", call. = FALSE)
  }
  if (is.null(correlation)) correlation <- diag(length(slopes))
  if (is.data.frame(correlation)) correlation <- .table_to_square_matrix(correlation, "correlation")
  correlation <- .validate_correlation_matrix(correlation)
  if (nrow(correlation) != length(slopes)) {
    stop("Predictor correlation dimensions must match coefficients.", call. = FALSE)
  }
  dimnames(correlation) <- list(predictor_names, predictor_names)
  generated <- .with_seed(seed, {
    predictors <- .draw_multivariate_normal(
      as.integer(n), predictor_means, predictor_sds, correlation
    )
    signal <- as.vector(intercept + predictors %*% slopes)
    response <- signal + stats::rnorm(as.integer(n), sd = error_sd)
    list(predictors = predictors, signal = signal, response = response)
  })
  data <- data.frame(
    id = seq_len(as.integer(n)),
    generated$predictors,
    outcome_value = generated$response,
    check.names = FALSE,
    row.names = NULL
  )
  names(data) <- c("id", predictor_names, outcome)
  covariance <- diag(predictor_sds) %*% correlation %*% diag(predictor_sds)
  signal_variance <- as.numeric(t(slopes) %*% covariance %*% slopes)
  coefficient_table <- data.frame(
    term = c("(Intercept)", predictor_names),
    coefficient = c(intercept, slopes),
    stringsAsFactors = FALSE,
    row.names = NULL
  )
  effects <- data.frame(
    signal_variance = signal_variance,
    residual_variance = error_sd^2,
    r_squared = signal_variance / (signal_variance + error_sd^2),
    row.names = NULL
  )
  .new_simulab_sim(
    data,
    type = "regression",
    seed = seed,
    tables = list(
      coefficients = coefficient_table,
      effects = effects,
      predictor_correlation = .matrix_to_table(correlation, "correlation")
    )
  )
}

#' Simulate Gaussian clusters
#'
#' @param n Sample size.
#' @param centers Matrix with one row per cluster and one column per variable.
#' @param sds Scalar, per-variable vector, or cluster-by-variable matrix.
#' @param proportions Optional cluster proportions.
#' @param labels Optional cluster labels.
#' @param seed Optional random seed.
#'
#' @return A `simulab_sim` base `data.frame` with true cluster membership and
#'   tidy center/scale tables.
#' @export
#'
#' @examples
#' # `centers` is one row per cluster and one column per variable.
#' result <- simulate_clusters(
#'   n = 150,
#'   centers = matrix(c(0, 0, 4, 4, 0, 4), nrow = 3, byrow = TRUE),
#'   sds = 1,
#'   seed = 1
#' )
#' head(result)
#' as.data.frame(result, what = "parameters")
simulate_clusters <- function(n, centers, sds = 1, proportions = NULL,
                              labels = NULL, seed = NULL) {
  stopifnot(
    "`n` must be a single whole number of at least 2" =
      is.numeric(n) &&
        length(n) == 1L &&
        all(n >= 2) &&
        all(n == as.integer(n)),
    "`centers` must be a matrix, with at least 2 rows" =
      is.matrix(centers) &&
        is.numeric(centers) &&
        nrow(centers) >= 2L,
    "`sds` must be a numeric vector, with at least one element" =
      is.numeric(sds) &&
        length(sds) >= 1L,
    "`proportions` must be NULL or a numeric vector" =
      is.null(proportions) || is.numeric(proportions),
    "`labels` must be NULL or an atomic vector" =
      is.null(labels) || is.atomic(labels),
    "`seed` must be NULL or a single number" =
      is.null(seed) || (is.numeric(seed) && length(seed) == 1L)
  )
  clusters <- nrow(centers)
  variables <- ncol(centers)
  if (is.null(proportions)) proportions <- rep(1 / clusters, clusters)
  if (length(proportions) != clusters || any(proportions <= 0)) {
    stop("proportions must contain one positive value per cluster.", call. = FALSE)
  }
  proportions <- proportions / sum(proportions)
  if (is.null(labels)) labels <- sprintf("Cluster %d", seq_len(clusters))
  if (length(labels) != clusters || anyDuplicated(labels)) {
    stop("labels must contain one unique value per cluster.", call. = FALSE)
  }
  sd_matrix <- if (length(sds) == 1L) {
    matrix(sds, nrow = clusters, ncol = variables)
  } else if (length(sds) == variables) {
    matrix(rep(sds, each = clusters), nrow = clusters)
  } else if (is.matrix(sds) && all(dim(sds) == dim(centers))) {
    sds
  } else {
    stop("sds must be scalar, per-variable, or cluster-by-variable.", call. = FALSE)
  }
  if (any(sd_matrix <= 0)) stop("Cluster standard deviations must be positive.", call. = FALSE)
  variable_names <- colnames(centers)
  if (is.null(variable_names)) variable_names <- sprintf("V%d", seq_len(variables))
  generated <- .with_seed(seed, {
    membership <- sample(seq_len(clusters), as.integer(n), replace = TRUE, prob = proportions)
    values <- vapply(seq_len(variables), function(variable) {
      stats::rnorm(
        as.integer(n),
        mean = centers[membership, variable],
        sd = sd_matrix[membership, variable]
      )
    }, numeric(as.integer(n)))
    list(membership = membership, values = values)
  })
  data <- data.frame(
    id = seq_len(as.integer(n)),
    cluster = labels[generated$membership],
    generated$values,
    check.names = FALSE,
    row.names = NULL
  )
  names(data) <- c("id", "cluster", variable_names)
  parameter_index <- expand.grid(
    cluster = seq_len(clusters),
    variable = seq_len(variables),
    KEEP.OUT.ATTRS = FALSE
  )
  parameters <- data.frame(
    cluster = labels[parameter_index$cluster],
    variable = variable_names[parameter_index$variable],
    center = centers[cbind(parameter_index$cluster, parameter_index$variable)],
    sd = sd_matrix[cbind(parameter_index$cluster, parameter_index$variable)],
    proportion = proportions[parameter_index$cluster],
    stringsAsFactors = FALSE,
    row.names = NULL
  )
  .new_simulab_sim(data, type = "clusters", seed = seed,
                   tables = list(parameters = parameters))
}

