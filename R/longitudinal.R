#' Simulate a two-level Gaussian model
#'
#' Draws a random intercept (and optionally a random slope) per cluster, draws
#' the predictors independently for every unit, and forms the outcome as the
#' fixed part plus the cluster random effects plus normal residual noise.
#'
#' @param clusters Number of clusters. A single whole number of at least 2.
#' @param cluster_size Units per cluster: a single whole number recycled
#'   across clusters, or one whole number per cluster, so clusters may be
#'   unbalanced.
#' @param intercept Fixed intercept. A single number, defaulting to `0`.
#' @param slopes Named fixed-effect slopes; the names become the predictor
#'   columns of the returned data. Defaults to `numeric(0)`, an
#'   intercept-only model with no predictor columns.
#' @param predictor_means,predictor_sds Mean and standard deviation of each
#'   predictor, a scalar recycled across predictors (the defaults, `0` and
#'   `1`) or one value per entry of `slopes`. Predictors are drawn
#'   independently at the unit level, not at the cluster level, so they carry
#'   no between-cluster variance by construction.
#' @param random_intercept_sd Random-intercept standard deviation. A single
#'   non-negative number, defaulting to `1`.
#' @param random_slope_sd Random-slope standard deviation for the first
#'   predictor only; the remaining predictors have fixed slopes. A single
#'   non-negative number, defaulting to `0` (no random slope).
#' @param random_effect_correlation Correlation between random intercept and
#'   slope. A single number in `[-1, 1]`, defaulting to `0`.
#' @param residual_sd Residual standard deviation. A single positive number,
#'   defaulting to `1`.
#' @param seed Optional random seed.
#'
#' @return A `simulab_sim` base `data.frame` with one row per unit
#'   (`sum(cluster_size)` rows) and columns `id`, `cluster`, one column per
#'   name of `slopes`, and `outcome`. Components: `fixed_effects` (one row per
#'   fixed term, columns `term` and `coefficient`), `variance_components` (one
#'   row for each of `random_intercept`, `random_slope` and `residual`,
#'   columns `component` and `variance` -- the *squared* standard deviations
#'   supplied as arguments), and `random_effects` (one row per cluster,
#'   columns `cluster`, `random_intercept` and `random_slope`; the
#'   `random_slope` column is present but zero when `random_slope_sd = 0`).
#' @export
#'
#' @examples
#' # `slopes` must be named; the names become the predictor columns.
#' result <- simulate_multilevel(
#'   clusters = 30,
#'   cluster_size = 10,
#'   intercept = 1,
#'   slopes = c(x1 = 0.5),
#'   random_intercept_sd = 0.8,
#'   seed = 1
#' )
#' head(result)
#' as.data.frame(result, what = "fixed_effects")
#' as.data.frame(result, what = "variance_components")
simulate_multilevel <- function(clusters, cluster_size, intercept = 0,
                                slopes = numeric(0L), predictor_means = 0,
                                predictor_sds = 1, random_intercept_sd = 1,
                                random_slope_sd = 0,
                                random_effect_correlation = 0,
                                residual_sd = 1, seed = NULL) {
  stopifnot(
    "`clusters` must be a single whole number of at least 2" =
      is.numeric(clusters) &&
        length(clusters) == 1L &&
        all(clusters >= 2) &&
        all(clusters == as.integer(clusters)),
    "`cluster_size` must be a positive numeric vector, of whole numbers, with at least one element" =
      is.numeric(cluster_size) &&
        length(cluster_size) >= 1L &&
        all(cluster_size >= 1) &&
        all(cluster_size == as.integer(cluster_size)),
    "`intercept` must be a single number" =
      is.numeric(intercept) &&
        length(intercept) == 1L,
    "`slopes` must be a numeric vector" =
      is.numeric(slopes),
    "`predictor_means` must be a numeric vector" =
      is.numeric(predictor_means),
    "`predictor_sds` must be a numeric vector" =
      is.numeric(predictor_sds),
    "`random_intercept_sd` must be a single non-negative number" =
      is.numeric(random_intercept_sd) &&
        length(random_intercept_sd) == 1L &&
        all(random_intercept_sd >= 0),
    "`random_slope_sd` must be a single non-negative number" =
      is.numeric(random_slope_sd) &&
        length(random_slope_sd) == 1L &&
        all(random_slope_sd >= 0),
    "`random_effect_correlation` must be a single correlation between -1 and 1" =
      is.numeric(random_effect_correlation) &&
        length(random_effect_correlation) == 1L &&
        all(abs(random_effect_correlation) <= 1),
    "`residual_sd` must be a single positive number" =
      is.numeric(residual_sd) &&
        length(residual_sd) == 1L &&
        all(residual_sd > 0),
    "`seed` must be NULL or a single number" =
      is.null(seed) || (is.numeric(seed) && length(seed) == 1L)
  )
  clusters <- as.integer(clusters)
  if (length(cluster_size) == 1L) cluster_size <- rep(cluster_size, clusters)
  if (length(cluster_size) != clusters) stop("cluster_size must be scalar or one per cluster.", call. = FALSE)
  if (length(slopes) && (is.null(names(slopes)) || any(!nzchar(names(slopes))))) {
    stop("slopes must be named.", call. = FALSE)
  }
  predictors <- length(slopes)
  if (random_slope_sd > 0 && predictors == 0L) {
    stop("A random slope requires at least one fixed-effect predictor.", call. = FALSE)
  }
  if (length(predictor_means) == 1L) predictor_means <- rep(predictor_means, predictors)
  if (length(predictor_sds) == 1L) predictor_sds <- rep(predictor_sds, predictors)
  if (length(predictor_means) != predictors || length(predictor_sds) != predictors ||
      any(predictor_sds <= 0)) stop("Predictor parameters must match slopes.", call. = FALSE)
  cluster_id <- rep(seq_len(clusters), times = as.integer(cluster_size))
  n <- length(cluster_id)
  generated <- .with_seed(seed, {
    random_correlation <- matrix(
      c(1, random_effect_correlation, random_effect_correlation, 1), 2L, 2L
    )
    random_effects <- .draw_multivariate_normal(
      clusters, c(0, 0), c(random_intercept_sd, random_slope_sd), random_correlation
    )
    random_intercepts <- random_effects[, 1L]
    random_slopes <- random_effects[, 2L]
    x <- if (predictors) {
      vapply(seq_len(predictors), function(index) {
        stats::rnorm(n, predictor_means[index], predictor_sds[index])
      }, numeric(n))
    } else matrix(numeric(0L), n, 0L)
    linear <- intercept + random_intercepts[cluster_id]
    if (predictors) linear <- linear + as.vector(x %*% slopes)
    if (predictors && random_slope_sd > 0) {
      linear <- linear + random_slopes[cluster_id] * x[, 1L]
    }
    y <- linear + stats::rnorm(n, sd = residual_sd)
    list(random_intercepts = random_intercepts, random_slopes = random_slopes,
         x = x, y = y)
  })
  data <- data.frame(id = seq_len(n), cluster = cluster_id, generated$x,
                     outcome = generated$y, check.names = FALSE, row.names = NULL)
  names(data) <- c("id", "cluster", names(slopes), "outcome")
  fixed <- data.frame(term = c("(Intercept)", names(slopes)),
                      coefficient = c(intercept, slopes), row.names = NULL)
  variance <- data.frame(
    component = c("random_intercept", "random_slope", "residual"),
    variance = c(random_intercept_sd^2, random_slope_sd^2, residual_sd^2),
    row.names = NULL
  )
  random_effects <- data.frame(cluster = seq_len(clusters),
                               random_intercept = generated$random_intercepts,
                               random_slope = generated$random_slopes,
                               row.names = NULL)
  .new_simulab_sim(data, "multilevel", seed,
                   list(fixed_effects = fixed, variance_components = variance,
                        random_effects = random_effects))
}

