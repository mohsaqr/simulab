#' List the tidy tables available from a simulation
#'
#' @param x A `simulab_sim` object.
#'
#' @return A base `data.frame` with one row per available table and columns
#'   `table`, `rows`, and `columns`.
#' @export
#'
#' @examples
#' result <- simulate_ttest(
#'   n_a = 10,
#'   n_b = 10,
#'   mean_a = 0,
#'   mean_b = 0.5,
#'   seed = 1
#' )
#' components(result)
components <- function(x) {
  stopifnot(
    "`x` must be a `simulab_sim` object" =
      inherits(x, "simulab_sim")
  )

  tables <- c(list(data = .plain_data(x)), attr(x, "simulab_tables"))
  data.frame(
    table = names(tables),
    rows = vapply(tables, nrow, integer(1)),
    columns = vapply(tables, ncol, integer(1)),
    row.names = NULL,
    stringsAsFactors = FALSE
  )
}

.new_simulab_sim <- function(data, type, seed = NULL, tables = list()) {
  stopifnot(
    "`data` must be a data frame" =
      is.data.frame(data),
    "`type` must be a single string" =
      is.character(type) &&
        length(type) == 1L,
    "`seed` must be NULL or a single number" =
      is.null(seed) || (is.numeric(seed) && length(seed) == 1L),
    "`tables` must be a list of data frames" =
      is.list(tables) &&
        all(vapply(tables, is.data.frame, logical(1)))
  )

  result <- data
  class(result) <- c("simulab_sim", "data.frame")
  attr(result, "simulab_type") <- type
  attr(result, "simulab_seed") <- seed
  attr(result, "simulab_tables") <- tables
  result
}

.plain_data <- function(x) {
  stopifnot(
    "`x` must be a data frame" =
      is.data.frame(x)
  )

  result <- x
  class(result) <- "data.frame"
  attr(result, "simulab_type") <- NULL
  attr(result, "simulab_seed") <- NULL
  attr(result, "simulab_tables") <- NULL
  result
}

#' Convert a simulation component to a tidy data frame
#'
#' @param x A `simulab_sim` object.
#' @param row.names Ignored.
#' @param optional Ignored.
#' @param what Name of the table to return. Use `components(x)` to list the
#'   available choices.
#' @param ... Reserved for future methods.
#'
#' @return A base `data.frame` containing the requested simulation table.
#' @export
#'
#' @examples
#' result <- simulate_ttest(
#'   n_a = 10,
#'   n_b = 10,
#'   mean_a = 0,
#'   mean_b = 0.5,
#'   seed = 1
#' )
#' as.data.frame(result)
#' as.data.frame(result, what = "parameters")
as.data.frame.simulab_sim <- function(x, row.names = NULL, optional = FALSE,
                                      what = "data", ...) {
  stopifnot(
    "`x` must be a `simulab_sim` object" =
      inherits(x, "simulab_sim"),
    "`what` must be a single string that is not NA" =
      is.character(what) &&
        length(what) == 1L &&
        !is.na(what)
  )

  if (identical(what, "data")) {
    return(.plain_data(x))
  }

  tables <- attr(x, "simulab_tables")
  if (!what %in% names(tables)) {
    stop(
      sprintf(
        "Unknown table '%s'. Available tables: %s.",
        what,
        paste(c("data", names(tables)), collapse = ", ")
      ),
      call. = FALSE
    )
  }

  tables[[what]]
}

#' Print a simulation result
#'
#' @param x A `simulab_sim` object.
#' @param ... Arguments passed to the base data-frame print method.
#'
#' @return `x`, invisibly.
#' @export
#'
#' @examples
#' result <- simulate_ttest(n_a = 30, n_b = 30, mean_a = 0, mean_b = 0.5, seed = 1)
#' print(result)
print.simulab_sim <- function(x, ...) {
  stopifnot(
    "`x` must be a `simulab_sim` object" =
      inherits(x, "simulab_sim")
  )

  shown <- utils::head(.plain_data(x), 10L)
  cat(sprintf(
    "<simulab_sim:%s> %d rows x %d columns\n",
    attr(x, "simulab_type"),
    nrow(x),
    ncol(x)
  ))
  print(shown, ...)
  if (nrow(x) > nrow(shown)) {
    cat(sprintf("... %d more rows\n", nrow(x) - nrow(shown)))
  }
  invisible(x)
}

#' Summarize simulated variables
#'
#' @param object A `simulab_sim` object.
#' @param ... Reserved for future methods.
#'
#' @return A base `data.frame` with one row per variable and columns describing
#'   storage class, missingness, uniqueness, and numeric summaries.
#' @export
#'
#' @examples
#' result <- simulate_ttest(n_a = 30, n_b = 30, mean_a = 0, mean_b = 0.5, seed = 1)
#' summary(result)
summary.simulab_sim <- function(object, ...) {
  stopifnot(
    "`object` must be a `simulab_sim` object" =
      inherits(object, "simulab_sim")
  )

  data <- .plain_data(object)
  summarize_column <- function(value, variable) {
    stopifnot(
      "`variable` must be a single string" =
        is.character(variable) &&
          length(variable) == 1L
    )

    numeric_value <- if (is.numeric(value)) value else numeric(0L)
    data.frame(
      variable = variable,
      class = class(value)[1L],
      observations = length(value),
      missing = sum(is.na(value)),
      unique = length(unique(value[!is.na(value)])),
      mean = if (length(numeric_value)) mean(numeric_value, na.rm = TRUE) else NA_real_,
      sd = if (length(numeric_value)) stats::sd(numeric_value, na.rm = TRUE) else NA_real_,
      minimum = if (length(numeric_value)) min(numeric_value, na.rm = TRUE) else NA_real_,
      maximum = if (length(numeric_value)) max(numeric_value, na.rm = TRUE) else NA_real_,
      row.names = NULL,
      stringsAsFactors = FALSE
    )
  }

  summaries <- Map(summarize_column, data, names(data))
  do.call(rbind, summaries)
}

