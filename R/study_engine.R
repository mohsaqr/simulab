.split_definition <- function(value) {
  stopifnot(
    "`value` must be a single string" =
      is.character(value) &&
        length(value) == 1L
  )
  trimws(strsplit(value, ";", fixed = TRUE)[[1L]])
}

.eval_definition <- function(formula, data, n, envir) {
  stopifnot(
    "`formula` must be a single string" =
      is.character(formula) &&
        length(formula) == 1L,
    "`data` must be a data frame" =
      is.data.frame(data),
    "`n` must be a single number of at least 1" =
      is.numeric(n) &&
        length(n) == 1L &&
        all(n >= 1),
    "`envir` must be an environment" =
      is.environment(envir)
  )

  expression <- tryCatch(
    str2lang(formula),
    error = function(error) {
      stop(
        sprintf("Invalid simulation formula '%s': %s", formula, error$message),
        call. = FALSE
      )
    }
  )
  value <- tryCatch(
    eval(expression, envir = data, enclos = envir),
    error = function(error) {
      stop(
        sprintf("Could not evaluate simulation formula '%s': %s", formula, error$message),
        call. = FALSE
      )
    }
  )

  if (length(value) == 1L) {
    value <- rep(value, n)
  }
  if (length(value) != n) {
    stop(
      sprintf("Formula '%s' returned %d values; expected %d.", formula, length(value), n),
      call. = FALSE
    )
  }
  value
}

.eval_definitions <- function(formulas, data, n, envir) {
  stopifnot(
    "`formulas` must be a character vector, with at least one element" =
      is.character(formulas) &&
        length(formulas) >= 1L
  )
  values <- lapply(formulas, .eval_definition, data = data, n = n, envir = envir)
  do.call(cbind, values)
}

.apply_link <- function(value, link) {
  stopifnot(
    "`value` must be a numeric vector" =
      is.numeric(value),
    "`link` must be a single string" =
      is.character(link) &&
        length(link) == 1L
  )
  link <- match.arg(link, c("identity", "log", "logit"))
  switch(
    link,
    identity = value,
    log = exp(value),
    logit = stats::plogis(value)
  )
}

.check_probability <- function(value, name) {
  stopifnot(
    "`value` must be a numeric vector" =
      is.numeric(value),
    "`name` must be a single string" =
      is.character(name) &&
        length(name) == 1L
  )
  if (any(!is.finite(value)) || any(value < 0 | value > 1)) {
    stop(sprintf("%s must contain probabilities between 0 and 1.", name), call. = FALSE)
  }
  value
}

.draw_categorical <- function(formula, labels, link, data, n, envir) {
  stopifnot(
    "`formula` must be a character vector" =
      is.character(formula),
    "`labels` must be a character vector" =
      is.character(labels),
    "`link` must be a character vector" =
      is.character(link)
  )

  probability_formulas <- .split_definition(formula)
  if (length(probability_formulas) < 2L) {
    stop("Categorical variables require at least two probabilities.", call. = FALSE)
  }
  probabilities <- .eval_definitions(probability_formulas, data, n, envir)
  if (identical(link, "logit")) {
    odds <- exp(probabilities)
    probabilities <- cbind(odds, 1) / (1 + rowSums(odds))
  } else {
    if (any(probabilities < 0)) {
      stop("Categorical probabilities cannot be negative.", call. = FALSE)
    }
    totals <- rowSums(probabilities)
    if (any(totals > 1 + sqrt(.Machine$double.eps))) {
      warning("Categorical probabilities above one were normalized by row.", call. = FALSE)
      probabilities <- probabilities / totals
      totals <- rowSums(probabilities)
    }
    if (any(totals < 1 - sqrt(.Machine$double.eps))) {
      probabilities <- cbind(probabilities, 1 - totals)
    }
  }
  probabilities <- probabilities / rowSums(probabilities)

  categories <- vapply(seq_len(n), function(index) {
    sample.int(ncol(probabilities), size = 1L, prob = probabilities[index, ])
  }, integer(1))

  label_values <- .split_definition(labels)
  if (length(label_values) == 1L && identical(label_values, "0")) {
    return(categories)
  }
  if (length(label_values) != ncol(probabilities)) {
    stop(
      sprintf(
        "Categorical labels contain %d values; expected %d.",
        length(label_values),
        ncol(probabilities)
      ),
      call. = FALSE
    )
  }
  ## Coercion warnings are the test here: labels are numeric only if every
  ## one converts, so the NA-with-warning case is the expected negative.
  numeric_labels <- suppressWarnings(as.numeric(label_values))
  if (all(!is.na(numeric_labels))) numeric_labels[categories] else label_values[categories]
}

