## ============================================================
## ReproStat — Local Test & Validation Script
##
## PURPOSE
##   1. Run package checks (document / test / check) to catch
##      warnings and errors before pushing to GitHub.
##   2. Exercise every exported function and every backend
##      (lm, glm, rlm, glmnet) across multiple datasets and
##      perturbation methods so you can see live results.
##
## HOW TO RUN
##   From the project root (one level above ReproStat/):
##     source("ReproStat/inst/scripts/run_reprostat.R")
##   Or open this file in RStudio and use Source.
##
## OUTPUT
##   Everything is printed to the console.
##   No files are written. No plots are saved.
## ============================================================

## ---- helpers -----------------------------------------------
sep <- function(title)cat("\n", strrep("=", 62), "\n ", title, "\n", strrep("=", 62), "\n\n", sep = "")

subsep <- function(title)cat("\n  ---", title, "---\n")

pkg_root <- if (basename(getwd()) == "ReproStat") "." else "ReproStat"

## ============================================================
## BLOCK 0 — PRE-COMMIT PACKAGE CHECKS
## ============================================================
sep("BLOCK 0: Pre-commit package checks")

cat("0a. devtools::document() ...\n")
tryCatch(
  devtools::document(pkg_root),
  error   = function(e) cat("  ERROR:", conditionMessage(e), "\n"),
  warning = function(w) cat("  WARNING:", conditionMessage(w), "\n")
)
cat("  document() done.\n")

cat("\n0b. devtools::test() ...\n")
tryCatch(
  devtools::test(pkg_root),
  error   = function(e) cat("  ERROR:", conditionMessage(e), "\n"),
  warning = function(w) cat("  WARNING:", conditionMessage(w), "\n")
)
cat("  test() done.\n")

cat("\n0c. devtools::check() ... (this may take a moment)\n")
chk <- tryCatch(
  devtools::check(pkg_root, quiet = FALSE),
  error   = function(e) { cat("  ERROR:", conditionMessage(e), "\n"); NULL }
)
if (!is.null(chk)) {
  if (length(chk$errors)   > 0) cat("  ERRORS  :", chk$errors,   sep = "\n    ")
  if (length(chk$warnings) > 0) cat("  WARNINGS:", chk$warnings, sep = "\n    ")
  if (length(chk$notes)    > 0) cat("  NOTES   :", chk$notes,    sep = "\n    ")
  if (length(c(chk$errors, chk$warnings, chk$notes)) == 0)
    cat("  check() passed with 0 errors, 0 warnings, 0 notes.\n")
}

## ============================================================
## BLOCK 1 — LOAD PACKAGE
## ============================================================
sep("BLOCK 1: Load package via devtools::load_all()")

## Remove any stale copies of exported names from the global environment
## so load_all() does not warn about masking conflicts.
.pkg_exports <- c(
  "coef_stability", "cv_ranking_stability", "perturb_data",
  "plot_cv_stability", "plot_stability", "prediction_stability",
  "pvalue_stability", "reproducibility_index", "ri_confidence_interval",
  "run_diagnostics", "selection_stability"
)
.to_rm <- intersect(.pkg_exports, ls(envir = .GlobalEnv))
if (length(.to_rm) > 0) {
  rm(list = .to_rm, envir = .GlobalEnv)
  cat("  Removed", length(.to_rm), "stale global binding(s) before load_all().\n")
}
rm(.pkg_exports, .to_rm)

devtools::load_all(pkg_root)
cat("  Package loaded. Exported functions available:\n")
cat("  ", paste(sort(getNamespaceExports("ReproStat")), collapse = ", "), "\n")

set.seed(20260307)

## ============================================================
## BLOCK 2 — perturb_data(): all three methods
## ============================================================
sep("BLOCK 2: perturb_data() — all three methods")

subsep("bootstrap (n=32 -> n=32 with replacement)")
d_boot <- perturb_data(mtcars, method = "bootstrap")
cat("  nrow:", nrow(d_boot), "| unique rows:", nrow(unique(d_boot)), "\n")

subsep("subsample frac=0.7 (n=32 -> ~22 rows)")
d_sub  <- perturb_data(mtcars, method = "subsample", frac = 0.7)
cat("  nrow:", nrow(d_sub), "\n")

