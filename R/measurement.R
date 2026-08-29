#' Simulate item-response data
#'
#' @param n Number of respondents.
#' @param discrimination Positive item discriminations.
#' @param difficulty Item difficulties. A vector gives dichotomous items; a
#'   matrix gives ordered thresholds by item.
#' @param dimensions Item-by-dimension loading weights. `NULL` uses one
#'   dimension.
#' @param ability_correlation Latent ability correlation matrix.
#' @param model Logistic model: Rasch, 2PL, 3PL, or graded response.
#' @param guessing Lower-asymptote guessing parameters for 3PL items.
#' @param seed Optional random seed.
#'
#' @return A `simulab_sim` base `data.frame` with responses and true parameters.
#' @export
#'
#' @examples
#' result <- simulate_irt(
#'   n = 200,
#'   discrimination = c(1, 1.2, 0.8),
#'   difficulty = c(-1, 0, 1),
#'   seed = 1
#' )
#' head(result)
#' as.data.frame(result, what = "parameters")
#'
#' # Three-parameter logistic with a guessing floor.
#' head(simulate_irt(
#'   n = 200,
#'   discrimination = c(1, 1.2, 0.8),
#'   difficulty = c(-1, 0, 1),
#'   model = "3pl",
#'   guessing = 0.2,
#'   seed = 1
#' ))
simulate_irt <- function(n, discrimination = 1, difficulty,
                         dimensions = NULL, ability_correlation = NULL,
                         model = c("2pl", "rasch", "3pl", "graded"),
                         guessing = 0.2, seed = NULL) {
  model <- match.arg(model)
  stopifnot(
    "`n` must be a single whole number of at least 2" =
      is.numeric(n) &&
        length(n) == 1L &&
        all(n >= 2) &&
        all(n == as.integer(n)),
    "`discrimination` must be a finite positive numeric vector" =
      is.numeric(discrimination) &&
        all(is.finite(discrimination)) &&
        all(discrimination > 0),
    "`difficulty` must be a numeric vector" =
      is.numeric(difficulty),
    "`guessing` must be a finite numeric vector" =
      is.numeric(guessing) &&
        all(is.finite(guessing)),
    "`dimensions` must be NULL or a matrix" =
      is.null(dimensions) || is.matrix(dimensions),
    "`ability_correlation` must be NULL or a matrix" =
      is.null(ability_correlation) || is.matrix(ability_correlation),
    "`seed` must be NULL or a single number" =
      is.null(seed) || (is.numeric(seed) && length(seed) == 1L)
  )
  items <- if (is.matrix(difficulty)) nrow(difficulty) else length(difficulty)
  if (length(discrimination) == 1L) discrimination <- rep(discrimination, items)
  if (length(guessing) == 1L) guessing <- rep(guessing, items)
  if (length(discrimination) != items) stop("discrimination must match the items.", call. = FALSE)
  if (length(guessing) != items || any(guessing < 0 | guessing >= 1)) {
    stop("guessing must contain values from zero up to, but not including, one.", call. = FALSE)
  }
  if (model != "3pl") guessing <- rep(0, items)
  if (model == "rasch" && any(abs(discrimination - 1) > 1e-12)) {
    stop("Rasch discrimination must equal one.", call. = FALSE)
  }
  if (is.null(dimensions)) dimensions <- matrix(1, items, 1L)
  if (!is.numeric(dimensions) || nrow(dimensions) != items ||
      any(rowSums(abs(dimensions)) == 0)) {
    stop("dimensions must contain one non-zero loading row per item.", call. = FALSE)
  }
  dimensions_count <- ncol(dimensions)
  normalized_dimensions <- dimensions / sqrt(rowSums(dimensions^2))
  if (is.null(ability_correlation)) ability_correlation <- diag(dimensions_count)
  ability_correlation <- .validate_correlation_matrix(ability_correlation)
  if (nrow(ability_correlation) != dimensions_count) {
    stop("ability_correlation must match dimensions.", call. = FALSE)
  }
  if (model == "graded" && !is.matrix(difficulty)) {
    stop("Graded items require an item-by-threshold difficulty matrix.", call. = FALSE)
  }
  if (is.matrix(difficulty) &&
      any(apply(difficulty, 1L, function(values) is.unsorted(values, strictly = TRUE)))) {
    stop("Graded thresholds must increase within item.", call. = FALSE)
  }
  item_names <- if (!is.null(rownames(dimensions))) rownames(dimensions) else sprintf("item_%d", seq_len(items))
  ability_names <- if (!is.null(colnames(dimensions))) colnames(dimensions) else sprintf("theta_%d", seq_len(dimensions_count))
  generated <- .with_seed(seed, {
    abilities <- .draw_multivariate_normal(as.integer(n), rep(0, dimensions_count),
                                           rep(1, dimensions_count), ability_correlation)
    trait <- abilities %*% t(normalized_dimensions)
    responses <- if (model != "graded") {
      probabilities <- stats::plogis(sweep(trait, 2L, difficulty, `-`) *
                                        rep(discrimination, each = as.integer(n)))
      probabilities <- sweep(probabilities, 2L, 1 - guessing, `*`)
      probabilities <- sweep(probabilities, 2L, guessing, `+`)
      matrix(stats::rbinom(length(probabilities), 1L, probabilities),
             as.integer(n), items)
    } else {
      vapply(seq_len(items), function(item) {
        cumulative <- vapply(difficulty[item, ], function(threshold) {
          stats::plogis(discrimination[item] * (trait[, item] - threshold))
        }, numeric(as.integer(n)))
        probabilities <- cbind(1, cumulative) - cbind(cumulative, 0)
        vapply(seq_len(as.integer(n)), function(person) {
          sample.int(ncol(probabilities), 1L, prob = probabilities[person, ]) - 1L
        }, integer(1))
      }, integer(as.integer(n)))
    }
    list(abilities = abilities, responses = responses)
  })
  data <- data.frame(id = seq_len(as.integer(n)), generated$responses,
                     check.names = FALSE, row.names = NULL)
  names(data) <- c("id", item_names)
  scores <- data.frame(id = seq_len(as.integer(n)), generated$abilities,
                       check.names = FALSE, row.names = NULL)
  names(scores) <- c("id", ability_names)
  parameters <- if (model == "graded") {
    index <- expand.grid(item = seq_len(items), threshold = seq_len(ncol(difficulty)))
    data.frame(item = item_names[index$item], parameter = "threshold",
               category = index$threshold,
               value = difficulty[cbind(index$item, index$threshold)],
               discrimination = discrimination[index$item], row.names = NULL)
  } else {
    data.frame(item = item_names, parameter = "difficulty", category = NA_integer_,
               value = difficulty, discrimination = discrimination,
               guessing = guessing, row.names = NULL)
  }
  .new_simulab_sim(data, paste0("irt_", model), seed,
                   list(parameters = parameters, abilities = scores))
}

