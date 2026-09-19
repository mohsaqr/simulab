test_that("the simulator catalogue covers the complete public generation surface", {
  catalogue <- list_simulators()
  exports <- getNamespaceExports("simulab")
  generation_exports <- grep("^(simulate|generate)_", exports, value = TRUE)

  expect_named(
    catalogue,
    c("simulator", "function_name", "kind", "family", "primary_shape",
      "dispatchable")
  )
  expect_equal(nrow(catalogue), length(generation_exports))
  expect_setequal(catalogue$function_name, generation_exports)
  expect_equal(anyDuplicated(catalogue$simulator), 0L)
  expect_equal(anyDuplicated(catalogue$function_name), 0L)
  expect_true(all(c("simulator", "generator", "workflow", "dispatcher") %in%
                    catalogue$kind))

  callable <- vapply(catalogue$function_name, function(name) {
    exists(name, envir = asNamespace("simulab"), mode = "function",
           inherits = FALSE)
  }, logical(1))
  expect_true(all(callable))
  expect_equal(catalogue$simulator[!catalogue$dispatchable], "data")
})

test_that("catalogue filters retain stable and intentional classifications", {
  expect_true(all(list_simulators(kind = "workflow")$kind == "workflow"))
  expect_true(all(list_simulators(family = "network")$family == "network"))
  expect_true(all(list_simulators(dispatchable = TRUE)$dispatchable))
  expect_equal(list_simulators(dispatchable = FALSE)$function_name, "simulate_data")

  expect_error(list_simulators(kind = "unknown"), "Unknown simulator kind")
  expect_error(list_simulators(dispatchable = NA), "must be a single logical")
  expect_error(simulate_data("not_registered"), "Unknown simulator")
  expect_error(simulate_data("data"), "cannot dispatch itself")
})

test_that("previously undiscoverable generators dispatch through the registry", {
  transition_system <- simulate_data(
    "transition_system", n_states = 3, seed = 301
  )
  expect_s3_class(transition_system, "simulab_sim")

  correlated <- simulate_data(
    "correlated", n = 20, means = c(0, 0), rho = 0.2, seed = 302
  )
  expect_equal(nrow(correlated), 20L)

  sequences <- simulate_data(
    "sequences", n = 4, chain_length = 5, n_states = 3, seed = 303
  )
  expect_equal(nrow(sequences), 20L)

  sequence_batches <- simulate_data(
    "sequence_batches", repetitions = 2, n = 3, chain_length = 4,
    n_states = 2, seed = 304
  )
  expect_equal(length(unique(sequence_batches$dataset)), 2L)

  network_batches <- simulate_data(
    "network_batches", repetitions = 2, nodes = 5, edges = 3,
    directed = FALSE, seed = 305
  )
  expect_equal(length(unique(network_batches$network)), 2L)

  until_event <- simulate_data(
    "until_event",
    data = data.frame(id = rep(1:2, each = 3), period = rep(1:3, 2)),
    definition = define_variable("event", 1, distribution = "binary"),
    seed = 306
  )
  expect_equal(nrow(until_event), 2L)

  scenarios <- simulate_data(
    "scenarios",
    scenarios = scenario_grid(mean_b = c(0, 1), replications = 1),
    simulator = "ttest", n_a = 3, n_b = 3, mean_a = 0, seed = 307
  )
  expect_equal(nrow(scenarios), 12L)
})

test_that("TNA batches use the same registry dispatch when tna is available", {
  skip_if_not_installed("tna", minimum_version = "1.2.3")
  result <- simulate_data(
    "tna_batches", repetitions = 1, model = "tna", n = 8,
    chain_length = 5, n_states = 2, seed = 308
  )
  expect_s3_class(result, "simulab_sim")
  expect_equal(unique(result$network), 1L)
})