subsep("noise sd=0.10")
d_nois <- perturb_data(mtcars, method = "noise", noise_sd = 0.10)
cat("  mpg original range: [", round(range(mtcars$mpg), 2), "]\n")
cat("  mpg noisy range   : [", round(range(d_nois$mpg), 2), "]\n")

## ============================================================
## BLOCK 3 — run_diagnostics(): lm backend
## ============================================================
sep("BLOCK 3: run_diagnostics() — lm backend")

subsep("bootstrap B=100")
diag_lm_boot <- run_diagnostics(mpg ~ wt + hp + disp, data = mtcars,
                                 B = 100, method = "bootstrap")
print(diag_lm_boot)

subsep("subsample frac=0.75 B=100")
diag_lm_sub  <- run_diagnostics(mpg ~ wt + hp + disp, data = mtcars,
                                 B = 100, method = "subsample", frac = 0.75)
print(diag_lm_sub)

subsep("noise sd=0.05 B=100")
diag_lm_noise <- run_diagnostics(mpg ~ wt + hp + disp, data = mtcars,
                                  B = 100, method = "noise", noise_sd = 0.05)
print(diag_lm_noise)

## ============================================================
## BLOCK 4 — run_diagnostics(): glm backend
## ============================================================
sep("BLOCK 4: run_diagnostics() — glm backend (logistic)")

diag_glm <- run_diagnostics(
  am ~ wt + hp + qsec, data = mtcars,
  B = 100, method = "bootstrap",
  family = stats::binomial()
)
print(diag_glm)

subsep("glm poisson on count-like outcome (am coded as integer)")
diag_glm_pois <- run_diagnostics(
  am ~ wt + hp, data = mtcars,
  B = 80, method = "bootstrap",
  backend = "glm", family = stats::poisson()
)
print(diag_glm_pois)

## ============================================================
## BLOCK 5 — run_diagnostics(): rlm backend
## ============================================================
sep("BLOCK 5: run_diagnostics() — rlm backend (MASS robust M-estimation)")

if (!requireNamespace("MASS", quietly = TRUE)) {
  cat("  MASS not installed — skipping rlm tests.\n")
} else {
  subsep("bootstrap B=100")
  diag_rlm_boot <- run_diagnostics(
    mpg ~ wt + hp + disp, data = mtcars,
    B = 100, method = "bootstrap", backend = "rlm"
  )
  print(diag_rlm_boot)

  subsep("subsample frac=0.75 B=100")
  diag_rlm_sub <- run_diagnostics(
    mpg ~ wt + hp + disp, data = mtcars,
    B = 100, method = "subsample", frac = 0.75, backend = "rlm"
  )
  print(diag_rlm_sub)

  subsep("noise sd=0.05 B=100")
  diag_rlm_noise <- run_diagnostics(
    mpg ~ wt + hp + disp, data = mtcars,
    B = 100, method = "noise", noise_sd = 0.05, backend = "rlm"
  )
  print(diag_rlm_noise)
}

## ============================================================
## BLOCK 6 — run_diagnostics(): glmnet backend
## ============================================================
sep("BLOCK 6: run_diagnostics() — glmnet backend (penalized regression)")

if (!requireNamespace("glmnet", quietly = TRUE)) {
  cat("  glmnet not installed — skipping glmnet tests.\n")
} else {
  subsep("LASSO (en_alpha=1) bootstrap B=80")
  diag_lasso <- run_diagnostics(
    mpg ~ wt + hp + disp + qsec + drat + am, data = mtcars,
    B = 80, method = "bootstrap",
    backend = "glmnet", en_alpha = 1
  )
  print(diag_lasso)

  subsep("Ridge (en_alpha=0) bootstrap B=80")
  diag_ridge <- run_diagnostics(
    mpg ~ wt + hp + disp + qsec + drat + am, data = mtcars,
    B = 80, method = "bootstrap",
    backend = "glmnet", en_alpha = 0
  )
  print(diag_ridge)

  subsep("Elastic net (en_alpha=0.5) subsample B=80")
  diag_enet <- run_diagnostics(
    mpg ~ wt + hp + disp + qsec + drat + am, data = mtcars,
    B = 80, method = "subsample", frac = 0.75,
    backend = "glmnet", en_alpha = 0.5
  )
  print(diag_enet)

  subsep("LASSO with fixed lambda=0.1")
  diag_lasso_fixed <- run_diagnostics(
    mpg ~ wt + hp + disp + qsec, data = mtcars,
    B = 60, method = "bootstrap",
    backend = "glmnet", en_alpha = 1, lambda = 0.1
  )
  print(diag_lasso_fixed)
}

