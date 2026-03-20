#' Cross-validation ranking stability
#'
#' Evaluates model selection stability by repeatedly running \eqn{K}-fold
#' cross-validation and recording the error-metric rank of each candidate model
#' across repetitions.  Supports four modeling backends: \code{"lm"},
#' \code{"glm"}, \code{"rlm"} (robust regression via \pkg{MASS}), and
#' \code{"glmnet"} (penalized regression via \pkg{glmnet}).
#'
#' @param formulas A named list of formulas, one per candidate model.
#' @param data A data frame.
#' @param v Number of cross-validation folds. Must satisfy
#'   \eqn{2 \le v \le n}. Default is \code{5}.
#' @param R Number of cross-validation repetitions. Default is \code{30}.
#' @param seed Integer random seed for reproducibility. Default is
#'   \code{20260307}.
#' @param family A GLM family object (e.g. \code{stats::binomial()}) or
#'   \code{NULL} (default) to use \code{stats::lm}.  Used only with
#'   \code{backend = "glm"}.
#' @param backend Modeling backend.  One of \code{"lm"} (default),
#'   \code{"glm"}, \code{"rlm"}, or \code{"glmnet"}.
#' @param en_alpha Elastic-net mixing parameter for \code{glmnet} (default
#'   \code{1} for LASSO). Ignored for other backends.
#' @param lambda Regularization parameter for \code{glmnet}. When \code{NULL}
#'   (default), selected per fold via \code{glmnet::cv.glmnet}.  Ignored for
#'   other backends.
#' @param metric Error metric used for ranking. One of \code{"auto"} (default:
#'   \code{"rmse"} for \code{lm}/\code{"rlm"}/\code{"glmnet"},
#'   \code{"logloss"} for \code{glm} with a non-Gaussian family),
#'   \code{"rmse"}, or \code{"logloss"}.  The \code{"logloss"} metric
#'   assumes a \strong{binary} (0/1) response; it is not defined for
#'   multi-class outcomes.
#'
#' @return A list with components:
#'   \describe{
#'     \item{\code{settings}}{List with \code{v}, \code{R}, \code{seed},
#'       \code{metric}, \code{family}, \code{backend}, \code{en_alpha}, and
#'       \code{lambda}.}
#'     \item{\code{rmse_mat}}{\eqn{R \times M} matrix of per-repeat mean
#'       error values (RMSE or log-loss depending on \code{metric}).}
#'     \item{\code{rank_mat}}{\eqn{R \times M} integer matrix of per-repeat
#'       model ranks (rank 1 = best).}
#'     \item{\code{summary}}{Data frame with columns \code{model},
#'       \code{mean_rmse}, \code{sd_rmse}, \code{mean_rank}, and
#'       \code{top1_frequency}, ordered by mean rank.  Note: the columns
#'       \code{mean_rmse} and \code{sd_rmse} store the mean and standard
#'       deviation of the chosen error metric (RMSE or log-loss); the column
#'       names are retained for backwards compatibility.}
#'   }
#'
#' @examples
#' \donttest{
#' # Linear models
#' models <- list(m1 = mpg ~ wt + hp, m2 = mpg ~ wt + hp + disp)
#' cv_ranking_stability(models, mtcars, v = 5, R = 20)
#'
#' # Logistic models
#' glm_models <- list(m1 = am ~ wt + hp, m2 = am ~ wt + hp + qsec)
#' cv_ranking_stability(glm_models, mtcars, v = 5, R = 20,
#'                      family = stats::binomial(), metric = "logloss")
#'
#' # Robust regression
#' if (requireNamespace("MASS", quietly = TRUE)) {
#'   cv_ranking_stability(models, mtcars, v = 5, R = 20, backend = "rlm")
#' }
#'
#' # Penalized (LASSO)
#' if (requireNamespace("glmnet", quietly = TRUE)) {
#'   lasso_models <- list(m1 = mpg ~ wt + hp, m2 = mpg ~ wt + hp + disp + qsec)
#'   cv_ranking_stability(lasso_models, mtcars, v = 5, R = 20, backend = "glmnet")
#' }
#' }
#'
#' @importFrom stats lm glm predict model.frame model.response sd model.matrix
#' @export
cv_ranking_stability <- function(formulas, data, v = 5L, R = 30L,
                                 seed = 20260307L,
                                 family = NULL,
                                 backend = c("lm", "glm", "rlm", "glmnet"),
                                 en_alpha = 1,
                                 lambda = NULL,
                                 metric = c("auto", "rmse", "logloss")) {
  metric  <- match.arg(metric)
  backend <- match.arg(backend)

  # Backward compat: family non-NULL with backend "lm" -> promote to "glm"
  if (!is.null(family) && backend == "lm") backend <- "glm"

  if (metric == "auto") {
    metric <- if (backend == "glm" && !is.null(family) &&
                    !identical(family$family, "gaussian")) "logloss" else "rmse"
  }

  if (!is.list(formulas))
    stop("`formulas` must be a named list of formulas.")
  if (is.null(names(formulas)) || any(names(formulas) == ""))
    names(formulas) <- paste0("model_", seq_along(formulas))

  n <- nrow(data)
  if (v < 2L || v > n)
    stop("`v` must be between 2 and nrow(data).")
  if (!is.numeric(R) || length(R) != 1L || R < 1L)
    stop("`R` must be a positive integer.")

  if (backend == "rlm" && !requireNamespace("MASS", quietly = TRUE))
    stop("Package 'MASS' is required for backend = \"rlm\".")
  if (backend == "glmnet" && !requireNamespace("glmnet", quietly = TRUE))
    stop("Package 'glmnet' is required for backend = \"glmnet\".")

  # ---- internal fit / predict helpers ----

  .fit_fold <- function(f, train) {
    switch(backend,
      "lm"  = stats::lm(f, data = train),
      "glm" = stats::glm(f, data = train, family = family),
      "rlm" = MASS::rlm(f, data = train),
      "glmnet" = {
        X_tr <- stats::model.matrix(f, train)[, -1L, drop = FALSE]
        y_tr <- stats::model.response(stats::model.frame(f, train))
        lam  <- if (is.null(lambda)) {
          cv_fit <- glmnet::cv.glmnet(X_tr, y_tr, alpha = en_alpha)
          cv_fit$lambda.min
        } else {
          lambda
        }
        fit <- glmnet::glmnet(X_tr, y_tr, alpha = en_alpha, lambda = lam)
        attr(fit, ".lambda")  <- lam
        attr(fit, ".formula") <- f
        fit
      }
    )
  }

  .pred_fold <- function(fit, test) {
    if (backend == "glmnet") {
      f_   <- attr(fit, ".formula")
      lam_ <- attr(fit, ".lambda")
      X_ts <- stats::model.matrix(f_, test)[, -1L, drop = FALSE]
      as.numeric(stats::predict(fit, newx = X_ts, s = lam_, type = "response"))
    } else if (inherits(fit, "glm")) {
      stats::predict(fit, newdata = test, type = "response")
    } else {
      stats::predict(fit, newdata = test)
    }
  }

  # ---- main CV loop ----

  set.seed(seed)
  model_names <- names(formulas)
  rmse_mat <- matrix(NA_real_, nrow = R, ncol = length(formulas),
                     dimnames = list(NULL, model_names))
  rank_mat <- matrix(NA_integer_, nrow = R, ncol = length(formulas),
                     dimnames = list(NULL, model_names))

  for (r in seq_len(R)) {
    fold_ids <- sample(rep(seq_len(v), length.out = n))

    for (m in seq_along(formulas)) {
      f         <- formulas[[m]]
      fold_err  <- rep(NA_real_, v)

      for (k in seq_len(v)) {
        test_idx  <- which(fold_ids == k)
        train_idx <- setdiff(seq_len(n), test_idx)
        train     <- data[train_idx, , drop = FALSE]
        test      <- data[test_idx,  , drop = FALSE]

        fit <- tryCatch(.fit_fold(f, train), error = function(e) NULL)
        if (is.null(fit)) next

        y_test <- stats::model.response(stats::model.frame(f, data = test))
        pred   <- tryCatch(
          .pred_fold(fit, test),
          error = function(e) rep(NA_real_, nrow(test))
        )

        if (metric == "rmse") {
          fold_err[k] <- sqrt(mean((y_test - pred)^2, na.rm = TRUE))
        } else {
          y_bin <- as.numeric(y_test)
          if (is.factor(y_test)) y_bin <- y_bin - 1L
          p <- pmin(pmax(pred, 1e-8), 1 - 1e-8)
          fold_err[k] <- -mean(
            y_bin * log(p) + (1 - y_bin) * log(1 - p), na.rm = TRUE
          )
        }
      }

      rmse_mat[r, m] <- mean(fold_err, na.rm = TRUE)
    }

    rank_mat[r, ] <- rank(rmse_mat[r, ], ties.method = "average")
  }

  mean_rmse <- colMeans(rmse_mat, na.rm = TRUE)
  sd_rmse   <- apply(rmse_mat, 2L, stats::sd, na.rm = TRUE)
  mean_rank <- colMeans(rank_mat, na.rm = TRUE)
  top1_freq <- colMeans(rank_mat == 1L, na.rm = TRUE)

  smry <- data.frame(
    model          = model_names,
    mean_rmse      = unname(mean_rmse),
    sd_rmse        = unname(sd_rmse),
    mean_rank      = unname(mean_rank),
    top1_frequency = unname(top1_freq),
    stringsAsFactors = FALSE
  )
  smry <- smry[order(smry$mean_rank, smry$mean_rmse), ]
  rownames(smry) <- NULL

  list(
    settings = list(v = v, R = R, seed = seed, metric = metric,
                    family = family, backend = backend,
                    en_alpha = en_alpha, lambda = lambda),
    rmse_mat = rmse_mat,
    rank_mat = rank_mat,
    summary  = smry
  )
}

