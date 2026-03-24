# ReproStat 0.1.0

## Initial release

* `run_diagnostics()`: main entry point supporting `"lm"`, `"glm"`, `"rlm"` (via
  **MASS**), and `"glmnet"` (via **glmnet**) backends; three perturbation methods
  (`"bootstrap"`, `"subsample"`, `"noise"`).  New argument `perturb_response`
  (default `FALSE`) controls whether the response column is perturbed under the
  noise method.
* `perturb_data()`: standalone data perturbation with bootstrap, subsampling,
  and Gaussian noise injection.  New argument `response_col` allows the
  response column to be excluded from noise perturbation.
* `coef_stability()`: variance of coefficient estimates across perturbation
  iterations.
* `pvalue_stability()`: proportion of iterations in which each predictor is
  significant; intercept excluded from output.
* `selection_stability()`: sign consistency of estimated coefficients for
  `"lm"` / `"glm"` / `"rlm"` backends; non-zero selection frequency for the
  `"glmnet"` backend.  Intercept excluded.  This is a genuinely distinct
  measure from `pvalue_stability()`.
* `prediction_stability()`: pointwise prediction variance across perturbation
  iterations.
* `reproducibility_index()`: composite 0--100 Reproducibility Index.
  - Coefficient component (`c_beta`) now uses a global scale reference
    (`median(|base_coef|)`) instead of a hard-coded epsilon, preventing the
    score from collapsing for near-zero coefficients.
  - `c_p` (p-value stability) and `c_sel` (selection stability) are now
    genuinely distinct components; they previously computed the same quantity.
  - For `backend = "glmnet"`, the selection component (`c_sel`) is now the
    mean non-zero selection frequency and is always available (previously it
    was `NA`).  The RI for glmnet is therefore based on three components
    instead of two.
* `ri_confidence_interval()`: bootstrap confidence interval for the RI.
  The `seed` argument now defaults to `NULL`, leaving the caller's global RNG
  state undisturbed.  Pass an integer to fix the seed explicitly.
* `cv_ranking_stability()`: repeated K-fold CV ranking stability for model
  comparison across the same four backends.
* `plot_stability()`, `plot_cv_stability()`: base-graphics visualisations.
* `plot_stability_gg()`, `plot_cv_stability_gg()`: optional **ggplot2**-based
  equivalents (require **ggplot2**).
