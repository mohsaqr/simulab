.simulab_distributions <- c(
  "beta", "binary", "binomial", "categorical", "cluster_size", "custom",
  "deterministic", "exponential", "gamma", "mixture", "negative_binomial",
  "normal", "no_zero_poisson", "poisson", "treatment", "uniform",
  "uniform_integer"
)

.definition_text <- function(value) {
  stopifnot(
    "`value` must have at least one element" =
      length(value) >= 1L
  )

  if (inherits(value, "simulab_formula")) {
    return(value$formula[1L])
  }
  if (inherits(value, "formula")) {
    return(paste(deparse(value[[2L]]), collapse = " "))
  }
  paste(as.character(value), collapse = ";")
}

#' Define one simulated variable
#'
#' @param name Variable name.
#' @param formula Numeric value, expression string, or one-sided formula that
#'   defines the distribution mean or probability.
#' @param variance Variance, dispersion, precision, trial count, category
#'   labels, or distribution-specific secondary parameter.
#' @param distribution Distribution name.
#' @param link Link applied to `formula`.
#'
#' @return A one-row `simulab_spec` base `data.frame`.
#' @export
#'
#' @examples
#' define_variable(
#'   name = "score",
#'   formula = 50,
#'   variance = 100,
#'   distribution = "normal"
#' )
define_variable <- function(name, formula, variance = 0,
                            distribution = .simulab_distributions,
                            link = c("identity", "log", "logit")) {
  stopifnot(
    "`name` must be a single non-empty string that is not NA" =
      is.character(name) &&
        length(name) == 1L &&
        all(nzchar(name)) &&
        !is.na(name),
    "`formula` must have at least one element" =
      length(formula) >= 1L,
    "`variance` must have at least one element" =
      length(variance) >= 1L
  )
  distribution <- match.arg(distribution)
  link <- match.arg(link)

  result <- data.frame(
    variable = name,
    distribution = distribution,
    formula = .definition_text(formula),
    variance = .definition_text(variance),
    link = link,
    stringsAsFactors = FALSE,
    row.names = NULL
  )
  class(result) <- c("simulab_spec", "data.frame")
  result
}

#' Combine variable definitions
#'
#' @param ... Objects created by `define_variable()` or `repeat_variables()`.
#'
#' @return A `simulab_spec` base `data.frame` with one row per variable.
#' @export
#'
#' @examples
#' define_variables(
#'   define_variable("age", 40, 100, "normal"),
#'   define_variable("treated", 0.5, distribution = "binary")
#' )
define_variables <- function(...) {
  definitions <- list(...)
  stopifnot(
    "`definitions` must be a list of `simulab_spec` objects, with at least one element" =
      length(definitions) >= 1L &&
        all(vapply(definitions, inherits, logical(1), what = "simulab_spec"))
  )

  result <- do.call(rbind, lapply(definitions, as.data.frame))
  if (anyDuplicated(result$variable)) {
    stop("Variable names must be unique.", call. = FALSE)
  }
  class(result) <- c("simulab_spec", "data.frame")
  rownames(result) <- NULL
  result
}

#' Define repeated variables
#'
#' @param n Number of variables.
#' @param prefix Variable-name prefix.
#' @param formula,variance,distribution,link Arguments passed to
#'   `define_variable()`.
#'
#' @return A `simulab_spec` base `data.frame` with one row per repeated
#'   variable.
#' @export
#'
#' @examples
#' specification <- repeat_variables(
#'   n = 3, prefix = "item", formula = "0", variance = "1", distribution = "normal"
#' )
#' specification
#' head(simulate_study(n = 20, specification = specification, seed = 1))
repeat_variables <- function(n, prefix, formula, variance = 0,
                             distribution = .simulab_distributions,
                             link = c("identity", "log", "logit")) {
  stopifnot(
    "`n` must be a single positive whole number" =
      is.numeric(n) &&
        length(n) == 1L &&
        all(n >= 1) &&
        all(n == as.integer(n)),
    "`prefix` must be a single non-empty string" =
      is.character(prefix) &&
        length(prefix) == 1L &&
        all(nzchar(prefix))
  )
  distribution <- match.arg(distribution)
  link <- match.arg(link)

  definitions <- lapply(seq_len(as.integer(n)), function(index) {
    define_variable(
      name = sprintf("%s%d", prefix, index),
      formula = formula,
      variance = variance,
      distribution = distribution,
      link = link
    )
  })
  do.call(define_variables, definitions)
}

