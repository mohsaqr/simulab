.learning_state_groups <- list(
  metacognitive = c(
    "Plan", "Monitor", "Evaluate", "Reflect", "Regulate", "Adjust",
    "Adapt", "Check", "Assess", "Judge", "Strategize", "Prioritize",
    "Set_goals", "Track", "Self_assess", "Calibrate", "Diagnose",
    "Forecast", "Anticipate", "Reconsider"
  ),
  cognitive = c(
    "Read", "Study", "Analyze", "Summarize", "Memorize", "Connect",
    "Apply", "Comprehend", "Synthesize", "Compare", "Contrast", "Infer",
    "Interpret", "Elaborate", "Encode", "Retrieve", "Process", "Understand",
    "Learn", "Recognize", "Recall", "Integrate", "Differentiate", "Abstract",
    "Generalize", "Classify", "Categorize", "Deduce", "Reason", "Conclude"
  ),
  behavioral = c(
    "Practice", "Annotate", "Research", "Review", "Revise", "Test", "Write",
    "Note", "Highlight", "Underline", "Reread", "Skim", "Scan", "Draft",
    "Edit", "Copy", "Record", "Complete", "Submit", "Attempt", "Repeat",
    "Drill", "Exercise", "Rehearse", "Outline", "Diagram", "Map", "List",
    "Organize", "Structure"
  ),
  social = c(
    "Collaborate", "Discuss", "Seek_help", "Question", "Explain", "Share",
    "Teach", "Tutor", "Debate", "Argue", "Negotiate", "Consult", "Ask",
    "Answer", "Present", "Participate", "Engage", "Contribute", "Support",
    "Help", "Clarify", "Communicate", "Listen", "Respond", "Feedback",
    "Critique", "Peer_review", "Co_create", "Brainstorm", "Network"
  ),
  motivational = c(
    "Focus", "Persist", "Explore", "Create", "Strive", "Commit", "Motivate",
    "Endure", "Overcome", "Challenge", "Aspire", "Dedicate", "Invest",
    "Concentrate", "Attend", "Sustain", "Maintain", "Initiate", "Continue",
    "Pursue", "Drive", "Hustle", "Push", "Achieve", "Accomplish", "Excel",
    "Improve", "Grow", "Develop", "Progress"
  ),
  affective = c(
    "Enjoy", "Appreciate", "Value", "Interest", "Curious", "Worry", "Stress",
    "Relax", "Cope", "Manage", "Calm", "Frustrate", "Satisfy", "Excite",
    "Bore", "Confuse", "Resolve", "Embrace", "Accept", "Tolerate",
    "Celebrate", "Doubt", "Confident", "Anxious", "Hopeful", "Discourage",
    "Encourage", "Inspire", "Overwhelm", "Relief"
  ),
  group_regulation = c(
    "Adapt", "Cohesion", "Consensus", "Coregulate", "Discuss", "Emotion",
    "Monitor", "Plan", "Synthesis"
  ),
  lms = c(
    "View", "Access", "Download", "Upload", "Submit", "Click", "Navigate",
    "Browse", "Login", "Logout", "Post", "Reply", "Forum", "Quiz",
    "Assignment", "Video", "Resource", "Grade", "Attempt", "Complete",
    "Module", "Page", "File", "Link", "Course", "Content", "Discussion",
    "Message", "Announcement", "Calendar"
  )
)

#' List learning-state categories
#'
#' @return A character vector of available category identifiers.
#' @export
#'
#' @examples
#' learning_state_categories()
learning_state_categories <- function() {
  names(.learning_state_groups)
}

#' List categorized learning states for sequence simulation
#'
#' @param categories A character vector of one or more category identifiers
#'   from [learning_state_categories()], or `"all"` (the default) for every
#'   category. Unknown identifiers raise an error.
#'
#' @return A tidy base `data.frame` with one row per category-state pair and
#'   columns `category` and `state`. A state may belong to more than one
#'   category and then appears once per category, so `state` is not unique:
#'   the full catalogue has 209 rows covering 202 distinct states.
#' @export
#'
#' @examples
#' head(learning_states())
#' head(learning_states(categories = "metacognitive"))
learning_states <- function(categories = "all") {
  stopifnot(
    "`categories` must be a character vector, with at least one element" =
      is.character(categories) &&
        length(categories) >= 1L
  )
  available <- names(.learning_state_groups)
  if ("all" %in% categories) categories <- available
  invalid <- setdiff(categories, available)
  if (length(invalid)) {
    stop(sprintf("Unknown learning-state categories: %s.",
                 paste(invalid, collapse = ", ")), call. = FALSE)
  }
  result <- do.call(rbind, lapply(categories, function(category) {
    data.frame(category = category, state = .learning_state_groups[[category]],
               stringsAsFactors = FALSE, row.names = NULL)
  }))
  rownames(result) <- NULL
  result
}

#' Sample learning states reproducibly
#'
#' Samples without replacement from the distinct states of the selected
#' categories, so the result never repeats a state.
#'
#' @param n Number of unique states to draw. A single positive whole number,
#'   at most the number of distinct states in the selected categories.
#' @param categories Categories passed to [learning_states()], defaulting to
#'   `"all"`.
#' @param seed Optional random seed.
#'
#' @return A tidy base `data.frame` with `n` rows, one per sampled state, and
#'   columns `order` (the selection order, `1:n`), `category` and `state`. A
#'   state belonging to several categories gets all of them in `category`,
#'   joined by `";"`.
#' @export
#'
#' @examples
#' sample_learning_states(n = 6, categories = "cognitive", seed = 1)
sample_learning_states <- function(n, categories = "all", seed = NULL) {
  stopifnot(
    "`n` must be a single positive whole number" =
      is.numeric(n) &&
        length(n) == 1L &&
        all(n >= 1) &&
        all(n == as.integer(n)),
    "`seed` must be NULL or a single number" =
      is.null(seed) || (is.numeric(seed) && length(seed) == 1L)
  )
  catalogue <- learning_states(categories)
  unique_states <- unique(catalogue$state)
  if (n > length(unique_states)) {
    stop("n exceeds the number of unique states in the selected categories.", call. = FALSE)
  }
  selected <- .with_seed(seed, sample(unique_states, as.integer(n), replace = FALSE))
  category <- vapply(selected, function(state) {
    paste(unique(catalogue$category[catalogue$state == state]), collapse = ";")
  }, character(1))
  data.frame(order = seq_len(as.integer(n)), category = category, state = selected,
             stringsAsFactors = FALSE, row.names = NULL)
}
