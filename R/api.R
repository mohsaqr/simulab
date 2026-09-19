#' Simulate a correlation design
#'
#' A thin wrapper around [simulate_correlated()] that supplies defaults for
#' `means` and `sds`, so `simulate_correlation(n)` generates a single standard
#' normal variable. `structure` is forwarded only when it is supplied, which
#' keeps [simulate_correlated()]'s own default resolution intact: `"custom"`
#' when `correlation` is given, `"exchangeable"` when a non-zero `rho` is
#' given, and `"independent"` otherwise.
#'
#' @param n Number of observations.
#' @param means,sds,rho,structure,correlation,variable_names,seed Arguments passed
#'   to [simulate_correlated()]. Unlike that function, `means` defaults to `0`.
#'   One variable is generated per element of `means`; `sds` must be a single
#'   value, which is recycled, or one value per mean.
#'
#' @return A `simulab_sim` base `data.frame` with one row per observation and
#'   an `id` column followed by one column per variable. The `parameters`,
#'   `correlation` and `covariance` components hold the requested means and
#'   standard deviations and the tidy correlation and covariance matrices; use
#'   `components()` to list them.
#' @export
#'
#' @examples
#' result <- simulate_correlation(n = 200, means = c(0, 0), sds = c(1, 1), rho = 0.6,
#'                                seed = 1)
#' head(result)
#' as.data.frame(result, what = "correlation")
simulate_correlation <- function(n, means = 0, sds = 1, rho = 0,
                                 structure = c("independent", "exchangeable", "ar1", "custom"),
                                 correlation = NULL, variable_names = NULL,
                                 seed = NULL) {
  # Forward `structure` only when the caller supplied it, so
  # simulate_correlated() can tell a default apart from an explicit choice.
  arguments <- list(n = n, means = means, sds = sds, rho = rho,
                    correlation = correlation,
                    variable_names = variable_names, seed = seed)
  if (!missing(structure)) arguments$structure <- match.arg(structure)
  do.call(simulate_correlated, arguments)
}

#' Simulate baseline data with survival outcomes
#'
#' @param n Number of observations.
#' @param specification Survival definitions from [define_survivals()], in
#'   either the `hazard()` call form or the column form.
#' @param covariates Optional baseline base `data.frame` with `n` rows.
#' @param id Identifier name used when covariates are omitted. Defaults to
#'   `"id"` and is ignored when `covariates` is supplied.
#' @param seed,digits,envir Arguments passed to [augment_survival()].
#'
#' @return A `simulab_sim` base `data.frame` with one row per simulated
#'   subject: the identifier (or the supplied covariates) followed by one
#'   column per event defined in `specification`. The `survival_definitions`
#'   component holds the specification that generated it.
#' @export
#'
#' @examples
#' result <- simulate_survival(
#'   n = 100,
#'   specification = define_survivals(define_survival("time", formula = -8, shape = 0.3)),
#'   seed = 1
#' )
#' head(result)
#'
#' # A hazard call states the same process, with the log rate as an expression.
#' head(simulate_survival(
#'   n = 100,
#'   specification = define_survivals(time = hazard(log_rate = -8, shape = 0.3)),
#'   seed = 1
#' ))
simulate_survival <- function(n, specification, covariates = NULL, id = "id",
                              seed = NULL, digits = NULL,
                              envir = parent.frame()) {
  stopifnot(
    "`n` must be a single positive whole number" =
      is.numeric(n) &&
        length(n) == 1L &&
        all(n >= 1) &&
        all(n == as.integer(n)),
    "`specification` must be a `simulab_survival_spec` object" =
      inherits(specification, "simulab_survival_spec"),
    "`covariates` must be NULL or a data frame" =
      is.null(covariates) || is.data.frame(covariates),
    "`id` must be a single non-empty string" =
      is.character(id) &&
        length(id) == 1L &&
        all(nzchar(id))
  )
  data <- if (is.null(covariates)) {
    result <- data.frame(sequence = seq_len(as.integer(n)), row.names = NULL)
    names(result) <- id
    result
  } else {
    if (nrow(covariates) != n) stop("covariates must contain n rows.", call. = FALSE)
    covariates
  }
  augment_survival(data, specification, seed = seed, digits = digits, envir = envir)
}