#' Simulate longitudinal growth trajectories
#'
#' Draws per-unit random growth coefficients, then forms the outcome at each
#' measurement occasion as
#' `(intercept + b0) + (slope + b1) * time + (quadratic + b2) * time^2` plus
#' normal residual noise, where `b2` is present only when `random_sd` has
#' three elements. Every unit is observed at every occasion (balanced design).
#'
#' @param n Number of units. A single whole number of at least 2.
#' @param times Measurement occasions: a finite numeric vector of at least two
#'   unique values, used verbatim as the `time` predictor (so `0:4` puts the
#'   intercept at the first occasion).
#' @param intercept,slope,quadratic Fixed growth coefficients, each a single
#'   number; they default to `0`, `1` and `0`.
#' @param random_sd Standard deviations for the random intercept, slope, and
#'   optional quadratic term. A non-negative numeric vector of length 2 (the
#'   default, `c(1, 0.25)`) or 3.
#' @param random_correlation Correlation matrix for the random effects,
#'   matching the length of `random_sd`, or a tidy data frame with columns
#'   `row`, `column` and `correlation`. `NULL` (the default) makes the random
#'   effects uncorrelated.
#' @param residual_sd Residual standard deviation. A single positive number,
#'   defaulting to `1`.
#' @param seed Optional random seed.
#'
#' @return A long-form `simulab_sim` base `data.frame` with one row per
#'   unit-occasion (`n * length(times)` rows) and columns `id`, `time` and
#'   `outcome`. Rows are ordered by occasion first and unit second. A
#'   `parameters` component holds one row for each of `intercept`, `slope`,
#'   `quadratic` and `residual_sd`, with columns `term` and `value` (note that
#'   `residual_sd` is a standard deviation, and that the random-effect
#'   standard deviations are not repeated there). A `random_effects` component
#'   holds one row per unit with columns `id`, `intercept`, `slope` and, when
#'   `random_sd` has three elements, `quadratic`, giving each unit's deviation
#'   from the fixed coefficients.
#' @export
#'
#' @examples
#' result <- simulate_growth(
#'   n = 100, times = 0:4, intercept = 10, slope = 0.5, seed = 1
#' )
#' head(result)
#' as.data.frame(result, what = "parameters")
simulate_growth <- function(n, times, intercept = 0, slope = 1, quadratic = 0,
                            random_sd = c(1, 0.25), random_correlation = NULL,
                            residual_sd = 1, seed = NULL) {
  random_correlation <- .tidy_to_symmetric(
    random_correlation, "random_correlation", "row", "column", "correlation",
    diagonal = 1
  )
  stopifnot(
    "`n` must be a single whole number of at least 2" =
      is.numeric(n) &&
        length(n) == 1L &&
        all(n >= 2) &&
        all(n == as.integer(n)),
    "`times` must be a finite numeric vector of at least two unique values" =
      is.numeric(times) &&
        length(times) >= 2L &&
        all(is.finite(times)) &&
        !anyDuplicated(times),
    "`intercept` must be a single number" =
      is.numeric(intercept) &&
        length(intercept) == 1L,
    "`slope` must be a single number" =
      is.numeric(slope) &&
        length(slope) == 1L,
    "`quadratic` must be a single number" =
      is.numeric(quadratic) &&
        length(quadratic) == 1L,
    "`random_sd` must be a non-negative numeric vector, of length 2 or 3" =
      is.numeric(random_sd) &&
        all(length(random_sd) %in% c(2L, 3L)) &&
        all(random_sd >= 0),
    "`random_correlation` must be NULL or a matrix" =
      is.null(random_correlation) || is.matrix(random_correlation),
    "`residual_sd` must be a single positive number" =
      is.numeric(residual_sd) &&
        length(residual_sd) == 1L &&
        all(residual_sd > 0),
    "`seed` must be NULL or a single number" =
      is.null(seed) || (is.numeric(seed) && length(seed) == 1L)
  )
  effects <- length(random_sd)
  if (is.null(random_correlation)) random_correlation <- diag(effects)
  random_correlation <- .validate_correlation_matrix(random_correlation)
  if (nrow(random_correlation) != effects) stop("random_correlation must match random_sd.", call. = FALSE)
  generated <- .with_seed(seed, {
    random <- .draw_multivariate_normal(as.integer(n), rep(0, effects),
                                        random_sd, random_correlation)
    grid <- expand.grid(id = seq_len(as.integer(n)), time = times,
                        KEEP.OUT.ATTRS = FALSE)
    random_mean <- random[grid$id, 1L] + random[grid$id, 2L] * grid$time
    if (effects == 3L) random_mean <- random_mean + random[grid$id, 3L] * grid$time^2
    fixed_mean <- intercept + slope * grid$time + quadratic * grid$time^2
    grid$outcome <- fixed_mean + random_mean + stats::rnorm(nrow(grid), sd = residual_sd)
    list(data = grid, random = random)
  })
  random_names <- c("intercept", "slope", "quadratic")[seq_len(effects)]
  random_table <- data.frame(id = seq_len(as.integer(n)), generated$random,
                             check.names = FALSE, row.names = NULL)
  names(random_table) <- c("id", random_names)
  parameters <- data.frame(term = c("intercept", "slope", "quadratic", "residual_sd"),
                           value = c(intercept, slope, quadratic, residual_sd), row.names = NULL)
  .new_simulab_sim(generated$data, "growth", seed,
                   list(parameters = parameters, random_effects = random_table))
}

