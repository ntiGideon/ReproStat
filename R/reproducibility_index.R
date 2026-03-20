#' Reproducibility index
#'
#' Computes a composite reproducibility index (RI) on a 0--100 scale by
#' aggregating normalized versions of coefficient, p-value, selection, and
#' prediction stability.
#'
#' @details
#' Each component is mapped to \eqn{[0, 1]} as follows:
#' \describe{
#'   \item{Coefficient component}{
#'     \eqn{C_\beta = \frac{1}{p}\sum_{j=1}^{p}
#'     \exp\!\left(-S_{\beta,j} / (|\hat\beta_j^{(0)}| +
#'     \varepsilon)\right)}. Relative variance drives the exponential decay.
#'     Includes all model terms (intercept and predictors).}
#'   \item{P-value component}{
#'     \eqn{C_p = \frac{1}{p'}\sum_{j \neq \text{intercept}} |2 S_{p,j} - 1|},
#'     where \eqn{p'} is the number of predictor terms (intercept excluded).
#'     Values near 0 or 1 (stable decisions) score high; 0.5 (random) scores
#'     zero.}
#'   \item{Selection component}{Same formula as p-value component, applied to
#'     selection frequencies, excluding the intercept.}
#'   \item{Prediction component}{
#'     \eqn{C_\mathrm{pred} = \exp(-\bar S_\mathrm{pred} /
#'     (\mathrm{Var}(y) + \varepsilon))}.
#'     Prediction variance relative to outcome variance drives the decay.}
#' }
#' The RI is \eqn{100 \times (C_\beta + C_p + C_\mathrm{sel} +
#' C_\mathrm{pred}) / 4}, where the mean is taken over available (non-NA)
#' components.  For \code{backend = "glmnet"}, p-values are not defined so
#' \eqn{C_p} and \eqn{C_\mathrm{sel}} are \code{NA} and the RI is based on
#' the remaining two components.
#'
#' @param diag_obj A \code{reprostat} object from \code{\link{run_diagnostics}}.
#'
#' @return A list with components:
#'   \describe{
#'     \item{\code{index}}{Scalar RI on a 0--100 scale.}
#'     \item{\code{components}}{Named numeric vector with four sub-scores:
#'       \code{coef}, \code{pvalue}, \code{selection}, \code{prediction}.
#'       \code{pvalue} and \code{selection} are \code{NA} for
#'       \code{backend = "glmnet"}.}
#'   }
#'
#' @examples
#' set.seed(1)
#' d <- run_diagnostics(mpg ~ wt + hp, data = mtcars, B = 50)
#' reproducibility_index(d)
#'
#' @importFrom stats coef var
#' @export
reproducibility_index <- function(diag_obj) {
  beta_var <- coef_stability(diag_obj)
  pred     <- prediction_stability(diag_obj)

  # Extract base coefficients; handle glmnet (needs s = lambda)
  base_coef_raw <- if (!is.null(diag_obj$backend) &&
                        diag_obj$backend == "glmnet") {
    lam <- attr(diag_obj$base_fit, ".lambda")
    cf  <- stats::coef(diag_obj$base_fit, s = lam)
    stats::setNames(as.numeric(cf), rownames(cf))
  } else {
    stats::coef(diag_obj$base_fit)
  }
  base_coef <- abs(base_coef_raw)
  b_keep    <- intersect(names(beta_var), names(base_coef))

  c_beta <- mean(
    exp(-beta_var[b_keep] / (base_coef[b_keep] + 1e-8)),
    na.rm = TRUE
  )

  # p-value and selection components: NA when p_mat is all NA (e.g. glmnet)
  p_available <- !all(is.na(diag_obj$p_mat))
  if (p_available) {
    p_sig    <- pvalue_stability(diag_obj)
    sel_freq <- selection_stability(diag_obj)
    # Exclude intercept from both c_p and c_sel for consistency
    p_pred <- p_sig[setdiff(names(p_sig), "(Intercept)")]
    c_p   <- mean(abs(2 * p_pred    - 1), na.rm = TRUE)
    c_sel <- mean(abs(2 * sel_freq  - 1), na.rm = TRUE)
  } else {
    c_p   <- NA_real_
    c_sel <- NA_real_
  }

  # Use stored y_train when available; fall back to model.response for lm/glm
  y <- if (!is.null(diag_obj$y_train)) {
    diag_obj$y_train
  } else {
    stats::model.response(diag_obj$base_fit$model)
  }
  y_scale <- stats::var(y, na.rm = TRUE)
  c_pred  <- exp(-pred$mean_variance / (y_scale + 1e-8))

  components <- c(coef = c_beta, pvalue = c_p,
                  selection = c_sel, prediction = c_pred)
  list(
    index      = 100 * mean(components, na.rm = TRUE),
    components = components
  )
}

#' Bootstrap confidence interval for the reproducibility index
#'
#' Estimates uncertainty in the RI by resampling the perturbation iterations
#' already stored in a \code{reprostat} object (no additional model fitting).
#'
#' @param diag_obj A \code{reprostat} object from \code{\link{run_diagnostics}}.
#' @param level Confidence level, e.g. \code{0.95} for a 95\% interval.
#'   Default is \code{0.95}.
#' @param R Number of bootstrap resamples of the perturbation draws.
#'   Default is \code{1000}. Values of 300--500 are sufficient for most uses.
#' @param seed Integer random seed. Default is \code{20260307}.
#'
#' @return A named numeric vector of length 2 giving the lower and upper
#'   quantile bounds of the RI bootstrap distribution.
#'
#' @examples
#' set.seed(1)
#' d <- run_diagnostics(mpg ~ wt + hp, data = mtcars, B = 50)
#' ri_confidence_interval(d, R = 200)
#'
#' @importFrom stats quantile
#' @export
ri_confidence_interval <- function(diag_obj, level = 0.95, R = 1000L,
                                   seed = 20260307L) {
  set.seed(seed)
  B    <- nrow(diag_obj$coef_mat)
  idx  <- numeric(R)

  for (r in seq_len(R)) {
    draw <- sample.int(B, size = B, replace = TRUE)
    boot_obj          <- diag_obj
    boot_obj$coef_mat <- diag_obj$coef_mat[draw,  , drop = FALSE]
    boot_obj$p_mat    <- diag_obj$p_mat[draw,    , drop = FALSE]
    boot_obj$pred_mat <- diag_obj$pred_mat[, draw, drop = FALSE]
    idx[r]            <- reproducibility_index(boot_obj)$index
  }

  alpha <- 1 - level
  stats::quantile(idx, probs = c(alpha / 2, 1 - alpha / 2), na.rm = TRUE)
}
