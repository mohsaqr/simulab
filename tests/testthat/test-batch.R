# `batch = n` on every single-dataset simulator returns a plain list of n
# results. The sweep reads its cases from `.seed_contract_calls()`
# (helper-seed-contract.R), which is itself checked against the registry.

.replicating_verbs <- c("sequence_batches", "tna_batches", "network_batches",
                        "scenarios")

.batch_verbs <- function() {
  setdiff(list_simulators(dispatchable = TRUE)$simulator, .replicating_verbs)
}

.ttest_batch <- function(...) {
  simulate_ttest(n_a = 5, n_b = 5, mean_a = 0, mean_b = 1, ...)
}

test_that("every single-dataset simulator takes `batch`, and only those", {
  catalogue <- list_simulators(dispatchable = TRUE)
  has_batch <- vapply(catalogue$function_name, function(name) {
    "batch" %in% names(formals(get(name, envir = asNamespace("simulab"))))
  }, logical(1))
  expect_setequal(catalogue$simulator[has_batch], .batch_verbs())
  expect_setequal(catalogue$simulator[!has_batch], .replicating_verbs)
})

test_that("a seeded batch is a reproducible list of standalone results", {
  calls <- .seed_contract_calls()[.batch_verbs()]
  if (!requireNamespace("tna", quietly = TRUE)) {
    calls <- calls[setdiff(names(calls), "group_tna")]
  }

  set.seed(1)
  checked <- vapply(names(calls), function(type) {
    arguments <- c(list(type = type), calls[[type]], list(seed = 99))

    before <- .Random.seed
    first <- do.call(simulate_data, c(arguments, list(batch = 2)))
    after <- .Random.seed
    second <- do.call(simulate_data, c(arguments, list(batch = 2)))

    is_plain_list <- identical(class(first), "list") && length(first) == 2L &&
      all(vapply(first, inherits, logical(1), what = "simulab_sim"))
    standalone <- all(vapply(first, function(dataset) {
      alone <- do.call(simulate_data, c(arguments[names(arguments) != "seed"],
                                        list(seed = attr(dataset, "simulab_seed"))))
      identical(dataset, alone)
    }, logical(1)))
    info <- sprintf("verb `%s`", type)
    expect_true(is_plain_list, info = info)
    expect_true(standalone, info = info)
    expect_identical(first, second, info = info)
    expect_identical(before, after, info = info)
    is_plain_list && standalone && identical(first, second) && identical(before, after)
  }, logical(1))

  expect_true(all(checked))
  expect_length(checked, length(calls))
})

test_that("`batch = NULL` is the single-result call and `batch = 1` a list of it", {
  single <- .ttest_batch(seed = 3)
  expect_identical(.ttest_batch(seed = 3, batch = NULL), single)
  one <- .ttest_batch(seed = 3, batch = 1)
  expect_identical(class(one), "list")
  expect_length(one, 1L)
  expect_s3_class(one[[1L]], "simulab_sim")
})

test_that("the datasets in a batch are distinct draws", {
  seeded <- .ttest_batch(seed = 3, batch = 3)
  outcomes <- lapply(seeded, function(dataset) dataset$outcome)
  expect_false(identical(outcomes[[1L]], outcomes[[2L]]))
  expect_false(identical(outcomes[[2L]], outcomes[[3L]]))

  set.seed(4)
  before <- .Random.seed
  unseeded <- .ttest_batch(batch = 2)
  expect_false(identical(before, .Random.seed))
  expect_false(identical(unseeded[[1L]]$outcome, unseeded[[2L]]$outcome))
})

test_that("batch datasets do not share a verb's internal per-group seeds", {
  # simulate_group_sequences() seeds group k with seed + k - 1, so seed 2's
  # first group is seed 1's second group. Consecutive batch seeds would make
  # dataset 2 silently reuse dataset 1's draws.
  group_states <- function(result, group) {
    as.data.frame(result)$state[as.data.frame(result)$group == group]
  }
  expect_identical(
    group_states(simulate_group_sequences(groups = 2, actors = 3,
                                          chain_length = 6, seed = 2), "Group 1"),
    group_states(simulate_group_sequences(groups = 2, actors = 3,
                                          chain_length = 6, seed = 1), "Group 2")
  )

  batch <- simulate_group_sequences(groups = 2, actors = 3, chain_length = 6,
                                    seed = 1, batch = 2)
  expect_false(identical(group_states(batch[[2L]], "Group 1"),
                         group_states(batch[[1L]], "Group 2")))
})

test_that("arguments reach every dataset however the call is written", {
  reference <- .ttest_batch(seed = 7, batch = 3)
  expect_identical(simulate_ttest(5, 5, 0, 1, seed = 7, batch = 3), reference)
  expect_identical(simulate_data("ttest", n_a = 5, n_b = 5, mean_a = 0,
                                 mean_b = 1, seed = 7, batch = 3), reference)
  forward <- function(...) simulate_ttest(...)
  expect_identical(forward(n_a = 5, n_b = 5, mean_a = 0, mean_b = 1, seed = 7,
                           batch = 3), reference)
})

test_that("formula variables resolve in the frame that made the call", {
  make <- function() {
    slope <- 3
    specification <- define_variables(
      variable     = c("x", "y"),
      formula      = c("0", "slope * x"),
      variance     = c("1", "0.01"),
      distribution = c("normal", "normal")
    )
    simulate_study(n = 200, specification = specification, seed = 1, batch = 2)
  }
  datasets <- make()
  slopes <- vapply(datasets, function(dataset) {
    unname(stats::coef(stats::lm(y ~ x, data = dataset))[["x"]])
  }, numeric(1))
  expect_equal(slopes, c(3, 3), tolerance = 0.01)
})

test_that("an invalid `batch` is a classed error", {
  invalid <- list(0, -1, 2.5, "2", c(1, 2), NA, Inf, TRUE)
  lapply(invalid, function(value) {
    expect_error(.ttest_batch(batch = value), class = "simulab_invalid_batch")
  })
})
