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

## Resolve a `sds` argument into a profile-by-variable matrix.
##
## Shared by the profile simulators so that scalar, per-variable and
## per-profile standard deviations are accepted identically everywhere.
.profile_sd_matrix <- function(sds, means) {
  stopifnot(
    "`means` must be a numeric matrix" =
      is.matrix(means) && is.numeric(means),
    "`sds` must be a numeric vector, with at least one element" =
      is.numeric(sds) && length(sds) >= 1L
  )
  profiles <- nrow(means)
  variables <- ncol(means)
  result <- if (length(sds) == 1L) {
    matrix(sds, profiles, variables)
  } else if (!is.matrix(sds) && length(sds) == variables) {
    matrix(rep(sds, each = profiles), profiles, variables)
  } else if (is.matrix(sds) && all(dim(sds) == dim(means))) {
    sds
  } else stop("sds must be scalar, per-variable, or profile-by-variable.", call. = FALSE)
  if (any(result <= 0)) stop("Profile standard deviations must be positive.", call. = FALSE)
  result
}

#' Simulate a latent profile model
#'
#' Draws each observation from a multivariate normal mixture: a profile is
#' sampled from `proportions`, then the indicators are drawn from that
#' profile's means, standard deviations and within-profile correlation matrix.
#'
#' @param n Number of observations. A single whole number of at least 2.
#' @param means Profile-by-variable mean matrix (one row per profile, one
#'   column per indicator, at least 2 rows), or a tidy data frame with columns
#'   `profile`, `variable` and `mean`. Column names become the indicator
#'   columns of the returned data; row names are ignored, profile names come
#'   from `labels`.
#' @param sds Scalar (the default, `1`), per-variable vector,
#'   profile-by-variable matrix, or a tidy data frame with columns `profile`,
#'   `variable` and `sd`. All values must be positive.
#' @param proportions Profile proportions, one positive value per profile;
#'   they are rescaled to sum to one. `NULL` (the default) makes every profile
#'   equally likely.
#' @param correlations Optional list of within-profile correlation matrices,
#'   one per profile, or a tidy data frame with columns `profile`, `row`,
#'   `column` and `correlation`. `NULL` (the default) makes the indicators
#'   uncorrelated within every profile.
#' @param labels Optional profile labels, one unique value per profile.
#'   Defaults to `"Profile 1"`, `"Profile 2"` and so on.
#' @param seed Optional random seed.
#'
#' @return A `simulab_sim` base `data.frame` with one row per observation and
#'   columns `id`, `profile` (the true profile label) and one numeric column
#'   per indicator. A `parameters` component holds one row per
#'   profile-by-variable combination with columns `profile`, `variable`,
#'   `mean`, `sd` and `proportion`.
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
  sd_matrix <- .profile_sd_matrix(sds, means)
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

