#' Generate parameter combinations
#'
#' @param ... Named vectors or two-value numeric ranges.
#' @param n Number of rows for random or Latin-hypercube designs.
#' @param method Full grid, random sampling, or Latin hypercube.
#' @param seed Optional random seed.
#'
#' @return A base `data.frame` with one row per parameter combination.
#' @export
#'
#' @examples
#' # Full factorial grid over named parameters.
#' parameter_grid(sample_size = c(50, 100), effect = c(0.2, 0.5))
#'
#' # Latin-hypercube sample of `n` draws over two ranges. Grid parameters are
#' # passed through `...`, so none of them may be called `n`, `method` or `seed`.
#' parameter_grid(
#'   sample_size = c(50, 200), effect = c(0, 1),
#'   n = 5, method = "latin_hypercube", seed = 1
#' )
parameter_grid <- function(..., n = 10L,
                           method = c("grid", "random", "latin_hypercube"),
                           seed = NULL) {
  method <- match.arg(method)
  parameters <- list(...)
  stopifnot(
    "`parameters` must have at least one element and names" =
      length(parameters) >= 1L &&
        !is.null(names(parameters)) &&
        all(nzchar(names(parameters))),
    "`n` must be a single positive whole number" =
      is.numeric(n) &&
        length(n) == 1L &&
        all(n >= 1) &&
        all(n == as.integer(n)),
    "`seed` must be NULL or a single number" =
      is.null(seed) || (is.numeric(seed) && length(seed) == 1L)
  )
  if (method == "grid") {
    result <- expand.grid(parameters, KEEP.OUT.ATTRS = FALSE, stringsAsFactors = FALSE)
  } else {
    n <- as.integer(n)
    result <- .with_seed(seed, as.data.frame(Map(function(value) {
      if (is.numeric(value) && length(value) == 2L) {
        uniforms <- if (method == "latin_hypercube") {
          sample((seq_len(n) - stats::runif(n)) / n)
        } else stats::runif(n)
        value[1L] + uniforms * (value[2L] - value[1L])
      } else sample(value, n, replace = TRUE)
    }, parameters), check.names = FALSE, stringsAsFactors = FALSE))
  }
  result$scenario_id <- seq_len(nrow(result))
  result <- result[, c("scenario_id", names(parameters)), drop = FALSE]
  rownames(result) <- NULL
  result
}

#' Apply a function across simulation results
#'
#' @param inputs List of data frames or simulation results.
#' @param fun Function returning a data frame.
#' @param ... Arguments passed to `fun`.
#' @param id Name of the batch identifier.
#'
#' @return A combined base `data.frame` with one batch identifier per output.
#' @export
#'
#' @examples
#' inputs <- list(
#'   small = simulate_ttest(n_a = 20, n_b = 20, mean_a = 0, mean_b = 0.5, seed = 1),
#'   large = simulate_ttest(n_a = 60, n_b = 60, mean_a = 0, mean_b = 0.5, seed = 2)
#' )
#' apply_batch(inputs, fun = summary)
apply_batch <- function(inputs, fun, ..., id = "batch_id") {
  stopifnot(
    "`inputs` must be a list, with at least one element" =
      is.list(inputs) &&
        length(inputs) >= 1L,
    "`fun` must be a function" =
      is.function(fun),
    "`id` must be a single string" =
      is.character(id) &&
        length(id) == 1L
  )
  labels <- names(inputs)
  if (is.null(labels)) labels <- as.character(seq_along(inputs))
  outputs <- Map(function(input, label) {
    value <- fun(input, ...)
    if (!is.data.frame(value)) stop("Batch functions must return data frames.", call. = FALSE)
    data.frame(batch_value = label, value, check.names = FALSE, row.names = NULL)
  }, inputs, labels)
  column_sets <- lapply(outputs, names)
  if (!all(vapply(column_sets, identical, logical(1), column_sets[[1L]]))) {
    stop("Every batch output must have the same columns.", call. = FALSE)
  }
  result <- do.call(rbind, outputs)
  names(result)[1L] <- id
  rownames(result) <- NULL
  result
}

