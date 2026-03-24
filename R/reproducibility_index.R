#' Reproducibility index
#'
#' Computes a composite reproducibility index (RI) on a 0--100 scale by
#' aggregating normalized versions of coefficient, p-value, selection, and
#' prediction stability.
#'
#' @details
#' Each component is mapped to \eqn{[0, 1]} as follows:
#' \describe{
#'   \item{Coefficient component (\eqn{C_\beta})}{
#'     \eqn{C_\beta = \frac{1}{p}\sum_{j=1}^{p}
#'     \exp\!\left(-S_{\beta,j} / (|\hat\beta_j^{(0)}| +
#'     \bar\beta)\right)}, where
#'     \eqn{\bar\beta = \max(\mathrm{median}_j|\hat\beta_j^{(0)}|,\, 10^{-4})}
#'     is a global scale reference.  This prevents the exponential from
#'     collapsing to zero for weakly-identified (near-zero) predictors.
#'     Includes all model terms (intercept and predictors).}
#'   \item{P-value component (\eqn{C_p})}{
#'     \eqn{C_p = \frac{1}{p'}\sum_{j \neq \text{intercept}} |2 S_{p,j} - 1|},
#'     where \eqn{S_{p,j}} is the proportion of perturbation iterations in
#'     which term \eqn{j} is significant at level \code{alpha} and \eqn{p'}
#'     is the number of predictor terms.  Values near 0 or 1 (consistent
#'     decisions) score high; 0.5 (random) scores zero.
#'     \code{NA} for \code{backend = "glmnet"}.}
#'   \item{Selection component (\eqn{C_\mathrm{sel}})}{
#'     For \code{"lm"}, \code{"glm"}, \code{"rlm"}: the mean
#'     \emph{sign consistency} across predictors — the proportion of
#'     perturbation iterations in which each predictor's estimated sign
#'     agrees with the base-fit sign.  Captures stability of effect direction,
#'     which is distinct from significance stability (\eqn{C_p}).
#'     For \code{"glmnet"}: the mean \emph{non-zero selection frequency} —
#'     proportion of perturbation iterations in which each predictor's
#'     coefficient is non-zero.  Always available (never \code{NA}).
#'     Excludes the intercept.}
#'   \item{Prediction component (\eqn{C_\mathrm{pred}})}{
#'     \eqn{C_\mathrm{pred} = \exp(-\bar S_\mathrm{pred} /
#'     (\mathrm{Var}(y) + \varepsilon))}.
#'     Prediction variance relative to outcome variance drives the decay.}
#' }
#' The RI is \eqn{100 \times (C_\beta + C_p + C_\mathrm{sel} +
#' C_\mathrm{pred}) / k}, where \eqn{k} is the number of non-\code{NA}
#' components.  For \code{backend = "glmnet"}, \eqn{C_p} is \code{NA} so
#' the RI is based on three components (\eqn{k = 3}): \eqn{C_\beta},
#' \eqn{C_\mathrm{sel}}, and \eqn{C_\mathrm{pred}}.  All other backends
#' contribute all four components (\eqn{k = 4}).
#'
#' \strong{Comparability across backends:} because \code{"glmnet"} uses three
#' components and \code{"lm"}/\code{"glm"}/\code{"rlm"} use four, RI values
#' are not directly comparable across backends.
#'
#' @param diag_obj A \code{reprostat} object from \code{\link{run_diagnostics}}.
#'
#' @return A list with components:
#'   \describe{
#'     \item{\code{index}}{Scalar RI on a 0--100 scale.}
#'     \item{\code{components}}{Named numeric vector with four sub-scores:
#'       \code{coef}, \code{pvalue}, \code{selection}, \code{prediction}.
#'       \code{pvalue} is \code{NA} for \code{backend = "glmnet"};
#'       \code{selection} is always available.}
#'   }
#'
#' @examples
#' set.seed(1)
#' d <- run_diagnostics(mpg ~ wt + hp, data = mtcars, B = 50)
#' reproducibility_index(d)
#'
#' @importFrom stats coef var median
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

  # c_beta: exponential decay of variance relative to coefficient magnitude.
  # scale_ref (median |base_coef|) prevents collapse for near-zero coefficients.
  scale_ref <- max(stats::median(base_coef[b_keep], na.rm = TRUE), 1e-4)
  c_beta <- mean(
    exp(-beta_var[b_keep] / (base_coef[b_keep] + scale_ref)),
    na.rm = TRUE
  )

  # c_p: stability of p-value significance decisions (NA for glmnet).
  # Uses abs(2x - 1) so that both "always significant" and "always
  # non-significant" score high; 0.5 (random) scores zero.
  p_available <- !all(is.na(diag_obj$p_mat))
  c_p <- if (p_available) {
    p_sig <- pvalue_stability(diag_obj)   # excludes intercept
    mean(abs(2 * p_sig - 1), na.rm = TRUE)
  } else {
    NA_real_
  }

  # c_sel: sign consistency (lm/glm/rlm) or non-zero frequency (glmnet).
  # This is genuinely distinct from c_p: it captures direction/selection
  # stability rather than significance-decision stability.
  c_sel <- mean(selection_stability(diag_obj), na.rm = TRUE)

  # c_pred: prediction variance relative to outcome variance.
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
#' @param seed Integer random seed passed to \code{\link[base]{set.seed}}, or
#'   \code{NULL} (default) to leave the global RNG state undisturbed.
#'   Pass an integer for fully reproducible intervals.
#'
#' @return A named numeric vector of length 2 giving the lower and upper
#'   quantile bounds of the RI bootstrap distribution.
#'
#' @examples
#' set.seed(1)
#' d <- run_diagnostics(mpg ~ wt + hp, data = mtcars, B = 50)
#' ri_confidence_interval(d, R = 200, seed = 1)
#'
#' @importFrom stats quantile
#' @export
ri_confidence_interval <- function(diag_obj, level = 0.95, R = 1000L,
                                   seed = NULL) {
  if (!is.null(seed)) set.seed(seed)
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
