#' Run reproducibility diagnostics
#'
#' Fits a model on the original data, then repeatedly fits on perturbed
#' versions to collect coefficient estimates, p-values, and predictions for
#' downstream stability analysis.  Four modeling backends are supported:
#' ordinary least squares (\code{"lm"}), generalized linear models
#' (\code{"glm"}), robust regression (\code{"rlm"} via \pkg{MASS}), and
#' penalized regression (\code{"glmnet"} via \pkg{glmnet}).
#'
#' @param formula A model formula.
#' @param data A data frame.
#' @param B Integer. Number of perturbation iterations. Default is \code{200}.
#' @param method Perturbation method passed to \code{\link{perturb_data}}.
#'   One of \code{"bootstrap"} (default), \code{"subsample"}, or
#'   \code{"noise"}.
#' @param alpha Significance threshold for p-value and selection stability.
#'   Default is \code{0.05}.
#' @param frac Subsampling fraction. Passed to \code{\link{perturb_data}}.
#'   Default is \code{0.8}.
#' @param noise_sd Noise level. Passed to \code{\link{perturb_data}}.
#'   Default is \code{0.05}.
#' @param predict_newdata Optional data frame for out-of-sample prediction
#'   stability. Defaults to \code{data}.
#' @param family A GLM family object (e.g. \code{stats::binomial()},
#'   \code{stats::poisson()}). Used only when \code{backend = "glm"} (or
#'   when \code{family} is non-\code{NULL} and \code{backend = "lm"}, in
#'   which case the backend is silently promoted to \code{"glm"}).
#' @param backend Modeling backend.  One of \code{"lm"} (default),
#'   \code{"glm"}, \code{"rlm"} (robust M-estimation via
#'   \code{MASS::rlm}), or \code{"glmnet"} (penalized regression via
#'   \code{glmnet::glmnet}).
#' @param en_alpha Elastic-net mixing parameter passed to
#'   \code{glmnet::glmnet}: \code{1} (default) gives the LASSO,
#'   \code{0} gives ridge, intermediate values give elastic net.
#'   Ignored for other backends.
#' @param lambda Regularization parameter for \code{glmnet}.  When
#'   \code{NULL} (default) the penalty is selected by
#'   \code{glmnet::cv.glmnet} using \code{lambda.min}.  Ignored for
#'   other backends.
#'
#' @return An object of class \code{"reprostat"}, a list with components:
#'   \describe{
#'     \item{\code{call}}{The matched call.}
#'     \item{\code{formula}}{The model formula.}
#'     \item{\code{B}}{Number of iterations used.}
#'     \item{\code{alpha}}{Significance threshold used.}
#'     \item{\code{base_fit}}{Model fitted on the original data.}
#'     \item{\code{y_train}}{Response vector from the original data (used
#'       internally for RI computation).}
#'     \item{\code{coef_mat}}{B x p matrix of coefficient estimates.}
#'     \item{\code{p_mat}}{B x p matrix of p-values, or all-\code{NA} for
#'       \code{backend = "glmnet"} (where p-values are not defined).}
#'     \item{\code{pred_mat}}{n x B matrix of predictions.}
#'     \item{\code{method}}{Perturbation method used.}
#'     \item{\code{family}}{GLM family used, or \code{NULL}.}
#'     \item{\code{backend}}{Backend used.}
#'     \item{\code{en_alpha}}{Elastic-net mixing parameter used (only relevant
#'       for \code{backend = "glmnet"}, otherwise \code{NA}).}
#'   }
#'
#' @examples
#' set.seed(1)
#' # Linear model
#' diag_lm <- run_diagnostics(mpg ~ wt + hp, data = mtcars, B = 50)
#' print(diag_lm)
#'
#' # Logistic regression
#' diag_glm <- run_diagnostics(am ~ wt + hp + qsec, data = mtcars, B = 50,
#'                             family = stats::binomial())
#' reproducibility_index(diag_glm)
#'
#' # Robust regression (requires MASS)
#' if (requireNamespace("MASS", quietly = TRUE)) {
#'   diag_rlm <- run_diagnostics(mpg ~ wt + hp, data = mtcars, B = 50,
#'                               backend = "rlm")
#'   reproducibility_index(diag_rlm)
#' }
#'
#' # Penalized regression / LASSO (requires glmnet)
#' if (requireNamespace("glmnet", quietly = TRUE)) {
#'   diag_glmnet <- run_diagnostics(mpg ~ wt + hp + disp + qsec, data = mtcars,
#'                                  B = 50, backend = "glmnet", en_alpha = 1)
#'   reproducibility_index(diag_glmnet)
#' }
#'
#' @importFrom stats lm glm coef predict model.matrix model.frame model.response pt
#' @export
run_diagnostics <- function(formula, data, B = 200,
                            method = c("bootstrap", "subsample", "noise"),
                            alpha = 0.05, frac = 0.8, noise_sd = 0.05,
                            predict_newdata = NULL,
                            family = NULL,
                            backend = c("lm", "glm", "rlm", "glmnet"),
                            en_alpha = 1,
                            lambda = NULL) {
  method  <- match.arg(method)
  backend <- match.arg(backend)

  if (!is.data.frame(data))
    stop("`data` must be a data frame.")
  if (!inherits(formula, "formula"))
    stop("`formula` must be a formula object.")
  if (!is.numeric(B) || length(B) != 1L || B < 2L)
    stop("`B` must be an integer >= 2.")
  B <- as.integer(B)
  if (!is.numeric(alpha) || alpha <= 0 || alpha >= 1)
    stop("`alpha` must be a number in (0, 1).")

  # Backward compat: if family is supplied with backend = "lm", promote to "glm"
  if (!is.null(family) && backend == "lm") backend <- "glm"

  if (is.null(predict_newdata)) predict_newdata <- data

  # Package availability checks
  if (backend == "rlm" && !requireNamespace("MASS", quietly = TRUE))
    stop("Package 'MASS' is required for backend = \"rlm\". ",
         "Install it with: install.packages(\"MASS\")")
  if (backend == "glmnet" && !requireNamespace("glmnet", quietly = TRUE))
    stop("Package 'glmnet' is required for backend = \"glmnet\". ",
         "Install it with: install.packages(\"glmnet\")")

  # Store response vector from original data for RI computation
  y_train <- stats::model.response(stats::model.frame(formula, data))

  # ---- internal helpers ----

  .fit <- function(d) {
    switch(backend,
      "lm" = stats::lm(formula = formula, data = d),
      "glm" = withCallingHandlers(
        stats::glm(formula = formula, data = d, family = family,
                   control = stats::glm.control(maxit = 100)),
        warning = function(w) {
          if (grepl("glm.fit", conditionMessage(w), fixed = TRUE))
            invokeRestart("muffleWarning")
        }
      ),
      "rlm" = MASS::rlm(formula = formula, data = d),
      "glmnet" = {
        X <- stats::model.matrix(formula, d)[, -1L, drop = FALSE]
        y <- stats::model.response(stats::model.frame(formula, d))
        lam <- if (is.null(lambda)) {
          cv_fit <- glmnet::cv.glmnet(X, y, alpha = en_alpha)
          cv_fit$lambda.min
        } else {
          lambda
        }
        fit <- glmnet::glmnet(X, y, alpha = en_alpha, lambda = lam)
        attr(fit, ".lambda") <- lam
        attr(fit, ".formula") <- formula
        fit
      }
    )
  }

  .coef <- function(fit) {
    if (backend == "glmnet") {
      lam <- attr(fit, ".lambda")
      cf  <- stats::coef(fit, s = lam)
      stats::setNames(as.numeric(cf), rownames(cf))
    } else {
      stats::coef(fit)
    }
  }

  # Returns named numeric p-value vector, or NULL when not applicable
  .pvals <- function(fit) {
    if (backend == "glmnet") return(NULL)
    if (backend == "rlm") {
      sm <- summary(fit)$coefficients
      if (is.null(sm) || ncol(sm) < 3L) return(NULL)
      t_vals <- sm[, 3L]
      df_res <- fit$df.residual
      if (is.null(df_res) || !is.finite(df_res) || df_res <= 0L)
        df_res <- nrow(fit$model) - length(stats::coef(fit))
      pv <- 2 * stats::pt(-abs(t_vals), df = df_res)
      stats::setNames(pv, rownames(sm))
    } else {
      sm <- summary(fit)$coefficients
      if (is.null(sm) || ncol(sm) < 4L) return(NULL)
      stats::setNames(sm[, 4L], rownames(sm))
    }
  }

  .predict <- function(fit, newdata) {
    if (backend == "glmnet") {
      f   <- attr(fit, ".formula")
      lam <- attr(fit, ".lambda")
      X_new <- stats::model.matrix(f, newdata)[, -1L, drop = FALSE]
      as.numeric(stats::predict(fit, newx = X_new, s = lam, type = "response"))
    } else if (inherits(fit, "glm")) {
      stats::predict(fit, newdata = newdata, type = "response")
    } else {
      stats::predict(fit, newdata = newdata)
    }
  }

  # ---- base fit ----
  base_fit  <- .fit(data)
  terms_all <- names(.coef(base_fit))
  p         <- length(terms_all)

  coef_mat <- matrix(NA_real_, nrow = B, ncol = p,
                     dimnames = list(NULL, terms_all))
  p_mat    <- matrix(NA_real_, nrow = B, ncol = p,
                     dimnames = list(NULL, terms_all))
  pred_mat <- matrix(NA_real_, nrow = nrow(predict_newdata), ncol = B)

  # ---- perturbation loop ----
  for (b in seq_len(B)) {
    d_b   <- perturb_data(data, method = method, frac = frac, noise_sd = noise_sd)
    fit_b <- tryCatch(.fit(d_b), error = function(e) NULL)
    if (is.null(fit_b)) next

    cf <- tryCatch(.coef(fit_b), error = function(e) NULL)
    if (!is.null(cf)) {
      keep <- intersect(names(cf), terms_all)
      coef_mat[b, keep] <- cf[keep]
    }

    pv <- tryCatch(.pvals(fit_b), error = function(e) NULL)
    if (!is.null(pv)) {
      keep_p <- intersect(names(pv), terms_all)
      p_mat[b, keep_p] <- pv[keep_p]
    }

    pred_mat[, b] <- tryCatch(
      .predict(fit_b, newdata = predict_newdata),
      error = function(e) rep(NA_real_, nrow(predict_newdata))
    )
  }

  structure(
    list(
      call     = match.call(),
      formula  = formula,
      B        = B,
      alpha    = alpha,
      base_fit = base_fit,
      y_train  = y_train,
      coef_mat = coef_mat,
      p_mat    = p_mat,
      pred_mat = pred_mat,
      method   = method,
      family   = family,
      backend  = backend,
      en_alpha = if (backend == "glmnet") en_alpha else NA_real_
    ),
    class = "reprostat"
  )
}

