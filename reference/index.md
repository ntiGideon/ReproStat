# Package index

## Package Overview

High-level entry point and the S3 class that all diagnostic functions
operate on. Start here if you are reading the reference for the first
time.

- [`ReproStat`](https://ntiGideon.github.io/ReproStat/reference/ReproStat-package.md)
  [`ReproStat-package`](https://ntiGideon.github.io/ReproStat/reference/ReproStat-package.md)
  : ReproStat: Reproducibility Diagnostics for Statistical Modeling
- [`run_diagnostics()`](https://ntiGideon.github.io/ReproStat/reference/run_diagnostics.md)
  : Run reproducibility diagnostics
- [`print(`*`<reprostat>`*`)`](https://ntiGideon.github.io/ReproStat/reference/print.reprostat.md)
  : Print a reprostat object

## Data Perturbation

[`perturb_data()`](https://ntiGideon.github.io/ReproStat/reference/perturb_data.md)
is the building block underneath
[`run_diagnostics()`](https://ntiGideon.github.io/ReproStat/reference/run_diagnostics.md).
Use it directly when you need fine-grained control over how the data are
perturbed — for example, to pass the perturbed datasets to an external
modelling pipeline. Three strategies are available: - **Bootstrap**
(`"bootstrap"`) — draws *n* rows with replacement, mimicking ordinary
sampling variability. - **Subsampling** (`"subsample"`) — draws *m =
⌊ρn⌋* rows without replacement, stressing robustness to sample
composition. - **Noise injection** (`"noise"`) — adds Gaussian noise
scaled to each predictor’s standard deviation, simulating measurement
error.

- [`perturb_data()`](https://ntiGideon.github.io/ReproStat/reference/perturb_data.md)
  : Perturb a dataset

## Stability Metrics

Four complementary views of how model outputs move across perturbation
runs. Each function takes a `reprostat` object returned by
[`run_diagnostics()`](https://ntiGideon.github.io/ReproStat/reference/run_diagnostics.md)
and returns a numeric summary. \| Function \| Question answered \| Unit
\| \|—\|—\|—\| \|
[`coef_stability()`](https://ntiGideon.github.io/ReproStat/reference/coef_stability.md)
\| How much do coefficient estimates vary? \| variance (lower = more
stable) \| \|
[`pvalue_stability()`](https://ntiGideon.github.io/ReproStat/reference/pvalue_stability.md)
\| How often is each predictor significant? \| frequency in \[0, 1\] \|
\|
[`selection_stability()`](https://ntiGideon.github.io/ReproStat/reference/selection_stability.md)
\| Do predictors keep the same direction/inclusion? \| proportion in
\[0, 1\] \| \|
[`prediction_stability()`](https://ntiGideon.github.io/ReproStat/reference/prediction_stability.md)
\| How much do predictions change? \| variance (lower = more stable) \|
[`pvalue_stability()`](https://ntiGideon.github.io/ReproStat/reference/pvalue_stability.md)
and
[`selection_stability()`](https://ntiGideon.github.io/ReproStat/reference/selection_stability.md)
measure *different* things: the former asks about the stability of a
binary significance decision; the latter asks about the direction or
inclusion pattern of each predictor.

- [`coef_stability()`](https://ntiGideon.github.io/ReproStat/reference/coef_stability.md)
  : Coefficient stability
- [`pvalue_stability()`](https://ntiGideon.github.io/ReproStat/reference/pvalue_stability.md)
  : P-value stability
- [`selection_stability()`](https://ntiGideon.github.io/ReproStat/reference/selection_stability.md)
  : Selection stability
- [`prediction_stability()`](https://ntiGideon.github.io/ReproStat/reference/prediction_stability.md)
  : Prediction stability

## Reproducibility Index

The Reproducibility Index (RI) aggregates the four stability components
into a single 0–100 score using a per-component normalisation and a
simple average.
[`ri_confidence_interval()`](https://ntiGideon.github.io/ReproStat/reference/ri_confidence_interval.md)
estimates uncertainty in that score by resampling the stored
perturbation draws — no additional model fitting required. **RI
quick-reference guide** \| RI \| Interpretation \| \|—\|—\| \| 90–100 \|
Highly stable under the chosen perturbation design \| \| 70–89 \|
Moderately stable; overall pattern is dependable \| \| 50–69 \| Mixed
stability; inspect component breakdown \| \| \< 50 \| Low stability;
results may be fragile \| These are interpretive anchors, not universal
cutoffs. Always inspect the component decomposition alongside the
aggregate score.

- [`reproducibility_index()`](https://ntiGideon.github.io/ReproStat/reference/reproducibility_index.md)
  : Reproducibility index
- [`ri_confidence_interval()`](https://ntiGideon.github.io/ReproStat/reference/ri_confidence_interval.md)
  : Bootstrap confidence interval for the reproducibility index

## Cross-Validation Ranking Stability

[`cv_ranking_stability()`](https://ntiGideon.github.io/ReproStat/reference/cv_ranking_stability.md)
evaluates *model-selection* stability: given several candidate formulas,
which one wins most consistently across repeated K-fold
cross-validation? It records each model’s rank in every repeat and
summarises the distribution of those ranks. Two summary statistics are
particularly useful: - **`top1_frequency`** — proportion of repeats in
which a model ranked first. High values mean the model is a consistently
strong choice. - **`mean_rank`** — average rank across all repeats
(lower is better). It is possible for the model with the lowest mean
error to *not* have the highest top-1 frequency.

Supports the same four backends as
[`run_diagnostics()`](https://ntiGideon.github.io/ReproStat/reference/run_diagnostics.md).

- [`cv_ranking_stability()`](https://ntiGideon.github.io/ReproStat/reference/cv_ranking_stability.md)
  : Cross-validation ranking stability
- [`plot_cv_stability()`](https://ntiGideon.github.io/ReproStat/reference/plot_cv_stability.md)
  : Plot cross-validation ranking stability
- [`plot_cv_stability_gg()`](https://ntiGideon.github.io/ReproStat/reference/plot_cv_stability_gg.md)
  : ggplot2-based CV ranking stability plot

## Visualization

Two families of plotting helpers are provided. The base-graphics
functions
([`plot_stability()`](https://ntiGideon.github.io/ReproStat/reference/plot_stability.md),
[`plot_cv_stability()`](https://ntiGideon.github.io/ReproStat/reference/plot_cv_stability.md))
have no external dependencies. The **ggplot2** variants
([`plot_stability_gg()`](https://ntiGideon.github.io/ReproStat/reference/plot_stability_gg.md),
[`plot_cv_stability_gg()`](https://ntiGideon.github.io/ReproStat/reference/plot_cv_stability_gg.md))
return `ggplot` objects that can be further customised with standard
ggplot2 layers and themes. Both families are called for their side
effects; the ggplot2 variants additionally return a `ggplot` object
invisibly.

- [`plot_stability()`](https://ntiGideon.github.io/ReproStat/reference/plot_stability.md)
  : Plot stability diagnostics
- [`plot_stability_gg()`](https://ntiGideon.github.io/ReproStat/reference/plot_stability_gg.md)
  : ggplot2-based stability plot
