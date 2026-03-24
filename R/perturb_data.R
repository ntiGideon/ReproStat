#' Perturb a dataset
#'
#' Generates a perturbed version of a dataset using one of three strategies:
#' bootstrap resampling, subsampling without replacement, or Gaussian noise
#' injection.
#'
#' @param data A data frame.
#' @param method Character string specifying the perturbation method. One of
#'   \code{"bootstrap"} (default), \code{"subsample"}, or \code{"noise"}.
#' @param frac Fraction of rows to retain for subsampling. Ignored for other
#'   methods. Must be in \eqn{(0, 1]}. Default is \code{0.8}.
#' @param noise_sd Noise level as a fraction of each column's standard
#'   deviation. Ignored unless \code{method = "noise"}. Default is
#'   \code{0.05}.
#' @param response_col Optional character string naming the response (outcome)
#'   column to \emph{exclude} from noise injection.  Useful when you want to
#'   perturb predictors only and leave the outcome unchanged.  Ignored for
#'   \code{method = "bootstrap"} and \code{method = "subsample"}.  When
#'   \code{NULL} (default) all numeric columns including the response receive
#'   noise.
#'
#' @return A data frame with the same columns as \code{data}. The number of
#'   rows equals \code{nrow(data)} for bootstrap and noise, and
#'   \code{floor(frac * nrow(data))} for subsampling.
#'
#' @examples
#' set.seed(1)
#' d_boot <- perturb_data(mtcars, method = "bootstrap")
#' d_sub  <- perturb_data(mtcars, method = "subsample", frac = 0.7)
#' d_nois <- perturb_data(mtcars, method = "noise", noise_sd = 0.1)
#'
#' # Perturb predictors only, leave the response (mpg) unchanged:
#' d_pred_only <- perturb_data(mtcars, method = "noise",
#'                             noise_sd = 0.1, response_col = "mpg")
#'
#' @importFrom stats sd rnorm
#' @export
perturb_data <- function(data,
                         method = c("bootstrap", "subsample", "noise"),
                         frac = 0.8,
                         noise_sd = 0.05,
                         response_col = NULL) {
  method <- match.arg(method)
  if (!is.data.frame(data))
    stop("`data` must be a data frame.")
  n <- nrow(data)
  if (n < 1L)
    stop("`data` must have at least one row.")
  if (method == "subsample") {
    if (!is.numeric(frac) || length(frac) != 1L || frac <= 0 || frac > 1)
      stop("`frac` must be a single number in (0, 1].")
    if (n < 2L)
      stop("`data` must have at least 2 rows for method = \"subsample\".")
  }
  if (method == "noise") {
    if (!is.numeric(noise_sd) || length(noise_sd) != 1L || noise_sd < 0)
      stop("`noise_sd` must be a non-negative number.")
    if (!is.null(response_col) &&
        (!is.character(response_col) || length(response_col) != 1L))
      stop("`response_col` must be a single character string or NULL.")
    if (!is.null(response_col) && !response_col %in% names(data))
      stop("`response_col` \"", response_col, "\" not found in `data`.")
  }

  if (method == "bootstrap") {
    idx <- sample.int(n, size = n, replace = TRUE)
    return(data[idx, , drop = FALSE])
  }

  if (method == "subsample") {
    m <- max(2L, floor(frac * n))
    idx <- sample.int(n, size = m, replace = FALSE)
    return(data[idx, , drop = FALSE])
  }

  # noise
  out <- data
  numeric_cols <- vapply(out, is.numeric, logical(1L))
  for (nm in names(out)[numeric_cols]) {
    if (!is.null(response_col) && nm == response_col) next
    s <- stats::sd(out[[nm]], na.rm = TRUE)
    if (is.finite(s) && s > 0) {
      out[[nm]] <- out[[nm]] + stats::rnorm(n, mean = 0, sd = noise_sd * s)
    }
  }
  out
}
