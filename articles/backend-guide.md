# Backend Guide

## Overview

ReproStat supports multiple model-fitting backends through the same
high-level API. That means you can often keep the same reproducibility
workflow while changing only the modeling engine.

Supported backends are:

- `"lm"` for ordinary least squares
- `"glm"` for generalized linear models
- `"rlm"` for robust regression via `MASS`
- `"glmnet"` for penalized regression via `glmnet`

This article explains when to use each one and what changes in the
returned diagnostics.

## Common interface

The same entry point is used across backends:

``` r
run_diagnostics(
  formula,
  data,
  B = 200,
  method = "bootstrap",
  backend = "lm"
)
```

The key differences are in:

- how the model is fit
- which quantities are available
- how to interpret selection-related outputs

## Backend: lm

`"lm"` is the default backend and is the best place to start for
standard linear regression.

``` r
diag_lm <- run_diagnostics(
  mpg ~ wt + hp + disp,
  data = mtcars,
  B = 100,
  backend = "lm"
)

reproducibility_index(diag_lm)
#> $index
#> [1] 90.13777
#> 
#> $components
#>       coef     pvalue  selection prediction 
#>  0.9218519  0.9000000  0.8100000  0.9736588
```

Use `"lm"` when:

- the response is continuous
- ordinary least squares is the intended analysis
- you want the simplest interpretation of all components

## Backend: glm

Use `"glm"` when you need a generalized linear model, such as logistic
or Poisson regression.

``` r
diag_glm <- run_diagnostics(
  am ~ wt + hp + qsec,
  data = mtcars,
  B = 100,
  backend = "glm",
  family = stats::binomial()
)

reproducibility_index(diag_glm)
#> $index
#> [1] 74.76995
#> 
#> $components
#>       coef     pvalue  selection prediction 
#>  0.2498896  1.0000000  0.8333333  0.9075752
```

Notes:

- if you provide `family = ...` while leaving `backend = "lm"`, the
  function promotes the fit to `"glm"`
- prediction stability for GLMs uses response-scale predictions
- p-value and selection summaries remain available

## Backend: rlm

Use `"rlm"` when you want robustness against outliers or heavy-tailed
error behavior.

``` r
if (requireNamespace("MASS", quietly = TRUE)) {
  diag_rlm <- run_diagnostics(
    mpg ~ wt + hp + disp,
    data = mtcars,
    B = 100,
    backend = "rlm"
  )

  reproducibility_index(diag_rlm)
}
#> Warning in rlm.default(x, y, weights, method = method, wt.method = wt.method, :
#> 'rlm' failed to converge in 20 steps
#> $index
#> [1] 88.09575
#> 
#> $components
#>       coef     pvalue  selection prediction 
#>  0.9103266  0.7800000  0.8600000  0.9735035
```

Use `"rlm"` when:

- a few influential observations may distort OLS results
- you want a more robust regression baseline
- you still want coefficient, selection, prediction, and RI summaries in
  a familiar regression framework

## Backend: glmnet

Use `"glmnet"` when you want penalized regression such as LASSO, ridge,
or elastic net.

``` r
if (requireNamespace("glmnet", quietly = TRUE)) {
  diag_glmnet <- run_diagnostics(
    mpg ~ wt + hp + disp + qsec,
    data = mtcars,
    B = 100,
    backend = "glmnet",
    en_alpha = 1
  )

  reproducibility_index(diag_glmnet)
}
#> $index
#> [1] 84.08971
#> 
#> $components
#>       coef     pvalue  selection prediction 
#>  0.7308482         NA  0.8250000  0.9668430
```

The `en_alpha` argument controls the penalty mix:

- `1` gives LASSO
- `0` gives ridge
- values in between give elastic net

Important differences for `"glmnet"`:

- p-values are not defined, so the `pvalue` component is `NA`
- selection stability measures non-zero selection frequency
- RI values are therefore based on a different component set than the
  non-penalized backends

## Backend comparison summary

| Backend    | Best for                   | P-values available? | Selection meaning  |
|------------|----------------------------|---------------------|--------------------|
| `"lm"`     | standard linear regression | yes                 | sign consistency   |
| `"glm"`    | logistic / GLM use cases   | yes                 | sign consistency   |
| `"rlm"`    | robust regression          | yes                 | sign consistency   |
| `"glmnet"` | penalized regression       | no                  | non-zero frequency |

## Choosing a backend in practice

A simple decision pattern is:

1.  Start with `"lm"` if a standard linear model is appropriate.
2.  Move to `"glm"` when the response distribution requires it.
3.  Use `"rlm"` when outlier resistance matters.
4.  Use `"glmnet"` when shrinkage, regularization, or sparse selection
    is the main modeling goal.

## Comparing RI values across backends

Be careful when comparing RI values between penalized and non-penalized
backends.

For `"glmnet"`, the p-value component is unavailable, so the composite
score is formed from a different set of ingredients. That makes
cross-backend RI comparisons descriptive at best, not strictly
apples-to-apples.

## Model comparison with repeated CV

All backends can also be used in
[`cv_ranking_stability()`](https://ntiGideon.github.io/ReproStat/reference/cv_ranking_stability.md):

``` r
models <- list(
  compact = mpg ~ wt + hp,
  fuller  = mpg ~ wt + hp + disp
)

cv_obj <- cv_ranking_stability(
  models,
  mtcars,
  v = 5,
  R = 20,
  backend = "lm"
)

cv_obj$summary
#>     model mean_rmse   sd_rmse mean_rank top1_frequency
#> 1 compact  2.709462 0.1712591         1              1
#> 2  fuller  2.824818 0.1573067         2              0
```

This is especially valuable when you are choosing between competing
formulas and want to know not just which model is best on average, but
which one is consistently best.

## Next steps

For a broader conceptual explanation, read the interpretation article.
For a complete first analysis, start with
[`vignette("ReproStat-intro")`](https://ntiGideon.github.io/ReproStat/articles/ReproStat-intro.md).
