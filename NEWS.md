# ReproStat 0.1.0

## Initial release

* `run_diagnostics()`: main entry point supporting `"lm"`, `"glm"`, `"rlm"` (via
  **MASS**), and `"glmnet"` (via **glmnet**) backends; three perturbation methods
  (`"bootstrap"`, `"subsample"`, `"noise"`).
* `perturb_data()`: standalone data perturbation with bootstrap, subsampling,
  and Gaussian noise injection.
* `coef_stability()`, `pvalue_stability()`, `selection_stability()`,
  `prediction_stability()`: four diagnostic metrics computed from a
  `"reprostat"` object.
* `reproducibility_index()`: composite 0--100 Reproducibility Index with
  component decomposition; handles NA components for glmnet.
* `ri_confidence_interval()`: bootstrap confidence interval for the RI.
* `cv_ranking_stability()`: repeated K-fold CV ranking stability for model
  comparison across the same four backends.
* `plot_stability()`: base-graphics bar chart / histogram for stability
  dimensions.
* `plot_cv_stability()`: base-graphics bar chart of CV ranking results.
* `plot_stability_gg()`, `plot_cv_stability_gg()`: optional ggplot2-based
  equivalents (require **ggplot2**).
