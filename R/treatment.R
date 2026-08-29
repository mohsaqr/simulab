.balanced_assignments <- function(n, ratios) {
  stopifnot(
    "`n` must be a single number of at least 1" =
      is.numeric(n) &&
        length(n) == 1L &&
        all(n >= 1),
    "`ratios` must be a positive numeric vector" =
      is.numeric(ratios) &&
        length(ratios) >= 2L &&
        all(ratios > 0)
  )
  target <- n * ratios / sum(ratios)
  counts <- floor(target)
  remainder <- as.integer(n - sum(counts))
  if (remainder > 0L) {
    order_fraction <- order(target - counts, decreasing = TRUE)
    counts[order_fraction[seq_len(remainder)]] <- counts[order_fraction[seq_len(remainder)]] + 1L
  }
  sample(rep(seq_along(ratios), times = counts), size = n, replace = FALSE)
}

#' Assign randomized treatment groups
#'
#' @param data Base `data.frame`.
#' @param groups Number of treatment groups or their labels.
#' @param balanced Use exact balance within strata.
#' @param strata Optional stratification variables.
#' @param ratios Relative allocation ratios.
#' @param name Name of the treatment variable.
#' @param seed Optional random seed.
#'
#' @return A `simulab_sim` base `data.frame` with a treatment variable and a
#'   tidy allocation table.
#' @export
#'
#' @examples
#' data <- data.frame(id = 1:100, site = rep(c("north", "south"), each = 50))
#'
#' result <- assign_treatment(data, groups = 2, strata = "site", seed = 1)
#' head(result)
#' table(as.data.frame(result)$treatment)
assign_treatment <- function(data, groups = 2L, balanced = TRUE,
                             strata = NULL, ratios = NULL,
                             name = "treatment", seed = NULL) {
  stopifnot(
    "`data` must be a data frame, with at least one row" =
      is.data.frame(data) &&
        nrow(data) >= 1L,
    "`groups` must be a single number" =
      (is.numeric(groups) && length(groups) == 1L) || is.atomic(groups),
    "`balanced` must be a single flag" =
      is.logical(balanced) &&
        length(balanced) == 1L,
    "`strata` must be NULL or a character vector" =
      is.null(strata) || is.character(strata),
    "`ratios` must be NULL or a numeric vector" =
      is.null(ratios) || is.numeric(ratios),
    "`name` must be a single non-empty string" =
      is.character(name) &&
        length(name) == 1L &&
        all(nzchar(name)),
    "`seed` must be NULL or a single number" =
      is.null(seed) || (is.numeric(seed) && length(seed) == 1L)
  )
  source <- .as_result_data(data)
  if (name %in% names(source)) {
    stop(sprintf("Variable '%s' already exists.", name), call. = FALSE)
  }
  if (!is.null(strata) && !all(strata %in% names(source))) {
    stop("Every strata variable must exist in data.", call. = FALSE)
  }
  group_labels <- if (is.numeric(groups) && length(groups) == 1L) {
    if (groups < 2 || groups != as.integer(groups)) {
      stop("groups must specify at least two groups.", call. = FALSE)
    }
    if (groups == 2L) c(0L, 1L) else seq_len(as.integer(groups))
  } else {
    groups
  }
  if (anyDuplicated(group_labels) || length(group_labels) < 2L) {
    stop("Treatment group labels must be unique.", call. = FALSE)
  }
  if (is.null(ratios)) ratios <- rep(1, length(group_labels))
  if (length(ratios) != length(group_labels) || any(ratios <= 0)) {
    stop("ratios must contain one positive value per treatment group.", call. = FALSE)
  }

  stratum <- if (is.null(strata)) {
    rep("all", nrow(source))
  } else {
    interaction(source[, strata, drop = FALSE], drop = TRUE, lex.order = TRUE)
  }
  index_groups <- split(seq_len(nrow(source)), stratum)
  assignment <- .with_seed(seed, {
    assigned <- lapply(index_groups, function(indices) {
      if (balanced) {
        .balanced_assignments(length(indices), ratios)
      } else {
        sample.int(length(group_labels), length(indices), replace = TRUE, prob = ratios)
      }
    })
    result <- integer(nrow(source))
    result[unlist(index_groups, use.names = FALSE)] <- unlist(assigned, use.names = FALSE)
    result
  })
  source[[name]] <- group_labels[assignment]
  allocation <- aggregate(
    rep(1L, nrow(source)),
    by = list(stratum = as.character(stratum), treatment = source[[name]]),
    FUN = sum
  )
  names(allocation)[3L] <- "observations"
  .new_simulab_sim(source, type = "treatment_assignment", seed = seed,
                   tables = list(allocation = allocation))
}