#' Simulate a two-level latent profile model
#'
#' Draws data from the nonparametric two-level mixture of Vermunt (2003). Every
#' cluster belongs to a latent cluster class, a cluster class fixes how common
#' each individual profile is inside its clusters, and the profiles themselves
#' share one measurement model across every cluster. Cluster classes therefore
#' differ in profile prevalence, not in profile means, which is what separates
#' this design from simulating one latent profile model per cluster.
#'
#' @param clusters Number of clusters (level-2 units). A single whole number of
#'   at least 2.
#' @param cluster_size Individuals per cluster: a single whole number recycled
#'   across clusters, or one whole number per cluster, so clusters may be
#'   unbalanced.
#' @param means Profile-by-variable mean matrix (one row per profile, one
#'   column per indicator, at least 2 rows), or a tidy data frame with columns
#'   `profile`, `variable` and `mean`. Column names become the indicator
#'   columns of the returned data; row names are ignored, profile names come
#'   from `labels`.
#' @param profile_probabilities Cluster-class-by-profile matrix of profile
#'   prevalences (one row per cluster class, one column per profile), or a tidy
#'   data frame with columns `cluster_class`, `profile` and `probability`. Every
#'   value must be positive and each row is rescaled to sum to one. A single row
#'   gives an ordinary latent profile model observed in clusters.
#' @param sds Scalar (the default, `1`), per-variable vector,
#'   profile-by-variable matrix, or a tidy data frame with columns `profile`,
#'   `variable` and `sd`. All values must be positive. The measurement model is
#'   shared by every cluster class, so standard deviations do not vary across
#'   them.
#' @param cluster_class_proportions Cluster-class proportions, one positive
#'   value per cluster class; they are rescaled to sum to one. `NULL` (the
#'   default) makes every cluster class equally likely.
#' @param correlations Optional list of within-profile correlation matrices, one
#'   per profile, or a tidy data frame with columns `profile`, `row`, `column`
#'   and `correlation`. `NULL` (the default) makes the indicators uncorrelated
#'   within every profile, the conditional-independence measurement model.
#' @param labels Optional profile labels, one unique value per profile.
#'   Defaults to `"Profile 1"`, `"Profile 2"` and so on.
#' @param cluster_class_labels Optional cluster-class labels, one unique value
#'   per cluster class. Defaults to `"Class 1"`, `"Class 2"` and so on.
#' @param seed Optional random seed.
#'
#' @return A `simulab_sim` base `data.frame` with one row per individual
#'   (`sum(cluster_size)` rows) and the columns `id`, `cluster` (the level-2
#'   identifier), `cluster_class` (the true cluster-class label), `profile` (the
#'   true profile label) and one numeric column per indicator. A `parameters`
#'   component holds one row per profile-by-variable combination with columns
#'   `profile`, `variable`, `mean`, `sd` and `proportion`, the profile's
#'   marginal prevalence across cluster classes. A `profile_probabilities`
#'   component holds one row per cluster-class-by-profile combination with
#'   columns `cluster_class`, `profile`, `probability` and
#'   `cluster_class_proportion`. A `clusters` component holds one row per
#'   cluster with columns `cluster`, `cluster_class` and `size`.
#' @references Vermunt, J. K. (2003). Multilevel latent class models.
#'   *Sociological Methodology*, 33, 213--239.
#'   \doi{10.1111/j.0081-1750.2003.t01-1-00131.x}
#' @export
#'
#' @examples
#' # One measurement model, two cluster classes that differ only in how common
#' # each profile is inside their clusters.
#' means <- matrix(
#'   c(-1.5, -1.2,
#'      0.0,  0.2,
#'      1.5,  1.2),
#'   nrow = 3, byrow = TRUE,
#'   dimnames = list(NULL, c("reading", "maths"))
#' )
#' prevalence <- matrix(
#'   c(0.60, 0.30, 0.10,
#'     0.10, 0.30, 0.60),
#'   nrow = 2, byrow = TRUE
#' )
#' result <- simulate_ml_lpa(
#'   clusters = 30,
#'   cluster_size = 20,
#'   means = means,
#'   profile_probabilities = prevalence,
#'   seed = 1
#' )
#' head(result)
#' as.data.frame(result, what = "profile_probabilities")
#' as.data.frame(result, what = "clusters")
simulate_ml_lpa <- function(clusters, cluster_size, means, profile_probabilities,
                            sds = 1, cluster_class_proportions = NULL,
                            correlations = NULL, labels = NULL,
                            cluster_class_labels = NULL, seed = NULL) {
  means <- .tidy_to_matrix(means, "means", "profile", "variable", "mean")
  profile_probabilities <- .tidy_to_matrix(
    profile_probabilities, "profile_probabilities",
    "cluster_class", "profile", "probability"
  )
  if (is.data.frame(sds)) {
    sds <- .tidy_to_matrix(sds, "sds", "profile", "variable", "sd")
  }
  correlations <- .tidy_to_matrix_list(
    correlations, "correlations", "profile", "row", "column", "correlation",
    symmetric = TRUE, diagonal = 1
  )
  stopifnot(
    "`clusters` must be a single whole number of at least 2" =
      is.numeric(clusters) &&
        length(clusters) == 1L &&
        all(clusters >= 2) &&
        all(clusters == as.integer(clusters)),
    "`cluster_size` must be a positive numeric vector, of whole numbers, with at least one element" =
      is.numeric(cluster_size) &&
        length(cluster_size) >= 1L &&
        all(cluster_size >= 1) &&
        all(cluster_size == as.integer(cluster_size)),
    "`means` must be a matrix, with at least 2 rows" =
      is.matrix(means) &&
        is.numeric(means) &&
        nrow(means) >= 2L,
    "`profile_probabilities` must be a numeric matrix, with one column per profile" =
      is.matrix(profile_probabilities) &&
        is.numeric(profile_probabilities) &&
        nrow(profile_probabilities) >= 1L &&
        ncol(profile_probabilities) == nrow(means),
    "`profile_probabilities` must contain only finite positive values" =
      all(is.finite(profile_probabilities)) &&
        all(profile_probabilities > 0),
    "`sds` must be a numeric vector, with at least one element" =
      is.numeric(sds) &&
        length(sds) >= 1L,
    "`correlations` must be NULL or a list" =
      is.null(correlations) || is.list(correlations),
    "`labels` must be NULL or an atomic vector" =
      is.null(labels) || is.atomic(labels),
    "`cluster_class_labels` must be NULL or an atomic vector" =
      is.null(cluster_class_labels) || is.atomic(cluster_class_labels),
    "`seed` must be NULL or a single number" =
      is.null(seed) || (is.numeric(seed) && length(seed) == 1L)
  )
  clusters <- as.integer(clusters)
  if (length(cluster_size) == 1L) cluster_size <- rep(cluster_size, clusters)
  if (length(cluster_size) != clusters) {
    stop("cluster_size must be scalar or one per cluster.", call. = FALSE)
  }
  profiles <- nrow(means)
  variables <- ncol(means)
  cluster_classes <- nrow(profile_probabilities)
  cluster_class_proportions <- .normalize_proportions(
    cluster_class_proportions, cluster_classes, "cluster_class_proportions"
  )
  prevalence <- profile_probabilities / rowSums(profile_probabilities)
  if (is.null(labels)) labels <- sprintf("Profile %d", seq_len(profiles))
  if (length(labels) != profiles || anyDuplicated(labels)) {
    stop("labels must contain one unique value per profile.", call. = FALSE)
  }
  if (is.null(cluster_class_labels)) {
    cluster_class_labels <- sprintf("Class %d", seq_len(cluster_classes))
  }
  if (length(cluster_class_labels) != cluster_classes ||
      anyDuplicated(cluster_class_labels)) {
    stop("cluster_class_labels must contain one unique value per cluster class.",
         call. = FALSE)
  }
  sd_matrix <- .profile_sd_matrix(sds, means)
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
  cluster_id <- rep(seq_len(clusters), times = as.integer(cluster_size))
  n <- length(cluster_id)
  generated <- .with_seed(seed, {
    cluster_class <- sample(seq_len(cluster_classes), clusters, TRUE,
                            cluster_class_proportions)
    ## Inverse-CDF sampling of one profile per individual, from the row of
    ## `prevalence` belonging to that individual's own cluster class. The last
    ## cumulative probability is set to exactly one so that a rounding shortfall
    ## cannot leave a draw unassigned and silently fall back to profile one.
    cumulative <- t(apply(prevalence, 1L, cumsum))
    cumulative[, profiles] <- 1
    thresholds <- cumulative[cluster_class[cluster_id], , drop = FALSE]
    membership <- max.col(thresholds >= stats::runif(n), ties.method = "first")
    chunks <- lapply(seq_len(profiles), function(profile) {
      indices <- which(membership == profile)
      values <- if (!length(indices)) matrix(numeric(0L), 0L, variables) else .draw_multivariate_normal(
        length(indices), means[profile, ], sd_matrix[profile, ], correlations[[profile]]
      )
      data.frame(index = indices, values, check.names = FALSE, row.names = NULL)
    })
    indexed <- do.call(rbind, chunks)
    indexed <- indexed[order(indexed$index), , drop = FALSE]
    list(cluster_class = cluster_class, membership = membership,
         values = as.matrix(indexed[, -1L, drop = FALSE]))
  })
  data <- data.frame(
    id = seq_len(n), cluster = cluster_id,
    cluster_class = cluster_class_labels[generated$cluster_class[cluster_id]],
    profile = labels[generated$membership], generated$values,
    check.names = FALSE, row.names = NULL
  )
  names(data) <- c("id", "cluster", "cluster_class", "profile", variable_names)
  ## The marginal prevalence of a profile mixes its cluster-class-specific
  ## prevalences over the cluster-class proportions, so it is the quantity a
  ## single-level latent profile model would target.
  marginal <- as.vector(cluster_class_proportions %*% prevalence)
  index <- expand.grid(profile = seq_len(profiles), variable = seq_len(variables))
  parameters <- data.frame(
    profile = labels[index$profile], variable = variable_names[index$variable],
    mean = means[cbind(index$profile, index$variable)],
    sd = sd_matrix[cbind(index$profile, index$variable)],
    proportion = marginal[index$profile], row.names = NULL
  )
  prevalence_index <- expand.grid(cluster_class = seq_len(cluster_classes),
                                  profile = seq_len(profiles))
  probability_table <- data.frame(
    cluster_class = cluster_class_labels[prevalence_index$cluster_class],
    profile = labels[prevalence_index$profile],
    probability = prevalence[cbind(prevalence_index$cluster_class,
                                   prevalence_index$profile)],
    cluster_class_proportion =
      cluster_class_proportions[prevalence_index$cluster_class],
    row.names = NULL
  )
  cluster_table <- data.frame(
    cluster = seq_len(clusters),
    cluster_class = cluster_class_labels[generated$cluster_class],
    size = as.integer(cluster_size), row.names = NULL
  )
  .new_simulab_sim(data, "ml_lpa", seed,
                   list(parameters = parameters,
                        profile_probabilities = probability_table,
                        clusters = cluster_table))
}

