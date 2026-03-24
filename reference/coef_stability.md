# Coefficient stability

Computes the variance of each regression coefficient across perturbation
iterations. Lower variance indicates greater stability.

## Usage

``` r
coef_stability(diag_obj)
```

## Arguments

- diag_obj:

  A `reprostat` object from
  [`run_diagnostics`](https://ntiGideon.github.io/ReproStat/reference/run_diagnostics.md).

## Value

A named numeric vector of per-coefficient variances.

## Examples

``` r
set.seed(1)
d <- run_diagnostics(mpg ~ wt + hp, data = mtcars, B = 50)
coef_stability(d)
#>  (Intercept)           wt           hp 
#> 3.512876e+00 3.919577e-01 4.783342e-05 
```
