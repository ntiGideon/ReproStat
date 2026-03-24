# Workflow Patterns

## Why workflow patterns help

Most users do not need every feature in ReproStat at once. They usually
need a small number of reliable patterns that fit real analysis
situations.

This article shows several practical ways to use the package.

## Pattern 1: Standard regression stability check

Use this when you already have a preferred regression specification and
want to know how stable its outputs are.

``` r
diag_obj <- run_diagnostics(
  mpg ~ wt + hp + disp,
  data = mtcars,
  B = 200,
  method = "bootstrap"
)

reproducibility_index(diag_obj)
#> $index
#> [1] 89.42195
#> 
#> $components
#>       coef     pvalue  selection prediction 
#>  0.9294961  0.8566667  0.8150000  0.9757153
selection_stability(diag_obj)
#>    wt    hp  disp 
#> 1.000 1.000 0.445
```

Recommended outputs to review:

- [`reproducibility_index()`](https://ntiGideon.github.io/ReproStat/reference/reproducibility_index.md)
- [`selection_stability()`](https://ntiGideon.github.io/ReproStat/reference/selection_stability.md)
- `plot_stability(diag_obj, "selection")`

## Pattern 2: Sample-composition sensitivity

Use this when you are worried that the model depends too strongly on
exactly which observations appear in the sample.

``` r
diag_sub <- run_diagnostics(
  mpg ~ wt + hp + disp,
  data = mtcars,
  B = 200,
  method = "subsample",
  frac = 0.75
)

reproducibility_index(diag_sub)
#> $index
#> [1] 89.61837
#> 
#> $components
#>       coef     pvalue  selection prediction 
#>  0.9665288  0.7833333  0.8450000  0.9898728
```

This is often useful for:

- smaller datasets
- observational studies
- analyses where influence of sample composition is a concern

## Pattern 3: Measurement-noise stress test

Use noise perturbation when predictors may be measured with minor error
and you want to know whether the fitted result is sensitive to that
noise.

``` r
diag_noise <- run_diagnostics(
  mpg ~ wt + hp + disp,
  data = mtcars,
  B = 150,
  method = "noise",
  noise_sd = 0.05
)

reproducibility_index(diag_noise)
#> $index
#> [1] 97.65751
#> 
#> $components
#>       coef     pvalue  selection prediction 
#>  0.9977687  1.0000000  0.9088889  0.9996427
prediction_stability(diag_noise)$mean_variance
#> [1] 0.01297961
```

This does not replace a full measurement-error model, but it gives a
useful practical stress test.

## Pattern 4: Logistic model reproducibility

Use a GLM backend when the response is binary.

``` r
diag_glm <- run_diagnostics(
  am ~ wt + hp + qsec,
  data = mtcars,
  B = 150,
  backend = "glm",
  family = stats::binomial()
)

reproducibility_index(diag_glm)
#> $index
#> [1] 74.84598
#> 
#> $components
#>       coef     pvalue  selection prediction 
#>  0.2502762  1.0000000  0.8355556  0.9080076
```

This pattern is helpful when you want to know whether the
classification-style conclusion is stable under perturbation, not just
whether the original fit looks significant.

## Pattern 5: Robust regression with outlier concern

If you suspect outliers or heavy tails are affecting the OLS result,
compare a robust backend.

``` r
if (requireNamespace("MASS", quietly = TRUE)) {
  diag_rlm <- run_diagnostics(
    mpg ~ wt + hp + disp,
    data = mtcars,
    B = 150,
    backend = "rlm"
  )

  reproducibility_index(diag_rlm)
}
#> Warning in rlm.default(x, y, weights, method = method, wt.method = wt.method, :
#> 'rlm' failed to converge in 20 steps
#> Warning in rlm.default(x, y, weights, method = method, wt.method = wt.method, :
#> 'rlm' failed to converge in 20 steps
#> Warning in rlm.default(x, y, weights, method = method, wt.method = wt.method, :
#> 'rlm' failed to converge in 20 steps
#> Warning in rlm.default(x, y, weights, method = method, wt.method = wt.method, :
#> 'rlm' failed to converge in 20 steps
#> $index
#> [1] 88.48408
#> 
#> $components
#>       coef     pvalue  selection prediction 
#>  0.9253969  0.7733333  0.8644444  0.9761887
```

This is often a useful companion analysis rather than a full
replacement.

## Pattern 6: Penalized regression and variable retention

Use `glmnet` when you care about regularized modeling and whether
variables are selected consistently.

``` r
if (requireNamespace("glmnet", quietly = TRUE)) {
  diag_lasso <- run_diagnostics(
    mpg ~ wt + hp + disp + qsec,
    data = mtcars,
    B = 150,
    backend = "glmnet",
    en_alpha = 1
  )

  reproducibility_index(diag_lasso)
  selection_stability(diag_lasso)
}
#>        wt        hp      disp      qsec 
#> 1.0000000 0.9533333 0.4400000 0.6800000
```

Here, selection stability is especially informative because it reflects
non-zero retention frequency.

## Pattern 7: Compare candidate models by ranking stability

When you have multiple plausible formulas, repeated CV ranking stability
helps you see whether one model wins consistently or only occasionally.

``` r
models <- list(
  compact  = mpg ~ wt + hp,
  standard = mpg ~ wt + hp + disp,
  expanded = mpg ~ wt + hp + disp + qsec
)

cv_obj <- cv_ranking_stability(models, mtcars, v = 5, R = 40)
cv_obj$summary
#>      model mean_rmse   sd_rmse mean_rank top1_frequency
#> 1  compact  2.684893 0.1629443     1.050           0.95
#> 2 expanded  2.811187 0.1605096     2.425           0.05
#> 3 standard  2.798253 0.1474168     2.525           0.00
```

Focus on two columns:

- `mean_rank`: lower is better on average
- `top1_frequency`: higher means the model is more often the winner

Those two quantities are related but not identical.

## Pattern 8: Reporting a compact reproducibility section

A practical reporting workflow is:

1.  fit a diagnostic object with your primary model
2.  compute the RI and a confidence interval
3.  report the most unstable component
4.  include one or two plots
5.  if model selection is part of the analysis, add CV ranking stability

Example:

``` r
diag_obj <- run_diagnostics(
  mpg ~ wt + hp + disp,
  data = mtcars,
  B = 150,
  method = "bootstrap"
)

ri <- reproducibility_index(diag_obj)
ci <- ri_confidence_interval(diag_obj, R = 300, seed = 1)

ri
#> $index
#> [1] 88.21907
#> 
#> $components
#>       coef     pvalue  selection prediction 
#>  0.9166282  0.8000000  0.8400000  0.9721348
ci
#>     2.5%    97.5% 
#> 86.65629 89.91509
```

## A practical decision checklist

Before running a large analysis, decide:

1.  which perturbation method reflects your concern
2.  how many iterations `B` are feasible
3.  whether prediction stability should be in-sample or on
    `predict_newdata`
4.  whether you want a standard, robust, or penalized backend
5.  whether model comparison is part of the task

## Next steps

Use these patterns as templates, then adapt them to your own data,
formulas, and modeling constraints. For conceptual interpretation, read
the interpretation article. For function-level details, use the
reference pages.
