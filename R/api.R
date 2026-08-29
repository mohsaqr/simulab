#' Simulate a correlation design
#'
#' @param n Number of observations.
#' @param means,sds,rho,structure,correlation,variable_names,seed Arguments passed
#'   to `simulate_correlated()`.
#'
#' @return A `simulab_sim` base `data.frame`.
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
#' @param id Identifier name used when covariates are omitted.
#' @param seed,digits,envir Arguments passed to `augment_survival()`.
#'
#' @return A `simulab_sim` base `data.frame`.
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
#' @param data Input base `data.frame`.
#' @param factors Named integer vector giving factor levels.
#' @param coding Factor coding passed to `factorial_design()`.
#'
#' @return A `simulab_sim` base `data.frame` containing every row-condition
#'   combination.
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

#' List canonical simulation verbs
#'
#' @param family Optional family filter.
#'
#' @return A base `data.frame` with simulator, family, and primary shape.
#' @export
#'
#' @examples
#' head(list_simulators())
#' list_simulators(family = "network")
list_simulators <- function(family = NULL) {
  catalogue <- data.frame(
    simulator = c(
      "study", "correlation", "copula", "ordinal", "ttest", "anova",
      "regression", "clusters", "lpa", "lca", "factors", "multilevel",
      "growth", "longitudinal", "irt", "markov", "sequence_clusters",
      "hmm", "group_sequences", "group_tna", "event_log", "survival",
      "proportional_survival", "prediction", "synthetic", "density",
      "spline", "network", "edge_list", "temporal_network",
      "network_matrix", "bipartite_network", "multiplex_network", "tna_network"
    ),
    family = c(
      rep("general", 4L), rep("statistical", 4L), rep("latent", 3L),
      rep("longitudinal", 3L), "measurement", rep("sequence", 6L),
      rep("survival", 2L), "statistical", rep("empirical", 2L),
      "functional", rep("network", 7L)
    ),
    primary_shape = c(
      rep("wide", 15L), rep("long", 6L), rep("wide", 6L),
      rep("edge_list", 3L), "matrix", rep("edge_list", 3L)
    ),
    stringsAsFactors = FALSE,
    row.names = NULL
  )
  if (!is.null(family)) {
    stopifnot(
      "`family` must be a single string" =
        is.character(family) &&
          length(family) == 1L
    )
    if (!family %in% unique(catalogue$family)) stop("Unknown simulator family.", call. = FALSE)
    catalogue <- catalogue[catalogue$family == family, , drop = FALSE]
    rownames(catalogue) <- NULL
  }
  catalogue
}

#' Simulate data through the unified catalogue
#'
#' `simulate_data()` is a discoverable dispatcher. Direct verbs remain the
#' preferred interface because they provide explicit, documented arguments.
#'
#' @param type Simulator name from `list_simulators()`.
#' @param ... Arguments passed to the selected canonical simulation verb.
#'
#' @return A `simulab_sim` base `data.frame`.
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
  functions <- c(
    study = "simulate_study", correlation = "simulate_correlation",
    copula = "simulate_copula", ordinal = "simulate_ordinal",
    ttest = "simulate_ttest", anova = "simulate_anova",
    regression = "simulate_regression", clusters = "simulate_clusters",
    lpa = "simulate_lpa", lca = "simulate_lca", factors = "simulate_factors",
    multilevel = "simulate_multilevel", growth = "simulate_growth",
    longitudinal = "simulate_longitudinal", irt = "simulate_irt",
    markov = "simulate_markov", sequence_clusters = "simulate_sequence_clusters",
    hmm = "simulate_hmm", group_sequences = "simulate_group_sequences",
    group_tna = "simulate_group_tna", event_log = "simulate_event_log",
    survival = "simulate_survival",
    proportional_survival = "simulate_proportional_survival",
    prediction = "simulate_prediction",
    synthetic = "simulate_synthetic", density = "simulate_density",
    spline = "simulate_spline", network = "simulate_network",
    edge_list = "simulate_edge_list",
    temporal_network = "simulate_temporal_network",
    network_matrix = "simulate_network_matrix",
    bipartite_network = "simulate_bipartite_network",
    multiplex_network = "simulate_multiplex_network",
    tna_network = "simulate_tna_network"
  )
  if (!type %in% names(functions)) {
    stop(sprintf("Unknown simulator '%s'. Use list_simulators() for choices.", type), call. = FALSE)
  }
  do.call(get(functions[[type]], mode = "function"), list(...))
}

#' Compare recovered estimates with known simulation truth
#'
#' @param estimates Tidy estimates with term and estimate columns.
#' @param truth Tidy truth with term and truth columns.
#' @param term,estimate,true_value Column names.
#' @param tolerance Absolute error tolerance for successful recovery.
#'
#' @return A base `data.frame` with bias, absolute/relative error, and recovery.
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
#' Scenario columns are matched to simulator arguments. Identifier and
#' replication columns are added to each generated observation, which makes
#' the result immediately suitable for grouped estimation and recovery checks.
#'
#' @param scenarios A base `data.frame`, commonly from `scenario_grid()`.
#' @param simulator Canonical simulator name from `list_simulators()`.
#' @param ... Arguments held constant across scenarios.
#' @param id Scenario identifier column.
#' @param replication Replication column.
#' @param seed Optional base seed. Each row receives a deterministic offset.
#'
#' @return A combined `simulab_sim` base `data.frame`; the scenario grid is a
#'   secondary component.
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
