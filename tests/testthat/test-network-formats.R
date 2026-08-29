test_that("simulate_edge_list returns exact tidy edges and complete components", {
  result <- simulate_edge_list(
    nodes = paste0("N", 1:10), edges = 18, directed = FALSE,
    weight = "uniform", weight_range = c(2, 3),
    edge_classes = c("support", "advice"), seed = 201
  )
  expect_s3_class(result, "simulab_sim")
  expect_equal(nrow(result), 18L)
  expect_true(all(c("from", "to", "weight", "edge_class") %in% names(result)))
  expect_true(all(result$weight >= 2 & result$weight <= 3))
  expect_false(anyDuplicated(data.frame(result$from, result$to)) > 0L)
  expect_equal(nrow(as.data.frame(result, what = "nodes")), 10L)
  expect_equal(nrow(as.data.frame(result, what = "adjacency")), 100L)

  loops <- simulate_edge_list(3, edges = 6, directed = FALSE, loops = TRUE,
                              seed = 202)
  expect_equal(nrow(loops), 6L)
  expect_true(any(loops$from == loops$to))
  expect_error(simulate_edge_list(3, edges = 7, directed = FALSE, loops = TRUE),
               "possible dyads")
})

test_that("simulate_temporal_network provides coherent spells, events, and snapshots", {
  persistent <- simulate_temporal_network(
    5, periods = 8, initial_probability = 1,
    formation_probability = 0, dissolution_probability = 0,
    directed = FALSE, seed = 210
  )
  expect_equal(nrow(persistent), choose(5, 2))
  expect_true(all(persistent$onset == 1L))
  expect_true(all(persistent$terminus == 9L))
  expect_true(all(persistent$censored))
  snapshots <- as.data.frame(persistent, what = "snapshots")
  expect_equal(nrow(snapshots), choose(5, 2) * 8L)
  expect_equal(sort(unique(snapshots$period)), 1:8)
  events <- as.data.frame(persistent, what = "events")
  expect_equal(as.integer(table(events$event)), choose(5, 2))

  changing <- simulate_temporal_network(
    6, periods = 12, initial_probability = 0.3,
    formation_probability = 0.4, dissolution_probability = 0.5,
    weight = "poisson", weight_mean = 3, seed = 211
  )
  expect_true(all(changing$onset < changing$terminus))
  expect_true(all(changing$terminus <= 13L))
  changing_events <- as.data.frame(changing, what = "events")
  expect_equal(sum(changing_events$event == "formation"), nrow(changing))
  expect_equal(sum(changing_events$event == "dissolution"), sum(!changing$censored))
  changing_snapshots <- as.data.frame(changing, what = "snapshots")
  expect_false(anyDuplicated(changing_snapshots[, c("period", "from", "to")]) > 0L)

  empty <- simulate_temporal_network(
    4, periods = 5, initial_probability = 0,
    formation_probability = 0, dissolution_probability = 1, seed = 212
  )
  expect_equal(nrow(empty), 0L)
  expect_equal(nrow(as.data.frame(empty, what = "events")), 0L)
  expect_equal(nrow(as.data.frame(empty, what = "snapshots")), 0L)
})

test_that("simulate_network_matrix enforces matrix-specific invariants", {
  transition <- simulate_network_matrix(
    7, type = "transition", probability = 0.15, seed = 220
  )
  expect_equal(nrow(transition), 49L)
  expect_equal(as.vector(tapply(transition$value, transition$from, sum)),
               rep(1, 7), tolerance = 1e-12)
  expect_true(all(transition$value[transition$from == transition$to] == 0))

  cooccurrence <- simulate_network_matrix(
    8, type = "cooccurrence", probability = 0.4,
    weight_range = c(1, 5), seed = 221
  )
  matrix_value <- stats::xtabs(value ~ from + to, cooccurrence)
  expect_equal(unname(unclass(matrix_value)), unname(t(unclass(matrix_value))))

  frequency <- simulate_network_matrix(
    6, type = "frequency", probability = 0.8,
    frequency_mean = 5, seed = 222
  )
  expect_true(all(frequency$value >= 0))
  expect_true(all(frequency$value == as.integer(frequency$value)))

  adjacency <- simulate_network_matrix(
    5, type = "adjacency", probability = 0.5,
    directed = FALSE, weighted = FALSE, seed = 223
  )
  expect_true(all(adjacency$value %in% c(0, 1)))
  adjacency_matrix <- unclass(stats::xtabs(value ~ from + to, adjacency))
  expect_equal(unname(adjacency_matrix), unname(t(adjacency_matrix)))
  expect_error(simulate_network_matrix(5, type = "transition", directed = FALSE),
               "must be directed")
})

test_that("simulate_bipartite_network contains only cross-mode edges", {
  result <- simulate_bipartite_network(
    actors = paste0("Student", 1:12), events = paste0("Course", 1:5),
    edges = 25, weight = "poisson", weight_mean = 4, seed = 230
  )
  expect_equal(nrow(result), 25L)
  expect_true(all(result$from_mode == "actor"))
  expect_true(all(result$to_mode == "event"))
  nodes <- as.data.frame(result, what = "nodes")
  expect_equal(as.vector(table(nodes$mode)), c(12, 5))
  incidence <- as.data.frame(result, what = "incidence")
  expect_equal(dim(incidence), c(12L, 6L))
  expect_false(anyDuplicated(result[, c("from", "to")]) > 0L)

  single <- simulate_bipartite_network(1, 3, edges = 2, seed = 231)
  expect_equal(nrow(single), 2L)
  expect_error(simulate_bipartite_network(c("A", "B"), c("B", "C")),
               "must be distinct")
})

test_that("simulate_multiplex_network preserves layer-specific controls", {
  result <- simulate_multiplex_network(
    nodes = 9, layers = c("advice", "collaboration", "friendship"),
    edges = c(8, 10, 12), directed = FALSE,
    probability = c(0.1, 0.2, 0.3), seed = 240
  )
  expect_equal(as.vector(table(result$layer)), c(8, 10, 12))
  expect_true(all(c("layer", "from", "to", "weight") %in% names(result)))
  expect_equal(nrow(as.data.frame(result, what = "layers")), 3L)
  expect_equal(nrow(as.data.frame(result, what = "nodes")), 9L)
  expect_equal(nrow(as.data.frame(result, what = "adjacency")), 3L * 9L^2)
  layer_table <- as.data.frame(result, what = "layers")
  expect_equal(layer_table$probability, c(0.1, 0.2, 0.3))
})

test_that("all five network formats are available through the unified dispatcher", {
  expected <- c("edge_list", "temporal_network", "network_matrix",
                "bipartite_network", "multiplex_network")
  expect_true(all(expected %in% list_simulators("network")$simulator))
  dispatched <- simulate_data(
    "bipartite_network", actors = 3, events = 2, edges = 4, seed = 250
  )
  expect_s3_class(dispatched, "simulab_sim")
  expect_equal(nrow(dispatched), 4L)
})
