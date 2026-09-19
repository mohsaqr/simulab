.global_name_groups <- list(
  africa = c("Amina", "Kwame", "Nia", "Tendai", "Zuri", "Chidi", "Lerato", "Kofi", "Amara", "Thabo"),
  east_asia = c("Mei", "Haruto", "Jiwoo", "Wei", "Yuna", "Ren", "Minjun", "Hana", "Tao", "Sora"),
  south_asia = c("Aarav", "Ananya", "Ishaan", "Diya", "Kabir", "Meera", "Rohan", "Asha", "Vikram", "Nisha"),
  middle_east = c("Layla", "Omar", "Noor", "Zayd", "Mariam", "Yusuf", "Salma", "Karim", "Rania", "Sami"),
  europe = c("Sofia", "Luca", "Freja", "Mateo", "Elena", "Jonas", "Ines", "Marek", "Nora", "Theo"),
  latin_america = c("Camila", "Diego", "Valentina", "Mateo", "Lucia", "Santiago", "Mariana", "Rafael", "Elisa", "Tomas"),
  north_america = c("Avery", "Jordan", "Taylor", "Morgan", "Riley", "Casey", "Quinn", "Cameron", "Skyler", "Parker"),
  oceania = c("Aria", "Jack", "Maia", "Liam", "Isla", "Noah", "Aroha", "Finn", "Ruby", "Kai")
)

#' List global-name regions
#'
#' @return A character vector of available region identifiers.
#' @export
#'
#' @examples
#' global_name_regions()
global_name_regions <- function() {
  names(.global_name_groups)
}

#' List the global-name catalogue
#'
#' @param regions Region names from [global_name_regions()], or `"all"`, the
#'   default, for every region.
#'
#' @return A tidy base `data.frame` with one row per region/name pair and
#'   columns `region` and `name`. A name shared by two regions appears once per
#'   region.
#' @export
#'
#' @examples
#' head(global_names())
#' head(global_names(regions = c("east_asia", "africa")))
global_names <- function(regions = "all") {
  stopifnot(
    "`regions` must be a character vector, with at least one element" =
      is.character(regions) &&
        length(regions) >= 1L
  )
  available <- names(.global_name_groups)
  if ("all" %in% regions) regions <- available
  invalid <- setdiff(regions, available)
  if (length(invalid)) {
    stop(sprintf("Unknown name regions: %s.", paste(invalid, collapse = ", ")),
         call. = FALSE)
  }
  result <- do.call(rbind, lapply(regions, function(region) data.frame(
    region = region, name = .global_name_groups[[region]],
    stringsAsFactors = FALSE, row.names = NULL
  )))
  rownames(result) <- NULL
  result
}

#' Sample globally diverse names
#'
#' @param n Number of unique names to draw, at most the number of distinct names
#'   the chosen regions hold.
#' @param regions Regions passed to `global_names()`.
#' @param seed Optional seed.
#'
#' @return A tidy base `data.frame` with one row per sampled name and columns
#'   `order`, `region` and `name`. A name belonging to more than one region
#'   carries them joined by `";"`.
#' @export
#'
#' @examples
#' sample_global_names(n = 8, seed = 1)
sample_global_names <- function(n, regions = "all", seed = NULL) {
  stopifnot(
    "`n` must be a single positive whole number" =
      is.numeric(n) &&
        length(n) == 1L &&
        all(n >= 1) &&
        all(n == as.integer(n))
  )
  catalogue <- global_names(regions)
  unique_names <- unique(catalogue$name)
  if (n > length(unique_names)) stop("n exceeds available unique names.", call. = FALSE)
  selected <- .with_seed(seed, sample(unique_names, as.integer(n), replace = FALSE))
  region <- vapply(selected, function(value) {
    paste(unique(catalogue$region[catalogue$name == value]), collapse = ";")
  }, character(1))
  data.frame(order = seq_len(as.integer(n)), region = region, name = selected,
             stringsAsFactors = FALSE, row.names = NULL)
}

#' List built-in simulation scenarios
#'
#' @return A base `data.frame` with one row per scenario and columns `scenario`,
#'   `family` and `description`. Every `scenario` is accepted by
#'   [run_simulation_scenario()].
#' @export
#'
#' @examples
#' simulation_scenarios()
simulation_scenarios <- function() {
  data.frame(
    scenario = c("small_effect", "large_effect", "clustered_trial", "growth",
                 "learning_sequences", "group_tna"),
    family = c("statistical", "statistical", "multilevel", "longitudinal",
               "sequence", "sequence"),
    description = c(
      "Two groups with Cohen's d approximately 0.2",
      "Two groups with Cohen's d approximately 0.8",
      "Clustered outcome with treatment predictor",
      "Five-occasion linear growth",
      "Learning-state sequences with probability perturbation",
      "Three grouped TNA learning-state systems"
    ),
    stringsAsFactors = FALSE, row.names = NULL
  )
}

#' Run a built-in simulation scenario
#'
#' @param scenario A single scenario name from [simulation_scenarios()].
#' @param seed Optional seed.
#'
#' @return The `simulab_sim` base `data.frame` returned by the simulator the
#'   scenario calls, whose columns depend on the scenario's family.
#' @export
#'
#' @examples
#' result <- run_simulation_scenario("small_effect", seed = 1)
#' head(result)
run_simulation_scenario <- function(scenario, seed = NULL) {
  stopifnot(
    "`scenario` must be a single string" =
      is.character(scenario) &&
        length(scenario) == 1L
  )
  if (!scenario %in% simulation_scenarios()$scenario) stop("Unknown simulation scenario.", call. = FALSE)
  switch(
    scenario,
    small_effect = simulate_ttest(100, 100, 0, 0.2, seed = seed),
    large_effect = simulate_ttest(100, 100, 0, 0.8, seed = seed),
    clustered_trial = simulate_multilevel(
      30, 20, intercept = 0, slopes = c(treatment = 0.5),
      random_intercept_sd = 0.7, seed = seed
    ),
    growth = simulate_growth(200, 0:4, intercept = 0, slope = 0.5, seed = seed),
    learning_sequences = simulate_sequences(
      200, chain_length = 20, n_states = 6,
      state_categories = c("metacognitive", "cognitive"),
      instability = "perturb", seed = seed
    ),
    group_tna = simulate_group_tna(
      3, 30, chain_length = 15, n_states = 5,
      state_categories = c("social", "group_regulation"), seed = seed
    )
  )
}
