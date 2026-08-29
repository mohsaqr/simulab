# Every simulator returns tidy data, so every matrix or array argument also
# accepts the equivalent long-form data frame. These tests assert that the two
# call styles produce byte-identical results under the same seed, which is the
# only guarantee that matters: the tidy path must not be a second, subtly
# different implementation.

long_form <- function(m, row, column, value) {
  grid <- expand.grid(r = seq_len(nrow(m)), c = seq_len(ncol(m)))
  result <- data.frame(
    rownames(m)[grid$r], colnames(m)[grid$c], m[cbind(grid$r, grid$c)],
    stringsAsFactors = FALSE
  )
  names(result) <- c(row, column, value)
  result[order(grid$r, grid$c), ]
}

two_state <- matrix(c(0.7, 0.3, 0.4, 0.6), 2, byrow = TRUE,
                    dimnames = list(c("A", "B"), c("A", "B")))

test_that("simulate_hmm accepts tidy transition and emission tables", {
  emission <- matrix(c(0.9, 0.1, 0.2, 0.8), 2, byrow = TRUE,
                     dimnames = list(c("A", "B"), c("x", "y")))
  expect_equal(
    as.data.frame(simulate_hmm(40, two_state, 10, emission, seed = 1)),
    as.data.frame(simulate_hmm(
      40, long_form(two_state, "from", "to", "probability"), 10,
      long_form(emission, "state", "observation", "probability"), seed = 1))
  )
})

test_that("simulate_longitudinal accepts a tidy transition table", {
  transition <- matrix(c(0.5, 0.1, 0, 0.4), 2, byrow = TRUE,
                       dimnames = list(c("v1", "v2"), c("v1", "v2")))
  expect_equal(
    as.data.frame(simulate_longitudinal(20, 15, transition, seed = 1)),
    as.data.frame(simulate_longitudinal(
      20, 15, long_form(transition, "from", "to", "coefficient"), seed = 1))
  )
})

test_that("simulate_clusters accepts tidy centres", {
  centers <- matrix(c(0, 0, 4, 4, 0, 4), nrow = 3, byrow = TRUE,
                    dimnames = list(c("c1", "c2", "c3"), c("V1", "V2")))
  expect_equal(
    as.data.frame(simulate_clusters(60, centers, seed = 1)),
    as.data.frame(simulate_clusters(
      60, long_form(centers, "cluster", "variable", "center"), seed = 1))
  )
})

test_that("simulate_factors accepts tidy loadings", {
  loadings <- matrix(c(0.8, 0.7, 0.6, 0, 0, 0, 0, 0, 0, 0.8, 0.7, 0.6), ncol = 2,
                     dimnames = list(paste0("item_", 1:6), c("f1", "f2")))
  expect_equal(
    as.data.frame(simulate_factors(80, loadings, seed = 1)),
    as.data.frame(simulate_factors(
      80, long_form(loadings, "item", "factor", "loading"), seed = 1))
  )
})

test_that("simulate_lpa accepts tidy means", {
  means <- matrix(c(0, 0, 3, 3), nrow = 2, byrow = TRUE,
                  dimnames = list(c("p1", "p2"), c("V1", "V2")))
  expect_equal(
    as.data.frame(simulate_lpa(80, means, seed = 1)),
    as.data.frame(simulate_lpa(
      80, long_form(means, "profile", "variable", "mean"), seed = 1))
  )
})

test_that("simulate_lca accepts a tidy probability table", {
  probabilities <- array(
    c(0.8, 0.2, 0.7, 0.3, 0.2, 0.8, 0.3, 0.7), dim = c(2, 2, 2),
    dimnames = list(c("C1", "C2"), c("i1", "i2"), c("no", "yes"))
  )
  tidy <- expand.grid(class = c("C1", "C2"), indicator = c("i1", "i2"),
                      category = c("no", "yes"), stringsAsFactors = FALSE)
  tidy$probability <- as.vector(probabilities)
  expect_equal(
    as.data.frame(simulate_lca(80, probabilities, seed = 1)),
    as.data.frame(simulate_lca(80, tidy, seed = 1))
  )
})

test_that("simulate_sequence_clusters accepts one table instead of a list", {
  first <- two_state
  second <- matrix(c(0.3, 0.7, 0.6, 0.4), 2, byrow = TRUE,
                   dimnames = list(c("A", "B"), c("A", "B")))
  tidy <- rbind(
    cbind(cluster = "a", long_form(first, "from", "to", "probability")),
    cbind(cluster = "b", long_form(second, "from", "to", "probability"))
  )
  expect_equal(
    as.data.frame(simulate_sequence_clusters(
      40, list(first, second), chain_length = 8, seed = 1)),
    as.data.frame(simulate_sequence_clusters(40, tidy, chain_length = 8, seed = 1))
  )
})

test_that("grouped sequence simulators accept one table instead of a list", {
  first <- two_state
  second <- matrix(c(0.3, 0.7, 0.6, 0.4), 2, byrow = TRUE,
                   dimnames = list(c("A", "B"), c("A", "B")))
  tidy <- rbind(
    cbind(group = "g1", long_form(first, "from", "to", "probability")),
    cbind(group = "g2", long_form(second, "from", "to", "probability"))
  )
  expect_equal(
    as.data.frame(simulate_group_sequences(2, 10, list(first, second),
                                           chain_length = 8, seed = 1)),
    as.data.frame(simulate_group_sequences(2, 10, tidy, chain_length = 8, seed = 1))
  )
})

test_that("a symmetric argument fills its mirror cell and diagonal", {
  # Only the upper triangle is supplied; the diagonal defaults to 1.
  result <- simulab:::.tidy_to_symmetric(
    data.frame(row = c("x", "x", "y"), column = c("y", "z", "z"),
               correlation = c(0.5, 0.3, 0.2)),
    what = "correlation", row = "row", column = "column",
    value = "correlation", diagonal = 1
  )
  expect_equal(unname(diag(result)), c(1, 1, 1))
  expect_equal(result["y", "x"], 0.5)
  expect_true(isSymmetric(result))
})

test_that("a matrix passes through unchanged", {
  expect_identical(
    simulab:::.tidy_to_matrix(two_state, "transition", "from", "to", "probability"),
    two_state
  )
})

test_that("a tidy input missing required columns is refused", {
  expect_error(
    simulab:::.tidy_to_matrix(data.frame(a = 1, b = 2), "transition",
                              "from", "to", "probability"),
    class = "simulab_bad_tidy_input"
  )
})

test_that("a tidy input missing cells is refused", {
  expect_error(
    simulab:::.tidy_to_matrix(
      data.frame(from = c("A", "B"), to = c("A", "B"), probability = c(1, 1)),
      "transition", "from", "to", "probability"),
    class = "simulab_incomplete_tidy_input"
  )
})

test_that("row and column order follows first appearance", {
  reordered <- data.frame(
    from = c("B", "B", "A", "A"), to = c("B", "A", "B", "A"),
    probability = c(0.6, 0.4, 0.3, 0.7)
  )
  result <- simulab:::.tidy_to_matrix(reordered, "transition", "from", "to",
                                      "probability")
  expect_equal(rownames(result), c("B", "A"))
  expect_equal(result["A", "A"], 0.7)
})
