# ReproStat

**Reproducibility Diagnostics for Statistical Modeling**

ReproStat evaluates how stable a fitted model's outputs (coefficients, p-values, variable selection, predictions) are under data perturbations. It reports four stability metrics and aggregates them into a single **Reproducibility Index (RI)** on a 0–100 scale.

---

## Installation


```r
# install.packages("devtools")
devtools::install_github("ntiGideon/ReproStat")
```

### Optional dependencies

| Package | Purpose |
|---------|---------|
| `MASS` | Robust M-estimation backend (`backend = "rlm"`) |
| `glmnet` | Penalized regression backend (`backend = "glmnet"`) |
| `ggplot2` | Enhanced ggplot-based visualisations |

---

## Quick start

```r
library(ReproStat)

set.seed(1)
diag <- run_diagnostics(mpg ~ wt + hp, data = mtcars, B = 200)

# Composite reproducibility index
reproducibility_index(diag)
#> $index
#> [1] 74.3
#>
#> $components
#>      coef    pvalue selection prediction
#>    0.8021    0.7154    0.7412     0.6821

# Confidence interval for the RI
ri_confidence_interval(diag, R = 500)
```

---

## Core workflow

```
perturb_data()       (optional, standalone use)
       |
run_diagnostics()    <-- main entry point
       |
   reprostat object
       |
   ┌───┴────────────────────────────────────┐
   │                                        │
stability metrics                  reproducibility_index()
coef_stability()                         │
pvalue_stability()               ri_confidence_interval()
selection_stability()
prediction_stability()
   │
plot_stability()
cv_ranking_stability() / plot_cv_stability()
```

---

## Functions

### `perturb_data()`

Generates a single perturbed copy of a data frame.

```r
perturb_data(data, method = "bootstrap", frac = 0.8, noise_sd = 0.05)
```

| `method` | Description |
|----------|-------------|
| `"bootstrap"` | Resample *n* rows with replacement (default) |
| `"subsample"` | Draw `floor(frac * n)` rows without replacement |
| `"noise"` | Add Gaussian noise scaled to `noise_sd * sd(column)` |

```r
set.seed(1)
d_boot <- perturb_data(mtcars, method = "bootstrap")
d_sub  <- perturb_data(mtcars, method = "subsample", frac = 0.7)
d_nois <- perturb_data(mtcars, method = "noise",     noise_sd = 0.1)
```

---

### `run_diagnostics()`

Fits a base model and re-fits it on `B` perturbed datasets, collecting
coefficient estimates, p-values, and predictions across iterations.

```r
run_diagnostics(
  formula,
  data,
  B           = 200,
  method      = c("bootstrap", "subsample", "noise"),
  alpha       = 0.05,
  frac        = 0.8,
  noise_sd    = 0.05,
  predict_newdata = NULL,
  family      = NULL,
  backend     = c("lm", "glm", "rlm", "glmnet"),
  en_alpha    = 1,
  lambda      = NULL
)
```

**Backends:**

| `backend` | Model type | Extra dependency |
|-----------|-----------|-----------------|
| `"lm"` | Ordinary least squares | — |
| `"glm"` | Generalized linear model | — |
| `"rlm"` | Robust M-estimation | `MASS` |
| `"glmnet"` | Penalized regression (LASSO / ridge / elastic net) | `glmnet` |

**Returns** an S3 object of class `"reprostat"` containing `coef_mat`
(B × p), `p_mat` (B × p), `pred_mat` (n × B), `base_fit`, `y_train`,
and metadata.

```r
set.seed(1)

# OLS
d_lm  <- run_diagnostics(mpg ~ wt + hp, data = mtcars, B = 200)

# Logistic regression
d_glm <- run_diagnostics(am ~ wt + hp + qsec, data = mtcars, B = 200,
                         family = binomial())

# Robust regression
d_rlm <- run_diagnostics(mpg ~ wt + hp, data = mtcars, B = 200,
                         backend = "rlm")

# LASSO  (lambda chosen by cv.glmnet when lambda = NULL)
d_las <- run_diagnostics(mpg ~ wt + hp + disp + qsec, data = mtcars,
                         B = 200, backend = "glmnet", en_alpha = 1)

# Ridge
d_rid <- run_diagnostics(mpg ~ wt + hp + disp + qsec, data = mtcars,
                         B = 200, backend = "glmnet", en_alpha = 0)

# Elastic net (alpha = 0.5)
d_en  <- run_diagnostics(mpg ~ wt + hp + disp + qsec, data = mtcars,
                         B = 200, backend = "glmnet", en_alpha = 0.5)

print(d_lm)
```

---

### Stability metrics

All four functions accept a `"reprostat"` object and return scalar or
vector summaries. Lower variance / higher frequency values indicate
greater stability.

#### `coef_stability()`

Per-coefficient variance across B iterations. Lower = more stable.

```r
coef_stability(d_lm)
#>  (Intercept)          wt          hp
#>     5.182741    0.043812    0.000231
```

#### `pvalue_stability()`

Proportion of iterations in which each coefficient is significant at
`alpha`. Values near 0 or 1 are stable; 0.5 indicates random decisions.

```r
pvalue_stability(d_lm)
#>  (Intercept)          wt          hp
#>        0.972       0.958       0.731
```

#### `selection_stability()`

Same as `pvalue_stability()` but excludes the intercept. Useful for
assessing variable selection consistency.

