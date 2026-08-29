.new_formula <- function(formula, type) {
  stopifnot(
    "`formula` must be a single string" =
      is.character(formula) &&
        length(formula) == 1L,
    "`type` must be a single string" =
      is.character(type) &&
        length(type) == 1L
  )
  result <- data.frame(type = type, formula = formula,
                       stringsAsFactors = FALSE, row.names = NULL)
  class(result) <- c("simulab_formula", "data.frame")
  result
}

#' Construct a linear simulation formula
#'
#' @param coefficients Coefficients with an optional intercept.
#' @param variables Variable names. When there is one additional coefficient,
#'   the first is the intercept.
#'
#' @return A one-row `simulab_formula` base `data.frame`.
#' @export
#'
#' @examples
#' linear_formula(coefficients = c(1, 0.5, -0.3), variables = c("x1", "x2"))
linear_formula <- function(coefficients, variables) {
  stopifnot(
    "`variables` must be a character vector, with at least one element" =
      is.character(variables) &&
        length(variables) >= 1L,
    "`coefficients` must be an atomic vector, with at least one element, of length " =
      is.atomic(coefficients) &&
        length(coefficients) >= 1L &&
        all(length(coefficients) %in% c(length(variables), length(variables) + 1L))
  )
  has_intercept <- length(coefficients) == length(variables) + 1L
  intercept <- if (has_intercept) as.character(coefficients[1L]) else character(0L)
  slopes <- if (has_intercept) coefficients[-1L] else coefficients
  terms <- sprintf("%s * %s", slopes, variables)
  .new_formula(paste(c(intercept, terms), collapse = " + "), "linear")
}

#' Construct a mixture simulation formula
#'
#' @param variables Variable names or expressions.
#' @param probabilities Optional probabilities. Equal probabilities are used by
#'   default.
#'
#' @return A one-row `simulab_formula` base `data.frame`.
#' @export
#'
#' @examples
#' mixture_formula(variables = c("a", "b"), probabilities = c(0.3, 0.7))
mixture_formula <- function(variables, probabilities = NULL) {
  stopifnot(
    "`variables` must be a character vector, with at least one element" =
      is.character(variables) &&
        length(variables) >= 1L,
    "`probabilities` must be NULL or a numeric vector" =
      is.null(probabilities) || is.numeric(probabilities)
  )
  if (is.null(probabilities)) probabilities <- rep(1 / length(variables), length(variables))
  if (length(probabilities) != length(variables) || any(probabilities < 0) ||
      sum(probabilities) <= 0) {
    stop("probabilities must contain one non-negative value per variable.", call. = FALSE)
  }
  probabilities <- probabilities / sum(probabilities)
  .new_formula(
    paste(sprintf("%s | %.17g", variables, probabilities), collapse = " + "),
    "mixture"
  )
}

#' Construct a categorical probability formula
#'
#' @param probabilities Category probabilities.
#' @param categories Number of equal-probability categories when probabilities
#'   are not supplied.
#'
#' @return A one-row `simulab_formula` base `data.frame`.
#' @export
#'
#' @examples
#' categorical_formula(probabilities = c(0.2, 0.5, 0.3))
categorical_formula <- function(probabilities = NULL, categories = NULL) {
  stopifnot(
    "`probabilities` must be NULL or a numeric vector" =
      is.null(probabilities) || is.numeric(probabilities),
    "`categories` must be NULL or a single whole number of at least 2" =
      is.null(categories) || (is.numeric(categories) && length(categories) == 1L && categories >= 2 && categories == as.integer(categories))
  )
  if (is.null(probabilities) == is.null(categories)) {
    stop("Supply probabilities or categories, not both.", call. = FALSE)
  }
  if (is.null(probabilities)) probabilities <- rep(1 / categories, categories)
  if (length(probabilities) < 2L || any(probabilities < 0) || sum(probabilities) <= 0) {
    stop("Categorical probabilities must be non-negative with positive sum.", call. = FALSE)
  }
  probabilities <- probabilities / sum(probabilities)
  .new_formula(paste(sprintf("%.17g", probabilities), collapse = ";"), "categorical")
}

