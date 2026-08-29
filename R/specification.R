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


## Lane detection runs before evaluation, so an unregistered distribution is
## reported by name rather than evaluated and reported as a missing function.
## The three lanes are told apart by shape: reserved column names select the
## column lane, the package's own constructors select the constructor lane,
## and anything else that is a call with a symbol head is a distribution call.
.specification_columns <- c("variable", "formula", "variance", "distribution", "link")
.specification_constructors <- c("define_variable", "repeat_variables", "define_variables")

.is_distribution_call_lane <- function(captured) {
  if (!length(captured)) return(FALSE)
  labels <- names(captured)
  if (!is.null(labels) && any(labels %in% .specification_columns)) return(FALSE)
  all(vapply(captured, function(x) {
    is.call(x) && is.name(x[[1L]]) &&
      !as.character(x[[1L]]) %in% .specification_constructors
  }, logical(1)))
}

#' Combine variable definitions into a specification
#'
#' @param ... One of three forms.
#'
#'   **Distribution calls.** `age = normal(mean = 50, sd = 10)` names the
#'   variable with the argument name and states its distribution as a call.
#'   Parameters may be given positionally or by name, in the order
#'   [list_distributions()] reports. A parameter may be any expression over
#'   variables defined earlier in the same call, so
#'   `outcome = normal(mean = 10 + 0.2 * age, sd = 2)` is a regression.
#'   Distribution names are never evaluated, so `gamma()`, `beta()` and `t()`
#'   do not reach the base functions of those names.
#'
#'   **Specification columns** given as named vectors (`variable`, `formula`,
#'   `variance`, `distribution`, `link`).
#'
#'   **Objects** created by [define_variable()] or [repeat_variables()].
#'
#'   The forms cannot be mixed in one call.
#'
#'   In the column form, `variable` and `formula` are required. A column given
#'   as a single value is recycled across every variable. `variance` defaults
#'   to 0, `distribution` to `"normal"`, and `link` to `"identity"`.
#'
#' @return A `simulab_spec` base `data.frame` with one row per variable and
#'   columns `variable`, `distribution`, `formula`, `variance` and `link`.
#' @export
#'
#' @examples
#' # Distribution calls. The variable name is the argument name.
#' define_variables(
#'   age     = normal(mean = 50, sd = 10),
#'   treated = binary(prob = 0.5),
#'   outcome = normal(mean = 10 + 0.2 * age + 2 * treated, sd = 2)
#' )
#'
#' # Parameters may be positional, in the order list_distributions() reports.
#' define_variables(y = normal(5, 1), count = poisson(3))
#'
#' # Specification columns. `formula` is the mean or linear predictor and may
#' # refer to variables defined earlier. `variance` is a variance, not a
#' # standard deviation.
#' define_variables(
#'   variable     = c("baseline", "treatment", "outcome"),
#'   formula      = c("0", "0.5", "0.4 * baseline + 0.8 * treatment"),
#'   variance     = c("1", "0", "1"),
#'   distribution = c("normal", "binary", "normal")
#' )
#'
#' # A column given once is recycled, so a specification that shares one
#' # distribution stays short.
#' define_variables(
#'   variable = c("x1", "x2", "x3"),
#'   formula  = "0",
#'   variance = "1"
#' )
#'
#' # Definitions built one at a time are still accepted.
#' define_variables(
#'   define_variable("age", formula = 40, variance = 100, distribution = "normal"),
#'   define_variable("treated", formula = 0.5, distribution = "binary")
#' )
define_variables <- function(...) {
  ## The distribution-call lane is detected before evaluation, because its
  ## arguments must not be evaluated: `gamma(shape = 2)` is a specification,
  ## not a call to base::gamma.
  captured <- as.list(substitute(list(...)))[-1L]
  if (.is_distribution_call_lane(captured)) {
    result <- .calls_to_specification(captured)
    class(result) <- c("simulab_spec", "data.frame")
    return(result)
  }

  definitions <- list(...)
  stopifnot(
    "`...` must contain at least one definition or one specification column" =
      length(definitions) >= 1L
  )

  from_constructor <- vapply(definitions, inherits, logical(1), what = "simulab_spec")
  if (all(from_constructor)) {
    result <- do.call(rbind, lapply(definitions, as.data.frame))
  } else if (any(from_constructor)) {
    stop(errorCondition(
      paste0("Give either specification columns or objects from ",
             "define_variable(), not both in one call."),
      class = "simulab_mixed_specification", call = NULL
    ))
  } else {
    result <- .specification_from_columns(definitions)
  }

  if (anyDuplicated(result$variable)) {
    stop(errorCondition(
      "Variable names must be unique.",
      class = "simulab_duplicate_variable", call = NULL
    ))
  }
  class(result) <- c("simulab_spec", "data.frame")
  rownames(result) <- NULL
  result
}

