# Plot stability diagnostics

Produces a bar chart or histogram summarising one stability dimension
from a `reprostat` object.

## Usage

``` r
plot_stability(
  diag_obj,
  type = c("coefficient", "pvalue", "selection", "prediction")
)
```

## Arguments

- diag_obj:

  A `reprostat` object from
  [`run_diagnostics`](https://ntiGideon.github.io/ReproStat/reference/run_diagnostics.md).

- type:

  Character string specifying the plot type. One of `"coefficient"`
  (default), `"pvalue"`, `"selection"`, or `"prediction"`.

## Value

Invisibly returns `NULL`; called for its side effect.

## Examples

``` r
set.seed(1)
d <- run_diagnostics(mpg ~ wt + hp, data = mtcars, B = 50)
plot_stability(d, "coefficient")

plot_stability(d, "selection")

```
