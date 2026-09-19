# The seed contract is a package-wide promise: a seeded call reproduces itself
# exactly, and it leaves the caller's random-number stream untouched. The
# minimal-call table below is keyed by catalogue name so that a verb added to
# the registry without a case here fails the completeness test rather than
# silently escaping the sweep.
.seed_contract_calls <- function() {
  specification <- define_variables(
    variable     = c("baseline", "outcome"),
    formula      = c("0", "0.4 * baseline"),
    variance     = c("1", "1"),
    distribution = c("normal", "normal")
  )
  transition <- matrix(c(0.6, 0.4, 0.3, 0.7), nrow = 2, byrow = TRUE,
                       dimnames = list(c("a", "b"), c("a", "b")))
  emission <- matrix(c(0.8, 0.2, 0.25, 0.75), nrow = 2, byrow = TRUE,
                     dimnames = list(c("a", "b"), c("x", "y")))
  centers <- matrix(c(0, 0, 2, 2), nrow = 2, byrow = TRUE,
                    dimnames = list(c("c1", "c2"), c("x", "y")))
  panel <- data.frame(id = rep(1:3, each = 3), period = rep(1:3, 3))
  frame <- data.frame(x = seq(0, 1, length.out = 12), y = rnorm(12))

  list(
    study                 = list(n = 12, specification = specification),
    correlation           = list(n = 12),
    correlated            = list(n = 12, means = c(0, 0), rho = 0.3),
    # A copula draws its marginals from a joint uniform, so a marginal is
    # parameterized on its own and never refers to another variable.
    copula                = list(n = 12, rho = 0.4, specification = define_variables(
      score  = normal(mean = 10, sd = 2),
      visits = poisson(lambda = 4)
    )),
    ordinal               = list(n = 12, probabilities = c(0.3, 0.7)),
    ttest                 = list(n_a = 8, n_b = 8, mean_a = 0, mean_b = 0.5),
    anova                 = list(n = 8, means = c(0, 1, 2)),
    regression            = list(n = 12, coefficients = c("(Intercept)" = 1, x = 0.5)),
    clusters              = list(n = 12, centers = centers),
    lpa                   = list(n = 12, means = centers),
    ml_lpa                = list(clusters = 4, cluster_size = 3, means = centers,
                                 profile_probabilities = matrix(
                                   c(0.7, 0.3, 0.2, 0.8), nrow = 2, byrow = TRUE)),
    lca                   = list(n = 12, probabilities = array(
      c(0.8, 0.2, 0.3, 0.7, 0.2, 0.8, 0.7, 0.3), dim = c(2, 2, 2))),
    factors               = list(n = 12, loadings = matrix(c(0.7, 0.7, 0.6), ncol = 1)),
    multilevel            = list(clusters = 4, cluster_size = 3),
    growth                = list(n = 10, times = 0:3),
    # `transition` here is a VAR lag-one coefficient matrix, which must be
    # stationary -- not the row-stochastic matrix `markov` takes.
    longitudinal          = list(n = 6, occasions = 4, transition = matrix(
      c(0.5, 0.1, 0.0, 0.4), nrow = 2, byrow = TRUE)),
    irt                   = list(n = 10, difficulty = c(-1, 0, 1)),
    markov                = list(n = 6, transition = transition, chain_length = 4),
    transition_system     = list(n_states = 3),
    sequences             = list(n = 6, chain_length = 4, n_states = 3),
    sequence_clusters     = list(n = 6, transitions = list(transition, transition),
                                 chain_length = 4),
    hmm                   = list(n = 6, transition = transition, chain_length = 4,
                                 emission = emission),
    group_sequences       = list(groups = 2, actors = 3, chain_length = 4),
    group_tna             = list(groups = 2, actors = 3, chain_length = 4),
    event_log             = list(n = 6),
    until_event           = list(data = panel,
                                 definition = define_variable("event", 1,
                                                              distribution = "binary")),
    survival              = list(n = 10, specification = define_survivals(
      define_survival("time", formula = -8, shape = 0.3))),
    proportional_survival = list(n = 10, coefficients = c(x = 0.4)),
    prediction            = list(n = 12, coefficients = c("(Intercept)" = 1, x = 0.5)),
    synthetic             = list(data = frame),
    density               = list(n = 12, values = rnorm(40)),
    # A cubic basis over three interior knots takes knots + degree + 1 = 7
    # coefficients.
    spline                = list(data = frame, predictor = "x", variable = "fitted",
                                 coefficients = c(0.1, 0.2, 0.5, 0.4, 0.7, 0.6, 0.9)),
    network               = list(nodes = 6, edges = 5),
    edge_list             = list(nodes = 6, edges = 5),
    temporal_network      = list(nodes = 5, periods = 2),
    network_matrix        = list(nodes = 5),
    bipartite_network     = list(actors = 4, events = 3),
    multiplex_network     = list(nodes = 5, layers = 2),
    tna_network           = list(groups = 2, nodes_per_group = 3),
    sequence_batches      = list(repetitions = 2, n = 4, chain_length = 3,
                                 n_states = 2),
    tna_batches           = list(repetitions = 1, model = "tna", n = 6,
                                 chain_length = 4, n_states = 2),
    network_batches       = list(repetitions = 2, nodes = 5, edges = 3,
                                 directed = FALSE),
    scenarios             = list(scenarios = scenario_grid(mean_b = c(0, 1),
                                                           replications = 1),
                                 simulator = "ttest", n_a = 4, n_b = 4, mean_a = 0)
  )
}

test_that("the seed-contract sweep covers every dispatchable verb", {
  dispatchable <- list_simulators(dispatchable = TRUE)$simulator
  expect_setequal(names(.seed_contract_calls()), dispatchable)
})

test_that("a seeded call reproduces itself and restores the caller's RNG stream", {
  calls <- .seed_contract_calls()
  needs_tna <- "tna_batches"
  if (!requireNamespace("tna", quietly = TRUE)) {
    calls <- calls[setdiff(names(calls), needs_tna)]
  }

  set.seed(1)
  checked <- vapply(names(calls), function(type) {
    arguments <- c(list(type = type), calls[[type]], list(seed = 99))

    before <- .Random.seed
    first <- do.call(simulate_data, arguments)
    after <- .Random.seed
    second <- do.call(simulate_data, arguments)

    reproducible <- identical(as.data.frame(first), as.data.frame(second))
    restored <- identical(before, after)
    expect_true(reproducible)
    expect_true(restored)
    reproducible && restored
  }, logical(1))

  expect_true(all(checked))
  expect_gte(length(checked), 42L)
})

test_that("an unseeded call advances the caller's RNG stream", {
  set.seed(2)
  before <- .Random.seed
  simulate_ttest(n_a = 8, n_b = 8, mean_a = 0, mean_b = 0.5)
  expect_false(identical(before, .Random.seed))
})
