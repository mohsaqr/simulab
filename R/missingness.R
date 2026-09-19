#' Define missingness for one variable
#'
#' Records the rule that decides whether one variable is missing for a row. The
#' rule is a formula evaluated row by row against the data, so missingness may
#' depend on any column: on a fully observed covariate, which is MAR, or on the
#' variable's own value, which is MNAR.
#'
#' @param variable Variable that may be missing. A single non-empty string.
#' @param formula Missingness formula, given as a number, a string, or an
#'   unquoted expression over the data columns. It is read as a probability
#'   under the identity link and as log odds under the logit link. It is stored
#'   as text and evaluated row by row.
#' @param link Scale the formula is stated on, one of `"identity"` (the default)
#'   or `"logit"`.
#' @param baseline Replace every period's draw for a unit with its first
#'   period's draw, so the unit is either always or never missing. A single
#'   flag, defaulting to `FALSE`. It needs `id` and `period` in
#'   [missingness_matrix()].
#' @param monotone Once missing, remain missing at every later period. A single
#'   flag, defaulting to `FALSE`. It needs `id` and `period` in
#'   [missingness_matrix()].
#'
#' @return A one-row `simulab_missing_spec` base `data.frame` with the character
#'   columns `variable`, `formula` and `link` and the logical columns `baseline`
#'   and `monotone`.
#' @export
#'
#' @examples
#' define_missingness("outcome", formula = "0.2")
define_missingness <- function(variable, formula,
                               link = c("identity", "logit"),
                               baseline = FALSE, monotone = FALSE) {
  stopifnot(
    "`variable` must be a single non-empty string" =
      is.character(variable) &&
        length(variable) == 1L &&
        all(nzchar(variable)),
    "`formula` must have at least one element" =
      length(formula) >= 1L,
    "`baseline` must be a single flag" =
      is.logical(baseline) &&
        length(baseline) == 1L,
    "`monotone` must be a single flag" =
      is.logical(monotone) &&
        length(monotone) == 1L
  )
  link <- match.arg(link)
  result <- data.frame(
    variable = variable,
    formula = .definition_text(formula),
    link = link,
    baseline = baseline,
    monotone = monotone,
    stringsAsFactors = FALSE,
    row.names = NULL
  )
  class(result) <- c("simulab_missing_spec", "data.frame")
  result
}

#' Combine missingness definitions into a specification
#'
#' @param ... Either the columns of a specification given as named vectors
#'   (`variable`, `formula`, `link`, `baseline`, `monotone`), or objects
#'   created by [define_missingness()]. The two forms cannot be mixed in one
#'   call.
#'
#'   In the column form, `variable` and `formula` are required. A column given
#'   as a single value is recycled across every variable. `link` defaults to
#'   `"identity"`, and `baseline` and `monotone` to `FALSE`.
#'
#' @return A `simulab_missing_spec` base `data.frame` with one row per target
#'   variable, in the order given, and the columns of [define_missingness()]:
#'   `variable`, `formula`, `link`, `baseline` and `monotone`. Target variables
#'   must be unique.
#' @export
#'
#' @examples
#' # One call, named arguments, one row per target variable.
#' define_missingnesses(
#'   variable = c("outcome", "baseline"),
#'   formula  = c("0.2", "0.1")
#' )
#'
#' # `monotone` keeps a unit missing at every later period once it drops out.
#' define_missingnesses(
#'   variable = c("outcome", "baseline"),
#'   formula  = c("0.2", "0.1"),
#'   monotone = TRUE
#' )
#'
#' # Definitions built one at a time are still accepted.
#' define_missingnesses(
#'   define_missingness("outcome", formula = "0.2"),
#'   define_missingness("baseline", formula = "0.1")
#' )
define_missingnesses <- function(...) {
  definitions <- list(...)
  stopifnot(
    "`...` must contain at least one definition or one specification column" =
      length(definitions) >= 1L
  )

  from_constructor <- vapply(definitions, inherits, logical(1),
                             what = "simulab_missing_spec")
  if (all(from_constructor)) {
    result <- do.call(rbind, lapply(definitions, as.data.frame))
  } else if (any(from_constructor)) {
    stop(errorCondition(
      paste0("Give either specification columns or objects from ",
             "define_missingness(), not both in one call."),
      class = "simulab_mixed_specification", call = NULL
    ))
  } else {
    result <- .spec_from_columns(
      definitions,
      required = c("variable", "formula"),
      defaults = list(link = "identity", baseline = FALSE, monotone = FALSE),
      coerce = list(baseline = .as_flag, monotone = .as_flag),
      choices = list(link = c("identity", "logit"))
    )
  }

  if (anyDuplicated(result$variable)) {
    stop(errorCondition(
      "Missingness target variables must be unique.",
      class = "simulab_duplicate_variable", call = NULL
    ))
  }
  class(result) <- c("simulab_missing_spec", "data.frame")
  rownames(result) <- NULL
  result
}