## Build a specification table from named column vectors.
##
## `schema` names the required columns, the default value for each optional
## column, and the coercion applied to every column. A column supplied once is
## recycled across every row, so a specification sharing one distribution
## remains a single short call. All four `define_*s()` collectors share this,
## so their column form behaves identically.
.as_text <- function(x) vapply(x, .definition_text, character(1), USE.NAMES = FALSE)
.as_flag <- function(x) {
  if (!is.logical(x)) {
    stop(errorCondition("Logical specification columns must be TRUE or FALSE.",
                        class = "simulab_column_type", call = NULL))
  }
  x
}
.as_number <- function(x) {
  if (!is.numeric(x)) {
    stop(errorCondition("Numeric specification columns must be numeric.",
                        class = "simulab_column_type", call = NULL))
  }
  x
}

.spec_from_columns <- function(columns, required, defaults,
                               coerce = list(), choices = list()) {
  known <- c(required, names(defaults))
  given <- names(columns)
  if (is.null(given) || any(!nzchar(given))) {
    stop(errorCondition(
      sprintf("Specification columns must be named. Supply %s, and optionally %s.",
              paste(sprintf("`%s`", required), collapse = " and "),
              paste(sprintf("`%s`", names(defaults)), collapse = ", ")),
      class = "simulab_unnamed_specification", call = NULL
    ))
  }
  unknown <- setdiff(given, known)
  if (length(unknown)) {
    stop(errorCondition(
      sprintf("Unknown specification columns: %s. Use %s.",
              paste(unknown, collapse = ", "), paste(known, collapse = ", ")),
      class = "simulab_unknown_column", call = NULL
    ))
  }
  absent <- setdiff(required, given)
  if (length(absent)) {
    stop(errorCondition(
      sprintf("A specification requires %s.", paste(absent, collapse = " and ")),
      class = "simulab_incomplete_specification", call = NULL
    ))
  }

  key <- required[1L]
  n <- length(columns[[key]])
  stopifnot(
    "the first required column must be a character vector with at least one element" =
      is.character(columns[[key]]) && n >= 1L &&
        all(nzchar(columns[[key]])) && !anyNA(columns[[key]])
  )

  build <- function(name) {
    value <- if (name %in% given) columns[[name]] else defaults[[name]]
    convert <- coerce[[name]]
    value <- if (is.null(convert)) .as_text(value) else convert(value)
    if (length(value) == 1L) value <- rep(value, n)
    if (length(value) != n) {
      stop(errorCondition(
        sprintf("`%s` has %d values; expected 1 or %d.", name, length(value), n),
        class = "simulab_column_length", call = NULL
      ))
    }
    allowed <- choices[[name]]
    if (!is.null(allowed)) {
      invalid <- setdiff(value, allowed)
      if (length(invalid)) {
        stop(errorCondition(
          sprintf("Unknown %s: %s. Use %s.", name,
                  paste(unique(invalid), collapse = ", "),
                  paste(allowed, collapse = ", ")),
          class = paste0("simulab_unknown_", name), call = NULL
        ))
      }
    }
    value
  }

  result <- lapply(known, build)
  names(result) <- known
  as.data.frame(result, stringsAsFactors = FALSE)
}

.specification_from_columns <- function(columns) {
  result <- .spec_from_columns(
    columns,
    required = c("variable", "formula"),
    defaults = list(variance = "0", distribution = "normal", link = "identity"),
    choices = list(distribution = .simulab_distributions,
                   link = c("identity", "log", "logit"))
  )
  result[, c("variable", "distribution", "formula", "variance", "link"), drop = FALSE]
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