#' Simulate a multivariate longitudinal VAR process
#'
#' Draws a person mean for each unit from `between_covariance` around
#' `grand_means`, then runs a first-order vector autoregression on the
#' deviations from that person mean:
#' `y_t = mu + intercept + transition %*% (y_{t-1} - mu) + e_t`, with `e_t`
#' drawn from `innovation_covariance`. The first `burn_in` occasions are
#' discarded so the retained occasions are near stationarity.
#'
#' @param n Number of units. A single positive whole number.
#' @param occasions Number of occasions retained per unit. A single whole
#'   number of at least 2.
#' @param transition Lag-one coefficients as a square matrix, or as a tidy
#'   data frame with columns `from`, `to` and `coefficient` (`from` supplies
#'   the matrix row and `to` the column). Entry `[i, j]` multiplies variable
#'   `j` at the previous occasion when forming variable `i` at the current
#'   occasion, so rows index the *receiving* variable and columns the
#'   *predicting* variable. The spectral radius must be below one.
#' @param intercept Variable intercepts, a scalar recycled across variables
#'   (the default, `0`) or one value per variable. The intercept is added to
#'   the deviation from the person mean at every occasion, so a non-zero
#'   intercept shifts the stationary mean to
#'   `person_mean + solve(diag(p) - transition) %*% intercept` and the
#'   `person_means` component is then no longer the realised process mean.
#' @param innovation_covariance Innovation covariance matrix, or a tidy data
#'   frame with columns `row`, `column` and `covariance`. Must be symmetric
#'   and positive semidefinite. `NULL` (the default) uses the identity.
#' @param initial_covariance Initial-state covariance matrix, or a tidy data
#'   frame with columns `row`, `column` and `covariance`. `NULL` (the default)
#'   reuses `innovation_covariance`.
#' @param between_covariance Between-unit covariance of person means, or a
#'   tidy data frame with columns `row`, `column` and `covariance`. `NULL`
#'   (the default) is a zero matrix, giving every unit the same person mean,
#'   `grand_means`.
#' @param grand_means Population means, a scalar recycled across variables
#'   (the default, `0`) or one value per variable.
#' @param beeps_per_day Optional number of occasions per day; `occasions` must
#'   be divisible by it. Adds `day` and `beep` columns to the returned data.
#'   Temporal carryover resets at each day boundary.
#' @param burn_in Warm-up occasions generated and then discarded before
#'   output. A single non-negative whole number, defaulting to `50`.
#' @param seed Optional random seed.
#'
#' @return A long-form `simulab_sim` base `data.frame` with one row per
#'   unit-occasion (`n * occasions` rows) and columns `id`, `occasion` and one
#'   per variable, plus `day` and `beep` when `beeps_per_day` is supplied.
#'   Components: `wide` (one row per unit, one `<variable>.<occasion>` column
#'   per measurement), `transition`, `innovation_covariance` and
#'   `between_covariance` (tidy matrix tables with columns `row`, `column` and
#'   `coefficient` or `covariance`), and `person_means` (one row per unit with
#'   columns `id` and one per variable).
#' @export
#'
#' @examples
#' # `transition` is the lag-one coefficient matrix of the VAR process.
#' result <- simulate_longitudinal(
#'   n = 20,
#'   occasions = 30,
#'   transition = matrix(c(0.5, 0.1, 0.0, 0.4), nrow = 2, byrow = TRUE),
#'   seed = 1
#' )
#' head(result)
#' components(result)
simulate_longitudinal <- function(n, occasions, transition, intercept = 0,
                                  innovation_covariance = NULL,
                                  initial_covariance = NULL,
                                  between_covariance = NULL, grand_means = 0,
                                  beeps_per_day = NULL, burn_in = 50L,
                                  seed = NULL) {
  ## `from` is the driving variable at t-1 and `to` the driven variable at t.
  ## The recursion below is `transition %*% (previous - unit_mean)`, so the ROW
  ## indexes the driven variable: `to` supplies rows and `from` supplies
  ## columns, not the other way round. Both axes are forced onto one shared
  ## level set so the matrix stays square and its rows and columns agree even
  ## when the table lists the pairs in an unusual order.
  if (is.data.frame(transition)) {
    .require_columns(transition, c("from", "to", "coefficient"), "transition")
    variables <- unique(c(as.character(transition$to), as.character(transition$from)))
    transition <- .tidy_to_matrix(transition, "transition", "to", "from",
                                  "coefficient", row_levels = variables,
                                  column_levels = variables)
  }
  innovation_covariance <- .tidy_to_symmetric(
    innovation_covariance, "innovation_covariance", "row", "column", "covariance"
  )
  initial_covariance <- .tidy_to_symmetric(
    initial_covariance, "initial_covariance", "row", "column", "covariance"
  )
  between_covariance <- .tidy_to_symmetric(
    between_covariance, "between_covariance", "row", "column", "covariance"
  )
  stopifnot(
    "`n` must be a single positive whole number" =
      is.numeric(n) &&
        length(n) == 1L &&
        all(n >= 1) &&
        all(n == as.integer(n)),
    "`occasions` must be a single whole number of at least 2" =
      is.numeric(occasions) &&
        length(occasions) == 1L &&
        all(occasions >= 2) &&
        all(occasions == as.integer(occasions)),
    "`transition` must be a matrix" =
      is.matrix(transition) &&
        is.numeric(transition) &&
        nrow(transition) == ncol(transition),
    "`intercept` must be a numeric vector" =
      is.numeric(intercept),
    "`innovation_covariance` must be NULL or a matrix" =
      is.null(innovation_covariance) || is.matrix(innovation_covariance),
    "`initial_covariance` must be NULL or a matrix" =
      is.null(initial_covariance) || is.matrix(initial_covariance),
    "`between_covariance` must be NULL or a matrix" =
      is.null(between_covariance) || is.matrix(between_covariance),
    "`grand_means` must be a numeric vector" =
      is.numeric(grand_means),
    "`beeps_per_day` must be NULL or a single positive whole number" =
      is.null(beeps_per_day) || (is.numeric(beeps_per_day) && length(beeps_per_day) == 1L && beeps_per_day >= 1 && beeps_per_day == as.integer(beeps_per_day)),
    "`burn_in` must be a single non-negative whole number" =
      is.numeric(burn_in) &&
        length(burn_in) == 1L &&
        all(burn_in >= 0) &&
        all(burn_in == as.integer(burn_in)),
    "`seed` must be NULL or a single number" =
      is.null(seed) || (is.numeric(seed) && length(seed) == 1L)
  )
  variables <- nrow(transition)
  if (max(Mod(eigen(transition, only.values = TRUE)$values)) >= 1) {
    stop("transition must define a stable process with spectral radius below one.", call. = FALSE)
  }
  if (length(intercept) == 1L) intercept <- rep(intercept, variables)
  if (length(intercept) != variables) stop("intercept must match transition dimensions.", call. = FALSE)
  if (is.null(innovation_covariance)) innovation_covariance <- diag(variables)
  if (is.null(initial_covariance)) initial_covariance <- innovation_covariance
  if (is.null(between_covariance)) between_covariance <- matrix(0, variables, variables)
  if (length(grand_means) == 1L) grand_means <- rep(grand_means, variables)
  if (length(grand_means) != variables) stop("grand_means must match variables.", call. = FALSE)
  if (!is.null(beeps_per_day) && occasions %% beeps_per_day != 0L) {
    stop("occasions must be divisible by beeps_per_day.", call. = FALSE)
  }
  innovation_covariance <- .validate_covariance_matrix(innovation_covariance, variables,
                                                        "innovation_covariance")
  initial_covariance <- .validate_covariance_matrix(initial_covariance, variables,
                                                     "initial_covariance")
  between_covariance <- .validate_covariance_matrix(between_covariance, variables,
                                                     "between_covariance")
  variable_names <- rownames(transition)
  if (is.null(variable_names)) variable_names <- sprintf("variable_%d", seq_len(variables))
  total <- as.integer(occasions + burn_in)
  generated <- .with_seed(seed, {
    person_means <- .draw_multivariate_covariance(
      as.integer(n), grand_means, between_covariance
    )
    values <- lapply(seq_len(as.integer(n)), function(id) {
    unit_mean <- person_means[id, ]
    initial <- .draw_multivariate_covariance(1L, unit_mean, initial_covariance)
    states <- Reduce(function(previous, occasion) {
      innovation <- as.vector(.draw_multivariate_covariance(
        1L, rep(0, variables), innovation_covariance
      ))
      day_break <- !is.null(beeps_per_day) && occasion > burn_in &&
        ((occasion - burn_in - 1L) %% beeps_per_day == 0L)
      if (day_break) as.vector(unit_mean + innovation) else
        as.vector(unit_mean + intercept + transition %*% (previous - unit_mean) + innovation)
    }, seq_len(total - 1L), init = as.vector(initial), accumulate = TRUE)
    matrix(unlist(states, use.names = FALSE), ncol = variables, byrow = TRUE)
    })
    list(values = values, person_means = person_means)
  })
  retained <- lapply(generated$values, function(values) utils::tail(values, as.integer(occasions)))
  long <- do.call(rbind, Map(function(id, values) {
    data.frame(id = id, occasion = seq_len(as.integer(occasions)), values,
               check.names = FALSE, row.names = NULL)
  }, seq_len(as.integer(n)), retained))
  names(long) <- c("id", "occasion", variable_names)
  if (!is.null(beeps_per_day)) {
    long$day <- (long$occasion - 1L) %/% as.integer(beeps_per_day) + 1L
    long$beep <- (long$occasion - 1L) %% as.integer(beeps_per_day) + 1L
    long <- long[, c("id", "occasion", "day", "beep", variable_names), drop = FALSE]
  }
  wide <- reshape(long, idvar = "id", timevar = "occasion", direction = "wide")
  rownames(wide) <- NULL
  dimnames(transition) <- list(variable_names, variable_names)
  dimnames(innovation_covariance) <- list(variable_names, variable_names)
  dimnames(between_covariance) <- list(variable_names, variable_names)
  person_means <- data.frame(id = seq_len(as.integer(n)), generated$person_means,
                             check.names = FALSE, row.names = NULL)
  names(person_means) <- c("id", variable_names)
  .new_simulab_sim(long, "longitudinal_var", seed,
                   list(wide = wide,
                        transition = .matrix_to_table(transition, "coefficient"),
                        innovation_covariance = .matrix_to_table(
                          innovation_covariance, "covariance"),
                        between_covariance = .matrix_to_table(
                          between_covariance, "covariance"),
                        person_means = person_means))
}