.missing_weight <- function(value) {
  stopifnot(
    "`value` must be an atomic vector" =
      is.atomic(value)
  )
  numeric_value <- if (is.numeric(value)) value else as.numeric(factor(value))
  observed <- !is.na(numeric_value)
  if (!any(observed) || length(unique(numeric_value[observed])) == 1L) {
    return(rep(0.5, length(value)))
  }
  ranked <- rank(numeric_value, na.last = "keep", ties.method = "average")
  result <- (ranked - 0.5) / sum(!is.na(ranked))
  result[is.na(result)] <- 0.5
  result
}

.calibrated_missing_probability <- function(weights, proportion) {
  stopifnot(
    "`weights` must be a finite non-negative numeric vector" =
      is.numeric(weights) &&
        all(is.finite(weights)) &&
        all(weights >= 0),
    "`proportion` must be a single number between 0 and 1" =
      is.numeric(proportion) &&
        length(proportion) == 1L &&
        all(proportion >= 0) &&
        all(proportion <= 1)
  )
  if (proportion == 0) return(rep(0, length(weights)))
  if (proportion == 1) return(rep(1, length(weights)))
  if (mean(weights) == 0) return(rep(proportion, length(weights)))
  objective <- function(multiplier) mean(pmin(multiplier * weights, 1)) - proportion
  multiplier <- .solve_root(
    objective, c(0, 1e12),
    what = "the multiplier matching the target missingness proportion"
  )
  pmin(multiplier * weights, 1)
}

.apply_longitudinal_missing_rule <- function(flag, data, id, period,
                                             baseline, monotone) {
  stopifnot(
    "`data` must be a data frame" =
      is.data.frame(data),
    "`flag` must be a logical vector" =
      is.logical(flag),
    "`id` must be a single string naming a column of `data`" =
      is.character(id) &&
        length(id) == 1L &&
        all(id %in% names(data)),
    "`period` must be a single string naming a column of `data`" =
      is.character(period) &&
        length(period) == 1L &&
        all(period %in% names(data)),
    "`baseline` must be a single flag" =
      is.logical(baseline) &&
        length(baseline) == 1L,
    "`monotone` must be a single flag" =
      is.logical(monotone) &&
        length(monotone) == 1L
  )
  groups <- split(seq_len(nrow(data)), data[[id]])
  adjusted <- lapply(groups, function(indices) {
    ordered <- indices[order(data[[period]][indices])]
    values <- flag[ordered]
    if (baseline) values <- rep(values[1L], length(values))
    if (monotone && any(values)) values[seq.int(which(values)[1L], length(values))] <- TRUE
    data.frame(index = ordered, missing = values)
  })
  combined <- do.call(rbind, adjusted)
  result <- logical(nrow(data))
  result[combined$index] <- combined$missing
  result
}

