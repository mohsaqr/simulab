## Long-form input for arguments that are matrices, arrays or lists of
## matrices.
##
## Every simulator returns tidy data, so every simulator should also accept it.
## These helpers convert a long-form data frame into the array shape a
## generator needs and pass a value that is already in that shape through
## unchanged, which keeps both call styles working at one cost.
##
## The column names are arguments rather than fixed strings because the natural
## names differ by argument: a transition matrix is `from`/`to`/`probability`,
## a loading matrix is `item`/`factor`/`loading`.

.is_tidy_input <- function(x) is.data.frame(x)

.require_columns <- function(table, columns, what) {
  absent <- setdiff(columns, names(table))
  if (length(absent)) {
    stop(errorCondition(
      sprintf("A tidy `%s` must have columns %s. Missing: %s.",
              what, paste(columns, collapse = ", "), paste(absent, collapse = ", ")),
      class = "simulab_bad_tidy_input", call = NULL
    ))
  }
  invisible(TRUE)
}

## Pivot a long-form table into a matrix. Row and column order follows first
## appearance, so the caller controls the layout by ordering the rows.
.tidy_to_matrix <- function(x, what, row, column, value,
                            row_levels = NULL, column_levels = NULL) {
  if (!.is_tidy_input(x)) return(x)
  .require_columns(x, c(row, column, value), what)

  if (is.null(row_levels)) row_levels <- unique(as.character(x[[row]]))
  if (is.null(column_levels)) column_levels <- unique(as.character(x[[column]]))
  result <- matrix(
    NA_real_, nrow = length(row_levels), ncol = length(column_levels),
    dimnames = list(row_levels, column_levels)
  )
  row_index <- match(as.character(x[[row]]), row_levels)
  column_index <- match(as.character(x[[column]]), column_levels)
  if (anyNA(row_index) || anyNA(column_index)) {
    stop(errorCondition(
      sprintf("A tidy `%s` names a row or column outside the expected set.", what),
      class = "simulab_bad_tidy_input", call = NULL
    ))
  }
  result[cbind(row_index, column_index)] <- as.numeric(x[[value]])
  if (anyNA(result)) {
    stop(errorCondition(
      sprintf("A tidy `%s` must give a value for every cell; %d are missing.",
              what, sum(is.na(result))),
      class = "simulab_incomplete_tidy_input", call = NULL
    ))
  }
  result
}

## Pivot a long-form table into a symmetric matrix, filling the mirror cell
## when only one triangle is supplied and defaulting the diagonal.
.tidy_to_symmetric <- function(x, what, row, column, value, diagonal = NA_real_) {
  if (!.is_tidy_input(x)) return(x)
  .require_columns(x, c(row, column, value), what)

  levels <- unique(c(as.character(x[[row]]), as.character(x[[column]])))
  result <- matrix(NA_real_, length(levels), length(levels),
                   dimnames = list(levels, levels))
  row_index <- match(as.character(x[[row]]), levels)
  column_index <- match(as.character(x[[column]]), levels)
  result[cbind(row_index, column_index)] <- as.numeric(x[[value]])
  mirror <- is.na(result[cbind(column_index, row_index)])
  if (any(mirror)) {
    result[cbind(column_index[mirror], row_index[mirror])] <-
      as.numeric(x[[value]])[mirror]
  }
  if (!is.na(diagonal)) diag(result)[is.na(diag(result))] <- diagonal
  if (anyNA(result)) {
    stop(errorCondition(
      sprintf("A tidy `%s` must give a value for every cell; %d are missing.",
              what, sum(is.na(result))),
      class = "simulab_incomplete_tidy_input", call = NULL
    ))
  }
  result
}

## Pivot a long-form table into a three-dimensional array.
.tidy_to_array <- function(x, what, first, second, third, value) {
  if (!.is_tidy_input(x)) return(x)
  .require_columns(x, c(first, second, third, value), what)

  levels <- lapply(c(first, second, third),
                   function(k) unique(as.character(x[[k]])))
  result <- array(NA_real_, dim = vapply(levels, length, integer(1)),
                  dimnames = levels)
  index <- cbind(
    match(as.character(x[[first]]), levels[[1L]]),
    match(as.character(x[[second]]), levels[[2L]]),
    match(as.character(x[[third]]), levels[[3L]])
  )
  result[index] <- as.numeric(x[[value]])
  if (anyNA(result)) {
    stop(errorCondition(
      sprintf("A tidy `%s` must give a value for every cell; %d are missing.",
              what, sum(is.na(result))),
      class = "simulab_incomplete_tidy_input", call = NULL
    ))
  }
  result
}

