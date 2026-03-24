# Run reproducibility diagnostics

Fits a model on the original data, then repeatedly fits on perturbed
versions to collect coefficient estimates, p-values, and predictions for
downstream stability analysis. Four modeling backends are supported:
ordinary least squares (`"lm"`), generalized linear models (`"glm"`),
robust regression (`"rlm"` via MASS), and penalized regression
(`"glmnet"` via glmnet).

## Usage

``` r
run_diagnostics(
  formula,
  data,
  B = 200,
  method = c("bootstrap", "subsample", "noise"),
  alpha = 0.05,
  frac = 0.8,
  noise_sd = 0.05,
  predict_newdata = NULL,
  family = NULL,
  backend = c("lm", "glm", "rlm", "glmnet"),
  en_alpha = 1,
  lambda = NULL,
  perturb_response = FALSE
)
```

## Arguments

- formula:

  A model formula.

- data:

  A data frame.

- B:

  Integer. Number of perturbation iterations. Default is `200`.

- method:

  Perturbation method passed to
  [`perturb_data`](https://ntiGideon.github.io/ReproStat/reference/perturb_data.md).
  One of `"bootstrap"` (default), `"subsample"`, or `"noise"`.

- alpha:

  Significance threshold for p-value and selection stability. Default is
  `0.05`.

- frac:

  Subsampling fraction. Passed to
  [`perturb_data`](https://ntiGideon.github.io/ReproStat/reference/perturb_data.md).
  Default is `0.8`.

- noise_sd:

  Noise level. Passed to
  [`perturb_data`](https://ntiGideon.github.io/ReproStat/reference/perturb_data.md).
  Default is `0.05`.

- predict_newdata:

  Optional data frame for out-of-sample prediction stability. Defaults
  to `data`.

- family:

  A GLM family object (e.g.
  [`stats::binomial()`](https://rdrr.io/r/stats/family.html),
  [`stats::poisson()`](https://rdrr.io/r/stats/family.html)). Used only
  when `backend = "glm"` (or when `family` is non-`NULL` and
  `backend = "lm"`, in which case the backend is silently promoted to
  `"glm"`).

- backend:

  Modeling backend. One of `"lm"` (default), `"glm"`, `"rlm"` (robust
  M-estimation via
  [`MASS::rlm`](https://rdrr.io/pkg/MASS/man/rlm.html)), or `"glmnet"`
  (penalized regression via
  [`glmnet::glmnet`](https://glmnet.stanford.edu/reference/glmnet.html)).

- en_alpha:

  Elastic-net mixing parameter passed to
  [`glmnet::glmnet`](https://glmnet.stanford.edu/reference/glmnet.html):
  `1` (default) gives the LASSO, `0` gives ridge, intermediate values
  give elastic net. Ignored for other backends.

- lambda:

  Regularization parameter for `glmnet`. When `NULL` (default) the
  penalty is selected by
  [`glmnet::cv.glmnet`](https://glmnet.stanford.edu/reference/cv.glmnet.html)
  using `lambda.min`. Ignored for other backends.

- perturb_response:

  Logical. When `FALSE` (default) and `method = "noise"`, noise is added
  only to predictor columns; the response variable is left unchanged.
  Set to `TRUE` to also perturb the response (e.g. to simulate
  measurement error in the outcome). Has no effect for
  `method = "bootstrap"` or `"subsample"`, where row-level resampling
  naturally carries the response along.

## Value

An object of class `"reprostat"`, a list with components:

- `call`:

  The matched call.

- `formula`:

  The model formula.

- `B`:

  Number of iterations used.

- `alpha`:

  Significance threshold used.

- `base_fit`:

  Model fitted on the original data.

- `y_train`:

  Response vector from the original data (used internally for RI
  computation).

- `coef_mat`:

  B x p matrix of coefficient estimates.

- `p_mat`:

  B x p matrix of p-values, or all-`NA` for `backend = "glmnet"` (where
  p-values are not defined).

- `pred_mat`:

  n x B matrix of predictions.

- `method`:

  Perturbation method used.

- `family`:

  GLM family used, or `NULL`.

- `backend`:

  Backend used.

- `en_alpha`:

  Elastic-net mixing parameter used (only relevant for
  `backend = "glmnet"`, otherwise `NA`).

## Examples

``` r
set.seed(1)
# Linear model (small B for a quick check)
diag_lm <- run_diagnostics(mpg ~ wt + hp, data = mtcars, B = 20)
print(diag_lm)
#> ReproStat Diagnostics
#> ---------------------
#> Formula   : mpg ~ wt + hp 
#> Backend   : lm 
#> Method    : bootstrap 
#> Iterations: 20 
#> Terms     : (Intercept), wt, hp 

# \donttest{
# Logistic regression
diag_glm <- run_diagnostics(am ~ wt + hp + qsec, data = mtcars, B = 50,
                            family = stats::binomial())
reproducibility_index(diag_glm)
#> $index
#> [1] 75.00492
#> 
#> $components
#>       coef     pvalue  selection prediction 
#>  0.2497427  1.0000000  0.8533333  0.8971209 
#> 

# Robust regression (requires MASS)
if (requireNamespace("MASS", quietly = TRUE)) {
  diag_rlm <- run_diagnostics(mpg ~ wt + hp, data = mtcars, B = 50,
                              backend = "rlm")
  reproducibility_index(diag_rlm)
}
#> $index
#> [1] 96.84662
#> 
#> $components
#>       coef     pvalue  selection prediction 
#>  0.9190617  0.9800000  1.0000000  0.9748032 
#> 

# Penalized regression / LASSO (requires glmnet)
if (requireNamespace("glmnet", quietly = TRUE)) {
  diag_glmnet <- run_diagnostics(mpg ~ wt + hp + disp + qsec, data = mtcars,
                                 B = 50, backend = "glmnet", en_alpha = 1)
  reproducibility_index(diag_glmnet)
}
#> $index
#> [1] 82.57931
#> 
#> $components
#>       coef     pvalue  selection prediction 
#>  0.7604751         NA  0.7450000  0.9719042 
#> 
# }
```