#' Generate a missingness mask
#'
#' Draws, for every row of `data` and every variable in `specification`, whether
#' that cell is missing, by comparing a uniform draw against the row's
#' probability. The mask is returned rather than applied, so the complete data
#' and the mask that hides part of it can both be kept; [observed_data()] joins
#' them.
#'
#' @param data Complete base `data.frame`, or a `simulab_sim`, with at least one
#'   row. Every target variable of `specification` must be one of its columns.
#' @param specification Definitions from [define_missingnesses()], a
#'   `simulab_missing_spec` object.
#' @param id Optional unit identifier. A single string naming a column of
#'   `data`, or `NULL` (the default). It is required by the `baseline` and
#'   `monotone` rules and is carried into the mask.
#' @param period Optional period variable that orders a unit's rows. A single
#'   string naming a column of `data`, or `NULL` (the default). It is required
#'   by the `baseline` and `monotone` rules and is carried into the mask.
#' @param seed Optional random seed. A single number, or `NULL` (the default).
#' @param envir Environment the formulas are evaluated in after the data
#'   columns. Defaults to the caller's environment.
#'
#' @return A base `data.frame` with one row per row of `data`, holding the `id`
#'   and `period` columns when they are given, or a single `row` column
#'   numbering the rows when neither is, followed by one logical column per
#'   target variable of `specification`, named after that variable. Variables of
#'   `data` that `specification` says nothing about get no column.
#' @export
#'
#' @examples
#' data <- data.frame(id = 1:100, baseline = stats::rnorm(100), outcome = stats::rnorm(100))
#' specification <- define_missingnesses(
#'   define_missingness("outcome", formula = "0.2")
#' )
#'
#' mask <- missingness_matrix(data, specification = specification, seed = 1)
#' head(mask)
missingness_matrix <- function(data, specification, id = NULL, period = NULL,
                               seed = NULL, envir = parent.frame()) {
  stopifnot(
    "`data` must be a data frame, with at least one row" =
      is.data.frame(data) &&
        nrow(data) >= 1L,
    "`specification` must be a `simulab_missing_spec` object" =
      inherits(specification, "simulab_missing_spec"),
    "`id` must be NULL or a single string naming a column of `data`" =
      is.null(id) || (is.character(id) && length(id) == 1L && id %in% names(data)),
    "`period` must be NULL or a single string naming a column of `data`" =
      is.null(period) || (is.character(period) && length(period) == 1L && period %in% names(data)),
    "`seed` must be NULL or a single number" =
      is.null(seed) || (is.numeric(seed) && length(seed) == 1L),
    "`envir` must be an environment" =
      is.environment(envir)
  )
  source <- .as_result_data(data)
  if (!all(specification$variable %in% names(source))) {
    stop("Every missingness target must exist in data.", call. = FALSE)
  }
  if (any(specification$baseline | specification$monotone) &&
      (is.null(id) || is.null(period))) {
    stop("id and period are required for baseline or monotone missingness.", call. = FALSE)
  }
  draws <- .with_seed(seed, lapply(seq_len(nrow(specification)), function(index) {
    definition <- specification[index, , drop = FALSE]
    probability <- .eval_definition(definition$formula, source, nrow(source), envir)
    if (identical(definition$link, "logit")) probability <- stats::plogis(probability)
    .check_probability(probability, sprintf("Missingness probability for %s", definition$variable))
    flag <- stats::runif(nrow(source)) < probability
    if (definition$baseline || definition$monotone) {
      flag <- .apply_longitudinal_missing_rule(
        flag,
        source,
        id,
        period,
        definition$baseline,
        definition$monotone
      )
    }
    data.frame(variable = definition$variable, probability = probability,
               missing = flag, stringsAsFactors = FALSE)
  }))
  identifiers <- unique(c(id, period))
  result <- if (length(identifiers)) source[, identifiers, drop = FALSE] else data.frame(row = seq_len(nrow(source)))
  indicator_columns <- lapply(draws, function(draw) draw$missing)
  names(indicator_columns) <- specification$variable
  result <- data.frame(result, indicator_columns, check.names = FALSE, row.names = NULL)
  result
}

