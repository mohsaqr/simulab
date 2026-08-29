.normalize_proportions <- function(proportions, groups, name = "proportions") {
  stopifnot(
    "`groups` must be a single number of at least 1" =
      is.numeric(groups) &&
        length(groups) == 1L &&
        all(groups >= 1)
  )
  if (is.null(proportions)) proportions <- rep(1 / groups, groups)
  if (!is.numeric(proportions) || length(proportions) != groups ||
      any(!is.finite(proportions)) || any(proportions <= 0)) {
    stop(sprintf("%s must contain one positive value per group.", name), call. = FALSE)
  }
  proportions / sum(proportions)
}

#' Simulate a latent profile model
#'
#' @param n Number of observations.
#' @param means Profile-by-variable mean matrix, or a tidy data frame with
#'   columns `profile`, `variable` and `mean`.
#' @param sds Scalar, per-variable vector, profile-by-variable matrix, or a
#'   tidy data frame with columns `profile`, `variable` and `sd`.
#' @param proportions Profile proportions.
#' @param correlations Optional list of within-profile correlation matrices,
#'   or a tidy data frame with columns `profile`, `row`, `column` and
#'   `correlation`.
#' @param labels Optional profile labels.
#' @param seed Optional random seed.
#'
#' @return A `simulab_sim` base `data.frame` with true profile and parameters.
#' @export
#'
#' @examples
#' # `means` is one row per profile and one column per indicator.
#' result <- simulate_lpa(
#'   n = 200,
#'   means = matrix(c(0, 0, 3, 3), nrow = 2, byrow = TRUE),
#'   proportions = c(0.6, 0.4),
#'   seed = 1
#' )
#' head(result)
#' as.data.frame(result, what = "parameters")
simulate_lpa <- function(n, means, sds = 1, proportions = NULL,
                         correlations = NULL, labels = NULL, seed = NULL) {
  means <- .tidy_to_matrix(means, "means", "profile", "variable", "mean")
  if (is.data.frame(sds)) {
    sds <- .tidy_to_matrix(sds, "sds", "profile", "variable", "sd")
  }
  correlations <- .tidy_to_matrix_list(
    correlations, "correlations", "profile", "row", "column", "correlation",
    symmetric = TRUE, diagonal = 1
  )
  stopifnot(
    "`n` must be a single whole number of at least 2" =
      is.numeric(n) &&
        length(n) == 1L &&
        all(n >= 2) &&
        all(n == as.integer(n)),
    "`means` must be a matrix, with at least 2 rows" =
      is.matrix(means) &&
        is.numeric(means) &&
        nrow(means) >= 2L,
    "`sds` must be a numeric vector, with at least one element" =
      is.numeric(sds) &&
        length(sds) >= 1L,
    "`correlations` must be NULL or a list" =
      is.null(correlations) || is.list(correlations),
    "`labels` must be NULL or an atomic vector" =
      is.null(labels) || is.atomic(labels),
    "`seed` must be NULL or a single number" =
      is.null(seed) || (is.numeric(seed) && length(seed) == 1L)
  )
  profiles <- nrow(means)
  variables <- ncol(means)
  proportions <- .normalize_proportions(proportions, profiles)
  if (is.null(labels)) labels <- sprintf("Profile %d", seq_len(profiles))
  if (length(labels) != profiles || anyDuplicated(labels)) {
    stop("labels must contain one unique value per profile.", call. = FALSE)
  }
  sd_matrix <- if (length(sds) == 1L) {
    matrix(sds, profiles, variables)
  } else if (!is.matrix(sds) && length(sds) == variables) {
    matrix(rep(sds, each = profiles), profiles, variables)
  } else if (is.matrix(sds) && all(dim(sds) == dim(means))) {
    sds
  } else stop("sds must be scalar, per-variable, or profile-by-variable.", call. = FALSE)
  if (any(sd_matrix <= 0)) stop("Profile standard deviations must be positive.", call. = FALSE)
  if (is.null(correlations)) correlations <- rep(list(diag(variables)), profiles)
  if (length(correlations) != profiles) {
    stop("correlations must contain one matrix per profile.", call. = FALSE)
  }
  correlations <- lapply(correlations, .validate_correlation_matrix)
  if (any(vapply(correlations, nrow, integer(1)) != variables)) {
    stop("Every profile correlation matrix must match the variables.", call. = FALSE)
  }
  variable_names <- colnames(means)
  if (is.null(variable_names)) variable_names <- sprintf("indicator_%d", seq_len(variables))
  generated <- .with_seed(seed, {
    membership <- sample(seq_len(profiles), as.integer(n), TRUE, proportions)
    chunks <- lapply(seq_len(profiles), function(profile) {
      indices <- which(membership == profile)
      values <- if (!length(indices)) matrix(numeric(0L), 0L, variables) else .draw_multivariate_normal(
        length(indices), means[profile, ], sd_matrix[profile, ], correlations[[profile]]
      )
      data.frame(index = indices, values, check.names = FALSE, row.names = NULL)
    })
    indexed <- do.call(rbind, chunks)
    indexed <- indexed[order(indexed$index), , drop = FALSE]
    values <- as.matrix(indexed[, -1L, drop = FALSE])
    list(membership = membership, values = values)
  })
  data <- data.frame(id = seq_len(as.integer(n)),
                     profile = labels[generated$membership], generated$values,
                     check.names = FALSE, row.names = NULL)
  names(data) <- c("id", "profile", variable_names)
  index <- expand.grid(profile = seq_len(profiles), variable = seq_len(variables))
  parameters <- data.frame(
    profile = labels[index$profile], variable = variable_names[index$variable],
    mean = means[cbind(index$profile, index$variable)],
    sd = sd_matrix[cbind(index$profile, index$variable)],
    proportion = proportions[index$profile], row.names = NULL
  )
  .new_simulab_sim(data, "lpa", seed, list(parameters = parameters))
}

