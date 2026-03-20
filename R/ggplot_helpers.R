# Suppress R CMD check NOTEs for ggplot2 aesthetic variable names
utils::globalVariables(c("term", "value", "model"))

#' ggplot2-based stability plot
#'
#' Produces a \pkg{ggplot2} bar chart for either the coefficient variance or
#' the selection frequency of each predictor term, ordered from lowest to
#' highest value.
#'
#' @param diag_obj A \code{"reprostat"} object returned by
#'   \code{\link{run_diagnostics}}.
#' @param type One of \code{"coefficient"} (default) or \code{"selection"}.
#'
#' @return A \code{ggplot} object.
#'
#' @examples
#' \donttest{
#' if (requireNamespace("ggplot2", quietly = TRUE)) {
#'   d <- run_diagnostics(mpg ~ wt + hp, mtcars, B = 50)
#'   plot_stability_gg(d, "coefficient")
#'   plot_stability_gg(d, "selection")
#' }
#' }
#'
#' @importFrom stats reorder
#' @export
plot_stability_gg <- function(diag_obj,
                               type = c("coefficient", "selection")) {
  if (!requireNamespace("ggplot2", quietly = TRUE)) {
    stop("ggplot2 is required for plot_stability_gg(). ",
         "Install it with: install.packages(\"ggplot2\")")
  }
  type <- match.arg(type)
  vals <- if (type == "coefficient") {
    coef_stability(diag_obj)
  } else {
    selection_stability(diag_obj)
  }
  df <- data.frame(term  = names(vals),
                   value = as.numeric(vals))
  ggplot2::ggplot(df, ggplot2::aes(
      x = stats::reorder(term, value), y = value)) +
    ggplot2::geom_col(fill = "#2C7FB8") +
    ggplot2::coord_flip() +
    ggplot2::labs(
      x     = if (type == "coefficient") "Coefficient" else "Predictor",
      y     = if (type == "coefficient") "Variance"
              else "Selection frequency",
      title = if (type == "coefficient") "Coefficient Stability"
              else "Selection Stability"
    ) +
    ggplot2::theme_minimal()
}


#' ggplot2-based CV ranking stability plot
#'
#' Produces a \pkg{ggplot2} horizontal bar chart of either the top-1 frequency
#' or the mean rank of each candidate model from a repeated cross-validation
#' stability run.
#'
#' @param cv_obj A list returned by \code{\link{cv_ranking_stability}}.
#' @param metric One of \code{"top1_frequency"} (default) or
#'   \code{"mean_rank"}.
#'
#' @return A \code{ggplot} object.
#'
#' @examples
#' \donttest{
#' if (requireNamespace("ggplot2", quietly = TRUE)) {
#'   models <- list(m1 = mpg ~ wt + hp, m2 = mpg ~ wt + hp + disp)
#'   cv <- cv_ranking_stability(models, mtcars, v = 5, R = 20)
#'   plot_cv_stability_gg(cv, "top1_frequency")
#'   plot_cv_stability_gg(cv, "mean_rank")
#' }
#' }
#'
#' @importFrom stats reorder
#' @export
plot_cv_stability_gg <- function(cv_obj,
                                  metric = c("top1_frequency", "mean_rank")) {
  if (!requireNamespace("ggplot2", quietly = TRUE)) {
    stop("ggplot2 is required for plot_cv_stability_gg(). ",
         "Install it with: install.packages(\"ggplot2\")")
  }
  metric <- match.arg(metric)
  tbl    <- cv_obj$summary
  plot_df <- if (metric == "top1_frequency") {
    data.frame(model = tbl$model, value = tbl$top1_frequency)
  } else {
    data.frame(model = tbl$model, value = tbl$mean_rank)
  }
  ggplot2::ggplot(plot_df,
      ggplot2::aes(x = stats::reorder(model, value), y = value)) +
    ggplot2::geom_col(fill = "#1B9E77") +
    ggplot2::coord_flip() +
    ggplot2::labs(
      x     = "Model",
      y     = if (metric == "top1_frequency") "Top-1 frequency"
              else "Mean rank",
      title = if (metric == "top1_frequency")
                "CV Ranking Stability (Top-1 frequency)"
              else "CV Ranking Stability (Mean rank)"
    ) +
    ggplot2::theme_minimal()
}
