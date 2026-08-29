## The distribution-call surface.
##
## `define_variables(age = normal(mean = 50, sd = 10))` names the variable with
## the argument name and states its distribution as a call. Arguments are
## captured unevaluated, so a distribution head never reaches base::gamma or
## stats::t, and a parameter may be an expression over variables defined
## earlier.

## Symbols in VALUE position must be defined variables. A call head is a
## function. Without this distinction `mean = 2 * t` silently reaches stats::t
## and fails later with "non-numeric argument to binary operator".
.value_symbols <- function(expression) {
  if (is.name(expression)) return(as.character(expression))
  if (!is.call(expression)) return(character(0))
  unlist(lapply(as.list(expression)[-1L], .value_symbols))
}

.check_value_symbols <- function(expression, defined, variable) {
  unknown <- setdiff(unique(.value_symbols(expression)), defined)
  if (!length(unknown)) return(invisible(TRUE))
  stop(errorCondition(
    sprintf("`%s` refers to %s, which %s not defined yet. Variables must be defined before they are used.",
            variable, paste(sprintf("`%s`", unknown), collapse = ", "),
            if (length(unknown) == 1L) "is" else "are"),
    class = "simulab_undefined_variable", call = NULL
  ))
}

## Match a distribution call against its registered parameters using R's own
## rules, so positional, named and mixed calls behave alike. Partial matching
## is rejected: a specification is saved and re-run, and an abbreviation that
## is unique today becomes ambiguous when a parameter is added later.
.match_distribution_arguments <- function(call, entry, distribution) {
  arguments <- as.list(call)[-1L]
  supplied <- names(arguments)
  if (!is.null(supplied)) {
    named <- supplied[nzchar(supplied)]
    unknown <- setdiff(named, entry$params)
    if (length(unknown)) {
      stop(errorCondition(
        sprintf("`%s` has no parameter %s. It takes: %s.", distribution,
                paste(unknown, collapse = ", "), paste(entry$params, collapse = ", ")),
        class = "simulab_unknown_parameter", call = NULL
      ))
    }
  }
  if (length(arguments) > length(entry$params)) {
    stop(errorCondition(
      sprintf("`%s` takes %d parameter%s (%s) but %d were supplied.",
              distribution, length(entry$params),
              if (length(entry$params) == 1L) "" else "s",
              paste(entry$params, collapse = ", "), length(arguments)),
      class = "simulab_unknown_parameter", call = NULL
    ))
  }
  stub <- function() NULL
  formals(stub) <- stats::setNames(
    rep(list(quote(expr = )), length(entry$params)), entry$params)
  matched <- match.call(stub, as.call(c(list(quote(stub)), arguments)))
  as.list(matched)[-1L]
}

.registry_entry <- function(distribution) {
  entry <- .simulab_registry[[distribution]]
  if (!is.null(entry)) return(entry)
  stop(errorCondition(
    sprintf("Unknown distribution '%s'. Use list_distributions() to see the catalogue.",
            distribution),
    class = "simulab_unknown_distribution", call = NULL
  ))
}

.evaluate_parameters <- function(matched, data, variable) {
  lapply(matched, function(expression) {
    .check_value_symbols(expression, names(data), variable)
    eval(expression, envir = data)
  })
}

