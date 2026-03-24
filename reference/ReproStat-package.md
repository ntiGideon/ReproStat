# ReproStat: Reproducibility Diagnostics for Statistical Modeling

Tools for diagnosing the reproducibility of statistical model outputs
under data perturbations. The package implements bootstrap, subsampling,
and noise-based perturbation schemes and computes coefficient stability,
p-value stability, selection stability, prediction stability, and a
composite reproducibility index on a 0–100 scale. Cross-validation
ranking stability for model comparison and visualization utilities are
also provided.

## Typical workflow

1.  Call
    [`run_diagnostics`](https://ntiGideon.github.io/ReproStat/reference/run_diagnostics.md)
    with your formula and data.

2.  Inspect individual metrics with
    [`coef_stability`](https://ntiGideon.github.io/ReproStat/reference/coef_stability.md),
    [`pvalue_stability`](https://ntiGideon.github.io/ReproStat/reference/pvalue_stability.md),
    [`selection_stability`](https://ntiGideon.github.io/ReproStat/reference/selection_stability.md),
    and
    [`prediction_stability`](https://ntiGideon.github.io/ReproStat/reference/prediction_stability.md).

3.  Summarise with
    [`reproducibility_index`](https://ntiGideon.github.io/ReproStat/reference/reproducibility_index.md).

4.  Visualise with
    [`plot_stability`](https://ntiGideon.github.io/ReproStat/reference/plot_stability.md).

5.  Compare competing models with
    [`cv_ranking_stability`](https://ntiGideon.github.io/ReproStat/reference/cv_ranking_stability.md)
    and
    [`plot_cv_stability`](https://ntiGideon.github.io/ReproStat/reference/plot_cv_stability.md).

## See also

Useful links:

- <https://ntiGideon.github.io/ReproStat>

- <https://github.com/ntiGideon/ReproStat>

- Report bugs at <https://github.com/ntiGideon/ReproStat/issues>

## Author

**Maintainer**: Gideon Nti Boateng <gidiboateng200@gmail.com>