#' Fit TNA models to multiple datasets
#'
#' @param inputs Named list of sequence data frames.
#' @param ... Arguments passed to `fit_tna()`.
#'
#' @return A tidy edge-list `simulab_sim` with dataset/model metadata.
#' @export
#'
#' @examples
#' inputs <- list(
#'   first = simulate_sequences(n = 30, n_states = 3, chain_length = 10, seed = 1),
#'   second = simulate_sequences(n = 30, n_states = 3, chain_length = 10, seed = 2)
#' )
#' if (requireNamespace("tna", quietly = TRUE)) {
#'   head(fit_tna_batch(inputs, model = "tna"))
#' }
fit_tna_batch <- function(inputs, ...) {
  stopifnot(
    "`inputs` must be a list of data frames, with at least one element" =
      is.list(inputs) &&
        length(inputs) >= 1L &&
        all(vapply(inputs, is.data.frame, logical(1)))
  )
  labels <- names(inputs)
  if (is.null(labels)) labels <- sprintf("Dataset %d", seq_along(inputs))
  fitted <- lapply(inputs, fit_tna, ...)
  edges <- do.call(rbind, Map(function(result, label) {
    data.frame(dataset = label, .plain_data(result), check.names = FALSE, row.names = NULL)
  }, fitted, labels))
  info <- do.call(rbind, Map(function(result, label) {
    data.frame(dataset = label, as.data.frame(result, what = "model_info"),
               check.names = FALSE, row.names = NULL)
  }, fitted, labels))
  result <- .new_simulab_sim(edges, "tna_batch", tables = list(model_info = info))
  attr(result, "simulab_tna_models") <- lapply(fitted, as_tna_model)
  names(attr(result, "simulab_tna_models")) <- labels
  result
}

.sample_sequence_rows <- function(data, format, id, period, state, group,
                                  fraction, replace) {
  prepared <- .prepare_tna_sequences(data, format, id, period, state, group)
  rows <- if (is.null(group)) {
    sample.int(nrow(prepared), max(2L, ceiling(nrow(prepared) * fraction)), replace = replace)
  } else {
    groups <- split(seq_len(nrow(prepared)), prepared[[group]])
    unlist(lapply(groups, function(indices) sample(
      indices, max(2L, ceiling(length(indices) * fraction)), replace = replace
    )), use.names = FALSE)
  }
  prepared[rows, , drop = FALSE]
}

#' Bootstrap a TNA model
#'
#' @param data Sequence data.
#' @param model TNA estimator.
#' @param repetitions Number of bootstrap samples.
#' @param fraction Fraction of sequences sampled with replacement.
#' @param format,id,period,state,group Input arguments passed to `fit_tna()`.
#' @param seed Optional seed.
#' @param ... Estimator arguments.
#'
#' @return A tidy edge-by-bootstrap `simulab_sim` with percentile summaries.
#' @export
#'
#' @examples
#' data <- simulate_sequences(n = 40, n_states = 3, chain_length = 12, seed = 1)
#' if (requireNamespace("tna", quietly = TRUE)) {
#'   head(bootstrap_tna(data, model = "tna", repetitions = 5, seed = 1))
#' }
bootstrap_tna <- function(data, model = c("tna", "ftna", "ctna", "atna"),
                          repetitions = 100L, fraction = 1,
                          format = c("auto", "long", "wide"),
                          id = "id", period = "period", state = "state",
                          group = NULL, seed = NULL, ...) {
  model <- match.arg(model)
  format <- match.arg(format)
  stopifnot(
    "`data` must be a data frame" =
      is.data.frame(data),
    "`repetitions` must be a single whole number of at least 2" =
      is.numeric(repetitions) &&
        length(repetitions) == 1L &&
        all(repetitions >= 2) &&
        all(repetitions == as.integer(repetitions)),
    "`fraction` must be a single number between 0 and 1" =
      is.numeric(fraction) &&
        length(fraction) == 1L &&
        all(fraction > 0) &&
        all(fraction <= 1)
  )
  estimates <- .with_seed(seed, lapply(seq_len(as.integer(repetitions)), function(iteration) {
    sampled <- .sample_sequence_rows(data, format, id, period, state, group,
                                     fraction, replace = TRUE)
    fitted <- fit_tna(sampled, model, format = "wide", group = group, ...)
    data.frame(iteration = iteration, .plain_data(fitted),
               check.names = FALSE, row.names = NULL)
  }))
  edges <- do.call(rbind, estimates)
  edge_keys <- intersect(c("group", "from", "to"), names(edges))
  grouped <- split(edges, interaction(edges[, edge_keys, drop = FALSE], drop = TRUE))
  summary <- do.call(rbind, lapply(grouped, function(values) data.frame(
    values[1L, edge_keys, drop = FALSE],
    mean = mean(values$weight), sd = stats::sd(values$weight),
    lower = stats::quantile(values$weight, 0.025, names = FALSE),
    upper = stats::quantile(values$weight, 0.975, names = FALSE),
    row.names = NULL
  )))
  .new_simulab_sim(edges, "tna_bootstrap", seed, list(summary = summary))
}

