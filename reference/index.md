# Package index

## Core workflow

The main pipeline: perturb data → run diagnostics → extract metrics.

- [`run_diagnostics()`](https://ntiGideon.github.io/ReproStat/reference/run_diagnostics.md)
  : Run reproducibility diagnostics
- [`perturb_data()`](https://ntiGideon.github.io/ReproStat/reference/perturb_data.md)
  : Perturb a dataset

## Stability metrics

Four metrics computed from a `reprostat` object returned by
[`run_diagnostics()`](https://ntiGideon.github.io/ReproStat/reference/run_diagnostics.md).
Each captures a different dimension of stability.

- [`coef_stability()`](https://ntiGideon.github.io/ReproStat/reference/coef_stability.md)
  : Coefficient stability
- [`pvalue_stability()`](https://ntiGideon.github.io/ReproStat/reference/pvalue_stability.md)
  : P-value stability
- [`selection_stability()`](https://ntiGideon.github.io/ReproStat/reference/selection_stability.md)
  : Selection stability
- [`prediction_stability()`](https://ntiGideon.github.io/ReproStat/reference/prediction_stability.md)
  : Prediction stability

## Reproducibility Index

Composite index (0–100) aggregating all four stability components, plus
a bootstrap confidence interval.

- [`reproducibility_index()`](https://ntiGideon.github.io/ReproStat/reference/reproducibility_index.md)
  : Reproducibility index
- [`ri_confidence_interval()`](https://ntiGideon.github.io/ReproStat/reference/ri_confidence_interval.md)
  : Bootstrap confidence interval for the reproducibility index

## Cross-validation ranking stability

Compare multiple candidate models via repeated K-fold CV and assess how
consistently each model ranks as the best.

- [`cv_ranking_stability()`](https://ntiGideon.github.io/ReproStat/reference/cv_ranking_stability.md)
  : Cross-validation ranking stability

## Visualisation

Base-graphics and ggplot2 plots for stability diagnostics and CV
results.

- [`plot_stability()`](https://ntiGideon.github.io/ReproStat/reference/plot_stability.md)
  : Plot stability diagnostics
- [`plot_stability_gg()`](https://ntiGideon.github.io/ReproStat/reference/plot_stability_gg.md)
  : ggplot2-based stability plot
- [`plot_cv_stability()`](https://ntiGideon.github.io/ReproStat/reference/plot_cv_stability.md)
  : Plot cross-validation ranking stability
- [`plot_cv_stability_gg()`](https://ntiGideon.github.io/ReproStat/reference/plot_cv_stability_gg.md)
  : ggplot2-based CV ranking stability plot

## S3 methods

Methods for the `reprostat` S3 class.

- [`print(`*`<reprostat>`*`)`](https://ntiGideon.github.io/ReproStat/reference/print.reprostat.md)
  : Print a reprostat object

## Package

Package-level documentation.

- [`ReproStat`](https://ntiGideon.github.io/ReproStat/reference/ReproStat-package.md)
  [`ReproStat-package`](https://ntiGideon.github.io/ReproStat/reference/ReproStat-package.md)
  : ReproStat: Reproducibility Diagnostics for Statistical Modeling