#' Simulate a latent class model
#'
#' Draws a latent class for each observation from `proportions`, then draws
#' every indicator independently from that class's category probabilities
#' (the usual local-independence assumption of latent class analysis).
#'
#' @param n Number of observations. A single whole number of at least 2.
#' @param probabilities Item probabilities as an array with dimensions class,
#'   indicator and category, or as a tidy data frame with columns `class`,
#'   `indicator`, `category` and `probability`. Category probabilities must
#'   sum to one within each class and indicator. Only the `indicator` dimnames
#'   are used, to name the indicator columns; any class and category dimnames
#'   are ignored, so class and category labels must be supplied through
#'   `class_labels` and `category_labels`.
#' @param proportions Latent-class proportions, one positive value per class;
#'   they are rescaled to sum to one. `NULL` (the default) makes every class
#'   equally likely.
#' @param class_labels,category_labels Optional labels, one unique value per
#'   class and per category. `class_labels` defaults to `"Class 1"`,
#'   `"Class 2"` and so on; `category_labels` defaults to the integers
#'   `1:categories`, which are the values written into the indicator columns.
#' @param seed Optional random seed.
#'
#' @return A `simulab_sim` base `data.frame` with one row per observation and
#'   columns `id`, `latent_class` (the true class label) and one column per
#'   indicator holding the sampled value of `category_labels`. A `parameters`
#'   component holds one row per class-by-indicator-by-category combination
#'   with columns `latent_class`, `indicator`, `category`, `probability` and
#'   `proportion`.
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
#' # Only the `indicator` dimnames name the output columns, so the class and
#' # category labels are passed explicitly.
#' result <- simulate_lca(
#'   n = 200,
#'   probabilities = probabilities,
#'   proportions = c(0.6, 0.4),
#'   category_labels = c("no", "yes"),
#'   seed = 1
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
#' Draws factor scores from a multivariate normal with unit variances and
#' correlation `factor_correlation`, then forms each indicator as
#' `intercept + loadings %*% scores + error`, where the error standard
#' deviation is `sqrt(uniqueness)`. The implied population covariance is
#' `loadings %*% factor_correlation %*% t(loadings) + diag(uniquenesses)`.
#' Because the factors have unit variance, the loadings are on the
#' standardized-factor metric.
#'
#' @param n Number of observations. A single whole number of at least 2.
#' @param loadings Variable-by-factor loading matrix (one row per indicator,
#'   one column per factor, at least 2 rows), or a tidy data frame with
#'   columns `item`, `factor` and `loading`. Row and column names, when
#'   present, name the indicators and the factors.
#' @param uniquenesses Residual *variances* (not standard deviations), a
#'   scalar recycled across indicators or one non-negative value per
#'   indicator. `NULL` (the default) uses `1 - rowSums(loadings^2)`, which
#'   gives every indicator unit total variance, so the loadings are then fully
#'   standardized. Loadings whose squared row sum exceeds one therefore raise
#'   an error rather than producing a Heywood case.
#' @param factor_correlation Optional factor correlation matrix, or a tidy
#'   data frame with columns `row`, `column` and `correlation`. `NULL` (the
#'   default) makes the factors orthogonal.
#' @param intercepts Variable intercepts, a scalar recycled across indicators
#'   (the default, `0`) or one value per indicator.
#' @param include_scores Single flag; when `TRUE` the true factor scores are
#'   appended to the primary data as one column per factor. Defaults to
#'   `FALSE`.
#' @param seed Optional random seed.
#'
#' @return A `simulab_sim` base `data.frame` with one row per observation and
#'   columns `id` and one per indicator, plus one column per factor when
#'   `include_scores = TRUE`. A `parameters` component holds one row per
#'   variable-by-factor combination with columns `variable`, `factor`,
#'   `loading`, `uniqueness` and `intercept`; a `covariance` component holds
#'   the implied population covariance in tidy form, one row per variable
#'   pair, with columns `row`, `column` and `covariance`.
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
