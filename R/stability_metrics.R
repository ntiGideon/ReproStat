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
#' Computes the proportion of perturbation iterations in which each predictor
#' is statistically significant (p-value below \code{alpha}).  The intercept
#' is excluded.  Values near 0 or 1 indicate stable decisions; values near 0.5
#' indicate high instability.
#'
#' @param diag_obj A \code{reprostat} object from \code{\link{run_diagnostics}}.
#'
#' @return A named numeric vector of significance frequencies in \eqn{[0, 1]},
#'   excluding the intercept.  All \code{NaN} for \code{backend = "glmnet"}
#'   (p-values are not defined).
#'
#' @examples
#' set.seed(1)
#' d <- run_diagnostics(mpg ~ wt + hp, data = mtcars, B = 50)
#' pvalue_stability(d)
#'
#' @importFrom stats setNames
#' @export
pvalue_stability <- function(diag_obj) {
  out  <- colMeans(diag_obj$p_mat < diag_obj$alpha, na.rm = TRUE)
  keep <- setdiff(names(out), "(Intercept)")
  stats::setNames(out[keep], keep)
}

#' Selection stability
#'
#' Measures how consistently each predictor is \emph{selected} across
#' perturbation iterations.  The definition depends on the modeling backend:
#'
#' \describe{
#'   \item{\code{"lm"}, \code{"glm"}, \code{"rlm"}}{
#'     \strong{Sign consistency}: the proportion of perturbation iterations in
#'     which the estimated coefficient has the same sign as in the base fit.
#'     A value of 1 means the direction of the effect is perfectly stable; 0.5
#'     means the sign is random.  Returns \code{NA} for a predictor whose
#'     base-fit coefficient is exactly zero.}
#'   \item{\code{"glmnet"}}{
#'     \strong{Non-zero selection frequency}: the proportion of perturbation
#'     iterations in which the coefficient is non-zero (i.e. the variable
#'     survives the regularisation penalty).}
#' }
#'
#' The intercept is always excluded.
#'
#' @param diag_obj A \code{reprostat} object from \code{\link{run_diagnostics}}.
#'
#' @return A named numeric vector of selection stability values in \eqn{[0, 1]},
#'   excluding the intercept.
#'
#' @examples
#' set.seed(1)
#' d <- run_diagnostics(mpg ~ wt + hp, data = mtcars, B = 50)
#' selection_stability(d)
#'
#' @importFrom stats coef setNames
#' @export
selection_stability <- function(diag_obj) {
  if (!is.null(diag_obj$backend) && diag_obj$backend == "glmnet") {
    # glmnet: selection = non-zero coefficient frequency
    cm   <- diag_obj$coef_mat
    keep <- setdiff(colnames(cm), "(Intercept)")
    out  <- colMeans(cm[, keep, drop = FALSE] != 0, na.rm = TRUE)
    stats::setNames(out, keep)
  } else {
    # lm / glm / rlm: sign consistency with the base-fit estimate
    base_cf    <- stats::coef(diag_obj$base_fit)
    keep       <- setdiff(names(base_cf), "(Intercept)")
    cm         <- diag_obj$coef_mat[, keep, drop = FALSE]
    out <- vapply(keep, function(j) {
      if (is.na(base_cf[j]) || base_cf[j] == 0) return(NA_real_)
      mean(sign(cm[, j]) == sign(base_cf[j]), na.rm = TRUE)
    }, numeric(1L))
    stats::setNames(out, keep)
  }
}

#' Prediction stability
#'
#' Computes the pointwise variance of predictions across perturbation
#' iterations, and the mean of these variances as a scalar summary.
#'
#' By default predictions are made on the training data used to fit the base
#' model.  For \code{method = "subsample"} this means the held-out rows
#' receive genuine out-of-sample predictions, while for \code{method =
#' "bootstrap"} the predictions are a mix of in-bag and out-of-bag.  Pass
#' \code{predict_newdata} to \code{\link{run_diagnostics}} for a dedicated
#' held-out evaluation set.
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