#' Cross-validate TNA estimators
#'
#' @param data Sequence data.
#' @param models TNA estimators.
#' @param iterations Number of splits.
#' @param training_fraction Training fraction.
#' @param format,id,period,state Input-format arguments.
#' @param seed Optional seed.
#' @param ... Estimator arguments.
#'
#' @return A tidy base `data.frame` of train/test network agreement metrics.
#' @export
#'
#' @examples
#' data <- simulate_sequences(n = 60, n_states = 3, chain_length = 12, seed = 1)
#' if (requireNamespace("tna", quietly = TRUE)) {
#'   cross_validate_tna(data, models = c("tna", "ftna"), iterations = 2, seed = 1)
#' }
cross_validate_tna <- function(data, models = c("tna", "ftna", "ctna", "atna"),
                               iterations = 20L, training_fraction = 0.7,
                               format = c("auto", "long", "wide"),
                               id = "id", period = "period", state = "state",
                               seed = NULL, ...) {
  format <- match.arg(format)
  stopifnot(
    "`data` must be a data frame" =
      is.data.frame(data),
    "`models` must be a character vector, with at least one element, naming one of `tna`, `ftna`, `ctna`, `atna`" =
      is.character(models) &&
        length(models) >= 1L &&
        all(models %in% c("tna", "ftna", "ctna", "atna")),
    "`iterations` must be a positive numeric vector, of whole numbers" =
      is.numeric(iterations) &&
        all(iterations >= 1) &&
        all(iterations == as.integer(iterations)),
    "`training_fraction` must be a numeric vector of values strictly between 0 and 1" =
      is.numeric(training_fraction) &&
        all(training_fraction > 0) &&
        all(training_fraction < 1)
  )
  prepared <- .prepare_tna_sequences(data, format, id, period, state, group = NULL)
  results <- .with_seed(seed, lapply(seq_len(as.integer(iterations)), function(iteration) {
    training_rows <- sample.int(
      nrow(prepared), max(2L, floor(nrow(prepared) * training_fraction)), replace = FALSE
    )
    testing_rows <- setdiff(seq_len(nrow(prepared)), training_rows)
    if (length(testing_rows) < 2L) stop("Cross-validation test folds need two sequences.", call. = FALSE)
    do.call(rbind, lapply(models, function(model) {
      training <- fit_tna(prepared[training_rows, , drop = FALSE], model, format = "wide", ...)
      testing <- fit_tna(prepared[testing_rows, , drop = FALSE], model, format = "wide", ...)
      data.frame(iteration = iteration, model = model,
                 compare_networks(training, testing), row.names = NULL)
    }))
  }))
  result <- do.call(rbind, results)
  rownames(result) <- NULL
  result
}

