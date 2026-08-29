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
.tidy_to_matrix_list <- function(x, what, group, row, column, value,
                                 symmetric = FALSE, diagonal = NA_real_) {
  if (!.is_tidy_input(x)) return(x)
  .require_columns(x, c(group, row, column, value), what)

  keys <- as.character(x[[group]])
  order_of_appearance <- unique(keys)
  pieces <- split(x, factor(keys, levels = order_of_appearance))
  lapply(pieces, function(piece) {
    if (symmetric) {
      .tidy_to_symmetric(piece, what, row, column, value, diagonal = diagonal)
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
