# ggplot2-based CV ranking stability plot

Produces a ggplot2 horizontal bar chart of either the top-1 frequency or
the mean rank of each candidate model from a repeated cross-validation
stability run.

## Usage

``` r
plot_cv_stability_gg(cv_obj, metric = c("top1_frequency", "mean_rank"))
```

## Arguments

- cv_obj:

  A list returned by
  [`cv_ranking_stability`](https://ntiGideon.github.io/ReproStat/reference/cv_ranking_stability.md).

- metric:

  One of `"top1_frequency"` (default) or `"mean_rank"`.

## Value

A `ggplot` object.

## Examples

``` r
# \donttest{
if (requireNamespace("ggplot2", quietly = TRUE)) {
  models <- list(m1 = mpg ~ wt + hp, m2 = mpg ~ wt + hp + disp)
  cv <- cv_ranking_stability(models, mtcars, v = 5, R = 20)
  plot_cv_stability_gg(cv, "top1_frequency")
  plot_cv_stability_gg(cv, "mean_rank")
}

# }
```
