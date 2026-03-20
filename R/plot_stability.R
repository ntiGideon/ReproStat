#' Plot stability diagnostics
#'
#' Produces a bar chart or histogram summarising one stability dimension from a
#' \code{reprostat} object.
#'
#' @param diag_obj A \code{reprostat} object from \code{\link{run_diagnostics}}.
#' @param type Character string specifying the plot type. One of
#'   \code{"coefficient"} (default), \code{"pvalue"}, \code{"selection"}, or
#'   \code{"prediction"}.
#'
#' @return Invisibly returns \code{NULL}; called for its side effect.
#'
#' @examples
#' set.seed(1)
#' d <- run_diagnostics(mpg ~ wt + hp, data = mtcars, B = 50)
#' plot_stability(d, "coefficient")
#' plot_stability(d, "selection")
#'
#' @importFrom graphics barplot hist
#' @export
plot_stability <- function(diag_obj,
                           type = c("coefficient", "pvalue",
                                    "selection", "prediction")) {
  type <- match.arg(type)

  if (type == "coefficient") {
    vals <- coef_stability(diag_obj)
    graphics::barplot(vals, las = 2,
                      main = "Coefficient Variance",
                      ylab = "Variance")

  } else if (type == "pvalue") {
    vals <- pvalue_stability(diag_obj)
    graphics::barplot(vals, las = 2, ylim = c(0, 1),
                      main = "P-value Significance Frequency",
                      ylab = "Frequency")

  } else if (type == "selection") {
    vals <- selection_stability(diag_obj)
    graphics::barplot(vals, las = 2, ylim = c(0, 1),
                      main = "Selection Frequency",
                      ylab = "Frequency")

  } else {
    vals <- prediction_stability(diag_obj)$pointwise_variance
    graphics::hist(vals, breaks = 20,
                   main = "Prediction Variance Distribution",
                   xlab = "Variance")
  }
  invisible(NULL)
}
