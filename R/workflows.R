#' Generate parameter combinations
#'
#' @param ... Named vectors, one per parameter. Under `method = "grid"` every
#'   element is a level of a full factorial crossing. Under the sampling
#'   methods a length-2 numeric vector is read as a `c(minimum, maximum)` range
#'   to draw from, and any other vector is sampled from with replacement.
#' @param n Single positive whole number of rows to draw for the `"random"` and
#'   `"latin_hypercube"` methods, default `10`. Ignored by `"grid"`, whose row
#'   count is the product of the parameter lengths.
#' @param method One of `"grid"` (the default), `"random"`, or
#'   `"latin_hypercube"`.
#' @param seed Optional single random seed. It is applied for the sampling
#'   methods only and is restored on exit.
#'
#' @return A base `data.frame` with one row per parameter combination, a
#'   leading `scenario_id` column numbering the rows, and then one column per
#'   parameter in the order given.
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
#' @param inputs List with at least one element, commonly data frames or
#'   simulation results. Element names label the batches; when `inputs` is
#'   unnamed the positions `"1"`, `"2"`, ... are used instead.
#' @param fun Function applied to each element. It must return a base
#'   `data.frame`, and every call must return the same columns, otherwise the
#'   run is an error.
#' @param ... Arguments passed to `fun`.
#' @param id Single string naming the batch-label column, default
#'   `"batch_id"`.
#'
#' @return A base `data.frame` stacking the `fun` outputs by row, with the
#'   batch label in a leading column named by `id`, so one row per row of each
#'   output.
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
#' @param inputs List of sequence data frames, with at least one element.
#'   Element names label the datasets; when `inputs` is unnamed the labels
#'   `"Dataset 1"`, `"Dataset 2"`, ... are used instead.
#' @param ... Arguments passed to [fit_tna()].
#'
#' @return A `simulab_sim` edge list with one row per dataset and transition: a
#'   leading `dataset` column followed by the columns [fit_tna()] returns
#'   (`from`, `to`, `weight`, and `group` when a grouped fit is requested). The
#'   `model_info` component holds one row per dataset describing the fitted
#'   model.
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
#' @param data Sequence data in long or wide form.
#' @param model TNA estimator, one of `"tna"` (the default), `"ftna"`,
#'   `"ctna"`, `"atna"`.
#' @param repetitions Single whole number of bootstrap samples, at least 2,
#'   default `100`.
#' @param fraction Single number in `(0, 1]` giving the fraction of sequences
#'   drawn with replacement in each repetition, default `1`. At least two
#'   sequences are always drawn.
#' @param format,id,period,state,group Arguments describing the shape and
#'   column names of `data`. They are used to reshape `data` before resampling;
#'   the resampled sequences are then fitted in wide form, so only `group` is
#'   forwarded to [fit_tna()]. `group` resamples within each group.
#' @param seed Optional single seed, restored on exit and recorded on the
#'   result.
#' @param ... Further arguments passed to [fit_tna()].
#'
#' @return A `simulab_sim` edge list with one row per repetition and
#'   transition: a leading `iteration` column followed by the columns
#'   [fit_tna()] returns. The `summary` component holds one row per edge (per
#'   group, when `group` is given) with the bootstrap `mean`, `sd`, and the
#'   2.5% and 97.5% percentiles as `lower` and `upper`.
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
#' Each iteration splits the sequences once into a training and a testing set,
#' fits every estimator to both halves, and compares the two networks with
#' [compare_networks()].
#'
#' @param data Sequence data in long or wide form.
#' @param models Character vector of TNA estimators to compare, any of `"tna"`,
#'   `"ftna"`, `"ctna"`, `"atna"`. The default runs all four.
#' @param iterations Number of train/test splits, a whole number of at least 1,
#'   default `20`.
#' @param training_fraction Fraction of sequences assigned to the training
#'   half, strictly between 0 and 1, default `0.7`. At least two training
#'   sequences are always used, and a split leaving fewer than two testing
#'   sequences is an error.
#' @param format,id,period,state Arguments describing the shape and column
#'   names of `data`. They are used to reshape `data` before splitting; both
#'   halves are then fitted in wide form.
#' @param seed Optional single seed, restored on exit.
#' @param ... Further arguments passed to [fit_tna()].
#'
#' @return A plain base `data.frame` with one row per iteration and estimator
#'   and the columns `iteration`, `model`, and the [compare_networks()]
#'   agreement metrics `pearson`, `cosine`, `mae`, `rmse`, `jaccard`, `edges_x`
#'   and `edges_y`. This is not a `simulab_sim`.
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
#' @param data Sequence data, in long or wide form.
#' @param fraction Single number in `(0, 1]` giving the fraction of sequences
#'   to draw, default `0.3`. At least two sequences are always drawn.
#' @param replace Single flag, whether to draw with replacement. Default
#'   `FALSE`.
#' @param seed Optional single seed, restored on exit.
#' @param format One of `"auto"`, `"long"` or `"wide"`, naming the layout of
#'   `data`. The default `"auto"` detects it.
#' @param id,period,state Column names identifying the sequence, the position
#'   within it, and the state. Used only when `data` is in long form; the
#'   defaults are `"id"`, `"period"` and `"state"`.
#' @param group Optional column name. When given, sequences are sampled within
#'   each group and the refit is grouped.
#' @param ... Further arguments passed to [fit_tna()], such as `model`. The
#'   sampled sequences are always refitted in wide form, so `format` is
#'   consumed by the sampling step and is not forwarded.
#'
#' @return The [fit_tna()] result for the sampled sequences: a `simulab_sim`
#'   edge list with one row per transition and the columns `from`, `to` and
#'   `weight`, plus the `initial_probabilities` and `model_info` components.
#' @export
#'
#' @examples
#' data <- simulate_sequences(n = 40, n_states = 3, chain_length = 12, seed = 1)
#' if (requireNamespace("tna", quietly = TRUE)) {
#'   head(sample_tna(data, fraction = 0.5, seed = 1))
#' }
sample_tna <- function(data, fraction = 0.3, replace = FALSE, seed = NULL,
                       format = c("auto", "long", "wide"), id = "id",
                       period = "period", state = "state", group = NULL, ...) {
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
        length(replace) == 1L,
    "`id` must be a single non-empty string" =
      is.character(id) && length(id) == 1L && nzchar(id),
    "`period` must be a single non-empty string" =
      is.character(period) && length(period) == 1L && nzchar(period),
    "`state` must be a single non-empty string" =
      is.character(state) && length(state) == 1L && nzchar(state),
    "`group` must be NULL or a single non-empty string" =
      is.null(group) || (is.character(group) && length(group) == 1L && nzchar(group))
  )
  format <- match.arg(format)
  ## The sampling step consumes the column names, because it reshapes `data`
  ## into wide form before drawing. Forwarding them to fit_tna() as well would
  ## describe the reshaped table with the pre-reshape names.
  prepared <- .with_seed(seed, .sample_sequence_rows(
    data, format, id, period, state, group, fraction, replace
  ))
  fit_tna(prepared, format = "wide", group = group, ...)
}

#' Summarize simulated numeric variables
#'
#' @param data Simulation data: a `simulab_sim` or a plain base `data.frame`.
#' @param by Optional character vector of grouping column names. `NULL`, the
#'   default, summarizes all rows together.
#' @param variables Character vector of numeric variables to summarize. `NULL`,
#'   the default, selects every numeric non-grouping column.
#'
#' @return A plain base `data.frame` with one row per group and variable: the
#'   `by` columns (or a single `.group` column holding `"all"` when `by` is
#'   `NULL`), then `variable`, `observations` (the non-missing count), `mean`,
#'   `sd`, `minimum` and `maximum`.
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
#' @param x A `simulab_sim` simulation result.
#' @param file Destination path. The extension decides the format and must be
#'   `.csv` (written with `utils::write.csv()`, without row names) or `.rds`;
#'   any other extension is an error.
#' @param what Single string naming the component to write, default `"data"`.
#'   Use `components(x)` to list the choices.
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