#' Generate observational treatment or exposure groups
#'
#' @param data Base `data.frame`.
#' @param formulas Character vector of probability formulas. An implicit final
#'   group receives the remaining probability.
#' @param link Identity or multinomial-logit link.
#' @param labels Optional group labels.
#' @param name Name of the exposure variable.
#' @param seed Optional random seed.
#' @param envir Formula evaluation environment.
#'
#' @return A `simulab_sim` base `data.frame` with the generated exposure group.
#' @export
#'
#' @examples
#' data <- data.frame(id = 1:100, severity = stats::rnorm(100))
#'
#' result <- observe_treatment(
#'   data, formulas = "-0.5 + 0.8 * severity", link = "logit", seed = 1
#' )
#' head(result)
observe_treatment <- function(data, formulas,
                              link = c("identity", "logit"),
                              labels = NULL, name = "treatment",
                              seed = NULL, envir = parent.frame()) {
  stopifnot(
    "`data` must be a data frame, with at least one row" =
      is.data.frame(data) &&
        nrow(data) >= 1L,
    "`formulas` must be a character vector, with at least one element" =
      is.character(formulas) &&
        length(formulas) >= 1L,
    "`labels` must be NULL or an atomic vector" =
      is.null(labels) || is.atomic(labels),
    "`name` must be a single non-empty string" =
      is.character(name) &&
        length(name) == 1L &&
        all(nzchar(name)),
    "`seed` must be NULL or a single number" =
      is.null(seed) || (is.numeric(seed) && length(seed) == 1L),
    "`envir` must be an environment" =
      is.environment(envir)
  )
  link <- match.arg(link)
  source <- .as_result_data(data)
  if (name %in% names(source)) {
    stop(sprintf("Variable '%s' already exists.", name), call. = FALSE)
  }
  probabilities <- .eval_definitions(formulas, source, nrow(source), envir)
  if (identical(link, "logit")) {
    odds <- exp(probabilities)
    probabilities <- cbind(odds, 1) / (1 + rowSums(odds))
  } else {
    if (any(probabilities < 0)) stop("Treatment probabilities cannot be negative.", call. = FALSE)
    totals <- rowSums(probabilities)
    if (any(totals > 1 + 1e-10)) {
      stop("Identity-link treatment probabilities cannot sum above one.", call. = FALSE)
    }
    probabilities <- cbind(probabilities, 1 - totals)
  }
  if (is.null(labels)) {
    labels <- if (ncol(probabilities) == 2L) c(1L, 0L) else seq_len(ncol(probabilities))
  }
  if (length(labels) != ncol(probabilities)) {
    stop("labels must contain one value per treatment group.", call. = FALSE)
  }
  selected <- .with_seed(seed, vapply(seq_len(nrow(source)), function(index) {
    sample.int(ncol(probabilities), 1L, prob = probabilities[index, ])
  }, integer(1)))
  source[[name]] <- labels[selected]
  probability_table <- data.frame(
    observation = rep(seq_len(nrow(source)), each = ncol(probabilities)),
    group = rep(labels, times = nrow(source)),
    probability = as.vector(t(probabilities)),
    stringsAsFactors = FALSE,
    row.names = NULL
  )
  .new_simulab_sim(source, type = "observed_treatment", seed = seed,
                   tables = list(probabilities = probability_table))
}

