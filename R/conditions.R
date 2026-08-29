#' Define a conditional data-generation rule
#'
#' @param variable Variable to create or replace.
#' @param condition Logical expression identifying affected rows.
#' @param formula,variance,distribution,link Generation arguments used for
#'   affected rows.
#'
#' @return A one-row `simulab_condition_spec` base `data.frame`.
#' @export
#'
#' @examples
#' define_condition(
#'   "outcome", condition = "group == 1",
#'   formula = "2", variance = "1", distribution = "normal"
#' )
define_condition <- function(variable, condition, formula, variance = 0,
                             distribution = .simulab_distributions,
                             link = c("identity", "log", "logit")) {
  stopifnot(
    "`variable` must be a single non-empty string" =
      is.character(variable) &&
        length(variable) == 1L &&
        all(nzchar(variable)),
    "`condition` must have at least one element" =
      length(condition) >= 1L,
    "`formula` must have at least one element" =
      length(formula) >= 1L,
    "`variance` must have at least one element" =
      length(variance) >= 1L
  )
  distribution <- match.arg(distribution)
  link <- match.arg(link)
  result <- data.frame(
    variable = variable,
    condition = .definition_text(condition),
    distribution = distribution,
    formula = .definition_text(formula),
    variance = .definition_text(variance),
    link = link,
    stringsAsFactors = FALSE,
    row.names = NULL
  )
  class(result) <- c("simulab_condition_spec", "data.frame")
  result
}

#' Combine conditional data-generation rules into a specification
#'
#' @param ... Either the columns of a specification given as named vectors
#'   (`variable`, `condition`, `formula`, `variance`, `distribution`, `link`),
#'   or objects created by [define_condition()]. The two forms cannot be mixed
#'   in one call.
#'
#'   In the column form, `variable`, `condition` and `formula` are required. A
#'   column given as a single value is recycled across every rule. `variance`
#'   defaults to 0, `distribution` to `"normal"`, and `link` to `"identity"`.
#'
#' @return A `simulab_condition_spec` base `data.frame` with one row per rule.
#' @export
#'
#' @examples
#' # One call, named arguments, one row per rule.
#' define_conditions(
#'   variable  = c("outcome", "outcome"),
#'   condition = c("group == 1", "group == 0"),
#'   formula   = c("2", "0"),
#'   variance  = "1"
#' )
#'
#' # Definitions built one at a time are still accepted.
#' define_conditions(
#'   define_condition("outcome", condition = "group == 1",
#'                    formula = "2", variance = "1", distribution = "normal"),
#'   define_condition("outcome", condition = "group == 0",
#'                    formula = "0", variance = "1", distribution = "normal")
#' )
define_conditions <- function(...) {
  definitions <- list(...)
  stopifnot(
    "`...` must contain at least one definition or one specification column" =
      length(definitions) >= 1L
  )

  from_constructor <- vapply(definitions, inherits, logical(1),
                             what = "simulab_condition_spec")
  if (all(from_constructor)) {
    result <- do.call(rbind, lapply(definitions, as.data.frame))
  } else if (any(from_constructor)) {
    stop(errorCondition(
      paste0("Give either specification columns or objects from ",
             "define_condition(), not both in one call."),
      class = "simulab_mixed_specification", call = NULL
    ))
  } else {
    result <- .spec_from_columns(
      definitions,
      required = c("variable", "condition", "formula"),
      defaults = list(variance = "0", distribution = "normal", link = "identity"),
      choices = list(distribution = .simulab_distributions,
                     link = c("identity", "log", "logit"))
    )
    result <- result[, c("variable", "condition", "distribution",
                         "formula", "variance", "link"), drop = FALSE]
  }

  class(result) <- c("simulab_condition_spec", "data.frame")
  rownames(result) <- NULL
  result
}

#' Apply conditional generation rules
#'
#' Rules are evaluated in order, so later rules may intentionally replace
#' values written by earlier rules.
#'
#' @param data Input base `data.frame`.
#' @param specification Rules from `define_conditions()`.
#' @param seed Optional random seed.
#' @param envir Formula evaluation environment.
#'
#' @return A `simulab_sim` base `data.frame` with conditional variables added.
#' @export
#'
#' @examples
#' data <- data.frame(id = 1:100, group = rep(0:1, each = 50))
#' specification <- define_conditions(
#'   define_condition("outcome", condition = "group == 1",
#'                    formula = "2", variance = "1", distribution = "normal"),
#'   define_condition("outcome", condition = "group == 0",
#'                    formula = "0", variance = "1", distribution = "normal")
#' )
#' result <- apply_conditions(data, specification = specification, seed = 1)
#' head(result)
apply_conditions <- function(data, specification, seed = NULL,
                             envir = parent.frame()) {
  stopifnot(
    "`data` must be a data frame, with at least one row" =
      is.data.frame(data) &&
        nrow(data) >= 1L,
    "`specification` must be a `simulab_condition_spec` object" =
      inherits(specification, "simulab_condition_spec"),
    "`seed` must be NULL or a single number" =
      is.null(seed) || (is.numeric(seed) && length(seed) == 1L),
    "`envir` must be an environment" =
      is.environment(envir)
  )
  source <- .as_result_data(data)
  generated <- .with_seed(seed, Reduce(function(current, index) {
    rule <- specification[index, , drop = FALSE]
    affected <- .eval_definition(rule$condition, current, nrow(current), envir)
    if (!is.logical(affected) || anyNA(affected)) {
      stop("Conditional expressions must return complete logical values.", call. = FALSE)
    }
    variable <- rule$variable
    if (!variable %in% names(current)) current[[variable]] <- NA
    if (any(affected)) {
      subset_data <- current[affected, , drop = FALSE]
      definition <- data.frame(
        variable = variable,
        distribution = rule$distribution,
        formula = rule$formula,
        variance = rule$variance,
        link = rule$link,
        stringsAsFactors = FALSE,
        row.names = NULL
      )
      current[[variable]][affected] <- .draw_variable(definition, subset_data, envir)
    }
    current
  }, seq_len(nrow(specification)), init = source))
  definitions <- as.data.frame(specification)
  class(definitions) <- "data.frame"
  .new_simulab_sim(generated, type = "conditional", seed = seed,
                   tables = list(conditions = definitions))
}