.validate_spline <- function(knots, degree, coefficients = NULL) {
  stopifnot(
    "`knots` must be a finite numeric vector" =
      is.numeric(knots) &&
        all(is.finite(knots)),
    "`degree` must be a single positive whole number" =
      is.numeric(degree) &&
        length(degree) == 1L &&
        all(degree >= 1) &&
        all(degree == as.integer(degree)),
    "`coefficients` must be NULL or a numeric vector" =
      is.null(coefficients) || is.numeric(coefficients)
  )
  if (length(knots) && (any(knots <= 0 | knots >= 1) || is.unsorted(knots, strictly = TRUE))) {
    stop("Spline knots must be strictly increasing between zero and one.", call. = FALSE)
  }
  required <- length(knots) + as.integer(degree) + 1L
  if (!is.null(coefficients)) {
    coefficient_matrix <- as.matrix(coefficients)
    if (nrow(coefficient_matrix) != required) {
      stop(sprintf("Spline coefficients require %d rows.", required), call. = FALSE)
    }
  }
  required
}

#' Compute tidy B-spline basis functions
#'
#' @param knots Interior knots between zero and one.
#' @param degree Polynomial degree.
#' @param n Number of evaluation points.
#'
#' @return A base `data.frame` with one row per x/basis combination and columns
#'   `x`, `basis`, and `value`.
#' @export
#'
#' @examples
#' head(spline_basis(knots = c(0.25, 0.5, 0.75), degree = 3, n = 20))
spline_basis <- function(knots = c(0.25, 0.5, 0.75), degree = 3L, n = 1000L) {
  stopifnot(
    "`knots` must be a numeric vector" =
      is.numeric(knots),
    "`degree` must be a single number" =
      is.numeric(degree) &&
        length(degree) == 1L,
    "`n` must be a single whole number of at least 2" =
      is.numeric(n) &&
        length(n) == 1L &&
        all(n >= 2) &&
        all(n == as.integer(n))
  )
  .validate_spline(knots, degree)
  x <- seq(0, 1, length.out = as.integer(n))
  basis <- splines::bs(
    x,
    knots = knots,
    degree = as.integer(degree),
    Boundary.knots = c(0, 1),
    intercept = TRUE
  )
  data.frame(
    x = rep(x, times = ncol(basis)),
    basis = rep(sprintf("basis_%d", seq_len(ncol(basis))), each = length(x)),
    value = as.vector(basis),
    stringsAsFactors = FALSE,
    row.names = NULL
  )
}

#' Compute one or more tidy spline curves
#'
#' @param knots,degree,n Spline-basis arguments.
#' @param coefficients Numeric vector or matrix with one coefficient column per
#'   curve.
#'
#' @return A base `data.frame` with one row per x/curve combination and columns
#'   `x`, `curve`, and `value`.
#' @export
#'
#' @examples
#' head(spline_curves(coefficients = c(0.1, 0.2, 0.5, 0.4, 0.7, 0.6, 0.9),
#'                    knots = c(0.25, 0.5, 0.75), degree = 3, n = 20))
spline_curves <- function(coefficients, knots = c(0.25, 0.5, 0.75),
                          degree = 3L, n = 1000L) {
  stopifnot(
    "`coefficients` must be a numeric vector" =
      is.numeric(coefficients),
    "`knots` must be a numeric vector" =
      is.numeric(knots),
    "`degree` must be a single number" =
      is.numeric(degree) &&
        length(degree) == 1L,
    "`n` must be a single whole number of at least 2" =
      is.numeric(n) &&
        length(n) == 1L &&
        all(n >= 2) &&
        all(n == as.integer(n))
  )
  .validate_spline(knots, degree, coefficients)
  coefficient_matrix <- as.matrix(coefficients)
  x <- seq(0, 1, length.out = as.integer(n))
  basis <- splines::bs(
    x,
    knots = knots,
    degree = as.integer(degree),
    Boundary.knots = c(0, 1),
    intercept = TRUE
  )
  values <- basis %*% coefficient_matrix
  data.frame(
    x = rep(x, times = ncol(values)),
    curve = rep(sprintf("curve_%d", seq_len(ncol(values))), each = length(x)),
    value = as.vector(values),
    stringsAsFactors = FALSE,
    row.names = NULL
  )
}

