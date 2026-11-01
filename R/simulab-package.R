#' simulab: Simulates a Wide Variety of Data Shapes, Sizes and Distributions
#'
#' `simulab` generates data in different shapes, sample sizes, distributions
#' and parameters: declared study variables, statistical designs, correlated
#' and longitudinal data, latent-variable and measurement models, survival
#' processes, sequences of states, and networks. The generating parameters are
#' drawn at random or set in advance, and in both cases they are stored with
#' the data, so their recovery can be tested.
#'
#' Every generator returns a data-frame-native `simulab_sim`, except
#' [simulate_tna()], which returns a native `tna` model of class `simulab_tna`.
#' The primary data can be passed directly to base-R and modeling functions.
#' [components()] lists the stored truth and design tables, and
#' `as.data.frame(x, what = ...)` returns each of them. Every single-dataset
#' generator takes `seed`, for reproducible output, and `batch`, which returns
#' a plain list of that many data sets, each reproducible from its own seed.
#' [list_simulators()] catalogues the generators.
#'
#' @importFrom stats aggregate ave reshape
#' @keywords internal
"_PACKAGE"
