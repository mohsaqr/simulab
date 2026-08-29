#' Define missingness for one variable
#'
#' @param variable Variable that may be missing.
#' @param formula Probability or log-odds formula.
#' @param link Identity or logit link.
#' @param baseline Apply one baseline missingness draw to every period for a
#'   unit.
#' @param monotone Once missing, remain missing at later periods.
#'
#' @return A one-row `simulab_missing_spec` base `data.frame`.
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
#'   variable.
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
#' @param data Complete base `data.frame`.
#' @param specification Definitions from `define_missingnesses()`.
#' @param id Optional unit identifier for longitudinal rules.
#' @param period Optional period variable for longitudinal rules.
#' @param seed Optional random seed.
#' @param envir Formula evaluation environment.
#'
#' @return A base `data.frame` containing identifier columns followed by one
#'   logical missingness indicator per data variable.
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
#' @param data Complete base `data.frame`.
#' @param missingness A logical mask returned by `missingness_matrix()`.
#' @param id Identifier columns present in both inputs and never made missing.
#'
#' @return A `simulab_sim` base `data.frame` containing observed data.
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
#' @param data Complete base `data.frame`.
#' @param mechanism Missingness mechanism.
#' @param proportion Target missing fraction.
#' @param variables Variables to make missing. `NULL` selects every variable.
#' @param predictor Observed predictor for MAR missingness.
#' @param seed Optional random seed.
#'
#' @return A `simulab_sim` base `data.frame`. The cell-level missingness mask is
#'   available with `as.data.frame(x, what = "missingness")`.
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

