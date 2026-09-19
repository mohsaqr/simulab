.ml_lpa_means <- function() {
  matrix(c(-1.5, -1.2,
            0.0,  0.2,
            1.5,  1.2),
         nrow = 3L, byrow = TRUE,
         dimnames = list(NULL, c("reading", "maths")))
}

.ml_lpa_prevalence <- function() {
  matrix(c(0.60, 0.30, 0.10,
           0.10, 0.30, 0.60),
         nrow = 2L, byrow = TRUE)
}

test_that("the two-level generator returns the documented shape and tables", {
  result <- simulate_ml_lpa(clusters = 30, cluster_size = 20,
                            means = .ml_lpa_means(),
                            profile_probabilities = .ml_lpa_prevalence(),
                            seed = 1)

  expect_s3_class(result, "simulab_sim")
  expect_equal(nrow(result), 600L)
  expect_named(as.data.frame(result),
               c("id", "cluster", "cluster_class", "profile", "reading", "maths"))
  expect_equal(components(result)$table,
               c("data", "parameters", "profile_probabilities", "clusters"))
  expect_named(as.data.frame(result, what = "parameters"),
               c("profile", "variable", "mean", "sd", "proportion"))
  expect_named(as.data.frame(result, what = "profile_probabilities"),
               c("cluster_class", "profile", "probability",
                 "cluster_class_proportion"))
  expect_named(as.data.frame(result, what = "clusters"),
               c("cluster", "cluster_class", "size"))
  expect_equal(nrow(as.data.frame(result, what = "clusters")), 30L)
  expect_equal(sum(as.data.frame(result, what = "clusters")$size), 600L)
  expect_false(anyNA(as.data.frame(result)))
})

test_that("a cluster keeps one cluster class and every individual one profile", {
  result <- simulate_ml_lpa(clusters = 12, cluster_size = c(rep(5L, 6L), rep(9L, 6L)),
                            means = .ml_lpa_means(),
                            profile_probabilities = .ml_lpa_prevalence(),
                            seed = 2)
  data <- as.data.frame(result)
  classes_per_cluster <- tapply(data$cluster_class, data$cluster,
                                function(value) length(unique(value)))

  expect_equal(nrow(result), 84L)
  expect_true(all(classes_per_cluster == 1L))
  expect_setequal(unique(data$profile), c("Profile 1", "Profile 2", "Profile 3"))
  expect_equal(as.vector(table(data$cluster)[1:6]), rep(5L, 6L))
})

test_that("the generated data reproduce the generating parameters at scale", {
  truth <- .ml_lpa_prevalence()
  result <- simulate_ml_lpa(clusters = 400, cluster_size = 100,
                            means = .ml_lpa_means(),
                            profile_probabilities = truth,
                            cluster_class_proportions = c(0.7, 0.3),
                            seed = 3)
  data <- as.data.frame(result)
  realised <- prop.table(table(data$cluster_class, data$profile), margin = 1L)
  clusters <- as.data.frame(result, what = "clusters")

  expect_equal(as.vector(realised["Class 1", ]), truth[1L, ], tolerance = 0.02)
  expect_equal(as.vector(realised["Class 2", ]), truth[2L, ], tolerance = 0.02)
  expect_equal(mean(clusters$cluster_class == "Class 1"), 0.7, tolerance = 0.05)
  expect_equal(as.vector(tapply(data$reading, data$profile, mean)),
               c(-1.5, 0, 1.5), tolerance = 0.05)
  expect_equal(as.vector(tapply(data$maths, data$profile, stats::sd)),
               rep(1, 3L), tolerance = 0.05)
})

test_that("marginal profile proportions mix the cluster-class prevalences", {
  result <- simulate_ml_lpa(clusters = 10, cluster_size = 5,
                            means = .ml_lpa_means(),
                            profile_probabilities = .ml_lpa_prevalence(),
                            cluster_class_proportions = c(0.25, 0.75),
                            seed = 4)
  parameters <- as.data.frame(result, what = "parameters")
  expected <- as.vector(c(0.25, 0.75) %*% .ml_lpa_prevalence())

  expect_equal(unique(parameters$proportion), expected)
  expect_equal(sum(unique(parameters$proportion)), 1)
})

test_that("one cluster class reduces the model to clustered single-level profiles", {
  single <- simulate_ml_lpa(clusters = 50, cluster_size = 40,
                            means = .ml_lpa_means(),
                            profile_probabilities = matrix(c(0.2, 0.3, 0.5), nrow = 1L),
                            seed = 5)
  data <- as.data.frame(single)

  expect_equal(nrow(as.data.frame(single, what = "profile_probabilities")), 3L)
  expect_setequal(unique(data$cluster_class), "Class 1")
  expect_equal(as.vector(prop.table(table(data$profile))), c(0.2, 0.3, 0.5),
               tolerance = 0.02)
})