## ============================================================
## BLOCK 7 — Stability metrics on each backend
## ============================================================
sep("BLOCK 7: Stability metrics — coef / pvalue / selection / prediction")

for (obj_name in c("diag_lm_boot", "diag_glm")) {
  obj <- get(obj_name)
  cat("\n  [", obj_name, "]\n")
  subsep("coef_stability()")
  print(round(coef_stability(obj), 5))
  subsep("pvalue_stability()")
  print(round(pvalue_stability(obj), 4))
  subsep("selection_stability()")
  print(round(selection_stability(obj), 4))
  subsep("prediction_stability()$mean_variance")
  cat("  ", round(prediction_stability(obj)$mean_variance, 5), "\n")
}

if (requireNamespace("MASS", quietly = TRUE)) {
  cat("\n  [diag_rlm_boot]\n")
  subsep("coef_stability()")
  print(round(coef_stability(diag_rlm_boot), 5))
  subsep("pvalue_stability()  (approximate, via t-distribution)")
  print(round(pvalue_stability(diag_rlm_boot), 4))
  subsep("selection_stability()")
  print(round(selection_stability(diag_rlm_boot), 4))
}

if (requireNamespace("glmnet", quietly = TRUE)) {
  cat("\n  [diag_lasso — glmnet]\n")
  subsep("coef_stability()  (includes shrinkage-to-zero variability)")
  print(round(coef_stability(diag_lasso), 5))
  subsep("pvalue_stability() — expect all NA (no p-values for glmnet)")
  print(pvalue_stability(diag_lasso))
  subsep("selection_stability() — expect all NA")
  print(selection_stability(diag_lasso))
  subsep("prediction_stability()$mean_variance")
  cat("  ", round(prediction_stability(diag_lasso)$mean_variance, 5), "\n")
}

## ============================================================
## BLOCK 8 — reproducibility_index() and ri_confidence_interval()
## ============================================================
sep("BLOCK 8: reproducibility_index() and ri_confidence_interval()")

for (obj_name in c("diag_lm_boot", "diag_lm_sub", "diag_lm_noise",
                   "diag_glm")) {
  cat("\n  [", obj_name, "]\n")
  ri <- reproducibility_index(get(obj_name))
  cat("  RI:", round(ri$index, 2), "/ 100\n")
  cat("  Components:\n")
  print(round(ri$components, 4))
  ci <- ri_confidence_interval(get(obj_name), R = 200, seed = 42L)
  cat("  95% CI: [", round(ci[1], 2), ",", round(ci[2], 2), "]\n")
}

if (requireNamespace("MASS", quietly = TRUE)) {
  cat("\n  [diag_rlm_boot]\n")
  ri_rlm <- reproducibility_index(diag_rlm_boot)
  cat("  RI:", round(ri_rlm$index, 2), "/ 100\n")
  cat("  Components:\n"); print(round(ri_rlm$components, 4))
  ci_rlm <- ri_confidence_interval(diag_rlm_boot, R = 200, seed = 42L)
  cat("  95% CI: [", round(ci_rlm[1], 2), ",", round(ci_rlm[2], 2), "]\n")
}

if (requireNamespace("glmnet", quietly = TRUE)) {
  for (obj_name in c("diag_lasso", "diag_ridge", "diag_enet")) {
    cat("\n  [", obj_name, "— glmnet]\n")
    ri_g <- reproducibility_index(get(obj_name))
    cat("  RI (coef + pred only):", round(ri_g$index, 2), "/ 100\n")
    cat("  Components (pvalue/selection = NA for glmnet):\n")
    print(round(ri_g$components, 4))
    ci_g <- ri_confidence_interval(get(obj_name), R = 200, seed = 42L)
    cat("  95% CI: [", round(ci_g[1], 2), ",", round(ci_g[2], 2), "]\n")
  }
}

## ============================================================
## BLOCK 9 — plot_stability(): all four types, multiple backends
## ============================================================
sep("BLOCK 9: plot_stability() — all 4 types (plots shown on screen)")

