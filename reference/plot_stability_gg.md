# ggplot2-based stability plot

Produces a ggplot2 bar chart for either the coefficient variance or the
selection frequency of each predictor term, ordered from lowest to
highest value.

## Usage

``` r
plot_stability_gg(diag_obj, type = c("coefficient", "selection"))
```

## Arguments

- diag_obj:

  A `"reprostat"` object returned by
  [`run_diagnostics`](https://ntiGideon.github.io/ReproStat/reference/run_diagnostics.md).

- type:

  One of `"coefficient"` (default) or `"selection"`.

## Value

A `ggplot` object.

## Examples

``` r
# \donttest{
if (requireNamespace("ggplot2", quietly = TRUE)) {
  d <- run_diagnostics(mpg ~ wt + hp, mtcars, B = 50)
  plot_stability_gg(d, "coefficient")
  plot_stability_gg(d, "selection")
}

# }
```
