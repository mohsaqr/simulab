# Resolution of the correlation `structure` argument.
#
# WHY THIS FILE EXISTS: `structure` defaults to "independent", which returns an
# identity matrix and discards `rho`. A supplied `rho` was therefore silently
# inert across six exported functions: simulate_correlation(n, rho = 0.6)
# returned data with correlation ~0.00 and issued no warning, while
# `@param rho` documents it as "Correlation used when `correlation` is not
# supplied".
#
# The existing suite could not catch this. test-specialized.R asserts
# cor(V1, V2) == 0.6, and it passes, because it calls
# structure = "exchangeable" explicitly. It certifies the working branch and
# never exercises the default one.
#
# Every test below uses the DEFAULT structure unless it is testing the
# explicit path on purpose.

# n large enough that the Monte Carlo error on a correlation is well under the
# tolerances used here.
n_big <- 8000


# ---- rho is honoured when structure is left unset -------------------------

test_that("simulate_correlation applies rho with structure left unset", {
  d <- simulate_correlation(n = n_big, means = c(0, 0), sds = c(1, 1),
                            rho = 0.8, seed = 1)
  expect_equal(stats::cor(d$V1, d$V2), 0.8, tolerance = 0.03)
})

test_that("simulate_correlated applies rho with structure left unset", {
  d <- simulate_correlated(n = n_big, means = c(0, 0), sds = c(1, 1),
                           rho = 0.5, seed = 1)
  expect_equal(stats::cor(d$V1, d$V2), 0.5, tolerance = 0.03)
})

test_that("simulate_copula applies rho with structure left unset", {
  spec <- define_variables(
    define_variable("x", formula = 0, variance = 1, distribution = "normal"),
    define_variable("y", formula = 0, variance = 1, distribution = "normal")
  )
  d <- simulate_copula(n = n_big, specification = spec, rho = 0.7, seed = 1)
  expect_equal(stats::cor(d$x, d$y), 0.7, tolerance = 0.05)
})

test_that("simulate_ordinal induces association with structure left unset", {
  d <- simulate_ordinal(n = n_big, probabilities = c(0.3, 0.3, 0.4),
                        n_variables = 2, rho = 0.7, seed = 1)
  variables <- setdiff(names(d), "id")
  observed <- stats::cor(as.integer(d[[variables[1]]]),
                         as.integer(d[[variables[2]]]))
  # Discretising a latent normal attenuates the correlation, so the observed
  # value is below the latent rho but must be clearly positive.
  expect_gt(observed, 0.4)
})

test_that("correlation_structure applies rho with structure left unset", {
  tab <- correlation_structure(n_variables = 3, rho = 0.5)
  off_diagonal <- tab$correlation[tab$row != tab$column]
  expect_equal(off_diagonal, rep(0.5, length(off_diagonal)))
})


# ---- rho = 0 still means independence -------------------------------------

test_that("omitting rho still gives independent variables", {
  d <- simulate_correlation(n = n_big, means = c(0, 0), sds = c(1, 1), seed = 1)
  expect_equal(stats::cor(d$V1, d$V2), 0, tolerance = 0.05)
})

test_that("correlation_structure with no rho is the identity", {
  tab <- correlation_structure(n_variables = 3)
  off_diagonal <- tab$correlation[tab$row != tab$column]
  expect_equal(off_diagonal, rep(0, length(off_diagonal)))
})


# ---- explicit structures are unaffected by the resolution rule ------------

test_that("explicit exchangeable and ar1 behave exactly as before", {
  for (structure in c("exchangeable", "ar1")) {
    d <- simulate_correlation(n = n_big, means = c(0, 0), sds = c(1, 1),
                              rho = 0.8, structure = structure, seed = 1)
    expect_equal(stats::cor(d$V1, d$V2), 0.8, tolerance = 0.03,
                 info = structure)
  }
})

test_that("an explicit custom correlation matrix is still used", {
  # expect_equal() applies a RELATIVE tolerance, so a smaller target needs a
  # larger one. At n = 8000 the Monte Carlo SE of r = 0.4 is about 0.009, and
  # 0.08 relative is 0.032 absolute, roughly 3.4 standard errors.
  target <- matrix(c(1, 0.4, 0.4, 1), nrow = 2)
  d <- simulate_correlated(n = n_big, means = c(0, 0), sds = c(1, 1),
                           structure = "custom", correlation = target, seed = 1)
  expect_equal(stats::cor(d$V1, d$V2), 0.4, tolerance = 0.08)
})

test_that("supplying a correlation matrix without a structure uses it", {
  target <- matrix(c(1, 0.6, 0.6, 1), nrow = 2)
  d <- simulate_correlated(n = n_big, means = c(0, 0), sds = c(1, 1),
                           correlation = target, seed = 1)
  expect_equal(stats::cor(d$V1, d$V2), 0.6, tolerance = 0.03)
})


# ---- a contradictory request is an error, not wrong data ------------------

test_that("explicit independent with a non-zero rho raises a classed error", {
  expect_error(
    simulate_correlation(n = 100, means = c(0, 0), rho = 0.6,
                         structure = "independent", seed = 1),
    class = "simulab_contradictory_structure"
  )
})

test_that("the contradiction error names the alternatives", {
  expect_error(
    simulate_correlated(n = 100, means = c(0, 0), rho = 0.6,
                        structure = "independent", seed = 1),
    "exchangeable"
  )
})

test_that("explicit independent with rho = 0 remains valid", {
  expect_no_error(
    simulate_correlation(n = 100, means = c(0, 0),
                         structure = "independent", seed = 1)
  )
})


# ---- the resolver itself ---------------------------------------------------

test_that("the resolver picks a structure from the supplied arguments", {
  resolve <- simulab:::.resolve_correlation_structure
  expect_identical(resolve(NULL, FALSE, NULL, supplied = FALSE), "independent")
  expect_identical(resolve(NULL, TRUE, NULL, supplied = FALSE), "exchangeable")
  expect_identical(resolve(NULL, TRUE, diag(2), supplied = FALSE), "custom")
  expect_identical(resolve(NULL, FALSE, diag(2), supplied = FALSE), "custom")
})

test_that("the resolver keeps an explicitly supplied structure", {
  resolve <- simulab:::.resolve_correlation_structure
  expect_identical(resolve("ar1", TRUE, NULL, supplied = TRUE), "ar1")
  expect_identical(resolve("exchangeable", TRUE, NULL, supplied = TRUE),
                   "exchangeable")
  expect_identical(resolve("independent", FALSE, NULL, supplied = TRUE),
                   "independent")
})


# ---- reproducibility and the result contract survive the change -----------

test_that("the resolved default is still reproducible and restores RNG state", {
  a <- simulate_correlation(n = 500, means = c(0, 0), rho = 0.5, seed = 3)
  b <- simulate_correlation(n = 500, means = c(0, 0), rho = 0.5, seed = 3)
  expect_equal(a, b)

  set.seed(99)
  before <- .Random.seed
  invisible(simulate_correlation(n = 500, means = c(0, 0), rho = 0.5, seed = 3))
  expect_identical(before, .Random.seed)
})
