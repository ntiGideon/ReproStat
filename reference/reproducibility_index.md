# Reproducibility index

Computes a composite reproducibility index (RI) on a 0–100 scale by
aggregating normalized versions of coefficient, p-value, selection, and
prediction stability.

## Usage

``` r
reproducibility_index(diag_obj)
```

## Arguments

- diag_obj:

  A `reprostat` object from
  [`run_diagnostics`](https://ntiGideon.github.io/ReproStat/reference/run_diagnostics.md).

## Value

A list with components:

- `index`:

  Scalar RI on a 0–100 scale.

- `components`:

  Named numeric vector with four sub-scores: `coef`, `pvalue`,
  `selection`, `prediction`. `pvalue` is `NA` for `backend = "glmnet"`;
  `selection` is always available.

## Details

Each component is mapped to \\\[0, 1\]\\ as follows:

- Coefficient component (\\C\_\beta\\):

  \\C\_\beta = \frac{1}{p}\sum\_{j=1}^{p} \exp\\\left(-S\_{\beta,j} /
  (\|\hat\beta_j^{(0)}\| + \bar\beta)\right)\\, where \\\bar\beta =
  \max(\mathrm{median}\_j\|\hat\beta_j^{(0)}\|,\\ 10^{-4})\\ is a global
  scale reference. This prevents the exponential from collapsing to zero
  for weakly-identified (near-zero) predictors. Includes all model terms
  (intercept and predictors).

- P-value component (\\C_p\\):

  \\C_p = \frac{1}{p'}\sum\_{j \neq \text{intercept}} \|2 S\_{p,j} -
  1\|\\, where \\S\_{p,j}\\ is the proportion of perturbation iterations
  in which term \\j\\ is significant at level `alpha` and \\p'\\ is the
  number of predictor terms. Values near 0 or 1 (consistent decisions)
  score high; 0.5 (random) scores zero. `NA` for `backend = "glmnet"`.

- Selection component (\\C\_\mathrm{sel}\\):

  For `"lm"`, `"glm"`, `"rlm"`: the mean *sign consistency* across
  predictors — the proportion of perturbation iterations in which each
  predictor's estimated sign agrees with the base-fit sign. Captures
  stability of effect direction, which is distinct from significance
  stability (\\C_p\\). For `"glmnet"`: the mean *non-zero selection
  frequency* — proportion of perturbation iterations in which each
  predictor's coefficient is non-zero. Always available (never `NA`).
  Excludes the intercept.

- Prediction component (\\C\_\mathrm{pred}\\):

  \\C\_\mathrm{pred} = \exp(-\bar S\_\mathrm{pred} / (\mathrm{Var}(y) +
  \varepsilon))\\. Prediction variance relative to outcome variance
  drives the decay.

The RI is \\100 \times (C\_\beta + C_p + C\_\mathrm{sel} +
C\_\mathrm{pred}) / k\\, where \\k\\ is the number of non-`NA`
components. For `backend = "glmnet"`, \\C_p\\ is `NA` so the RI is based
on three components (\\k = 3\\): \\C\_\beta\\, \\C\_\mathrm{sel}\\, and
\\C\_\mathrm{pred}\\. All other backends contribute all four components
(\\k = 4\\).

**Comparability across backends:** because `"glmnet"` uses three
components and `"lm"`/`"glm"`/`"rlm"` use four, RI values are not
directly comparable across backends.

## Examples

``` r
set.seed(1)
d <- run_diagnostics(mpg ~ wt + hp, data = mtcars, B = 50)
reproducibility_index(d)
#> $index
#> [1] 97.50225
#> 
#> $components
#>       coef     pvalue  selection prediction 
#>  0.9562648  0.9600000  1.0000000  0.9838253 
#> 
```