.draw_mixture <- function(formula, data, n, envir) {
  stopifnot(
    "`formula` must be a single string" =
      is.character(formula) &&
        length(formula) == 1L
  )

  terms <- trimws(strsplit(formula, "+", fixed = TRUE)[[1L]])
  pieces <- lapply(terms, function(term) trimws(strsplit(term, "|", fixed = TRUE)[[1L]]))
  if (any(vapply(pieces, length, integer(1)) != 2L)) {
    stop("Mixture formula terms must use 'value | probability'.", call. = FALSE)
  }
  values <- vapply(pieces, function(piece) piece[1L], character(1))
  probability_formulas <- vapply(pieces, function(piece) piece[2L], character(1))
  probabilities <- .eval_definitions(probability_formulas, data, n, envir)
  if (any(probabilities < 0)) {
    stop("Mixture probabilities cannot be negative.", call. = FALSE)
  }
  totals <- rowSums(probabilities)
  if (any(abs(totals - 1) > 1e-8)) {
    stop("Mixture probabilities must sum to one in every row.", call. = FALSE)
  }
  selected <- vapply(seq_len(n), function(index) {
    sample.int(ncol(probabilities), size = 1L, prob = probabilities[index, ])
  }, integer(1))
  evaluated <- .eval_definitions(values, data, n, envir)
  evaluated[cbind(seq_len(n), selected)]
}

.draw_custom <- function(function_name, arguments, data, n, envir) {
  stopifnot(
    "`function_name` must be a single string" =
      is.character(function_name) &&
        length(function_name) == 1L
  )

  generator <- get(function_name, envir = envir, mode = "function", inherits = TRUE)
  argument_terms <- .split_definition(gsub(",", ";", arguments, fixed = TRUE))
  parsed <- lapply(argument_terms, function(term) {
    parts <- trimws(strsplit(term, "=", fixed = TRUE)[[1L]])
    if (length(parts) != 2L) {
      stop("Custom arguments must use 'name = expression'.", call. = FALSE)
    }
    value <- .eval_definition(parts[2L], data, n, envir)
    list(name = parts[1L], value = value)
  })
  values <- lapply(parsed, function(item) item$value)
  names(values) <- vapply(parsed, function(item) item$name, character(1))
  result <- do.call(generator, c(list(n = n), values))
  if (length(result) != n) {
    stop(sprintf("Custom generator returned %d values; expected %d.", length(result), n), call. = FALSE)
  }
  result
}

