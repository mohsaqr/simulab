.copula_quantile <- function(uniform, definition, data, envir) {
  stopifnot(
    "`uniform` must be a numeric vector of values strictly between 0 and 1" =
      is.numeric(uniform) &&
        all(uniform > 0 & uniform < 1),
    "`definition` must be a data frame, with exactly one row" =
      is.data.frame(definition) &&
        nrow(definition) == 1L,
    "`data` must be a data frame" =
      is.data.frame(data) &&
        nrow(data) == length(uniform),
    "`envir` must be an environment" =
      is.environment(envir)
  )
  n <- length(uniform)
  formula <- definition$formula
  variance <- definition$variance
  link <- definition$link
  parameter_1 <- function() {
    .apply_link(.eval_definition(formula, data, n, envir), link)
  }
  parameter_2 <- function() {
    .eval_definition(variance, data, n, envir)
  }

  switch(
    definition$distribution,
    beta = {
      mean <- .check_probability(parameter_1(), "Beta mean")
      precision <- parameter_2()
      if (any(mean <= 0 | mean >= 1)) stop("Beta means must be strictly between zero and one.", call. = FALSE)
      if (any(precision <= 0)) stop("Beta precision must be positive.", call. = FALSE)
      stats::qbeta(uniform, mean * precision, (1 - mean) * precision)
    },
    binary = {
      probability <- .check_probability(parameter_1(), "Binary probability")
      stats::qbinom(uniform, size = 1L, prob = probability)
    },
    binomial = {
      probability <- .check_probability(parameter_1(), "Binomial probability")
      stats::qbinom(uniform, size = parameter_2(), prob = probability)
    },
    categorical = {
      probability_formulas <- .split_definition(formula)
      probabilities <- .eval_definitions(probability_formulas, data, n, envir)
      if (identical(link, "logit")) {
        odds <- exp(probabilities)
        probabilities <- cbind(odds, 1) / (1 + rowSums(odds))
      } else {
        totals <- rowSums(probabilities)
        if (any(probabilities < 0) || any(totals > 1 + 1e-10)) {
          stop("Categorical probabilities must be non-negative and sum to at most one.", call. = FALSE)
        }
        if (any(totals < 1 - 1e-10)) probabilities <- cbind(probabilities, 1 - totals)
      }
      category <- vapply(seq_len(n), function(index) {
        which(uniform[index] <= cumsum(probabilities[index, ]))[1L]
      }, integer(1))
      labels <- .split_definition(variance)
      if (length(labels) == 1L && labels == "0") return(category)
      if (length(labels) != ncol(probabilities)) {
        stop("Categorical labels must match the number of categories.", call. = FALSE)
      }
      ## Coercion warnings are the test here: labels are numeric only if every
      ## one converts, so the NA-with-warning case is the expected negative.
      numeric_labels <- suppressWarnings(as.numeric(labels))
      if (all(!is.na(numeric_labels))) numeric_labels[category] else labels[category]
    },
    exponential = {
      mean <- parameter_1()
      if (any(mean <= 0)) stop("Exponential means must be positive.", call. = FALSE)
      stats::qexp(uniform, rate = 1 / mean)
    },
    gamma = {
      mean <- parameter_1()
      dispersion <- parameter_2()
      if (any(mean <= 0) || any(dispersion <= 0)) {
        stop("Gamma means and dispersions must be positive.", call. = FALSE)
      }
      stats::qgamma(uniform, shape = 1 / dispersion,
                    rate = 1 / (mean * dispersion))
    },
    negative_binomial = {
      mean <- parameter_1()
      dispersion <- parameter_2()
      if (any(mean < 0) || any(dispersion <= 0)) {
        stop("Negative-binomial means must be non-negative and dispersions positive.", call. = FALSE)
      }
      stats::qnbinom(uniform, size = 1 / dispersion, mu = mean)
    },
    normal = {
      mean <- .eval_definition(formula, data, n, envir)
      variance_value <- parameter_2()
      if (any(variance_value < 0)) stop("Normal variances cannot be negative.", call. = FALSE)
      stats::qnorm(uniform, mean = mean, sd = sqrt(variance_value))
    },
    no_zero_poisson = {
      mean <- parameter_1()
      if (any(mean <= 0)) stop("Zero-truncated Poisson means must be positive.", call. = FALSE)
      lower <- stats::ppois(0, lambda = mean)
      stats::qpois(lower + uniform * (1 - lower), lambda = mean)
    },
    poisson = {
      mean <- parameter_1()
      if (any(mean < 0)) stop("Poisson means cannot be negative.", call. = FALSE)
      stats::qpois(uniform, lambda = mean)
    },
    uniform = {
      limits <- .eval_definitions(.split_definition(formula), data, n, envir)
      limits[, 1L] + uniform * (limits[, 2L] - limits[, 1L])
    },
    uniform_integer = {
      limits <- .eval_definitions(.split_definition(formula), data, n, envir)
      floor(limits[, 1L] + uniform * (limits[, 2L] - limits[, 1L] + 1))
    },
    stop(
      sprintf("Distribution '%s' is not available for copula generation.", definition$distribution),
      call. = FALSE
    )
  )
}