#' Print a reprostat object
#'
#' @param x A \code{reprostat} object.
#' @param ... Further arguments (ignored).
#'
#' @return Invisibly returns \code{x}.
#'
#' @examples
#' set.seed(1)
#' d <- run_diagnostics(mpg ~ wt + hp, data = mtcars, B = 20)
#' print(d)
#'
#' @export
print.reprostat <- function(x, ...) {
  backend_label <- switch(x$backend,
    "lm"     = "lm",
    "glm"    = paste0("glm (", x$family$family, "/", x$family$link, ")"),
    "rlm"    = "rlm (MASS robust M-estimation)",
    "glmnet" = paste0("glmnet (lambda = ",
                      if (!is.null(attr(x$base_fit, ".lambda")))
                        format(round(attr(x$base_fit, ".lambda"), 5), scientific = FALSE)
                      else "cv-selected",
                      ", en_alpha = ", x$en_alpha, ")")
  )
  cat("ReproStat Diagnostics\n")
  cat("---------------------\n")
  cat("Formula   :", deparse(x$formula), "\n")
  cat("Backend   :", backend_label, "\n")
  cat("Method    :", x$method, "\n")
  cat("Iterations:", x$B, "\n")
  cat("Terms     :", paste(colnames(x$coef_mat), collapse = ", "), "\n")
  if (x$backend == "glmnet")
    cat("Note      : p-values not defined for penalized regression;",
        "p_mat is all NA.\n")
  invisible(x)
}
