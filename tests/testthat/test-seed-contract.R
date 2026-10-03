# Case table: `.seed_contract_calls()` in helper-seed-contract.R.

test_that("the seed-contract sweep covers every dispatchable verb", {
  dispatchable <- list_simulators(dispatchable = TRUE)$simulator
  expect_setequal(names(.seed_contract_calls()), dispatchable)
})

test_that("a seeded call reproduces itself and restores the caller's RNG stream", {
  calls <- .seed_contract_calls()
  # Both verbs call fit_tna(); CRAN's no-Suggests check runs without `tna`.
  needs_tna <- c("group_tna", "tna_batches")
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
  expect_length(checked, length(calls))
})

test_that("an unseeded call advances the caller's RNG stream", {
  set.seed(2)
  before <- .Random.seed
  simulate_ttest(n_a = 8, n_b = 8, mean_a = 0, mean_b = 0.5)
  expect_false(identical(before, .Random.seed))
})
