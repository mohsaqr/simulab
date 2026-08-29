test_that("latent profile and class generators preserve target structure", {
  means <- matrix(c(0, 0, 3, 3), 2L, byrow = TRUE,
                  dimnames = list(NULL, c("x", "y")))
  lpa <- simulate_lpa(10000, means, proportions = c(0.4, 0.6), seed = 1)
  expect_equal(mean(lpa$profile == "Profile 1"), 0.4, tolerance = 0.02)
  expect_equal(as.vector(tapply(lpa$x, lpa$profile, mean)), c(0, 3), tolerance = 0.05)

  probabilities <- array(NA_real_, dim = c(2, 2, 2))
  probabilities[1, 1, ] <- c(0.9, 0.1)
  probabilities[1, 2, ] <- c(0.8, 0.2)
  probabilities[2, 1, ] <- c(0.2, 0.8)
  probabilities[2, 2, ] <- c(0.1, 0.9)
  lca <- simulate_lca(200, probabilities, seed = 2)
  expect_equal(nrow(lca), 200L)
  expect_equal(nrow(as.data.frame(lca, what = "parameters")), 8L)
})

test_that("factor and IRT simulations expose true latent quantities", {
  loadings <- matrix(c(0.8, 0, 0.7, 0, 0, 0.9, 0, 0.75), 4L, 2L, byrow = TRUE)
  factors <- simulate_factors(5000, loadings, uniquenesses = rep(0.36, 4), seed = 3)
  population <- as.data.frame(factors, what = "covariance")
  expect_equal(nrow(population), 16L)
  expect_equal(nrow(factors), 5000L)

  irt <- simulate_irt(1000, discrimination = c(1, 1.5), difficulty = c(0, 1), seed = 4)
  expect_true(all(unlist(irt[c("item_1", "item_2")]) %in% 0:1))
  expect_equal(nrow(as.data.frame(irt, what = "abilities")), 1000L)
  graded <- simulate_irt(100, difficulty = matrix(c(-1, 1, -0.5, 1.5), 2L, byrow = TRUE),
                         model = "graded", seed = 5)
  expect_true(all(unlist(graded[c("item_1", "item_2")]) %in% 0:2))
})