#' Add factorial conditions to existing rows
#'
#' @param data Input base `data.frame`, with at least one row.
#' @param factors Named numeric vector of whole numbers giving the number of
#'   levels of each factor. Every entry must be at least 2.
#' @param coding Factor coding passed to [factorial_design()]: `"dummy"` (the
#'   default), `"effect"` or `"level"`.
#'
#' @return A `simulab_sim` base `data.frame` with one row per row of `data`
#'   crossed with every design condition, so `nrow(data) * prod(factors)` rows:
#'   the columns of `data` followed by one column per factor. The `design`
#'   component holds the distinct conditions, one row each.
#' @export
#'
#' @examples
#' data <- data.frame(id = 1:12)
#' result <- augment_factorial(data, factors = c(dose = 3L, timing = 2L))
#' head(result)
augment_factorial <- function(data, factors,
                              coding = c("dummy", "effect", "level")) {
  stopifnot(
    "`data` must be a data frame, with at least one row" =
      is.data.frame(data) &&
        nrow(data) >= 1L,
    "`factors` must be a named numeric vector, of whole numbers, each at least 2" =
      is.numeric(factors) &&
        !is.null(names(factors)) &&
        all(factors >= 2) &&
        all(factors == as.integer(factors)),
    "`coding` must be a character vector" =
      is.character(coding)
  )
  coding <- match.arg(coding)
  design <- .plain_data(factorial_design(factors, coding = coding))
  design$id <- NULL
  rows <- merge(data.frame(.row = seq_len(nrow(data))),
                data.frame(.condition = seq_len(nrow(design))))
  result <- data.frame(.as_result_data(data)[rows$.row, , drop = FALSE],
                       design[rows$.condition, , drop = FALSE],
                       check.names = FALSE, row.names = NULL)
  .new_simulab_sim(result, "augmented_factorial",
                   tables = list(design = design))
}

# The public simulation registry is the single source for both discovery and
# dispatch. Keeping the callable beside its metadata prevents a simulator from
# being added to one surface while silently missing from the other.
.simulator_registry <- function() {
  data.frame(
    simulator = c(
      "study", "correlation", "correlated", "copula", "ordinal", "ttest",
      "anova", "regression", "clusters", "lpa", "ml_lpa", "lca", "factors",
      "multilevel", "growth", "longitudinal", "irt", "markov",
      "transition_system", "sequences", "sequence_clusters", "hmm",
      "group_sequences", "group_tna", "event_log", "until_event", "survival",
      "proportional_survival", "prediction", "synthetic", "density", "spline",
      "network", "edge_list", "temporal_network", "network_matrix",
      "bipartite_network", "multiplex_network", "tna_network",
      "sequence_batches", "tna_batches", "network_batches", "scenarios", "data"
    ),
    function_name = c(
      "simulate_study", "simulate_correlation", "simulate_correlated",
      "simulate_copula", "simulate_ordinal", "simulate_ttest", "simulate_anova",
      "simulate_regression", "simulate_clusters", "simulate_lpa",
      "simulate_ml_lpa", "simulate_lca",
      "simulate_factors", "simulate_multilevel", "simulate_growth",
      "simulate_longitudinal", "simulate_irt", "simulate_markov",
      "generate_transition_system", "simulate_sequences",
      "simulate_sequence_clusters", "simulate_hmm", "simulate_group_sequences",
      "simulate_group_tna", "simulate_event_log", "simulate_until_event",
      "simulate_survival", "simulate_proportional_survival", "simulate_prediction",
      "simulate_synthetic", "simulate_density", "simulate_spline",
      "simulate_network", "simulate_edge_list", "simulate_temporal_network",
      "simulate_network_matrix", "simulate_bipartite_network",
      "simulate_multiplex_network", "simulate_tna_network",
      "simulate_sequence_batches", "simulate_tna_batches",
      "simulate_network_batches", "simulate_scenarios", "simulate_data"
    ),
    kind = c(
      rep("simulator", 18L), "generator", rep("simulator", 6L), "workflow",
      rep("simulator", 13L), rep("workflow", 4L), "dispatcher"
    ),
    family = c(
      rep("general", 5L), rep("statistical", 4L), rep("latent", 4L),
      rep("longitudinal", 3L), "measurement", rep("sequence", 9L),
      rep("survival", 2L), "statistical", rep("empirical", 2L), "functional",
      rep("network", 7L), rep("sequence", 2L), "network", rep("general", 2L)
    ),
    primary_shape = c(
      rep("wide", 17L), "long", "edge_list", "long", "long", "long", "long",
      "long", "long", "long", rep("wide", 6L), rep("edge_list", 3L), "matrix",
      rep("edge_list", 3L), "long", "edge_list", "edge_list", "varies", "varies"
    ),
    dispatchable = c(rep(TRUE, 43L), FALSE),
    stringsAsFactors = FALSE,
    row.names = NULL
  )
}

