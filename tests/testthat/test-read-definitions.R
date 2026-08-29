# Written into the session temporary directory, which R removes on exit.
write_spec_file <- function(...) {
  file <- tempfile(fileext = ".csv")
  utils::write.csv(data.frame(..., stringsAsFactors = FALSE), file, row.names = FALSE)
  file
}

test_that("a written specification reads back as source text, not numbers", {
  # read.csv() types a column of numeric literals as integer; a specification
  # column is always source text, so the round trip must coerce it back.
  file <- write_spec_file(
    variable = c("a", "b"),
    distribution = c("normal", "poisson"),
    formula = c("0", "3"),
    variance = c("1", "0"),
    link = c("identity", "identity")
  )
  specification <- read_definitions(file)

  expect_s3_class(specification, "simulab_spec")
  expect_true(all(vapply(specification, is.character, logical(1))))
})

test_that("a specification read from disk drives simulate_study()", {
  file <- write_spec_file(
    variable = c("baseline", "outcome"),
    distribution = c("normal", "normal"),
    formula = c("0", "2 * baseline"),
    variance = c("1", "1"),
    link = c("identity", "identity")
  )
  result <- simulate_study(n = 4000, specification = read_definitions(file), seed = 1)
  data <- as.data.frame(result)

  expect_named(data, c("id", "baseline", "outcome"))
  # The regression of outcome on baseline recovers the formula coefficient.
  slope <- unname(stats::coef(stats::lm(outcome ~ baseline, data = data))[2L])
  expect_lt(abs(slope - 2), 0.05)
})

test_that("read_definitions() and define_variables() agree", {
  file <- write_spec_file(
    variable = "a", distribution = "normal",
    formula = "0", variance = "1", link = "identity"
  )
  from_file <- read_definitions(file)
  from_code <- define_variables(
    define_variable("a", formula = "0", variance = "1", distribution = "normal")
  )
  expect_equal(as.data.frame(from_file), as.data.frame(from_code))
})

test_that("a missing required column is refused", {
  file <- write_spec_file(variable = "a", distribution = "normal", formula = "0")
  expect_error(read_definitions(file), class = "simulab_bad_definition_file")
})

test_that("duplicate variables are refused", {
  file <- write_spec_file(
    variable = c("a", "a"), distribution = c("normal", "normal"),
    formula = c("0", "1"), variance = c("1", "1"),
    link = c("identity", "identity")
  )
  expect_error(read_definitions(file), class = "simulab_duplicate_variable")
})

test_that("an unknown distribution is refused", {
  file <- write_spec_file(
    variable = "a", distribution = "wishart",
    formula = "0", variance = "1", link = "identity"
  )
  expect_error(read_definitions(file), class = "simulab_unknown_distribution")
})

test_that("an unknown link is refused", {
  file <- write_spec_file(
    variable = "a", distribution = "normal",
    formula = "0", variance = "1", link = "probit"
  )
  expect_error(read_definitions(file), class = "simulab_unknown_link")
})