#' Simulate a latent class model
#'
#' @param n Number of observations.
#' @param probabilities Item probabilities as an array with dimensions class,
#'   indicator and category, or as a tidy data frame with columns `class`,
#'   `indicator`, `category` and `probability`.
#' @param proportions Latent-class proportions.
#' @param class_labels,category_labels Optional labels.
#' @param seed Optional random seed.
#'
#' @return A `simulab_sim` base `data.frame` with true class and indicators.
#' @export
#'
#' @examples
#' # `probabilities` is a class x indicator x category array. Values fill the
#' # class dimension fastest, so each pair below is one category across the two
#' # classes: P(indicator = 1) then P(indicator = 2).
#' probabilities <- array(
#'   c(0.8, 0.2,   0.7, 0.3,     # category 1, for each class and indicator
#'     0.2, 0.8,   0.3, 0.7),    # category 2, for each class and indicator
#'   dim = c(2, 2, 2),
#'   dimnames = list(
#'     class = c("Class 1", "Class 2"),
#'     indicator = c("item_1", "item_2"),
#'     category = c("no", "yes")
#'   )
#' )
#'
#' result <- simulate_lca(
#'   n = 200, probabilities = probabilities, proportions = c(0.6, 0.4), seed = 1
#' )
#' head(result)
#' as.data.frame(result, what = "parameters")
simulate_lca <- function(n, probabilities, proportions = NULL,
                         class_labels = NULL, category_labels = NULL,
                         seed = NULL) {
  probabilities <- .tidy_to_array(
    probabilities, "probabilities", "class", "indicator", "category", "probability"
  )
  stopifnot(
    "`n` must be a single whole number of at least 2" =
      is.numeric(n) &&
        length(n) == 1L &&
        all(n >= 2) &&
        all(n == as.integer(n)),
    "`probabilities` must be a finite non-negative array" =
      is.array(probabilities) &&
        length(dim(probabilities)) == 3L &&
        is.numeric(probabilities) &&
        all(is.finite(probabilities)) &&
        all(probabilities >= 0),
    "`seed` must be NULL or a single number" =
      is.null(seed) || (is.numeric(seed) && length(seed) == 1L)
  )
  dimensions <- dim(probabilities)
  classes <- dimensions[1L]
  indicators <- dimensions[2L]
  categories <- dimensions[3L]
  if (any(abs(apply(probabilities, c(1L, 2L), sum) - 1) > 1e-8)) {
    stop("Category probabilities must sum to one for each class and indicator.", call. = FALSE)
  }
  proportions <- .normalize_proportions(proportions, classes)
  if (is.null(class_labels)) class_labels <- sprintf("Class %d", seq_len(classes))
  if (is.null(category_labels)) category_labels <- seq_len(categories)
  if (length(class_labels) != classes || anyDuplicated(class_labels) ||
      length(category_labels) != categories || anyDuplicated(category_labels)) {
    stop("Class and category labels must match their dimensions and be unique.", call. = FALSE)
  }
  indicator_names <- dimnames(probabilities)[[2L]]
  if (is.null(indicator_names)) indicator_names <- sprintf("item_%d", seq_len(indicators))
  generated <- .with_seed(seed, {
    membership <- sample(seq_len(classes), as.integer(n), TRUE, proportions)
    values <- vapply(seq_len(indicators), function(indicator) {
      vapply(membership, function(class) {
        sample(category_labels, 1L, prob = probabilities[class, indicator, ])
      }, category_labels[1L])
    }, rep(category_labels[1L], as.integer(n)))
    list(membership = membership, values = values)
  })
  data <- data.frame(id = seq_len(as.integer(n)),
                     latent_class = class_labels[generated$membership],
                     generated$values, check.names = FALSE, row.names = NULL)
  names(data) <- c("id", "latent_class", indicator_names)
  index <- expand.grid(class = seq_len(classes), indicator = seq_len(indicators),
                       category = seq_len(categories))
  parameters <- data.frame(
    latent_class = class_labels[index$class],
    indicator = indicator_names[index$indicator],
    category = category_labels[index$category],
    probability = probabilities[cbind(index$class, index$indicator, index$category)],
    proportion = proportions[index$class], row.names = NULL
  )
  .new_simulab_sim(data, "lca", seed, list(parameters = parameters))
}