#' List public simulation and generation verbs
#'
#' @param family Optional single-string family filter, one of `"general"`,
#'   `"statistical"`, `"latent"`, `"longitudinal"`, `"measurement"`,
#'   `"sequence"`, `"survival"`, `"empirical"`, `"functional"` or `"network"`.
#'   An unknown family is an error.
#' @param kind Optional single-string kind filter: `"simulator"`,
#'   `"generator"`, `"workflow"`, or `"dispatcher"`. An unknown kind is an
#'   error.
#' @param dispatchable Optional single logical filter: `TRUE` keeps only the
#'   verbs that can be called through [simulate_data()], `FALSE` keeps only
#'   those that cannot.
#'
#' @return A base `data.frame` with one row per catalogued verb and the columns
#'   `simulator` (the catalogue name), `function_name`, `kind`, `family`,
#'   `primary_shape` and `dispatchable`.
#' @export
#'
#' @examples
#' head(list_simulators())
#' list_simulators(kind = "workflow")
list_simulators <- function(family = NULL, kind = NULL, dispatchable = NULL) {
  catalogue <- .simulator_registry()
  if (!is.null(family)) {
    stopifnot(
      "`family` must be a single string" =
        is.character(family) &&
          length(family) == 1L
    )
    if (!family %in% unique(catalogue$family)) stop("Unknown simulator family.", call. = FALSE)
    catalogue <- catalogue[catalogue$family == family, , drop = FALSE]
  }
  if (!is.null(kind)) {
    stopifnot(
      "`kind` must be a single string" =
        is.character(kind) &&
          length(kind) == 1L
    )
    if (!kind %in% unique(.simulator_registry()$kind)) stop("Unknown simulator kind.", call. = FALSE)
    catalogue <- catalogue[catalogue$kind == kind, , drop = FALSE]
  }
  if (!is.null(dispatchable)) {
    stopifnot(
      "`dispatchable` must be a single logical value" =
        is.logical(dispatchable) &&
          length(dispatchable) == 1L &&
          !is.na(dispatchable)
    )
    catalogue <- catalogue[catalogue$dispatchable == dispatchable, , drop = FALSE]
  }
  rownames(catalogue) <- NULL
  catalogue
}