#' Add a spline-generated variable
#'
#' @param data Base `data.frame`.
#' @param predictor Predictor variable.
#' @param variable Name of the generated variable.
#' @param coefficients Spline coefficients.
#' @param knots Quantile probabilities for interior knots.
#' @param degree Polynomial degree.
#' @param output_range Optional output range.
#' @param noise_variance Non-negative Gaussian noise variance.
#' @param seed Optional random seed.
#'
#' @return A `simulab_sim` base `data.frame` with the spline variable and a tidy
#'   basis table.
#' @export
#'
#' @examples
#' data <- data.frame(id = 1:100, x = stats::runif(100))
#' result <- simulate_spline(
#'   data, predictor = "x", variable = "y",
#'   coefficients = c(0.1, 0.2, 0.5, 0.4, 0.7, 0.6, 0.9),
#'   knots = c(0.25, 0.5, 0.75), seed = 1
#' )
#' head(result)
simulate_spline <- function(data, predictor, variable, coefficients,
                            knots = c(0.25, 0.5, 0.75), degree = 3L,
                            output_range = NULL, noise_variance = 0, seed = NULL) {
  stopifnot(
    "`data` must be a data frame, with at least one row" =
      is.data.frame(data) &&
        nrow(data) >= 1L,
    "`predictor` must be a single string naming a column of `data`" =
      is.character(predictor) &&
        length(predictor) == 1L &&
        all(predictor %in% names(data)),
    "`variable` must be a single non-empty string" =
      is.character(variable) &&
        length(variable) == 1L &&
        all(nzchar(variable)),
    "`coefficients` must be a numeric vector" =
      is.numeric(coefficients),
    "`knots` must be a numeric vector" =
      is.numeric(knots),
    "`degree` must be a single number" =
      is.numeric(degree) &&
        length(degree) == 1L,
    "`output_range` must be NULL or a numeric vector, of length 2" =
      is.null(output_range) || (is.numeric(output_range) && length(output_range) == 2L && output_range[2L] > output_range[1L]),
    "`noise_variance` must be a single non-negative number" =
      is.numeric(noise_variance) &&
        length(noise_variance) == 1L &&
        all(noise_variance >= 0),
    "`seed` must be NULL or a single number" =
      is.null(seed) || (is.numeric(seed) && length(seed) == 1L)
  )
  .validate_spline(knots, degree, coefficients)
  source <- .as_result_data(data)
  if (variable %in% names(source)) stop("Spline variable already exists in data.", call. = FALSE)
  x <- source[[predictor]]
  if (!is.numeric(x) || anyNA(x)) stop("Spline predictor must be complete numeric data.", call. = FALSE)
  normalized <- if (diff(range(x)) == 0) rep(0.5, length(x)) else (x - min(x)) / diff(range(x))
  quantile_knots <- stats::quantile(normalized, probs = knots, names = FALSE)
  basis <- splines::bs(
    normalized,
    knots = quantile_knots,
    degree = as.integer(degree),
    Boundary.knots = c(0, 1),
    intercept = TRUE
  )
  mean_value <- as.vector(basis %*% coefficients)
  if (!is.null(output_range)) {
    mean_value <- output_range[1L] + mean_value * diff(output_range)
  }
  source[[variable]] <- .with_seed(
    seed,
    stats::rnorm(length(mean_value), mean = mean_value, sd = sqrt(noise_variance))
  )
  basis_table <- data.frame(
    observation = rep(seq_len(nrow(source)), times = ncol(basis)),
    basis = rep(sprintf("basis_%d", seq_len(ncol(basis))), each = nrow(source)),
    value = as.vector(basis),
    stringsAsFactors = FALSE,
    row.names = NULL
  )
  parameters <- data.frame(
    basis = sprintf("basis_%d", seq_along(coefficients)),
    coefficient = coefficients,
    stringsAsFactors = FALSE,
    row.names = NULL
  )
  .new_simulab_sim(source, type = "spline", seed = seed,
                   tables = list(basis = basis_table, parameters = parameters))
}