cat("  Showing all 4 plot types for diag_lm_boot ...\n")
graphics::par(mfrow = c(2, 2))
plot_stability(diag_lm_boot, "coefficient")
plot_stability(diag_lm_boot, "pvalue")
plot_stability(diag_lm_boot, "selection")
plot_stability(diag_lm_boot, "prediction")
graphics::par(mfrow = c(1, 1))

cat("  Showing coefficient + selection for diag_glm ...\n")
graphics::par(mfrow = c(1, 2))
plot_stability(diag_glm, "coefficient")
plot_stability(diag_glm, "selection")
graphics::par(mfrow = c(1, 1))

if (requireNamespace("MASS", quietly = TRUE)) {
  cat("  rlm: coefficient + selection ...\n")
  graphics::par(mfrow = c(1, 2))
  plot_stability(diag_rlm_boot, "coefficient")
  plot_stability(diag_rlm_boot, "selection")
  graphics::par(mfrow = c(1, 1))
}

if (requireNamespace("glmnet", quietly = TRUE)) {
  cat("  glmnet (LASSO vs Ridge) coefficient stability ...\n")
  graphics::par(mfrow = c(1, 2))
  plot_stability(diag_lasso, "coefficient")
  plot_stability(diag_ridge, "coefficient")
  graphics::par(mfrow = c(1, 1))
  cat("  (note: pvalue/selection plots will warn for glmnet — all-NA values)\n")
}

## ============================================================
## BLOCK 10 — cv_ranking_stability(): all backends
## ============================================================
sep("BLOCK 10: cv_ranking_stability() — all backends")

lm_models <- list(
  baseline = mpg ~ wt + hp + disp,
  compact  = mpg ~ wt + hp,
  expanded = mpg ~ wt + hp + disp + qsec
)

subsep("lm backend — RMSE metric")
cv_lm <- cv_ranking_stability(lm_models, mtcars, v = 5, R = 20, seed = 42L)
cat("  Settings: backend =", cv_lm$settings$backend,
    "| metric =", cv_lm$settings$metric, "\n")
print(cv_lm$summary)

subsep("glm backend — logistic / log-loss metric")
glm_models <- list(
  baseline = am ~ wt + hp + qsec,
  compact  = am ~ wt + hp,
  expanded = am ~ wt + hp + qsec + disp
)
cv_glm <- cv_ranking_stability(glm_models, mtcars, v = 5, R = 20,
                                seed = 42L, family = stats::binomial(),
                                metric = "logloss")
cat("  Settings: backend =", cv_glm$settings$backend,
    "| metric =", cv_glm$settings$metric, "\n")
print(cv_glm$summary)

subsep("lm backend — mean_rank metric (different sort order)")
cv_lm_rank <- cv_ranking_stability(lm_models, mtcars, v = 5, R = 20,
                                    seed = 42L, metric = "rmse")
print(cv_lm_rank$summary[, c("model", "mean_rank", "top1_frequency")])

if (requireNamespace("MASS", quietly = TRUE)) {
  subsep("rlm backend — robust CV ranking")
  cv_rlm <- cv_ranking_stability(lm_models, mtcars, v = 5, R = 20,
                                  seed = 42L, backend = "rlm")
  cat("  Settings: backend =", cv_rlm$settings$backend, "\n")
  print(cv_rlm$summary)
}

if (requireNamespace("glmnet", quietly = TRUE)) {
  subsep("glmnet LASSO backend — CV ranking")
  lasso_cv_models <- list(
    small  = mpg ~ wt + hp,
    medium = mpg ~ wt + hp + disp,
    large  = mpg ~ wt + hp + disp + qsec + drat + am
  )
  cv_glmnet <- cv_ranking_stability(lasso_cv_models, mtcars, v = 5, R = 20,
                                     seed = 42L, backend = "glmnet", en_alpha = 1)
  cat("  Settings: backend =", cv_glmnet$settings$backend, "\n")
  print(cv_glmnet$summary)

  subsep("glmnet Ridge backend — CV ranking")
  cv_ridge_cv <- cv_ranking_stability(lasso_cv_models, mtcars, v = 5, R = 20,
                                       seed = 42L, backend = "glmnet", en_alpha = 0)
  print(cv_ridge_cv$summary)
}