#' Simulate data through the unified catalogue
#'
#' `simulate_data()` is a discoverable dispatcher. Direct verbs remain the
#' preferred interface because they provide explicit, documented arguments.
#'
#' @param type Dispatchable simulator name, taken from the `simulator` column
#'   of [list_simulators()]. An unknown name, or a name whose `dispatchable`
#'   entry is `FALSE`, is an error.
#' @param ... Arguments passed on to the selected canonical simulation verb.
#'
#' @return Whatever the selected verb returns, which for every dispatchable
#'   entry is a `simulab_sim` base `data.frame`.
#' @export
#'
#' @examples
#' result <- simulate_data("ttest", n_a = 30, n_b = 30, mean_a = 0, mean_b = 0.5, seed = 1)
#' head(result)
simulate_data <- function(type, ...) {
  stopifnot(
    "`type` must be a single non-empty string" =
      is.character(type) &&
        length(type) == 1L &&
        all(nzchar(type))
  )
  entry <- .simulator_registry()
  entry <- entry[entry$simulator == type, , drop = FALSE]
  if (!nrow(entry)) {
    stop(sprintf("Unknown simulator '%s'. Use list_simulators() for choices.", type), call. = FALSE)
  }
  if (!entry$dispatchable[[1L]]) {
    stop(sprintf("'%s' is a %s and cannot dispatch itself.", type, entry$kind[[1L]]),
         call. = FALSE)
  }
  simulator <- get(entry$function_name[[1L]], envir = environment(simulate_data),
                   mode = "function")
  do.call(simulator, list(...))
}

#' Compare recovered estimates with known simulation truth
#'
#' @param estimates Tidy base `data.frame` with a term column and an estimate
#'   column.
#' @param truth Tidy base `data.frame` with a term column and a true-value
#'   column.
#' @param term Name of the term column in both frames, default `"term"`. It is
#'   the key the two frames are merged on.
#' @param estimate Name of the estimate column in `estimates`, default
#'   `"estimate"`.
#' @param true_value Name of the true-value column in `truth`, default
#'   `"truth"`.
#' @param tolerance Single non-negative absolute-error tolerance for successful
#'   recovery, default `0.1`.
#'
#' @return A base `data.frame` with one row per term appearing in either frame
#'   (the merge keeps unmatched terms) and the columns `term`, `estimate`,
#'   `truth`, `bias` (estimate minus truth), `absolute_error`,
#'   `relative_error` (`NA` where truth is zero) and `recovered`, a logical
#'   that is `TRUE` when `absolute_error` is at most `tolerance`.
#' @export
#'
#' @examples
#' estimates <- data.frame(term = c("x1", "x2"), estimate = c(0.52, -0.28))
#' truth <- data.frame(term = c("x1", "x2"), truth = c(0.5, -0.3))
#' validate_recovery(estimates, truth, tolerance = 0.1)
validate_recovery <- function(estimates, truth, term = "term", estimate = "estimate",
                              true_value = "truth", tolerance = 0.1) {
  stopifnot(
    "`estimates` must be a data frame" =
      is.data.frame(estimates),
    "`truth` must be a data frame" =
      is.data.frame(truth),
    "`term` and `estimate` must name columns of `estimates`" =
      all(c(term, estimate) %in% names(estimates)) &&
        all(c(term, true_value) %in% names(truth)),
    "`tolerance` must be a single non-negative number" =
      is.numeric(tolerance) &&
        length(tolerance) == 1L &&
        all(tolerance >= 0)
  )
  merged <- merge(estimates[, c(term, estimate), drop = FALSE],
                  truth[, c(term, true_value), drop = FALSE], by = term, all = TRUE)
  names(merged) <- c("term", "estimate", "truth")
  if (!is.numeric(merged$estimate) || !is.numeric(merged$truth)) {
    stop("Estimate and truth columns must be numeric.", call. = FALSE)
  }
  merged$bias <- merged$estimate - merged$truth
  merged$absolute_error <- abs(merged$bias)
  merged$relative_error <- ifelse(merged$truth == 0, NA_real_, merged$bias / merged$truth)
  merged$recovered <- !is.na(merged$absolute_error) & merged$absolute_error <= tolerance
  merged
}