#' Fit TNA to a sequence sample
#'
#' @param data Sequence data.
#' @param fraction Sampling fraction.
#' @param replace Sample with replacement.
#' @param seed Optional seed.
#' @param ... Arguments passed to `fit_tna()`.
#'
#' @return A tidy fitted TNA result.
#' @export
#'
#' @examples
#' data <- simulate_sequences(n = 40, n_states = 3, chain_length = 12, seed = 1)
#' if (requireNamespace("tna", quietly = TRUE)) {
#'   head(sample_tna(data, fraction = 0.5, seed = 1))
#' }
sample_tna <- function(data, fraction = 0.3, replace = FALSE, seed = NULL, ...) {
  stopifnot(
    "`data` must be a data frame" =
      is.data.frame(data),
    "`fraction` must be a single number between 0 and 1" =
      is.numeric(fraction) &&
        length(fraction) == 1L &&
        all(fraction > 0) &&
        all(fraction <= 1),
    "`replace` must be a single flag" =
      is.logical(replace) &&
        length(replace) == 1L
  )
  prepared <- .with_seed(seed, .sample_sequence_rows(
    data, "auto", "id", "period", "state", NULL, fraction, replace
  ))
  fit_tna(prepared, format = "wide", ...)
}

#' Summarize simulated numeric variables
#'
#' @param data Simulation data.
#' @param by Optional grouping columns.
#' @param variables Numeric variables. `NULL` selects all numeric non-grouping
#'   columns.
#'
#' @return A tidy base `data.frame` of variable/group summaries.
#' @export
#'
#' @examples
#' data <- simulate_ttest(n_a = 50, n_b = 50, mean_a = 0, mean_b = 0.6, seed = 1)
#' summarize_simulations(data, by = "group", variables = "outcome")
summarize_simulations <- function(data, by = NULL, variables = NULL) {
  stopifnot(
    "`data` must be a data frame" =
      is.data.frame(data),
    "`by` must be NULL or a character vector" =
      is.null(by) || is.character(by),
    "`variables` must be NULL or a character vector" =
      is.null(variables) || is.character(variables)
  )
  source <- .as_result_data(data)
  if (!is.null(by) && !all(by %in% names(source))) stop("Unknown grouping columns.", call. = FALSE)
  if (is.null(variables)) {
    variables <- setdiff(names(source)[vapply(source, is.numeric, logical(1))], by)
  }
  if (!all(variables %in% names(source)) ||
      !all(vapply(source[, variables, drop = FALSE], is.numeric, logical(1)))) {
    stop("Summary variables must be numeric columns.", call. = FALSE)
  }
  groups <- if (is.null(by)) list(all = seq_len(nrow(source))) else
    split(seq_len(nrow(source)), interaction(source[, by, drop = FALSE], drop = TRUE))
  do.call(rbind, lapply(groups, function(indices) {
    group_values <- if (is.null(by)) data.frame(.group = "all") else
      source[indices[1L], by, drop = FALSE]
    do.call(rbind, lapply(variables, function(variable) data.frame(
      group_values, variable = variable, observations = sum(!is.na(source[[variable]][indices])),
      mean = mean(source[[variable]][indices], na.rm = TRUE),
      sd = stats::sd(source[[variable]][indices], na.rm = TRUE),
      minimum = min(source[[variable]][indices], na.rm = TRUE),
      maximum = max(source[[variable]][indices], na.rm = TRUE),
      row.names = NULL
    )))
  }))
}

#' Export a simulation component
#'
#' @param x A simulation result.
#' @param file Destination `.csv` or `.rds` path.
#' @param what Component name.
#'
#' @return The normalized output path, invisibly.
#' @export
#'
#' @examples
#' result <- simulate_ttest(n_a = 20, n_b = 20, mean_a = 0, mean_b = 0.5, seed = 1)
#' file <- tempfile(fileext = ".csv")
#' write_simulation(result, file = file)
#' head(utils::read.csv(file))
#' unlink(file)
write_simulation <- function(x, file, what = "data") {
  stopifnot(
    "`x` must be a `simulab_sim` object" =
      inherits(x, "simulab_sim"),
    "`file` must be a single string" =
      is.character(file) &&
        length(file) == 1L,
    "`what` must be a single string" =
      is.character(what) &&
        length(what) == 1L
  )
  data <- as.data.frame(x, what = what)
  extension <- tolower(tools::file_ext(file))
  if (extension == "csv") utils::write.csv(data, file, row.names = FALSE) else if (
    extension == "rds"
  ) saveRDS(data, file) else stop("file must use a .csv or .rds extension.", call. = FALSE)
  invisible(normalizePath(file, mustWork = TRUE))
}