## Draw one variable from a distribution call, recursing through mixtures.
.draw_distribution_call <- function(call, n, data, variable) {
  if (!is.call(call)) {
    stop(errorCondition(
      sprintf("`%s` must be a distribution call, for example normal(mean = 0, sd = 1).",
              variable),
      class = "simulab_bad_distribution_call", call = NULL
    ))
  }
  distribution <- as.character(call[[1L]])
  entry <- .registry_entry(distribution)
  arguments <- as.list(call)[-1L]

  if (identical(entry$special, "mixture")) {
    labels <- names(arguments)
    if (is.null(labels)) labels <- rep("", length(arguments))
    components <- arguments[!nzchar(labels)]
    if (is.null(arguments$weights)) {
      stop(errorCondition("`mixture` requires `weights`.",
                          class = "simulab_unknown_parameter", call = NULL))
    }
    weights <- eval(arguments$weights, envir = data)
    if (length(components) != length(weights)) {
      stop(errorCondition(
        sprintf("`mixture` has %d component%s but %d weight%s.",
                length(components), if (length(components) == 1L) "" else "s",
                length(weights), if (length(weights) == 1L) "" else "s"),
        class = "simulab_mixture_mismatch", call = NULL
      ))
    }
    drawn <- lapply(components, .draw_distribution_call, n = n, data = data,
                    variable = variable)
    chosen <- sample(seq_along(components), n, replace = TRUE, prob = weights)
    return(vapply(seq_len(n), function(i) drawn[[chosen[i]]][i], numeric(1)))
  }

  if (identical(entry$special, "categorical")) {
    matched <- .match_distribution_arguments(call, entry, distribution)
    probabilities <- eval(matched$probs, envir = data)
    return(sample(seq_along(probabilities), n, replace = TRUE, prob = probabilities))
  }

  matched <- .match_distribution_arguments(call, entry, distribution)
  values <- .evaluate_parameters(matched, data, variable)
  count <- entry$count_argument %||% "n"
  ## A base-R sampler handed a parameter outside its support returns NA and
  ## warns. That warning is caught here rather than left to pass, so a
  ## specification whose parameters go out of range names the variable that did
  ## it instead of yielding a column of quiet NAs.
  result <- withCallingHandlers(
    do.call(.distribution_sampler(entry),
            stats::setNames(c(list(n), values), c(count, names(values)))),
    warning = function(w) {
      if (grepl("NaN|NA", conditionMessage(w))) invokeRestart("muffleWarning")
    }
  )
  if (length(result) != n) {
    stop(errorCondition(
      sprintf("`%s` produced %d values; expected %d.", distribution, length(result), n),
      class = "simulab_bad_sampler", call = NULL
    ))
  }
  if (anyNA(result)) {
    stop(errorCondition(
      sprintf(paste0("`%s` drew %d missing value%s from `%s`, because its ",
                     "parameters fall outside that distribution's support. ",
                     "Parameters given: %s."),
              variable, sum(is.na(result)), if (sum(is.na(result)) == 1L) "" else "s",
              distribution,
              paste(sprintf("%s = %s", names(matched),
                            vapply(matched, function(x)
                              paste(deparse(x), collapse = " "), character(1))),
                    collapse = ", ")),
      class = "simulab_invalid_parameter", call = NULL
    ))
  }
  result
}

## The inverse CDF of a distribution call, evaluated at `uniform`. This is what
## a Gaussian copula needs: correlated uniforms in, the target marginal out. A
## mixture has no closed-form inverse CDF and is refused by name.
.quantile_distribution_call <- function(uniform, call, data, variable) {
  if (!is.call(call)) {
    stop(errorCondition(
      sprintf("`%s` must be a distribution call, for example normal(mean = 0, sd = 1).",
              variable),
      class = "simulab_bad_distribution_call", call = NULL
    ))
  }
  distribution <- as.character(call[[1L]])
  entry <- .registry_entry(distribution)

  if (identical(entry$special, "categorical")) {
    matched <- .match_distribution_arguments(call, entry, distribution)
    probabilities <- eval(matched$probs, envir = data)
    return(findInterval(uniform, cumsum(probabilities)) + 1L)
  }

  quantile_function <- .distribution_quantile(entry)
  if (is.null(quantile_function)) {
    stop(errorCondition(
      sprintf(paste0("`%s` has no quantile function, so it cannot be a copula ",
                     "marginal. Use list_distributions(copula = TRUE) to see ",
                     "the distributions that can."), distribution),
      class = "simulab_no_quantile", call = NULL
    ))
  }
  matched <- .match_distribution_arguments(call, entry, distribution)
  values <- .evaluate_parameters(matched, data, variable)
  do.call(quantile_function, c(list(uniform), values))
}

`%||%` <- function(x, y) if (is.null(x)) y else x

