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
  values <- lapply(matched, function(expression) {
    .check_value_symbols(expression, names(data), variable)
    eval(expression, envir = data)
  })
  count <- entry$count_argument %||% "n"
  result <- do.call(entry$sampler, stats::setNames(c(list(n), values),
                                                   c(count, names(values))))
  if (length(result) != n) {
    stop(errorCondition(
      sprintf("`%s` produced %d values; expected %d.", distribution, length(result), n),
      class = "simulab_bad_sampler", call = NULL
    ))
  }
  result
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

.is_call_specification <- function(x) {
  is.data.frame(x) &&
    all(c("variable", "distribution", "parameter", "value") %in% names(x))
}

## Generate every variable of a call specification, in definition order.
.simulate_call_specification <- function(specification, n, id = "id") {
  data <- data.frame(seq_len(n))
  names(data) <- id
  for (variable in unique(specification$variable)) {
    rows <- specification[specification$variable == variable, , drop = FALSE]
    call <- if (identical(rows$parameter[1L], "specification")) {
      str2lang(rows$value[1L])
    } else {
      as.call(c(list(as.name(rows$distribution[1L])),
                stats::setNames(lapply(rows$value, str2lang), rows$parameter)))
    }
    data[[variable]] <- .draw_distribution_call(call, n, data, variable)
  }
  data
}