.draw_variable <- function(definition, data, envir) {
  stopifnot(
    "`definition` must be a data frame, with exactly one row" =
      is.data.frame(definition) &&
        nrow(definition) == 1L,
    "`data` must be a data frame" =
      is.data.frame(data)
  )

  n <- nrow(data)
  distribution <- definition$distribution
  formula <- definition$formula
  variance <- definition$variance
  link <- definition$link
  mean_value <- function() {
    .apply_link(.eval_definition(formula, data, n, envir), link)
  }
  second_value <- function() {
    .eval_definition(variance, data, n, envir)
  }

  switch(
    distribution,
    beta = {
      mean <- .check_probability(mean_value(), "Beta mean")
      precision <- second_value()
      if (any(mean <= 0 | mean >= 1)) stop("Beta means must be strictly between zero and one.", call. = FALSE)
      if (any(precision <= 0)) stop("Beta precision must be positive.", call. = FALSE)
      stats::rbeta(n, mean * precision, (1 - mean) * precision)
    },
    binary = {
      probability <- .check_probability(mean_value(), "Binary probability")
      stats::rbinom(n, size = 1L, prob = probability)
    },
    binomial = {
      probability <- .check_probability(mean_value(), "Binomial probability")
      size <- second_value()
      if (any(size < 0 | size != as.integer(size))) {
        stop("Binomial trial counts must be non-negative integers.", call. = FALSE)
      }
      stats::rbinom(n, size = size, prob = probability)
    },
    categorical = .draw_categorical(formula, variance, link, data, n, envir),
    cluster_size = {
      total <- .eval_definition(formula, data, n, envir)[1L]
      concentration <- .eval_definition(variance, data, n, envir)[1L]
      if (total < n || total != as.integer(total) || concentration < 0) {
        stop("Cluster size requires an integer total at least n and non-negative dispersion.", call. = FALSE)
      }
      if (concentration == 0) {
        base <- rep(total %/% n, n)
        base[seq_len(total - sum(base))] <- base[seq_len(total - sum(base))] + 1L
        base
      } else {
        weights <- stats::rgamma(n, shape = 1 / concentration)
        sizes <- as.integer(floor(total * weights / sum(weights)))
        sizes[seq_len(total - sum(sizes))] <- sizes[seq_len(total - sum(sizes))] + 1L
        sizes
      }
    },
    custom = .draw_custom(formula, variance, data, n, envir),
    deterministic = mean_value(),
    exponential = {
      mean <- mean_value()
      if (any(mean <= 0)) stop("Exponential means must be positive.", call. = FALSE)
      stats::rexp(n, rate = 1 / mean)
    },
    gamma = {
      mean <- mean_value()
      dispersion <- second_value()
      if (any(mean <= 0) || any(dispersion <= 0)) {
        stop("Gamma means and dispersions must be positive.", call. = FALSE)
      }
      stats::rgamma(n, shape = 1 / dispersion, rate = 1 / (mean * dispersion))
    },
    mixture = .draw_mixture(formula, data, n, envir),
    negative_binomial = {
      mean <- mean_value()
      dispersion <- second_value()
      if (any(mean < 0) || any(dispersion <= 0)) {
        stop("Negative-binomial means must be non-negative and dispersions positive.", call. = FALSE)
      }
      stats::rnbinom(n, size = 1 / dispersion, mu = mean)
    },
    normal = {
      mean <- .eval_definition(formula, data, n, envir)
      variance_value <- second_value()
      if (any(variance_value < 0)) stop("Normal variances cannot be negative.", call. = FALSE)
      stats::rnorm(n, mean = mean, sd = sqrt(variance_value))
    },
    no_zero_poisson = {
      mean <- mean_value()
      if (any(mean <= 0)) stop("Zero-truncated Poisson means must be positive.", call. = FALSE)
      lower <- stats::ppois(0, lambda = mean)
      stats::qpois(lower + stats::runif(n) * (1 - lower), lambda = mean)
    },
    poisson = {
      mean <- mean_value()
      if (any(mean < 0)) stop("Poisson means cannot be negative.", call. = FALSE)
      stats::rpois(n, lambda = mean)
    },
    treatment = {
      ratios <- as.numeric(.split_definition(formula))
      if (any(!is.finite(ratios)) || any(ratios <= 0)) {
        stop("Treatment ratios must be positive numbers.", call. = FALSE)
      }
      assignments <- rep(seq_along(ratios), length.out = n)
      sample(assignments, size = n, replace = FALSE)
    },
    uniform = {
      range <- .eval_definitions(.split_definition(formula), data, n, envir)
      if (ncol(range) != 2L || any(range[, 2L] < range[, 1L])) {
        stop("Uniform formulas require 'minimum;maximum' with maximum >= minimum.", call. = FALSE)
      }
      stats::runif(n, min = range[, 1L], max = range[, 2L])
    },
    uniform_integer = {
      range <- .eval_definitions(.split_definition(formula), data, n, envir)
      if (ncol(range) != 2L || any(range != floor(range)) || any(range[, 2L] < range[, 1L])) {
        stop("Integer-uniform limits must be ordered integers.", call. = FALSE)
      }
      as.integer(floor(stats::runif(n, min = range[, 1L], max = range[, 2L] + 1)))
    },
    stop(sprintf("Distribution '%s' is not implemented.", distribution), call. = FALSE)
  )
}