#' Simulate a common-factor model
#'
#' @param n Number of observations.
#' @param loadings Variable-by-factor loading matrix, or a tidy data frame
#'   with columns `item`, `factor` and `loading`.
#' @param uniquenesses Residual variances.
#' @param factor_correlation Optional factor correlation matrix, or a tidy
#'   data frame with columns `row`, `column` and `correlation`.
#' @param intercepts Variable intercepts.
#' @param include_scores Include true factor scores in primary data.
#' @param seed Optional random seed.
#'
#' @return A `simulab_sim` base `data.frame` with population covariance and
#'   parameter tables.
#' @export
#'
#' @examples
#' # `loadings` is one row per item and one column per factor.
#' loadings <- matrix(
#'   c(0.8, 0.7, 0.6, 0, 0, 0,
#'     0, 0, 0, 0.8, 0.7, 0.6),
#'   ncol = 2
#' )
#' result <- simulate_factors(n = 300, loadings = loadings, seed = 1)
#' head(result)
#' as.data.frame(result, what = "parameters")
simulate_factors <- function(n, loadings, uniquenesses = NULL,
                             factor_correlation = NULL, intercepts = 0,
                             include_scores = FALSE, seed = NULL) {
  loadings <- .tidy_to_matrix(loadings, "loadings", "item", "factor", "loading")
  factor_correlation <- .tidy_to_symmetric(
    factor_correlation, "factor_correlation", "row", "column", "correlation",
    diagonal = 1
  )
  stopifnot(
    "`n` must be a single whole number of at least 2" =
      is.numeric(n) &&
        length(n) == 1L &&
        all(n >= 2) &&
        all(n == as.integer(n)),
    "`loadings` must be a matrix, with at least 2 rows" =
      is.matrix(loadings) &&
        is.numeric(loadings) &&
        nrow(loadings) >= 2L,
    "`uniquenesses` must be NULL or a numeric vector" =
      is.null(uniquenesses) || is.numeric(uniquenesses),
    "`factor_correlation` must be NULL or a matrix" =
      is.null(factor_correlation) || is.matrix(factor_correlation),
    "`intercepts` must be a numeric vector" =
      is.numeric(intercepts),
    "`include_scores` must be a single flag" =
      is.logical(include_scores) &&
        length(include_scores) == 1L,
    "`seed` must be NULL or a single number" =
      is.null(seed) || (is.numeric(seed) && length(seed) == 1L)
  )
  variables <- nrow(loadings)
  factors <- ncol(loadings)
  if (is.null(uniquenesses)) uniquenesses <- 1 - rowSums(loadings^2)
  if (length(uniquenesses) == 1L) uniquenesses <- rep(uniquenesses, variables)
  if (length(uniquenesses) != variables || any(uniquenesses < 0)) {
    stop("uniquenesses must contain one non-negative variance per variable.", call. = FALSE)
  }
  if (length(intercepts) == 1L) intercepts <- rep(intercepts, variables)
  if (length(intercepts) != variables) stop("intercepts must match variables.", call. = FALSE)
  if (is.null(factor_correlation)) factor_correlation <- diag(factors)
  factor_correlation <- .validate_correlation_matrix(factor_correlation)
  if (nrow(factor_correlation) != factors) {
    stop("factor_correlation dimensions must match the factors.", call. = FALSE)
  }
  variable_names <- rownames(loadings)
  factor_names <- colnames(loadings)
  if (is.null(variable_names)) variable_names <- sprintf("item_%d", seq_len(variables))
  if (is.null(factor_names)) factor_names <- sprintf("factor_%d", seq_len(factors))
  generated <- .with_seed(seed, {
    scores <- .draw_multivariate_normal(as.integer(n), rep(0, factors),
                                        rep(1, factors), factor_correlation)
    errors <- matrix(stats::rnorm(as.integer(n) * variables), as.integer(n), variables)
    observed <- scores %*% t(loadings) + sweep(errors, 2L, sqrt(uniquenesses), `*`)
    observed <- sweep(observed, 2L, intercepts, `+`)
    list(scores = scores, observed = observed)
  })
  data <- data.frame(id = seq_len(as.integer(n)), generated$observed,
                     check.names = FALSE, row.names = NULL)
  names(data) <- c("id", variable_names)
  if (include_scores) {
    score_data <- data.frame(generated$scores, check.names = FALSE)
    names(score_data) <- factor_names
    data <- data.frame(data, score_data, check.names = FALSE)
  }
  index <- expand.grid(variable = seq_len(variables), factor = seq_len(factors))
  parameter_table <- data.frame(
    variable = variable_names[index$variable], factor = factor_names[index$factor],
    loading = loadings[cbind(index$variable, index$factor)],
    uniqueness = uniquenesses[index$variable], intercept = intercepts[index$variable],
    row.names = NULL
  )
  covariance <- loadings %*% factor_correlation %*% t(loadings) + diag(uniquenesses)
  dimnames(covariance) <- list(variable_names, variable_names)
  .new_simulab_sim(data, "factor_model", seed,
                   list(parameters = parameter_table,
                        covariance = .matrix_to_table(covariance, "covariance")))
}
