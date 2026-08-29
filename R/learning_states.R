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
#' @param categories One or more learning-state categories, or `"all"`.
#'
#' @return A tidy base `data.frame` with category and state columns.
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
#' @param n Number of unique states.
#' @param categories Categories passed to `learning_states()`.
#' @param seed Optional random seed.
#'
#' @return A tidy base `data.frame` with selection order, category, and state.
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
