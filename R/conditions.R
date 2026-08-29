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
#' @param ... One of three forms.
#'
#'   **Rules.** `outcome = when(group == 1, normal(mean = 5, sd = 1))` names the
#'   variable with the argument name, states the condition that selects the rows
#'   the rule writes, and states their distribution as a call. Any distribution
#'   in [list_distributions()] may be used, and its parameters may be
#'   expressions over the data. Repeating the argument name gives one variable
#'   several rules, which is how a variable takes a different distribution in
#'   each group. `when(TRUE, ...)` applies to every row.
#'
#'   **Specification columns** given as named vectors (`variable`, `condition`,
#'   `formula`, `variance`, `distribution`, `link`).
#'
#'   **Objects** created by [define_condition()].
#'
#'   The forms cannot be mixed in one call.
#'
#'   In the column form, `variable`, `condition` and `formula` are required. A
#'   column given as a single value is recycled across every rule. `variance`
#'   defaults to 0, `distribution` to `"normal"`, and `link` to `"identity"`.
#'
#' @return A `simulab_condition_spec` base `data.frame`. Rules written with
#'   `when()` give one row per parameter, with columns `rule`, `variable`,
#'   `condition`, `distribution`, `parameter` and `value`; the other two forms
#'   give one row per rule with the `formula`/`variance` columns.
#' @export
#'
#' @examples
#' # Rules. One line per rule; a repeated name gives a variable several rules.
#' define_conditions(
#'   outcome = when(group == 1, normal(mean = 5, sd = 1)),
#'   outcome = when(group == 0, poisson(lambda = 2)),
#'   bonus   = when(group == 1, gamma(shape = 2, rate = 0.5))
#' )
#'
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
  ## The rule lane is detected before evaluation: `when()` and the distribution
  ## inside it are specification syntax, not functions to call.
  captured <- as.list(substitute(list(...)))[-1L]
  if (.is_condition_call_lane(captured)) {
    result <- .when_calls_to_specification(captured)
    class(result) <- c("simulab_condition_spec", "data.frame")
    return(result)
  }

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
#' values written by earlier rules. A row no rule selects is left missing.
#'
#' @param data Input base `data.frame`.
#' @param specification Rules from [define_conditions()], in either the rule
#'   form written with `when()` or the `formula`/`variance` column form.
#' @param seed Optional random seed.
#' @param envir Formula evaluation environment.
#'
#' @return A `simulab_sim` base `data.frame` with conditional variables added.
#' @export
#'
#' @examples
#' data <- data.frame(id = 1:100, group = rep(0:1, each = 50))
#'
#' # Rules written with when() may use any distribution in the catalogue.
#' result <- apply_conditions(
#'   data,
#'   specification = define_conditions(
#'     outcome = when(group == 1, normal(mean = 5, sd = 1)),
#'     outcome = when(group == 0, poisson(lambda = 2))
#'   ),
#'   seed = 1
#' )
#' head(result)
#'
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

  ## Rules written with when() carry one row per parameter and are drawn by the
  ## distribution registry, so every catalogued distribution is available to a
  ## conditional rule, not only the formula/variance families.
  if (.is_condition_call_specification(specification)) {
    generated <- .with_seed(seed, .apply_condition_call_specification(
      source, specification, envir))
    return(.new_simulab_sim(generated, type = "conditional", seed = seed,
                            tables = list(conditions = as.data.frame(specification))))
  }

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
