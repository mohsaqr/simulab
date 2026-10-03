## Batches of datasets from one simulator call.
##
## Every single-dataset simulator takes `batch = NULL`. Given a whole number
## instead, it returns a plain list of that many results, each exactly what the
## same call without `batch` would return. The simulator opts in with one line
## as its first statement, before it reads or changes any argument:
##
##   if (!is.null(batch)) return(.simulate_batch(batch, seed))

## Upper bound for the per-dataset seeds drawn from a batch seed. Verbs add
## offsets of up to 200000 plus a group or layer index to their seed, and the
## result must stay a valid integer seed.
.batch_seed_ceiling <- 1e9

## Run the simulator that called this helper `batch` times.
##
## The arguments the caller supplied are read from the simulator's frame, so
## each is evaluated once, and passed back to the same function with `batch`
## dropped and `seed` replaced. Values go through `do.call(quote = TRUE)` so a
## formula or other language value is passed as it is rather than re-evaluated.
## The calls run in the simulator's caller frame, so an `envir = parent.frame()`
## default resolves where the user wrote the call.
##
## Each dataset gets its own seed drawn from `seed`, not `seed + i - 1`: several
## verbs already offset their seed by a group or layer index (for example
## simulate_group_tna()), so consecutive seeds would make dataset 2's first
## group reuse dataset 1's second group's draws. With `seed = NULL` the datasets
## are consecutive draws from the caller's random-number stream.
.simulate_batch <- function(batch, seed) {
  if (!(is.numeric(batch) && length(batch) == 1L && is.finite(batch) &&
          batch >= 1 && batch == trunc(batch))) {
    stop(errorCondition(
      "`batch` must be NULL or a single positive whole number.",
      class = "simulab_invalid_batch", call = NULL
    ))
  }
  simulator_frame <- parent.frame()
  caller_frame <- parent.frame(2L)
  simulator <- sys.function(-1L)
  matched <- match.call(simulator, sys.call(-1L), expand.dots = FALSE,
                        envir = caller_frame)
  supplied <- names(as.list(matched))[-1L]
  arguments <- mget(setdiff(supplied, c("...", "batch", "seed")),
                    envir = simulator_frame)
  if ("..." %in% supplied) {
    arguments <- c(arguments, eval(quote(list(...)), simulator_frame))
  }
  seeds <- if (is.null(seed)) {
    vector("list", batch)
  } else {
    # Doubles, so a seed typed back in reproduces the dataset identically.
    as.list(as.numeric(.with_seed(seed, sample.int(.batch_seed_ceiling, batch))))
  }
  lapply(seeds, function(dataset_seed) {
    do.call(simulator, c(arguments, list(seed = dataset_seed)),
            quote = TRUE, envir = caller_frame)
  })
}