#' Run a simulator across a scenario grid
#'
#' Every column of `scenarios` other than `id` and `replication` is passed to
#' the simulator as a named argument, so the column names must be simulator
#' argument names and must not repeat an argument given in `...`. The
#' identifier and replication values are prepended to each generated
#' observation, which makes the result immediately suitable for grouped
#' estimation and recovery checks. Every scenario must produce the same primary
#' columns, otherwise the run is an error.
#'
#' @param scenarios A base `data.frame` with at least one row, commonly from
#'   [scenario_grid()], containing the `id` and `replication` columns.
#' @param simulator Canonical simulator name, taken from the `simulator` column
#'   of [list_simulators()] and dispatched through [simulate_data()].
#' @param ... Arguments held constant across scenarios.
#' @param id Single string naming the scenario identifier column of
#'   `scenarios`, default `"scenario_id"`.
#' @param replication Single string naming the replication column of
#'   `scenarios`, default `"replication"`.
#' @param seed Optional single base seed. Row `i` of `scenarios` is simulated
#'   with `seed + i - 1`, unless `scenarios` or `...` already supplies a
#'   `seed`.
#'
#' @return A `simulab_sim` base `data.frame` stacking every scenario's output,
#'   with one row per generated observation: the `id` and `replication` columns
#'   first, then the simulator's own columns. The `scenarios` component holds
#'   the grid that was run, one row per scenario.
#' @export
#'
#' @examples
#' scenarios <- scenario_grid(mean_b = c(0, 0.5), replications = 2)
#' result <- simulate_scenarios(
#'   scenarios, simulator = "ttest",
#'   n_a = 20, n_b = 20, mean_a = 0, seed = 1
#' )
#' head(result)
simulate_scenarios <- function(scenarios, simulator, ..., id = "scenario_id",
                               replication = "replication", seed = NULL) {
  stopifnot(
    "`scenarios` must be a data frame, with at least one row" =
      is.data.frame(scenarios) &&
        nrow(scenarios) >= 1L,
    "`simulator` must be a single string" =
      is.character(simulator) &&
        length(simulator) == 1L,
    "`id` must be a single string naming a column of `scenarios`" =
      is.character(id) &&
        length(id) == 1L &&
        all(id %in% names(scenarios)),
    "`replication` must be a single string naming a column of `scenarios`" =
      is.character(replication) &&
        length(replication) == 1L &&
        all(replication %in% names(scenarios)),
    "`seed` must be NULL or a single number" =
      is.null(seed) || (is.numeric(seed) && length(seed) == 1L)
  )
  constant_arguments <- list(...)
  scenario_arguments <- setdiff(names(scenarios), c(id, replication))
  generated <- lapply(seq_len(nrow(scenarios)), function(index) {
    varying <- as.list(scenarios[index, scenario_arguments, drop = FALSE])
    duplicated <- intersect(names(varying), names(constant_arguments))
    if (length(duplicated)) {
      stop(sprintf("Scenario and constant arguments overlap: %s.",
                   paste(duplicated, collapse = ", ")), call. = FALSE)
    }
    row_seed <- if (is.null(seed)) NULL else seed + index - 1L
    arguments <- c(list(type = simulator), varying, constant_arguments)
    if (!"seed" %in% names(arguments)) arguments$seed <- row_seed
    simulation <- do.call(simulate_data, arguments)
    data.frame(
      scenario_id_value = scenarios[[id]][index],
      replication_value = scenarios[[replication]][index],
      .plain_data(simulation),
      check.names = FALSE,
      row.names = NULL
    )
  })
  column_sets <- lapply(generated, names)
  if (!all(vapply(column_sets, identical, logical(1), column_sets[[1L]]))) {
    stop("Every scenario must generate the same primary columns.", call. = FALSE)
  }
  result <- do.call(rbind, generated)
  names(result)[1:2] <- c(id, replication)
  rownames(result) <- NULL
  .new_simulab_sim(result, "scenarios", seed,
                   list(scenarios = as.data.frame(scenarios)))
}
