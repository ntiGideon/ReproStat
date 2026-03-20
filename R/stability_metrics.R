#' Coefficient stability
#'
#' Computes the variance of each regression coefficient across perturbation
#' iterations. Lower variance indicates greater stability.
#'
#' @param diag_obj A \code{reprostat} object from \code{\link{run_diagnostics}}.
#'
#' @return A named numeric vector of per-coefficient variances.
#'
#' @examples
#' set.seed(1)
#' d <- run_diagnostics(mpg ~ wt + hp, data = mtcars, B = 50)
#' coef_stability(d)
#'
#' @importFrom stats var setNames
#' @export
coef_stability <- function(diag_obj) {
  stats::setNames(
    apply(diag_obj$coef_mat, 2L, stats::var, na.rm = TRUE),
    colnames(diag_obj$coef_mat)
  )
}

#' P-value stability
#'
#' Computes the proportion of perturbation iterations in which each coefficient
#' is statistically significant (p-value below \code{alpha}).
#' Values near 0 or 1 indicate stable decisions; values near 0.5 indicate high
#' instability.
#'
#' @param diag_obj A \code{reprostat} object from \code{\link{run_diagnostics}}.
#'
#' @return A named numeric vector of significance frequencies in \eqn{[0, 1]}.
#'
#' @examples
#' set.seed(1)
#' d <- run_diagnostics(mpg ~ wt + hp, data = mtcars, B = 50)
#' pvalue_stability(d)
#'
#' @importFrom stats setNames
#' @export
pvalue_stability <- function(diag_obj) {
  out <- colMeans(diag_obj$p_mat < diag_obj$alpha, na.rm = TRUE)
  stats::setNames(out, colnames(diag_obj$p_mat))
}

#' Selection stability
#'
#' Computes the proportion of perturbation iterations in which each predictor
#' is selected (its p-value is below \code{alpha}). The intercept is excluded.
#'
#' @param diag_obj A \code{reprostat} object from \code{\link{run_diagnostics}}.
#'
#' @return A named numeric vector of selection frequencies in \eqn{[0, 1]},
#'   excluding the intercept.
#'
#' @examples
#' set.seed(1)
#' d <- run_diagnostics(mpg ~ wt + hp, data = mtcars, B = 50)
#' selection_stability(d)
#'
#' @importFrom stats setNames
#' @export
selection_stability <- function(diag_obj) {
  out <- colMeans(diag_obj$p_mat < diag_obj$alpha, na.rm = TRUE)
  keep <- setdiff(names(out), "(Intercept)")
  out[keep]
}

#' Prediction stability
#'
#' Computes the pointwise variance of predictions across perturbation
#' iterations, and the mean of these variances as a scalar summary.
#'
#' @param diag_obj A \code{reprostat} object from \code{\link{run_diagnostics}}.
#'
#' @return A list with components:
#'   \describe{
#'     \item{\code{pointwise_variance}}{Numeric vector of per-observation
#'       prediction variances.}
#'     \item{\code{mean_variance}}{Mean of pointwise variances.}
#'   }
#'
#' @examples
#' set.seed(1)
#' d <- run_diagnostics(mpg ~ wt + hp, data = mtcars, B = 50)
#' prediction_stability(d)$mean_variance
#'
#' @importFrom stats var
#' @export
prediction_stability <- function(diag_obj) {
  vars <- apply(diag_obj$pred_mat, 1L, stats::var, na.rm = TRUE)
  list(pointwise_variance = vars, mean_variance = mean(vars, na.rm = TRUE))
}