#' Simulate a hidden Markov model
#'
#' @param n Number of sequences.
#' @param transition Hidden-state transition matrix.
#' @param chain_length Sequence length.
#' @param emission Hidden-state-by-observed-category probability matrix.
#' @param initial Initial hidden-state probabilities.
#' @param state_labels,observation_labels Optional labels.
#' @param seed Optional random seed.
#'
#' @return A long-form `simulab_sim` base `data.frame` with observed and true
#'   hidden states, plus tidy parameter tables.
#' @export
#'
#' @examples
#' result <- simulate_hmm(
#'   n = 50,
#'   transition = matrix(c(0.7, 0.3, 0.4, 0.6), nrow = 2, byrow = TRUE),
#'   chain_length = 20,
#'   emission = matrix(c(0.9, 0.1, 0.2, 0.8), nrow = 2, byrow = TRUE),
#'   seed = 1
#' )
#' head(result)
#' components(result)
simulate_hmm <- function(n, transition, chain_length, emission, initial = NULL,
                         state_labels = NULL, observation_labels = NULL,
                         seed = NULL) {
  stopifnot(
    "`n` must be a single positive whole number" =
      is.numeric(n) &&
        length(n) == 1L &&
        all(n >= 1) &&
        all(n == as.integer(n)),
    "`transition` must be a matrix" =
      is.matrix(transition) &&
        is.numeric(transition),
    "`chain_length` must be a single positive whole number" =
      is.numeric(chain_length) &&
        length(chain_length) == 1L &&
        all(chain_length >= 1) &&
        all(chain_length == as.integer(chain_length)),
    "`emission` must be a matrix" =
      is.matrix(emission) &&
        is.numeric(emission),
    "`initial` must be NULL or a numeric vector" =
      is.null(initial) || is.numeric(initial),
    "`seed` must be NULL or a single number" =
      is.null(seed) || (is.numeric(seed) && length(seed) == 1L)
  )
  states <- nrow(transition)
  if (ncol(transition) != states || nrow(emission) != states ||
      any(transition < 0) || any(emission < 0) ||
      any(abs(rowSums(transition) - 1) > 1e-8) ||
      any(abs(rowSums(emission) - 1) > 1e-8)) {
    stop("Transition and emission rows must be valid probability distributions.", call. = FALSE)
  }
  if (is.null(initial)) initial <- c(1, rep(0, states - 1L))
  if (length(initial) != states || any(initial < 0) || abs(sum(initial) - 1) > 1e-8) {
    stop("initial must contain one probability per hidden state.", call. = FALSE)
  }
  if (is.null(state_labels)) state_labels <- sprintf("State %d", seq_len(states))
  observed <- ncol(emission)
  if (is.null(observation_labels)) observation_labels <- sprintf("Observation %d", seq_len(observed))
  if (length(state_labels) != states || anyDuplicated(state_labels) ||
      length(observation_labels) != observed || anyDuplicated(observation_labels)) {
    stop("State and observation labels must match their matrices and be unique.", call. = FALSE)
  }
  chains <- .with_seed(seed, lapply(seq_len(as.integer(n)), function(id) {
    hidden <- .simulate_one_chain(transition, seq_len(states), as.integer(chain_length),
                                  sample.int(states, 1L, prob = initial))
    observations <- vapply(hidden, function(state) {
      sample.int(observed, 1L, prob = emission[state, ])
    }, integer(1))
    data.frame(id = id, occasion = seq_along(hidden),
               state = state_labels[hidden], observation = observation_labels[observations],
               stringsAsFactors = FALSE, row.names = NULL)
  }))
  data <- do.call(rbind, chains)
  transition_table <- .matrix_to_table(transition, "probability", state_labels, state_labels)
  names(transition_table)[1:2] <- c("from", "to")
  emission_table <- .matrix_to_table(emission, "probability", state_labels, observation_labels)
  names(emission_table)[1:2] <- c("state", "observation")
  initial_table <- data.frame(state = state_labels, probability = initial, row.names = NULL)
  .new_simulab_sim(data, "hmm", seed,
                   list(transitions = transition_table, emissions = emission_table,
                        initial_probabilities = initial_table))
}