## Turn captured distribution calls into a long specification: one row per
## parameter, so the specification stays a tidy data frame that round-trips
## through CSV.
.calls_to_specification <- function(calls) {
  labels <- names(calls)
  if (is.null(labels) || any(!nzchar(labels))) {
    stop(errorCondition(
      "Every variable must be named, for example age = normal(mean = 50, sd = 10).",
      class = "simulab_unnamed_specification", call = NULL
    ))
  }
  if (anyDuplicated(labels)) {
    stop(errorCondition("Variable names must be unique.",
                        class = "simulab_duplicate_variable", call = NULL))
  }
  rows <- Map(function(variable, call) {
    if (!is.call(call)) {
      stop(errorCondition(
        sprintf("`%s` must be a distribution call, for example normal(mean = 0, sd = 1).",
                variable),
        class = "simulab_bad_distribution_call", call = NULL
      ))
    }
    distribution <- as.character(call[[1L]])
    entry <- .registry_entry(distribution)
    arguments <- if (identical(entry$special, "mixture")) {
      list(specification = call)
    } else {
      .match_distribution_arguments(call, entry, distribution)
    }
    data.frame(
      variable = variable,
      distribution = distribution,
      parameter = names(arguments),
      value = vapply(arguments, function(x) paste(deparse(x), collapse = " "),
                     character(1)),
      stringsAsFactors = FALSE, row.names = NULL
    )
  }, labels, calls)
  result <- do.call(rbind, rows)
  rownames(result) <- NULL
  result
}

.call_specification_columns <- c("variable", "distribution", "parameter", "value")

.is_call_specification <- function(x) {
  is.data.frame(x) &&
    all(.call_specification_columns %in% names(x)) &&
    !"condition" %in% names(x)
}

.is_condition_call_specification <- function(x) {
  is.data.frame(x) &&
    all(c("rule", "condition", .call_specification_columns) %in% names(x))
}

## A conditional rule is `when(condition, distribution_call)`. Repeating the
## argument name gives one variable several rules, which R permits in a call
## and which reads as one rule per line.
.is_condition_call_lane <- function(captured) {
  if (!length(captured)) return(FALSE)
  all(vapply(captured, function(x)
    is.call(x) && is.name(x[[1L]]) && identical(as.character(x[[1L]]), "when"),
    logical(1)))
}

.when_arguments <- function(call, variable) {
  arguments <- as.list(call)[-1L]
  labels <- names(arguments) %||% rep("", length(arguments))
  unknown <- setdiff(labels[nzchar(labels)], c("condition", "distribution"))
  if (length(unknown) || length(arguments) != 2L) {
    stop(errorCondition(
      sprintf(paste0("`%s` must be when(condition, distribution), for example ",
                     "when(group == 1, normal(mean = 2, sd = 1))."), variable),
      class = "simulab_bad_condition_call", call = NULL
    ))
  }
  stub <- function(condition, distribution) NULL
  as.list(match.call(stub, as.call(c(list(quote(stub)), arguments))))[-1L]
}

## Turn captured `when()` rules into a long specification: one row per
## parameter, carrying the condition and the rule's position, so the rules stay
## ordered and the table round-trips through CSV.
.when_calls_to_specification <- function(calls) {
  labels <- names(calls)
  if (is.null(labels) || any(!nzchar(labels))) {
    stop(errorCondition(
      paste0("Every rule must name its variable, for example ",
             "outcome = when(group == 1, normal(mean = 2, sd = 1))."),
      class = "simulab_unnamed_specification", call = NULL
    ))
  }
  rows <- Map(function(rule, variable, call) {
    arguments <- .when_arguments(call, variable)
    parameters <- .calls_to_specification(
      stats::setNames(list(arguments$distribution), variable))
    data.frame(
      rule = rule,
      condition = paste(deparse(arguments$condition), collapse = " "),
      parameters,
      stringsAsFactors = FALSE, row.names = NULL
    )
  }, seq_along(calls), labels, calls)
  result <- do.call(rbind, rows)
  result <- result[, c("rule", "variable", "condition", "distribution",
                       "parameter", "value"), drop = FALSE]
  rownames(result) <- NULL
  result
}

## A survival process is `hazard(log_rate, shape, scale, from)`. Repeating the
## argument name gives one event several segments, which is a piecewise hazard.
.hazard_parameters <- list(params = c("log_rate", "shape", "scale", "from"))
.hazard_defaults <- list(log_rate = quote(0), shape = quote(1), scale = quote(1),
                         from = quote(0))

