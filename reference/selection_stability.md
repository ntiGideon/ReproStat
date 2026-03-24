# Selection stability

Measures how consistently each predictor is *selected* across
perturbation iterations. The definition depends on the modeling backend:

## Usage

``` r
selection_stability(diag_obj)
```

## Arguments

- diag_obj:

  A `reprostat` object from
  [`run_diagnostics`](https://ntiGideon.github.io/ReproStat/reference/run_diagnostics.md).

## Value

A named numeric vector of selection stability values in \\\[0, 1\]\\,
excluding the intercept.

## Details

- `"lm"`, `"glm"`, `"rlm"`:

  **Sign consistency**: the proportion of perturbation iterations in
  which the estimated coefficient has the same sign as in the base fit.
  A value of 1 means the direction of the effect is perfectly stable;
  0.5 means the sign is random. Returns `NA` for a predictor whose
  base-fit coefficient is exactly zero.

- `"glmnet"`:

  **Non-zero selection frequency**: the proportion of perturbation
  iterations in which the coefficient is non-zero (i.e. the variable
  survives the regularisation penalty).

The intercept is always excluded.

## Examples

``` r
set.seed(1)
d <- run_diagnostics(mpg ~ wt + hp, data = mtcars, B = 50)
selection_stability(d)
#> wt hp 
#>  1  1 
```
