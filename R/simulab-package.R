#' simulab: Unified simulation of statistical and study data
#'
#' `simulab` provides one consistent interface for declarative study simulation,
#' specialized statistical designs, correlated and longitudinal data,
#' latent-variable and measurement models, survival processes, sequences, and
#' networks.
#'
#' Every simulator returns a data-frame-native `simulab_sim`. Primary data can
#' be passed directly to base-R and modeling functions. Use `components()` to
#' discover ground-truth and design tables, then `as.data.frame(x, what = ...)`
#' to retrieve them.
#'
#' @importFrom stats aggregate ave reshape
#' @keywords internal
"_PACKAGE"