.copula_correlation <- function(n_variables, rho, tau, structure, correlation) {
  stopifnot(
    "`n_variables` must be a numeric vector" =
      is.numeric(n_variables),
    "`rho` must be a single number" =
      is.numeric(rho) &&
        length(rho) == 1L,
    "`tau` must be NULL or a single number" =
      is.null(tau) || (is.numeric(tau) && length(tau) == 1L),
    "`structure` must be a single string" =
      is.character(structure) &&
        length(structure) == 1L,
    "`correlation` must be NULL or a matrix or data frame" =
      is.null(correlation) || is.matrix(correlation) || is.data.frame(correlation)
  )
  if (!is.null(tau)) {
    if (tau < -1 || tau > 1) stop("tau must be between -1 and 1.", call. = FALSE)
    rho <- sin(pi * tau / 2)
  }
  if (is.data.frame(correlation)) correlation <- .table_to_square_matrix(correlation, "correlation")
  if (!is.null(correlation)) structure <- "custom"
  .correlation_matrix(n_variables, rho, structure, correlation)
}

#' Simulate correlated general-distribution variables with a Gaussian copula
#'
#' @param n Number of observations.
#' @param specification Variable definitions with supported marginal
#'   distributions.
#' @param rho Optional latent Pearson correlation.
#' @param tau Optional Kendall correlation, overriding `rho`.
#' @param structure Correlation structure: one of `"independent"`,
#'   `"exchangeable"`, `"ar1"`, or `"custom"`. If left unset it is chosen from
#'   the other arguments: `"custom"` when `correlation` is supplied,
#'   `"exchangeable"` when a non-zero `rho` (or `tau`) is supplied, and
#'   `"independent"` otherwise. Passing `"independent"` together with a
#'   non-zero `rho` is a contradiction and raises an error.
#' @param correlation Custom latent correlation matrix or tidy table.
#' @param id Identifier name.
#' @param seed Optional random seed.
#' @param envir Formula evaluation environment.
#'
#' @return A `simulab_sim` base `data.frame` with one row per observation and a
#'   tidy latent-correlation table.
#' @export
#'
#' @examples
#' specification <- define_variables(
#'   define_variable("normal_var", formula = "0", variance = "1", distribution = "normal"),
#'   define_variable("count_var", formula = "3", variance = "0", distribution = "poisson")
#' )
#' result <- simulate_copula(n = 200, specification = specification, rho = 0.5, seed = 1)
#' head(result)
#' components(result)
simulate_copula <- function(n, specification, rho = 0, tau = NULL,
                            structure = c("independent", "exchangeable", "ar1", "custom"),
                            correlation = NULL, id = "id", seed = NULL,
                            envir = parent.frame()) {
  stopifnot(
    "`n` must be a single positive whole number" =
      is.numeric(n) &&
        length(n) == 1L &&
        all(n >= 1) &&
        all(n == as.integer(n)),
    "`specification` must be a `simulab_spec` object, with at least one row" =
      inherits(specification, "simulab_spec") &&
        nrow(specification) >= 1L,
    "`rho` must be a single number" =
      is.numeric(rho) &&
        length(rho) == 1L,
    "`tau` must be NULL or a single number" =
      is.null(tau) || (is.numeric(tau) && length(tau) == 1L),
    "`correlation` must be NULL or a matrix or data frame" =
      is.null(correlation) || is.matrix(correlation) || is.data.frame(correlation),
    "`id` must be a single non-empty string" =
      is.character(id) &&
        length(id) == 1L &&
        all(nzchar(id)),
    "`seed` must be NULL or a single number" =
      is.null(seed) || (is.numeric(seed) && length(seed) == 1L),
    "`envir` must be an environment" =
      is.environment(envir)
  )
  structure <- .resolve_correlation_structure(
    structure, rho != 0 || !is.null(tau), correlation, !missing(structure))
  correlation_matrix <- .copula_correlation(
    nrow(specification), rho, tau, structure, correlation
  )
  variable_names <- specification$variable
  dimnames(correlation_matrix) <- list(variable_names, variable_names)
  base_data <- data.frame(sequence = seq_len(as.integer(n)), row.names = NULL)
  names(base_data) <- id
  latent <- .with_seed(
    seed,
    .draw_multivariate_normal(as.integer(n), rep(0, nrow(specification)),
                              rep(1, nrow(specification)), correlation_matrix)
  )
  uniforms <- stats::pnorm(latent)
  generated <- Map(function(index, variable) {
    .copula_quantile(
      uniforms[, index],
      specification[index, , drop = FALSE],
      base_data,
      envir
    )
  }, seq_len(nrow(specification)), variable_names)
  result <- data.frame(base_data, generated, check.names = FALSE, row.names = NULL)
  names(result) <- c(id, variable_names)
  .new_simulab_sim(
    result,
    type = "copula",
    seed = seed,
    tables = list(
      definitions = .specification_table(specification),
      latent_correlation = .matrix_to_table(correlation_matrix, "correlation")
    )
  )
}