.validate_covariance_matrix <- function(value, dimensions, name) {
  stopifnot(
    "`value` must be a matrix" =
      is.matrix(value),
    "`dimensions` must be a numeric vector" =
      is.numeric(dimensions),
    "`name` must be a character vector" =
      is.character(name)
  )
  if (!is.numeric(value) || any(dim(value) != dimensions) ||
      max(abs(value - t(value))) > 1e-8 ||
      min(eigen(value, symmetric = TRUE, only.values = TRUE)$values) < -1e-8) {
    stop(sprintf("%s must be a symmetric positive-semidefinite matrix of the required size.", name),
         call. = FALSE)
  }
  value
}

.draw_multivariate_covariance <- function(n, means, covariance) {
  stopifnot(
    "`n` must be a numeric vector" =
      is.numeric(n),
    "`means` must be a numeric vector" =
      is.numeric(means),
    "`covariance` must be a matrix" =
      is.matrix(covariance)
  )
  decomposition <- eigen(covariance, symmetric = TRUE)
  root <- decomposition$vectors %*% diag(sqrt(pmax(decomposition$values, 0)), nrow(covariance))
  noise <- matrix(stats::rnorm(as.integer(n) * length(means)), as.integer(n), length(means))
  sweep(noise %*% t(root), 2L, means, `+`)
}