#' Assign a stepped-wedge treatment schedule
#'
#' @param data Long-form base `data.frame`.
#' @param cluster Cluster identifier.
#' @param period Period variable.
#' @param waves Number of waves.
#' @param wave_length Periods between wave starts.
#' @param start First treatment-start period.
#' @param lag Transition periods before treatment becomes active.
#' @param treatment Name of the active-treatment variable.
#' @param transition Name of the transition variable.
#' @param randomize Randomize clusters to waves.
#' @param seed Optional random seed.
#'
#' @return A `simulab_sim` base `data.frame` and a tidy cluster-wave schedule.
#' @export
#'
#' @examples
#' data <- expand_clusters(
#'   data.frame(cluster = 1:6), cluster = "cluster", size = 4
#' )
#' data <- expand_periods(data, periods = 5, id = "id", period = "period")
#'
#' result <- assign_stepped_wedge(
#'   data, cluster = "cluster", period = "period",
#'   waves = 3, wave_length = 1, start = 2, seed = 1
#' )
#' head(result)
assign_stepped_wedge <- function(data, cluster, period, waves, wave_length,
                                 start, lag = 0L, treatment = "treatment",
                                 transition = "transition", randomize = TRUE,
                                 seed = NULL) {
  stopifnot(
    "`data` must be a data frame, with at least one row" =
      is.data.frame(data) &&
        nrow(data) >= 1L,
    "`cluster` must be a single string naming a column of `data`" =
      is.character(cluster) &&
        length(cluster) == 1L &&
        all(cluster %in% names(data)),
    "`period` must be a single string naming a column of `data`" =
      is.character(period) &&
        length(period) == 1L &&
        all(period %in% names(data)),
    "`waves` must be a single positive whole number" =
      is.numeric(waves) &&
        length(waves) == 1L &&
        all(waves >= 1) &&
        all(waves == as.integer(waves)),
    "`wave_length` must be a single positive whole number" =
      is.numeric(wave_length) &&
        length(wave_length) == 1L &&
        all(wave_length >= 1) &&
        all(wave_length == as.integer(wave_length)),
    "`start` must be a single number" =
      is.numeric(start) &&
        length(start) == 1L,
    "`lag` must be a single non-negative whole number" =
      is.numeric(lag) &&
        length(lag) == 1L &&
        all(lag >= 0) &&
        all(lag == as.integer(lag)),
    "`treatment` must be a single string" =
      is.character(treatment) &&
        length(treatment) == 1L,
    "`transition` must be a single string" =
      is.character(transition) &&
        length(transition) == 1L,
    "`randomize` must be a single flag" =
      is.logical(randomize) &&
        length(randomize) == 1L,
    "`seed` must be NULL or a single number" =
      is.null(seed) || (is.numeric(seed) && length(seed) == 1L)
  )
  source <- .as_result_data(data)
  clusters <- unique(source[[cluster]])
  if (length(clusters) %% waves != 0L) {
    stop("The number of clusters must be divisible by waves.", call. = FALSE)
  }
  required_last_period <- start + (waves - 1L) * wave_length + lag
  if (max(source[[period]], na.rm = TRUE) < required_last_period) {
    stop(
      sprintf("The design requires periods through %s.", required_last_period),
      call. = FALSE
    )
  }
  ordered_clusters <- .with_seed(
    seed,
    if (randomize) sample(clusters, length(clusters), replace = FALSE) else clusters
  )
  wave <- rep(seq_len(as.integer(waves)), each = length(clusters) / waves)
  schedule <- data.frame(
    cluster = ordered_clusters,
    wave = wave,
    treatment_start = start + (wave - 1L) * wave_length,
    stringsAsFactors = FALSE,
    row.names = NULL
  )
  names(schedule)[1L] <- cluster
  start_lookup <- schedule$treatment_start[match(source[[cluster]], schedule[[cluster]])]
  source[[transition]] <- as.integer(
    source[[period]] >= start_lookup & source[[period]] < start_lookup + lag
  )
  source[[treatment]] <- as.integer(source[[period]] >= start_lookup + lag)
  if (lag == 0L) source[[transition]] <- NULL
  .new_simulab_sim(source, type = "stepped_wedge", seed = seed,
                   tables = list(schedule = schedule))
}
