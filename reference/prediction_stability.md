# Prediction stability

Computes the pointwise variance of predictions across perturbation
iterations, and the mean of these variances as a scalar summary.

## Usage

``` r
prediction_stability(diag_obj)
```

## Arguments

- diag_obj:

  A `reprostat` object from
  [`run_diagnostics`](https://ntiGideon.github.io/ReproStat/reference/run_diagnostics.md).

## Value

A list with components:

- `pointwise_variance`:

  Numeric vector of per-observation prediction variances.

- `mean_variance`:

  Mean of pointwise variances.

## Details

By default predictions are made on the training data used to fit the
base model. For `method = "subsample"` this means the held-out rows
receive genuine out-of-sample predictions, while for
`method = "bootstrap"` the predictions are a mix of in-bag and
out-of-bag. Pass `predict_newdata` to
[`run_diagnostics`](https://ntiGideon.github.io/ReproStat/reference/run_diagnostics.md)
for a dedicated held-out evaluation set.

## Examples

``` r
set.seed(1)
d <- run_diagnostics(mpg ~ wt + hp, data = mtcars, B = 50)
prediction_stability(d)$mean_variance
#> [1] 0.5923358
```