```r
selection_stability(d_lm)
#>    wt    hp
#> 0.958 0.731
```

#### `prediction_stability()`

Pointwise prediction variance across iterations, plus the mean.

```r
ps <- prediction_stability(d_lm)
ps$mean_variance          # scalar summary
ps$pointwise_variance     # length-n vector
```

---

### `reproducibility_index()`

Aggregates the four stability components into a composite RI on 0–100.

```r
ri <- reproducibility_index(d_lm)
ri$index        # 0–100 scalar
ri$components   # named vector: coef, pvalue, selection, prediction
```

**Interpretation:**

| RI | Interpretation |
|----|---------------|
| 90–100 | Highly reproducible |
| 70–89 | Moderately reproducible |
| 50–69 | Marginal — results sensitive to data variation |
| < 50 | Low reproducibility — results should be interpreted with caution |

> **Note:** For `backend = "glmnet"`, p-values are undefined, so the
> `pvalue` and `selection` components are `NA` and the RI is averaged
> over the remaining two components (`coef` and `prediction`).

---

### `ri_confidence_interval()`

Bootstrap confidence interval for the RI, computed by resampling the
already-stored perturbation draws (no extra model fitting).

```r
ri_confidence_interval(d_lm, level = 0.95, R = 1000)
#>  2.5% 97.5%
#>  68.4  79.9
```

---

### `plot_stability()`

Bar chart or histogram for one stability dimension.

```r
plot_stability(d_lm, type = "coefficient")   # coefficient variance
plot_stability(d_lm, type = "pvalue")        # significance frequency
plot_stability(d_lm, type = "selection")     # selection frequency
plot_stability(d_lm, type = "prediction")    # prediction variance histogram
```

---

### `cv_ranking_stability()`

Evaluates model *selection* stability by running repeated K-fold
cross-validation and recording the error-metric rank of each candidate
model across repetitions.

```r
cv_ranking_stability(
  formulas,
  data,
  v       = 5L,
  R       = 30L,
  seed    = 20260307L,
  family  = NULL,
  backend = c("lm", "glm", "rlm", "glmnet"),
  en_alpha = 1,
  lambda  = NULL,
  metric  = c("auto", "rmse", "logloss")
)
```

```r
models <- list(
  m1 = mpg ~ wt + hp,
  m2 = mpg ~ wt + hp + disp,
  m3 = mpg ~ wt + hp + disp + qsec
)

cv_obj <- cv_ranking_stability(models, mtcars, v = 5, R = 50)
cv_obj$summary
#>   model mean_rmse sd_rmse mean_rank top1_frequency
#> 1    m3     2.891   0.312      1.24           0.72
#> 2    m2     3.014   0.389      1.94           0.24
#> 3    m1     3.207   0.401      2.82           0.04
```

**Logistic models (log-loss metric):**

```r
glm_models <- list(
  m1 = am ~ wt + hp,
  m2 = am ~ wt + hp + qsec
)
cv_ranking_stability(glm_models, mtcars, v = 5, R = 30,
                     family = binomial(), metric = "logloss")
```

---

### `plot_cv_stability()`

Bar chart of CV ranking results.

```r
plot_cv_stability(cv_obj, metric = "top1_frequency")  # proportion ranked 1st
plot_cv_stability(cv_obj, metric = "mean_rank")        # average rank
```

---

## Full example

```r
library(ReproStat)
set.seed(42)

# 1. Run diagnostics
diag <- run_diagnostics(mpg ~ wt + hp + disp, data = mtcars, B = 200)

# 2. Inspect individual metrics
coef_stability(diag)
pvalue_stability(diag)
selection_stability(diag)
prediction_stability(diag)$mean_variance

# 3. Composite RI + CI
ri <- reproducibility_index(diag)
cat(sprintf("RI = %.1f\n", ri$index))
ri_confidence_interval(diag, R = 500)

# 4. Visualise
par(mfrow = c(2, 2))
plot_stability(diag, "coefficient")
plot_stability(diag, "pvalue")
plot_stability(diag, "selection")
plot_stability(diag, "prediction")

# 5. Cross-validation ranking stability
models <- list(
  base     = mpg ~ wt + hp,
  extended = mpg ~ wt + hp + disp
)
cv_obj <- cv_ranking_stability(models, mtcars, v = 5, R = 50)
plot_cv_stability(cv_obj)
```

---

## Perturbation methods — when to use which

| Scenario | Recommended method |
|----------|--------------------|
| Small dataset, standard inference | `"bootstrap"` |
| Robustness to sample composition | `"subsample"` |
| Sensitivity to measurement noise | `"noise"` |

---

## Reproducibility Index — component reference

| Component | Formula summary | NA for glmnet? |
|-----------|----------------|----------------|
| `coef` | Mean exp-decay of coefficient variance relative to base estimate | No |
| `pvalue` | Mean distance of significance frequency from 0.5 | Yes |
| `selection` | Mean distance of selection frequency from 0.5 | Yes |
| `prediction` | Exp-decay of mean prediction variance relative to outcome variance | No |

The final RI averages all non-NA components and scales to 0–100.

---

## Citation

If you use ReproStat in published work, please cite the accompanying
Journal of Statistical Software manuscript:

> Nti Boateng, G. (2026). *ReproStat: Reproducibility Diagnostics for
> Statistical Modeling in R*. Journal of Statistical Software.

---

## License

GPL (>= 3)