.is_hazard_call_lane <- function(captured) {
  if (!length(captured)) return(FALSE)
  all(vapply(captured, function(x)
    is.call(x) && is.name(x[[1L]]) && identical(as.character(x[[1L]]), "hazard"),
    logical(1)))
}

## The survival engine stores its formulas as text and its transition time as a
## number, so a hazard call needs no new engine: it deparses into the columns
## define_survival() already writes.
.hazard_calls_to_specification <- function(calls, envir) {
  labels <- names(calls)
  if (is.null(labels) || any(!nzchar(labels))) {
    stop(errorCondition(
      paste0("Every process must name its event, for example ",
             "time = hazard(log_rate = -8, shape = 0.3)."),
      class = "simulab_unnamed_specification", call = NULL
    ))
  }
  rows <- Map(function(event, call) {
    supplied <- .match_distribution_arguments(call, .hazard_parameters, "hazard")
    arguments <- utils::modifyList(.hazard_defaults, supplied)
    from <- eval(arguments$from, envir = envir)
    stopifnot(
      "`from` must be a single finite non-negative number" =
        is.numeric(from) && length(from) == 1L && is.finite(from) && from >= 0
    )
    data.frame(
      event = event,
      formula = paste(deparse(arguments$log_rate), collapse = " "),
      scale = paste(deparse(arguments$scale), collapse = " "),
      shape = paste(deparse(arguments$shape), collapse = " "),
      transition = from,
      stringsAsFactors = FALSE, row.names = NULL
    )
  }, labels, calls)
  result <- do.call(rbind, rows)
  rownames(result) <- NULL
  result
}

## Apply one conditional rule: draw the rule's distribution for the rows its
## condition selects, leaving every other row as it stands.
.apply_condition_call <- function(current, rows, envir) {
  variable <- rows$variable[1L]
  affected <- eval(str2lang(rows$condition[1L]), current, envir)
  ## A length-one condition recycles, so `when(TRUE, ...)` is the rule that
  ## applies to every row.
  if (is.logical(affected) && length(affected) == 1L && !is.na(affected)) {
    affected <- rep(affected, nrow(current))
  }
  if (!is.logical(affected) || length(affected) != nrow(current) || anyNA(affected)) {
    stop(errorCondition(
      sprintf("`%s` must be a complete logical condition over the data, one value per row.",
              rows$condition[1L]),
      class = "simulab_bad_condition", call = NULL
    ))
  }
  if (!variable %in% names(current)) current[[variable]] <- NA_real_
  if (!any(affected)) return(current)
  selected <- current[affected, , drop = FALSE]
  current[[variable]][affected] <- .draw_distribution_call(
    .specification_call(rows), nrow(selected), selected, variable)
  current
}

.apply_condition_call_specification <- function(data, specification, envir) {
  Reduce(function(current, rule) {
    .apply_condition_call(
      current, specification[specification$rule == rule, , drop = FALSE], envir)
  }, unique(specification$rule), init = data)
}

## The call of one variable, rebuilt from its rows of a call specification. A
## mixture is stored whole, under the parameter name `specification`, because
## its components are themselves calls.
.specification_call <- function(rows) {
  if (identical(rows$parameter[1L], "specification")) return(str2lang(rows$value[1L]))
  as.call(c(list(as.name(rows$distribution[1L])),
            stats::setNames(lapply(rows$value, str2lang), rows$parameter)))
}

## One call per variable, in definition order.
.specification_calls <- function(specification) {
  variables <- unique(specification$variable)
  stats::setNames(
    lapply(variables, function(variable) .specification_call(
      specification[specification$variable == variable, , drop = FALSE])),
    variables
  )
}

## Generate every variable of a call specification, in definition order, into
## `data`. Each variable is drawn against the frame the earlier ones have
## already written, so `augment_study()` passes the data it was given and a
## parameter may refer to a column that was already there.
.simulate_call_specification <- function(specification, n, id = "id", data = NULL) {
  if (is.null(data)) {
    data <- data.frame(seq_len(n))
    names(data) <- id
  }
  calls <- .specification_calls(specification)
  Reduce(function(current, variable) {
    current[[variable]] <- .draw_distribution_call(calls[[variable]], n,
                                                   current, variable)
    current
  }, names(calls), init = data)
}