#' Apply a missingness mask to complete data
#'
#' Sets every cell the mask flags to `NA`, leaving the complete data otherwise
#' untouched, and keeps the mask alongside the result as a tidy component.
#'
#' @param data Complete base `data.frame`, or a `simulab_sim`, with as many rows
#'   as `missingness` and in the same row order.
#' @param missingness A logical mask returned by [missingness_matrix()], with
#'   one row per row of `data`. Its columns that also name columns of `data`,
#'   other than those listed in `id`, are the targets, and each must be logical.
#' @param id Identifier columns the mask carries that are never made missing. A
#'   character vector, or `NULL` (the default). Name the identifier columns of
#'   the mask here, or they are treated as targets and rejected for not being
#'   logical.
#'
#' @return A `simulab_sim` base `data.frame` with the columns and rows of
#'   `data`, the flagged cells of the target variables replaced by `NA`. The
#'   component `missingness`, reached with
#'   `as.data.frame(x, what = "missingness")`, is the mask in long form, one row
#'   per observation and target variable, with columns `observation`, `variable`
#'   and the logical `missing`.
#' @export
#'
#' @examples
#' data <- data.frame(id = 1:100, outcome = stats::rnorm(100))
#' mask <- missingness_matrix(
#'   data,
#'   specification = define_missingnesses(define_missingness("outcome", formula = "0.3")),
#'   seed = 1
#' )
#'
#' result <- observed_data(data, missingness = mask, id = "id")
#' head(result)
observed_data <- function(data, missingness, id = NULL) {
  stopifnot(
    "`missingness` must be a data frame" =
      is.data.frame(missingness),
    "`data` must be a data frame" =
      is.data.frame(data) &&
        nrow(data) == nrow(missingness),
    "`id` must be NULL or a character vector" =
      is.null(id) || is.character(id)
  )
  source <- .as_result_data(data)
  targets <- intersect(setdiff(names(missingness), id), names(source))
  if (!length(targets)) stop("The missingness mask contains no target variables.", call. = FALSE)
  if (!all(vapply(missingness[, targets, drop = FALSE], is.logical, logical(1)))) {
    stop("Missingness target columns must be logical.", call. = FALSE)
  }
  source[targets] <- Map(function(value, flag) {
    value[flag] <- NA
    value
  }, source[targets], missingness[targets])
  long_mask <- do.call(rbind, Map(function(variable, flag) {
    data.frame(
      observation = seq_len(nrow(source)),
      variable = variable,
      missing = flag,
      stringsAsFactors = FALSE,
      row.names = NULL
    )
  }, targets, missingness[targets]))
  rownames(long_mask) <- NULL
  .new_simulab_sim(source, type = "observed_data",
                   tables = list(missingness = long_mask))
}

