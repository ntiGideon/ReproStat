# P-value stability

Computes the proportion of perturbation iterations in which each
predictor is statistically significant (p-value below `alpha`). The
intercept is excluded. Values near 0 or 1 indicate stable decisions;
values near 0.5 indicate high instability.

## Usage

``` r
pvalue_stability(diag_obj)
```

## Arguments

- diag_obj:

  A `reprostat` object from
  [`run_diagnostics`](https://ntiGideon.github.io/ReproStat/reference/run_diagnostics.md).

## Value

A named numeric vector of significance frequencies in \\\[0, 1\]\\,
excluding the intercept. All `NaN` for `backend = "glmnet"` (p-values
are not defined).

## Examples

``` r
set.seed(1)
d <- run_diagnostics(mpg ~ wt + hp, data = mtcars, B = 50)
pvalue_stability(d)
#>   wt   hp 
#> 1.00 0.96 
```
