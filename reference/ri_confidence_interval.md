# Bootstrap confidence interval for the reproducibility index

Estimates uncertainty in the RI by resampling the perturbation
iterations already stored in a `reprostat` object (no additional model
fitting).

## Usage

``` r
ri_confidence_interval(diag_obj, level = 0.95, R = 1000L, seed = NULL)
```

## Arguments

- diag_obj:

  A `reprostat` object from
  [`run_diagnostics`](https://ntiGideon.github.io/ReproStat/reference/run_diagnostics.md).

- level:

  Confidence level, e.g. `0.95` for a 95% interval. Default is `0.95`.

- R:

  Number of bootstrap resamples of the perturbation draws. Default is
  `1000`. Values of 300–500 are sufficient for most uses.

- seed:

  Integer random seed passed to
  [`set.seed`](https://rdrr.io/r/base/Random.html), or `NULL` (default)
  to leave the global RNG state undisturbed. Pass an integer for fully
  reproducible intervals.

## Value

A named numeric vector of length 2 giving the lower and upper quantile
bounds of the RI bootstrap distribution.

## Examples

``` r
set.seed(1)
d <- run_diagnostics(mpg ~ wt + hp, data = mtcars, B = 50)
ri_confidence_interval(d, R = 200, seed = 1)
#>     2.5%    97.5% 
#> 95.75155 98.61878 
```