#' Plot cross-validation ranking stability
#'
#' Produces a bar chart of either the top-1 selection frequency or the mean
#' CV rank for each candidate model.
#'
#' @param cv_obj A list returned by \code{\link{cv_ranking_stability}}.
#' @param metric Character string. One of \code{"top1_frequency"} (default) or
#'   \code{"mean_rank"}.
#'
#' @return Invisibly returns \code{NULL}; called for its side effect.
#'
#' @examples
#' models <- list(m1 = mpg ~ wt + hp, m2 = mpg ~ wt + hp + disp)
#' cv_obj <- cv_ranking_stability(models, mtcars, v = 5, R = 20)
#' plot_cv_stability(cv_obj, metric = "top1_frequency")
#'
#' @importFrom graphics barplot
#' @export
plot_cv_stability <- function(cv_obj,
                              metric = c("top1_frequency", "mean_rank")) {
  metric <- match.arg(metric)
  tbl    <- cv_obj$summary

  if (metric == "top1_frequency") {
    ord <- order(tbl$top1_frequency, decreasing = TRUE)
    graphics::barplot(
      tbl$top1_frequency[ord],
      names.arg = tbl$model[ord],
      las  = 2,
      ylim = c(0, 1),
      ylab = "Proportion of repeats ranked first",
      main = "CV Ranking Stability (Top-1 Frequency)"
    )
  } else {
    ord <- order(tbl$mean_rank)
    graphics::barplot(
      tbl$mean_rank[ord],
      names.arg = tbl$model[ord],
      las  = 2,
      ylab = "Average rank (lower is better)",
      main = "CV Ranking Stability (Mean Rank)"
    )
  }
  invisible(NULL)
}