#' Inject MCAR, MAR, or MNAR missingness
#'
#' Blanks cells of `data` under one of the three standard mechanisms. `"MCAR"`
#' gives every row the same probability `proportion`, so missingness depends on
#' nothing. `"MAR"` makes it depend on the fully observed `predictor`, which is
#' itself never made missing. `"MNAR"` makes each target variable's missingness
#' depend on its own value, so the values that disappear are not a random sample
#' of them. For MAR and MNAR the probability increases with the driving
#' variable's rank: its ties-averaged rank mapped into `(0, 1)`, or `0.5` for a
#' missing or constant driver, scaled by the multiplier that makes the mean
#' probability equal `proportion`, and capped at 1. Each MAR target therefore
#' shares one probability vector, while each MNAR target gets its own.
#'
#' @param data Complete base `data.frame`, or a `simulab_sim`, with at least one
#'   row.
#' @param mechanism Missingness mechanism, one of `"MCAR"` (the default),
#'   `"MAR"` or `"MNAR"`.
#' @param proportion Target missing fraction, the mean cell probability rather
#'   than a realized count. A single number between 0 and 1, defaulting to
#'   `0.1`; the realized fraction is random around it and is reported in the
#'   `missingness_summary` component.
#' @param variables Variables to make missing. A character vector of column
#'   names, or `NULL` (the default), which selects every column of `data`,
#'   identifiers included. Under `"MAR"` the `predictor` is removed from this
#'   set.
#' @param predictor Fully observed predictor that drives MAR missingness. A
#'   single string naming a column of `data`, required when `mechanism` is
#'   `"MAR"` and ignored otherwise. Defaults to `NULL`.
#' @param seed Optional random seed. A single number, or `NULL` (the default).
#'
#' @return A `simulab_sim` base `data.frame` with the columns and rows of
#'   `data`, the drawn cells of the target variables replaced by `NA`.
#'   Components: `missingness`, the cell-level mask reached with
#'   `as.data.frame(x, what = "missingness")`, one row per observation and
#'   target variable with columns `observation`, `variable`, `probability`,
#'   the logical `missing` and `mechanism`; and `missingness_summary`, one row
#'   per target variable with columns `variable`, `realized_proportion` and
#'   `target_proportion`.
#' @export
#'
#' @examples
#' data <- data.frame(id = 1:200, x = stats::rnorm(200), y = stats::rnorm(200))
#'
#' result <- inject_missingness(
#'   data, mechanism = "MCAR", proportion = 0.2, variables = "y", seed = 1
#' )
#' head(result)
#'
#' # MAR missingness in `y` driven by the observed predictor `x`.
#' head(inject_missingness(
#'   data, mechanism = "MAR", proportion = 0.2,
#'   variables = "y", predictor = "x", seed = 1
#' ))
inject_missingness <- function(data, mechanism = c("MCAR", "MAR", "MNAR"),
                               proportion = 0.1, variables = NULL,
                               predictor = NULL, seed = NULL) {
  stopifnot(
    "`data` must be a data frame, with at least one row" =
      is.data.frame(data) &&
        nrow(data) >= 1L,
    "`proportion` must be a single number between 0 and 1" =
      is.numeric(proportion) &&
        length(proportion) == 1L &&
        all(proportion >= 0) &&
        all(proportion <= 1),
    "`variables` must be NULL or a character vector" =
      is.null(variables) || is.character(variables),
    "`predictor` must be NULL or a single string" =
      is.null(predictor) || (is.character(predictor) && length(predictor) == 1L),
    "`seed` must be NULL or a single number" =
      is.null(seed) || (is.numeric(seed) && length(seed) == 1L)
  )
  mechanism <- match.arg(mechanism)
  source <- .as_result_data(data)
  if (is.null(variables)) variables <- names(source)
  if (!all(variables %in% names(source))) stop("Every target variable must exist in data.", call. = FALSE)
  if (identical(mechanism, "MAR")) {
    if (is.null(predictor) || !predictor %in% names(source)) {
      stop("MAR missingness requires an observed predictor variable.", call. = FALSE)
    }
    variables <- setdiff(variables, predictor)
  }
  if (!length(variables)) stop("At least one missingness target is required.", call. = FALSE)

  probabilities <- switch(
    mechanism,
    MCAR = rep(list(rep(proportion, nrow(source))), length(variables)),
    MAR = {
      probability <- .calibrated_missing_probability(.missing_weight(source[[predictor]]), proportion)
      rep(list(probability), length(variables))
    },
    MNAR = lapply(variables, function(variable) {
      .calibrated_missing_probability(.missing_weight(source[[variable]]), proportion)
    })
  )
  flags <- .with_seed(seed, lapply(probabilities, function(probability) {
    stats::runif(length(probability)) < probability
  }))
  names(flags) <- variables
  source[variables] <- Map(function(value, flag) {
    value[flag] <- NA
    value
  }, source[variables], flags)
  missingness <- do.call(rbind, Map(function(variable, probability, flag) {
    data.frame(
      observation = seq_len(nrow(source)),
      variable = variable,
      probability = probability,
      missing = flag,
      mechanism = mechanism,
      stringsAsFactors = FALSE,
      row.names = NULL
    )
  }, variables, probabilities, flags))
  rownames(missingness) <- NULL
  summary_table <- aggregate(
    missingness$missing,
    by = list(variable = missingness$variable),
    FUN = mean
  )
  names(summary_table)[2L] <- "realized_proportion"
  summary_table$target_proportion <- proportion
  .new_simulab_sim(
    source,
    type = "missingness",
    seed = seed,
    tables = list(missingness = missingness, missingness_summary = summary_table)
  )
}

