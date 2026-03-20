#' ReproStat: Reproducibility Diagnostics for Statistical Modeling
#'
#' @description
#' Tools for diagnosing the reproducibility of statistical model outputs under
#' data perturbations. The package implements bootstrap, subsampling, and
#' noise-based perturbation schemes and computes coefficient stability,
#' p-value stability, selection stability, prediction stability, and a
#' composite reproducibility index on a 0--100 scale.
#' Cross-validation ranking stability for model comparison and visualization
#' utilities are also provided.
#'
#' @section Typical workflow:
#' \enumerate{
#'   \item Call \code{\link{run_diagnostics}} with your formula and data.
#'   \item Inspect individual metrics with \code{\link{coef_stability}},
#'         \code{\link{pvalue_stability}}, \code{\link{selection_stability}},
#'         and \code{\link{prediction_stability}}.
#'   \item Summarise with \code{\link{reproducibility_index}}.
#'   \item Visualise with \code{\link{plot_stability}}.
#'   \item Compare competing models with \code{\link{cv_ranking_stability}}
#'         and \code{\link{plot_cv_stability}}.
#' }
#'
#' @keywords internal
"_PACKAGE"