## ============================================================
## BLOCK 11 — plot_cv_stability(): both metrics
## ============================================================
sep("BLOCK 11: plot_cv_stability() — top1_frequency and mean_rank")

graphics::par(mfrow = c(1, 2))
plot_cv_stability(cv_lm, "top1_frequency")
plot_cv_stability(cv_lm, "mean_rank")
graphics::par(mfrow = c(1, 1))

graphics::par(mfrow = c(1, 2))
plot_cv_stability(cv_glm, "top1_frequency")
plot_cv_stability(cv_glm, "mean_rank")
graphics::par(mfrow = c(1, 1))

if (requireNamespace("MASS", quietly = TRUE)) {
  graphics::par(mfrow = c(1, 2))
  plot_cv_stability(cv_rlm, "top1_frequency")
  plot_cv_stability(cv_rlm, "mean_rank")
  graphics::par(mfrow = c(1, 1))
}

if (requireNamespace("glmnet", quietly = TRUE)) {
  graphics::par(mfrow = c(1, 2))
  plot_cv_stability(cv_glmnet, "top1_frequency")
  plot_cv_stability(cv_glmnet, "mean_rank")
  graphics::par(mfrow = c(1, 1))
}

## ============================================================
## BLOCK 12 — Multiple real datasets
## ============================================================
sep("BLOCK 12: Multiple real datasets")

subsep("iris — noise perturbation")
iris_diag <- run_diagnostics(
  Sepal.Length ~ Sepal.Width + Petal.Length + Petal.Width,
  data = iris, B = 100, method = "noise", noise_sd = 0.03
)
iris_ri <- reproducibility_index(iris_diag)
cat("  RI:", round(iris_ri$index, 2), "\n")
print(round(iris_ri$components, 4))

subsep("airquality — bootstrap (111 complete rows)")
aq      <- na.omit(airquality[, c("Ozone", "Solar.R", "Wind", "Temp")])
aq_diag <- run_diagnostics(
  Ozone ~ Solar.R + Wind + Temp, data = aq,
  B = 100, method = "bootstrap"
)
aq_ri <- reproducibility_index(aq_diag)
cat("  RI:", round(aq_ri$index, 2), "\n")
print(round(aq_ri$components, 4))

subsep("airquality — CV with quadratic term")
aq_models <- list(
  full      = Ozone ~ Solar.R + Wind + Temp,
  no_solar  = Ozone ~ Wind + Temp,
  quadratic = Ozone ~ Solar.R + Wind + Temp + I(Temp^2)
)
aq_cv <- cv_ranking_stability(aq_models, aq, v = 5, R = 20, seed = 42L)
print(aq_cv$summary)

## ============================================================
## BLOCK 13 — Simulation study (4 stress scenarios)
## ============================================================
sep("BLOCK 13: Simulation study — 4 stress scenarios")

simulate_scenario <- function(n = 120, noise = 1, rho = 0.2, seed = 1L) {
  set.seed(seed)
  x1 <- rnorm(n)
  x2 <- rho * x1 + sqrt(1 - rho^2) * rnorm(n)
  x3 <- rnorm(n)
  data.frame(y = 3 + 2*x1 - 1.5*x3 + rnorm(n, sd = noise),
             x1 = x1, x2 = x2, x3 = x3)
}

scenarios <- list(
  list(label = "baseline",          n = 200, noise = 1.0, rho = 0.20),
  list(label = "multicollinearity", n = 200, noise = 1.0, rho = 0.98),
  list(label = "small_sample",      n = 40,  noise = 1.0, rho = 0.20),
  list(label = "high_noise",        n = 200, noise = 3.0, rho = 0.20)
)

sim_results <- do.call(rbind, lapply(seq_along(scenarios), function(i) {
  s   <- scenarios[[i]]
  dat <- simulate_scenario(n = s$n, noise = s$noise, rho = s$rho, seed = i)
  d   <- run_diagnostics(y ~ x1 + x2 + x3, data = dat, B = 100,
                          method = "subsample", frac = 0.75)
  ri  <- reproducibility_index(d)
  ci  <- ri_confidence_interval(d, R = 200, seed = 42L)
  cat("  [", s$label, "] RI =", round(ri$index, 2),
      "| CI [", round(ci[1], 2), ",", round(ci[2], 2), "]\n")
  data.frame(
    scenario   = s$label,
    n          = s$n,
    noise      = s$noise,
    rho        = s$rho,
    RI         = round(ri$index, 2),
    CI_lower   = round(ci[1], 2),
    CI_upper   = round(ci[2], 2),
    C_coef     = round(ri$components["coef"],       3),
    C_pvalue   = round(ri$components["pvalue"],     3),
    C_sel      = round(ri$components["selection"],  3),
    C_pred     = round(ri$components["prediction"], 3),
    stringsAsFactors = FALSE
  )
}))
sim_results <- sim_results[order(sim_results$RI, decreasing = TRUE), ]
rownames(sim_results) <- NULL
cat("\n  Full simulation table:\n")
print(sim_results)

