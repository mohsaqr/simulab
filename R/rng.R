.with_seed <- function(seed, code) {
  stopifnot(
    "`seed` must be NULL or a single number" =
      is.null(seed) || (is.numeric(seed) && length(seed) == 1L && is.finite(seed))
  )

  if (is.null(seed)) {
    return(force(code))
  }

  had_seed <- exists(".Random.seed", envir = .GlobalEnv, inherits = FALSE)
  if (had_seed) {
    old_seed <- get(".Random.seed", envir = .GlobalEnv, inherits = FALSE)
  }

  on.exit({
    if (had_seed) {
      assign(".Random.seed", old_seed, envir = .GlobalEnv)
    } else if (exists(".Random.seed", envir = .GlobalEnv, inherits = FALSE)) {
      remove(".Random.seed", envir = .GlobalEnv)
    }
  }, add = TRUE)

  set.seed(as.integer(seed))
  force(code)
}


## Solve f(x) = 0 on `interval`, refusing to return an unconverged root.
##
## stats::uniroot() returns `$root` whether or not the search succeeded, so
## taking `$root` alone hands back a plausible-looking number from a search
## that never converged. Convergence is judged on the RESIDUAL, not on
## `$estim.prec`: `estim.prec` bounds the surviving bracket, which stays wide
## whenever the objective is flat near the root (the missingness multiplier,
## where pmin() saturates, converges to a residual of exactly zero with a
## bracket still 0.5 wide). `what` names the quantity being solved for so the
## condition says which calibration failed.
## The default `tol` is deliberately tighter than uniroot's own
## (.Machine$double.eps^0.25). uniroot's tolerance bounds x, not f, and on the
## censoring-rate objective the looser default stops one iteration early at a
## residual of 1.6e-07 where one more iteration reaches 3.2e-14.
.solve_root <- function(f, interval, what, tol = .Machine$double.eps^0.5,
                        maxiter = 1000L) {
  stopifnot(
    "`f` must be a function" = is.function(f),
    "`interval` must be a numeric vector of length 2" =
      is.numeric(interval) && length(interval) == 2L && all(is.finite(interval)),
    "`what` must be a single non-empty string" =
      is.character(what) && length(what) == 1L && nzchar(what),
    "`tol` must be a single positive number" =
      is.numeric(tol) && length(tol) == 1L && tol > 0,
    "`maxiter` must be a single positive whole number" =
      is.numeric(maxiter) && length(maxiter) == 1L && maxiter >= 1 &&
        maxiter == as.integer(maxiter)
  )

  endpoints <- c(f(interval[1L]), f(interval[2L]))
  if (!all(is.finite(endpoints))) {
    stop(errorCondition(
      sprintf("Could not solve for %s: the objective is not finite at the search bounds [%s, %s].",
              what, format(interval[1L]), format(interval[2L])),
      class = "simulab_no_solution", call = NULL
    ))
  }
  if (endpoints[1L] * endpoints[2L] > 0) {
    stop(errorCondition(
      sprintf(paste0("Could not solve for %s: no solution exists in [%s, %s], so the ",
                     "requested target is not attainable for these inputs."),
              what, format(interval[1L]), format(interval[2L])),
      class = "simulab_no_solution", call = NULL
    ))
  }

  ## uniroot() signals its own "NOT converged" warning and then returns anyway.
  ## That warning is caught here rather than suppressed, so the caller sees the
  ## stronger classed error below instead of a warning plus a wrong number.
  hit_bound <- FALSE
  fit <- withCallingHandlers(
    stats::uniroot(f, interval = interval, tol = tol, maxiter = as.integer(maxiter)),
    warning = function(w) {
      if (grepl("converge", conditionMessage(w), fixed = TRUE)) {
        hit_bound <<- TRUE
        invokeRestart("muffleWarning")
      }
    }
  )
  residual <- f(fit$root)
  residual_tol <- sqrt(.Machine$double.eps) * max(1, max(abs(endpoints)))
  if (hit_bound || fit$iter >= maxiter || !is.finite(residual) ||
      abs(residual) > residual_tol) {
    stop(errorCondition(
      sprintf(paste0("Solving for %s did not converge: stopped after %d iterations with ",
                     "residual %s, outside the tolerance %s."),
              what, fit$iter, format(residual), format(residual_tol)),
      class = "simulab_no_convergence", call = NULL
    ))
  }
  fit$root
}