test_that("tidy input describes the same model as the matrix input", {
  tidy_means <- data.frame(
    profile = rep(c("Profile 1", "Profile 2", "Profile 3"), times = 2L),
    variable = rep(c("reading", "maths"), each = 3L),
    mean = c(-1.5, 0, 1.5, -1.2, 0.2, 1.2)
  )
  tidy_prevalence <- data.frame(
    cluster_class = rep(c("Class 1", "Class 2"), each = 3L),
    profile = rep(c("Profile 1", "Profile 2", "Profile 3"), times = 2L),
    probability = c(0.6, 0.3, 0.1, 0.1, 0.3, 0.6)
  )
  from_tidy <- simulate_ml_lpa(clusters = 20, cluster_size = 10, means = tidy_means,
                               profile_probabilities = tidy_prevalence, seed = 6)
  from_matrix <- simulate_ml_lpa(clusters = 20, cluster_size = 10,
                                 means = .ml_lpa_means(),
                                 profile_probabilities = .ml_lpa_prevalence(),
                                 seed = 6)

  expect_equal(as.data.frame(from_tidy), as.data.frame(from_matrix))
  expect_equal(as.data.frame(from_tidy, what = "parameters"),
               as.data.frame(from_matrix, what = "parameters"))
})

test_that("labels, standard deviations and correlations reach the drawn data", {
  correlations <- rep(list(matrix(c(1, 0.6, 0.6, 1), 2L, 2L)), 3L)
  result <- simulate_ml_lpa(clusters = 100, cluster_size = 100,
                            means = .ml_lpa_means(),
                            profile_probabilities = .ml_lpa_prevalence(),
                            sds = c(0.5, 2), correlations = correlations,
                            labels = c("low", "middle", "high"),
                            cluster_class_labels = c("typical", "advanced"),
                            seed = 7)
  data <- as.data.frame(result)
  within_profile <- tapply(seq_len(nrow(data)), data$profile,
                           function(rows) stats::cor(data$reading[rows], data$maths[rows]))

  expect_setequal(unique(data$profile), c("low", "middle", "high"))
  expect_setequal(unique(data$cluster_class), c("typical", "advanced"))
  expect_equal(as.vector(tapply(data$reading, data$profile, stats::sd)),
               rep(0.5, 3L), tolerance = 0.05)
  expect_equal(as.vector(tapply(data$maths, data$profile, stats::sd)),
               rep(2, 3L), tolerance = 0.05)
  expect_equal(as.vector(within_profile), rep(0.6, 3L), tolerance = 0.05)
})

test_that("a broken contract is refused rather than silently reshaped", {
  means <- .ml_lpa_means()
  prevalence <- .ml_lpa_prevalence()

  expect_error(
    simulate_ml_lpa(clusters = 1, cluster_size = 10, means = means,
                    profile_probabilities = prevalence),
    "`clusters` must be a single whole number of at least 2"
  )
  expect_error(
    simulate_ml_lpa(clusters = 10, cluster_size = 2.5, means = means,
                    profile_probabilities = prevalence),
    "`cluster_size` must be a positive numeric vector"
  )
  expect_error(
    simulate_ml_lpa(clusters = 10, cluster_size = c(4L, 4L), means = means,
                    profile_probabilities = prevalence),
    "cluster_size must be scalar or one per cluster"
  )
  expect_error(
    simulate_ml_lpa(clusters = 10, cluster_size = 5, means = means,
                    profile_probabilities = matrix(c(0.5, 0.5), nrow = 1L)),
    "one column per profile"
  )
  expect_error(
    simulate_ml_lpa(clusters = 10, cluster_size = 5, means = means,
                    profile_probabilities = matrix(c(0.6, 0.4, 0, 0.1, 0.3, 0.6),
                                                   nrow = 2L, byrow = TRUE)),
    "finite positive values"
  )
  expect_error(
    simulate_ml_lpa(clusters = 10, cluster_size = 5, means = means,
                    profile_probabilities = prevalence, sds = -1),
    "standard deviations must be positive"
  )
  expect_error(
    simulate_ml_lpa(clusters = 10, cluster_size = 5, means = means,
                    profile_probabilities = prevalence,
                    labels = c("a", "a", "b")),
    "one unique value per profile"
  )
  expect_error(
    simulate_ml_lpa(clusters = 10, cluster_size = 5, means = means,
                    profile_probabilities = prevalence,
                    cluster_class_labels = "only one"),
    "one unique value per cluster class"
  )
  expect_error(
    simulate_ml_lpa(clusters = 10, cluster_size = 5, means = means,
                    profile_probabilities = data.frame(
                      cluster_class = c("Class 1", "Class 1", "Class 1", "Class 2"),
                      profile = c("Profile 1", "Profile 2", "Profile 3", "Profile 1"),
                      probability = c(0.6, 0.3, 0.1, 1))),
    class = "simulab_incomplete_tidy_input"
  )
})

test_that("a seeded call reproduces itself and leaves the caller's stream alone", {
  arguments <- list(clusters = 10, cluster_size = 5, means = .ml_lpa_means(),
                    profile_probabilities = .ml_lpa_prevalence(), seed = 8)

  set.seed(99)
  before <- .Random.seed
  first <- do.call(simulate_ml_lpa, arguments)
  after <- .Random.seed
  second <- do.call(simulate_ml_lpa, arguments)

  expect_identical(as.data.frame(first), as.data.frame(second))
  expect_identical(before, after)
})