.generate_from_specification <- function(data, specification, envir) {
  stopifnot(
    "`data` must be a data frame" =
      is.data.frame(data),
    "`specification` must be a `simulab_spec` object" =
      inherits(specification, "simulab_spec"),
    "`envir` must be an environment" =
      is.environment(envir)
  )

  Reduce(
    function(current, index) {
      definition <- specification[index, , drop = FALSE]
      current[[definition$variable]] <- .draw_variable(definition, current, envir)
      current
    },
    seq_len(nrow(specification)),
    init = data
  )
}

## An augmenting verb must not silently overwrite a column the caller already
## has; both specification lanes report the clash the same way.
.stop_if_variables_exist <- function(existing, variables) {
  overlap <- intersect(existing, variables)
  if (!length(overlap)) return(invisible(TRUE))
  stop(errorCondition(
    sprintf("Variables already exist: %s.", paste(overlap, collapse = ", ")),
    class = "simulab_existing_variable", call = NULL
  ))
}

.specification_table <- function(specification) {
  stopifnot(
    "`specification` must be a `simulab_spec` object" =
      inherits(specification, "simulab_spec")
  )
  result <- as.data.frame(specification)
  class(result) <- "data.frame"
  rownames(result) <- NULL
  result
}

#' Simulate a declaratively specified study
#'
#' @param n Number of observational units.
#' @param specification A tidy definition table created with
#'   [define_variables()], in either the distribution-call form or the
#'   `formula`/`variance` column form.
#' @param id Name of the identifier column.
#' @param seed Optional random seed. The caller's random-number state is
#'   restored on exit.
#' @param envir Environment used to resolve functions and external values in
#'   formulas.
#'
#' @return A `simulab_sim` base `data.frame`. Use
#'   `as.data.frame(x, what = "definitions")` for the generating definitions.
#' @export
#'
#' @examples
#' # `formula` is the mean or linear predictor and may refer to variables
#' # defined earlier. `variance` is a variance, not a standard deviation, so
#' # age has sd 10 and outcome has residual sd 2.
#' simulate_study(
#'   n = 20,
#'   specification = define_variables(
#'     define_variable("age", formula = 40, variance = 100, distribution = "normal"),
#'     define_variable("treated", formula = 0.5, distribution = "binary"),
#'     define_variable("outcome", formula = "10 + 2 * treated", variance = 4,
#'                     distribution = "normal")
#'   ),
#'   seed = 1
#' )
simulate_study <- function(n, specification, id = "id", seed = NULL,
                           envir = parent.frame()) {
    ## A call specification carries one row per parameter and is generated by
  ## the distribution registry; the formula/variance specification keeps the
  ## declarative engine below.
  if (.is_call_specification(specification)) {
    stopifnot(
      "`n` must be a single positive whole number" =
        is.numeric(n) && length(n) == 1L && all(n >= 1) && all(n == as.integer(n)),
      "`id` must be a single non-empty string" =
        is.character(id) && length(id) == 1L && all(nzchar(id))
    )
    data <- .with_seed(seed,
      .simulate_call_specification(specification, as.integer(n), id = id))
    return(.new_simulab_sim(data, "study", seed,
                            list(definitions = as.data.frame(specification))))
  }

  stopifnot(
    "`n` must be a single positive whole number" =
      is.numeric(n) &&
        length(n) == 1L &&
        all(n >= 1) &&
        all(n == as.integer(n)),
    "`specification` must be a `simulab_spec` object" =
      inherits(specification, "simulab_spec"),
    "`id` must be a single non-empty string" =
      is.character(id) &&
        length(id) == 1L &&
        all(nzchar(id)),
    "`seed` must be NULL or a single number" =
      is.null(seed) || (is.numeric(seed) && length(seed) == 1L),
    "`envir` must be an environment" =
      is.environment(envir)
  )

  data <- data.frame(sequence = seq_len(as.integer(n)), row.names = NULL)
  names(data) <- id
  generated <- .with_seed(
    seed,
    .generate_from_specification(data, specification, envir)
  )
  metadata <- data.frame(
    type = "study",
    observations = as.integer(n),
    seed = if (is.null(seed)) NA_integer_ else as.integer(seed),
    stringsAsFactors = FALSE,
    row.names = NULL
  )
  .new_simulab_sim(
    generated,
    type = "study",
    seed = seed,
    tables = list(
      definitions = .specification_table(specification),
      metadata = metadata
    )
  )
}