#' Update one variable definition
#'
#' @param specification A `simulab_spec` object.
#' @param variable Variable to update.
#' @param formula,variance,distribution,link Replacement values. `NULL` keeps
#'   the existing value.
#'
#' @return An updated `simulab_spec` base `data.frame`.
#' @export
#'
#' @examples
#' specification <- define_variables(
#'   define_variable("a", formula = "0", variance = "1", distribution = "normal")
#' )
#' update_definition(specification, variable = "a", formula = "5")
update_definition <- function(specification, variable, formula = NULL,
                              variance = NULL, distribution = NULL,
                              link = NULL) {
  stopifnot(
    "`specification` must be a `simulab_spec` object" =
      inherits(specification, "simulab_spec"),
    "`variable` must be a single string" =
      is.character(variable) &&
        length(variable) == 1L
  )

  location <- match(variable, specification$variable)
  if (is.na(location)) {
    stop(sprintf("Variable '%s' is not defined.", variable), call. = FALSE)
  }

  result <- specification
  if (!is.null(formula)) result$formula[location] <- .definition_text(formula)
  if (!is.null(variance)) result$variance[location] <- .definition_text(variance)
  if (!is.null(distribution)) {
    result$distribution[location] <- match.arg(distribution, .simulab_distributions)
  }
  if (!is.null(link)) {
    result$link[location] <- match.arg(link, c("identity", "log", "logit"))
  }
  class(result) <- c("simulab_spec", "data.frame")
  result
}

#' Read variable definitions from a CSV file
#'
#' @param file Path to a CSV file containing `variable`, `distribution`,
#'   `formula`, `variance`, and `link` columns.
#'
#' @return A `simulab_spec` base `data.frame`.
#' @export
#'
#' @examples
#' file <- tempfile(fileext = ".csv")
#' utils::write.csv(
#'   data.frame(
#'     variable = c("baseline", "outcome"),
#'     distribution = c("normal", "normal"),
#'     formula = c("0", "0.5 * baseline"),
#'     variance = c("1", "1"),
#'     link = c("identity", "identity")
#'   ),
#'   file, row.names = FALSE
#' )
#'
#' specification <- read_definitions(file)
#' specification
#' head(simulate_study(n = 50, specification = specification, seed = 1))
#' unlink(file)
read_definitions <- function(file) {
  stopifnot(
    "`file` must be a single string pointing at an existing file" =
      is.character(file) &&
        length(file) == 1L &&
        file.exists(file)
  )

  result <- utils::read.csv(file, stringsAsFactors = FALSE, check.names = FALSE)
  required <- c("variable", "distribution", "formula", "variance", "link")
  if (!all(required %in% names(result))) {
    stop(errorCondition(
      sprintf("Definition file must contain: %s.", paste(required, collapse = ", ")),
      class = "simulab_bad_definition_file", call = NULL
    ))
  }
  result <- result[, required, drop = FALSE]
  ## read.csv() types a column of numeric literals as integer or double, but a
  ## specification column is always source text. Without this coercion a file
  ## whose formulas are all constants round-trips into a spec that
  ## simulate_study() rejects.
  result[] <- lapply(result, as.character)
  if (anyNA(result) || !all(nzchar(trimws(result$variable)))) {
    stop(errorCondition(
      "Definition files must not contain empty or missing entries.",
      class = "simulab_bad_definition_file", call = NULL
    ))
  }
  if (anyDuplicated(result$variable)) {
    stop(errorCondition(
      "Variable names must be unique.",
      class = "simulab_duplicate_variable", call = NULL
    ))
  }
  invalid <- setdiff(result$distribution, .simulab_distributions)
  if (length(invalid)) {
    stop(errorCondition(
      sprintf("Unknown distributions: %s.", paste(invalid, collapse = ", ")),
      class = "simulab_unknown_distribution", call = NULL
    ))
  }
  invalid_link <- setdiff(result$link, c("identity", "log", "logit"))
  if (length(invalid_link)) {
    stop(errorCondition(
      sprintf("Unknown links: %s. Use identity, log, or logit.",
              paste(invalid_link, collapse = ", ")),
      class = "simulab_unknown_link", call = NULL
    ))
  }
  class(result) <- c("simulab_spec", "data.frame")
  rownames(result) <- NULL
  result
}