## Split a long-form table by a grouping column and pivot each group into its
## own matrix, so a list of matrices is expressible as one table.
## With `square = TRUE` (a from/to table) each group's matrix uses one state
## order, its own order of first appearance, for both rows and columns, so the
## diagonal holds the self-transitions. Groups may use different state sets;
## downstream code matches states by their labels.
.tidy_to_matrix_list <- function(x, what, group, row, column, value,
                                 symmetric = FALSE, diagonal = NA_real_,
                                 square = FALSE) {
  if (!.is_tidy_input(x)) return(x)
  .require_columns(x, c(group, row, column, value), what)

  keys <- as.character(x[[group]])
  order_of_appearance <- unique(keys)
  pieces <- split(x, factor(keys, levels = order_of_appearance))
  lapply(pieces, function(piece) {
    if (symmetric) {
      .tidy_to_symmetric(piece, what, row, column, value, diagonal = diagonal)
    } else if (square) {
      .tidy_to_square(piece, what, row, column, value)
    } else {
      .tidy_to_matrix(piece, what, row, column, value)
    }
  })
}

## Split a long-form table into a named list of vectors, so a per-group vector
## argument is expressible as one table.
.tidy_to_vector_list <- function(x, what, group, value, name = NULL) {
  if (!.is_tidy_input(x)) return(x)
  .require_columns(x, c(group, value, name), what)

  keys <- as.character(x[[group]])
  pieces <- split(x, factor(keys, levels = unique(keys)))
  lapply(pieces, function(piece) {
    values <- piece[[value]]
    if (!is.null(name)) names(values) <- as.character(piece[[name]])
    values
  })
}

## Match a secondary input to the names its primary input defines.
##
## Several simulators take two inputs that describe the same things: `means`
## and `sds` both have one row per profile, a hidden-state `transition` and an
## `emission` matrix both have one row per state. Each tidy table is pivoted in
## its own order of first appearance, and a named matrix keeps its own row
## order, so without this step the two would be joined by position and a
## differently ordered second table would silently attach its values to the
## wrong profile or state. When both sides carry names the secondary input is
## reordered to the primary's names, and differing name sets are an error.
## When either side is unnamed, matching stays positional, as documented for
## plain matrices and vectors.
.align_names <- function(current, target, what) {
  if (is.null(target) || is.null(current)) return(NULL)
  if (anyDuplicated(current) || !setequal(current, target)) {
    stop(errorCondition(
      sprintf(paste0("`%s` names %s, which do not match the names %s given by the ",
                     "primary input."),
              what, paste(current, collapse = ", "), paste(target, collapse = ", ")),
      class = "simulab_mismatched_names", call = NULL
    ))
  }
  match(target, current)
}

.align_matrix <- function(x, rows = NULL, columns = NULL, what) {
  if (!is.matrix(x)) return(x)
  row_index <- .align_names(rownames(x), rows, what)
  if (!is.null(row_index)) x <- x[row_index, , drop = FALSE]
  column_index <- .align_names(colnames(x), columns, what)
  if (!is.null(column_index)) x <- x[, column_index, drop = FALSE]
  x
}

.align_vector <- function(x, target, what) {
  if (is.null(x) || is.matrix(x) || is.list(x) || length(x) != length(target)) return(x)
  index <- .align_names(names(x), target, what)
  if (is.null(index)) x else x[index]
}

.align_list <- function(x, target, what) {
  if (!is.list(x) || is.data.frame(x)) return(x)
  index <- .align_names(names(x), target, what)
  if (is.null(index)) x else x[index]
}

## Pivot a square from/to table so rows and columns share one state order.
## Taking the two orders separately would put a table whose `to` column first
## names a different state than its `from` column off the diagonal.
.tidy_to_square <- function(x, what, row, column, value, levels = NULL) {
  if (!.is_tidy_input(x)) return(x)
  .require_columns(x, c(row, column, value), what)
  if (is.null(levels)) {
    levels <- unique(c(as.character(x[[row]]), as.character(x[[column]])))
  }
  .tidy_to_matrix(x, what, row, column, value, row_levels = levels, column_levels = levels)
}