#' Add declaratively specified variables to existing data
#'
#' A parameter or formula may refer to a column `data` already has as readily as
#' to a variable defined earlier in the same specification. A variable that
#' already exists is refused rather than overwritten.
#'
#' @param data A base `data.frame`.
#' @param specification A tidy definition table created with
#'   [define_variables()], in either the distribution-call form or the
#'   `formula`/`variance` column form.
#' @param seed Optional random seed.
#' @param envir Environment used to resolve formula values.
#'
#' @return A `simulab_sim` base `data.frame` containing the original and new
#'   variables.
#'
#' @section Conditions:
#' `simulab_existing_variable` when the specification names a column `data`
#' already has.
#' @export
#'
#' @examples
#' # Distribution calls, generated into data that is already there.
#' head(augment_study(
#'   data.frame(id = 1:100, treated = rep(0:1, each = 50)),
#'   specification = define_variables(
#'     outcome = normal(mean = 3 + 2 * treated, sd = 1),
#'     visits  = poisson(lambda = 4)
#'   ),
#'   seed = 3
#' ))
#'
#' base <- simulate_study(
#'   n = 100,
#'   specification = define_variables(
#'     define_variable("baseline", formula = "0", variance = "1", distribution = "normal")
#'   ),
#'   seed = 1
#' )
#'
#' result <- augment_study(
#'   base,
#'   specification = define_variables(
#'     define_variable("outcome", formula = "2 * baseline", variance = "1",
#'                     distribution = "normal")
#'   ),
#'   seed = 2
#' )
#' head(result)
augment_study <- function(data, specification, seed = NULL,
                          envir = parent.frame()) {
  ## A call specification is generated by the distribution registry, into the
  ## data the caller supplied, so a parameter may refer to a column that was
  ## already there as readily as to one defined earlier in the same call.
  if (.is_call_specification(specification)) {
    stopifnot(
      "`data` must be a data frame, with at least one row" =
        is.data.frame(data) && nrow(data) >= 1L
    )
    source <- .as_result_data(data)
    .stop_if_variables_exist(names(source), unique(specification$variable))
    generated <- .with_seed(seed, .simulate_call_specification(
      specification, nrow(source), data = source))
    return(.new_simulab_sim(generated, "augmented_study", seed,
                            list(definitions = as.data.frame(specification))))
  }

  stopifnot(
    "`data` must be a data frame, with at least one row" =
      is.data.frame(data) &&
        nrow(data) >= 1L,
    "`specification` must be a `simulab_spec` object" =
      inherits(specification, "simulab_spec"),
    "`seed` must be NULL or a single number" =
      is.null(seed) || (is.numeric(seed) && length(seed) == 1L),
    "`envir` must be an environment" =
      is.environment(envir)
  )
  .stop_if_variables_exist(names(data), specification$variable)

  generated <- .with_seed(
    seed,
    .generate_from_specification(as.data.frame(data), specification, envir)
  )
  metadata <- data.frame(
    type = "augmented_study",
    observations = nrow(data),
    seed = if (is.null(seed)) NA_integer_ else as.integer(seed),
    stringsAsFactors = FALSE,
    row.names = NULL
  )
  .new_simulab_sim(
    generated,
    type = "augmented_study",
    seed = seed,
    tables = list(
      definitions = .specification_table(specification),
      metadata = metadata
    )
  )
}