#' Add correlated variables to existing data
#'
#' @param data Base `data.frame`.
#' @param specification New variable definitions.
#' @param rho,tau,structure,correlation Copula correlation arguments.
#'   `structure` follows the same resolution rule as [simulate_copula()]:
#'   leaving it unset selects `"exchangeable"` when a non-zero `rho` or `tau`
#'   is given.
#' @param group Optional grouping variable. With grouping, one definition is
#'   generated as correlated observations within each group.
#' @param seed Optional random seed.
#' @param envir Formula evaluation environment.
#'
#' @return A `simulab_sim` base `data.frame` with the correlated variables.
#' @export
#'
#' @examples
#' data <- data.frame(id = 1:100)
#' specification <- define_variables(
#'   define_variable("a", formula = "0", variance = "1", distribution = "normal"),
#'   define_variable("b", formula = "0", variance = "1", distribution = "normal")
#' )
#' result <- augment_correlated(data, specification = specification, rho = 0.5, seed = 1)
#' head(result)
augment_correlated <- function(data, specification, rho = 0, tau = NULL,
                               structure = c("independent", "exchangeable", "ar1", "custom"),
                               correlation = NULL, group = NULL,
                               seed = NULL, envir = parent.frame()) {
  stopifnot(
    "`data` must be a data frame, with at least one row" =
      is.data.frame(data) &&
        nrow(data) >= 1L,
    "`specification` must be a `simulab_spec` object, with at least one row" =
      inherits(specification, "simulab_spec") &&
        nrow(specification) >= 1L,
    "`rho` must be a single number" =
      is.numeric(rho) &&
        length(rho) == 1L,
    "`tau` must be NULL or a single number" =
      is.null(tau) || (is.numeric(tau) && length(tau) == 1L),
    "`correlation` must be NULL or a matrix or data frame" =
      is.null(correlation) || is.matrix(correlation) || is.data.frame(correlation),
    "`group` must be NULL or a single string naming a column of `data`" =
      is.null(group) || (is.character(group) && length(group) == 1L && group %in% names(data)),
    "`seed` must be NULL or a single number" =
      is.null(seed) || (is.numeric(seed) && length(seed) == 1L),
    "`envir` must be an environment" =
      is.environment(envir)
  )
  structure <- .resolve_correlation_structure(
    structure, rho != 0 || !is.null(tau), correlation, !missing(structure))
  source <- .as_result_data(data)
  if (any(specification$variable %in% names(source))) {
    stop("Correlated variables must not already exist in data.", call. = FALSE)
  }
  if (is.null(group)) {
    correlation_matrix <- .copula_correlation(
      nrow(specification), rho, tau, structure, correlation
    )
    latent <- .with_seed(
      seed,
      .draw_multivariate_normal(nrow(source), rep(0, nrow(specification)),
                                rep(1, nrow(specification)), correlation_matrix)
    )
    uniforms <- stats::pnorm(latent)
    generated <- Map(function(index, variable) {
      .copula_quantile(
        uniforms[, index],
        specification[index, , drop = FALSE],
        source,
        envir
      )
    }, seq_len(nrow(specification)), specification$variable)
    result <- data.frame(source, generated, check.names = FALSE, row.names = NULL)
    names(result) <- c(names(source), specification$variable)
    dimnames(correlation_matrix) <- list(specification$variable, specification$variable)
    correlation_table <- .matrix_to_table(correlation_matrix, "correlation")
  } else {
    if (nrow(specification) != 1L) {
      stop("Grouped correlated generation requires exactly one variable definition.", call. = FALSE)
    }
    group_indices <- split(seq_len(nrow(source)), source[[group]])
    generated <- .with_seed(seed, lapply(group_indices, function(indices) {
      group_correlation <- .copula_correlation(
        length(indices), rho, tau, structure, correlation
      )
      uniform <- stats::pnorm(.draw_multivariate_normal(
        1L,
        rep(0, length(indices)),
        rep(1, length(indices)),
        group_correlation
      ))
      .copula_quantile(as.vector(uniform), specification, source[indices, , drop = FALSE], envir)
    }))
    values <- vector(mode = typeof(generated[[1L]]), length = nrow(source))
    values[unlist(group_indices, use.names = FALSE)] <- unlist(generated, use.names = FALSE)
    source[[specification$variable]] <- values
    result <- source
    correlation_table <- data.frame(
      group = names(group_indices),
      observations = vapply(group_indices, length, integer(1)),
      rho = if (is.null(tau)) rho else sin(pi * tau / 2),
      structure = structure,
      stringsAsFactors = FALSE,
      row.names = NULL
    )
  }
  .new_simulab_sim(
    result,
    type = "augmented_correlated",
    seed = seed,
    tables = list(
      definitions = .specification_table(specification),
      latent_correlation = correlation_table
    )
  )
}
