# A deparsed predicate ("is.matrix(centers) is not TRUE") tells a caller what
# the code asked, not what the argument must be. These tests pin the contract
# text so a rewrite cannot quietly regress to the deparsed form.

test_that("a rejected argument is named in the message", {
  expect_error(
    simulate_clusters(n = 10, centers = list(c(0, 0), c(4, 4))),
    regexp = "`centers` must be a matrix"
  )
  expect_error(
    simulate_regression(n = 10, coefficients = c(1, 0.5)),
    regexp = "`coefficients` must be a named numeric vector"
  )
  expect_error(
    simulate_lca(n = 10, probabilities = list(c(0.8, 0.7))),
    regexp = "`probabilities` must be a finite non-negative array"
  )
  expect_error(
    simulate_ttest(n_a = 1.5, n_b = 20, mean_a = 0, mean_b = 1),
    regexp = "`n_a` must be a single whole number of at least 2"
  )
})

test_that("no validation message is a deparsed predicate", {
  messages <- c(
    tryCatch(simulate_clusters(n = 10, centers = "x"),
             error = conditionMessage),
    tryCatch(simulate_ttest(n_a = "x", n_b = 20, mean_a = 0, mean_b = 1),
             error = conditionMessage),
    tryCatch(simulate_network(nodes = -1, model = "bernoulli"),
             error = conditionMessage)
  )
  expect_false(any(grepl("is not TRUE", messages, fixed = TRUE)))
  expect_true(all(grepl("must", messages, fixed = TRUE)))
})

test_that("every stopifnot() in the package names its contract", {
  # Guards the whole surface, not just the examples above. R CMD check runs
  # tests against the installed package, where R/ sources are absent.
  source_dir <- "../../R"
  skip_if_not(dir.exists(source_dir), "package sources are not available")
  unnamed <- unlist(lapply(list.files(source_dir, pattern = "[.]R$", full.names = TRUE),
                           function(path) {
    collect <- function(e) {
      if (!is.call(e)) return(NULL)
      out <- NULL
      if (identical(e[[1L]], as.name("stopifnot"))) {
        arguments <- as.list(e)[-1L]
        labels <- names(arguments)
        if (is.null(labels) || any(!nzchar(labels))) out <- basename(path)
      }
      c(out, unlist(lapply(as.list(e)[-1L], collect)))
    }
    unlist(lapply(as.list(parse(path, keep.source = FALSE)), collect))
  }))
  expect_equal(unnamed, NULL)
})

test_that("a contradictory correlation request raises a classed error", {
  expect_error(
    simulate_correlated(n = 10, means = c(0, 0), sds = c(1, 1), rho = 0.5,
                        structure = "independent"),
    class = "simulab_contradictory_structure"
  )
})
