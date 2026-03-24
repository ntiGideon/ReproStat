# Package index

## Start Here

Core entry points for fitting diagnostics, summarizing them, and
understanding the package.

- [`ReproStat`](https://ntiGideon.github.io/ReproStat/reference/ReproStat-package.md)
  [`ReproStat-package`](https://ntiGideon.github.io/ReproStat/reference/ReproStat-package.md)
  : ReproStat: Reproducibility Diagnostics for Statistical Modeling
- [`run_diagnostics()`](https://ntiGideon.github.io/ReproStat/reference/run_diagnostics.md)
  : Run reproducibility diagnostics
- [`print(`*`<reprostat>`*`)`](https://ntiGideon.github.io/ReproStat/reference/print.reprostat.md)
  : Print a reprostat object

## Data Perturbation

Functions for generating perturbed datasets and choosing a perturbation
design that matches the stability question you want to ask.

- [`perturb_data()`](https://ntiGideon.github.io/ReproStat/reference/perturb_data.md)
  : Perturb a dataset

## Stability Metrics

Component-level summaries of how coefficients, significance decisions,
predictor behavior, and predictions vary across perturbations.

- [`coef_stability()`](https://ntiGideon.github.io/ReproStat/reference/coef_stability.md)
  : Coefficient stability
- [`pvalue_stability()`](https://ntiGideon.github.io/ReproStat/reference/pvalue_stability.md)
  : P-value stability
- [`selection_stability()`](https://ntiGideon.github.io/ReproStat/reference/selection_stability.md)
  : Selection stability
- [`prediction_stability()`](https://ntiGideon.github.io/ReproStat/reference/prediction_stability.md)
  : Prediction stability

## Composite Summary

Aggregate the component diagnostics into a Reproducibility Index and
quantify uncertainty in that summary.

- [`reproducibility_index()`](https://ntiGideon.github.io/ReproStat/reference/reproducibility_index.md)
  : Reproducibility index
- [`ri_confidence_interval()`](https://ntiGideon.github.io/ReproStat/reference/ri_confidence_interval.md)
  : Bootstrap confidence interval for the reproducibility index

## Model Comparison

Repeated cross-validation tools for comparing candidate formulas by
ranking stability rather than average error alone.

- [`cv_ranking_stability()`](https://ntiGideon.github.io/ReproStat/reference/cv_ranking_stability.md)
  : Cross-validation ranking stability
- [`plot_cv_stability()`](https://ntiGideon.github.io/ReproStat/reference/plot_cv_stability.md)
  : Plot cross-validation ranking stability
- [`plot_cv_stability_gg()`](https://ntiGideon.github.io/ReproStat/reference/plot_cv_stability_gg.md)
  : ggplot2-based CV ranking stability plot

## Visualization

Plotting helpers for inspecting the stability structure of a fitted
ReproStat object.

- [`plot_stability()`](https://ntiGideon.github.io/ReproStat/reference/plot_stability.md)
  : Plot stability diagnostics
- [`plot_stability_gg()`](https://ntiGideon.github.io/ReproStat/reference/plot_stability_gg.md)
  : ggplot2-based stability plot