## ============================================================
## BLOCK 14 — print.reprostat() and edge cases
## ============================================================
sep("BLOCK 14: print.reprostat() for all backends")

print(diag_lm_boot)
print(diag_glm)
if (requireNamespace("MASS",   quietly = TRUE)) print(diag_rlm_boot)
if (requireNamespace("glmnet", quietly = TRUE)) print(diag_lasso)

sep("BLOCK 14b: Edge cases")

subsep("Single predictor (lm)")
diag_single <- run_diagnostics(mpg ~ wt, data = mtcars, B = 50)
cat("  RI:", round(reproducibility_index(diag_single)$index, 2), "\n")

subsep("Large number of predictors (lm, all mtcars columns as predictors)")
diag_full <- run_diagnostics(mpg ~ ., data = mtcars, B = 50)
cat("  RI:", round(reproducibility_index(diag_full)$index, 2), "\n")
cat("  Coef names:", paste(colnames(diag_full$coef_mat), collapse = ", "), "\n")

subsep("ri_confidence_interval() with different levels")
d_tmp <- run_diagnostics(mpg ~ wt + hp, data = mtcars, B = 50)
cat("  90% CI:", round(ri_confidence_interval(d_tmp, level = 0.90, R = 150), 2), "\n")
cat("  95% CI:", round(ri_confidence_interval(d_tmp, level = 0.95, R = 150), 2), "\n")
cat("  99% CI:", round(ri_confidence_interval(d_tmp, level = 0.99, R = 150), 2), "\n")

subsep("predict_newdata out-of-sample — first 10 rows as test set")
diag_oos <- run_diagnostics(
  mpg ~ wt + hp, data = mtcars,
  B = 50, predict_newdata = mtcars[1:10, ]
)
cat("  pred_mat dimensions:", dim(diag_oos$pred_mat), "(should be 10 x 50)\n")
cat("  mean prediction variance:", round(prediction_stability(diag_oos)$mean_variance, 4), "\n")

subsep("cv_ranking_stability() with 2 models (minimum)")
cv_min <- cv_ranking_stability(
  list(m1 = mpg ~ wt, m2 = mpg ~ hp),
  mtcars, v = 5, R = 10, seed = 1L
)
print(cv_min$summary)

## ============================================================
## BLOCK 15 — Cross-backend comparison on same data
## ============================================================
sep("BLOCK 15: Cross-backend RI comparison on mtcars mpg ~ wt + hp + disp")

backends_to_test <- c("lm", "rlm", "glmnet")
for (bk in backends_to_test) {
  ok <- if (bk == "rlm")    requireNamespace("MASS",   quietly = TRUE) else
        if (bk == "glmnet") requireNamespace("glmnet", quietly = TRUE) else TRUE
  if (!ok) { cat("  [", bk, "] skipped — package not installed\n"); next }

  d <- run_diagnostics(
    mpg ~ wt + hp + disp, data = mtcars,
    B = 80, method = "bootstrap", backend = bk
  )
  ri <- reproducibility_index(d)
  cat(sprintf("  %-8s RI = %6.2f  |  C_coef=%5.3f  C_pred=%5.3f",
              bk, ri$index,
              ri$components["coef"],
              ri$components["prediction"]))
  if (!is.na(ri$components["pvalue"]))
    cat(sprintf("  C_pval=%5.3f  C_sel=%5.3f",
                ri$components["pvalue"], ri$components["selection"]))
  else
    cat("  C_pval=  NA    C_sel=  NA  (penalized)")
  cat("\n")
}

## ============================================================
sep("ALL BLOCKS COMPLETE — no files were written")
cat("  Check console output above for any errors or unexpected values.\n\n")
