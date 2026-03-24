## ============================================================
## ReproStat - Complete Function Walkthrough
## Run this demo with:
##   demo("reprostat", package = "ReproStat")
## ============================================================

library(ReproStat)

cat("\n======================================================\n")
cat("  ReproStat: Reproducibility Diagnostics Demo\n")
cat("======================================================\n\n")

set.seed(20260307)


## ------------------------------------------------------------
## SECTION 1 - perturb_data()
## Generate perturbed versions of a dataset
## ------------------------------------------------------------
cat("--- 1. perturb_data() ---\n")

# Bootstrap: same size, sampling with replacement
d_boot <- perturb_data(mtcars, method = "bootstrap")
cat("Bootstrap rows (should equal original):", nrow(d_boot), "==", nrow(mtcars), "\n")

# Subsampling: 75 % of rows, no replacement
d_sub <- perturb_data(mtcars, method = "subsample", frac = 0.75)
cat("Subsample rows:", nrow(d_sub), "(75% of", nrow(mtcars), ")\n")

# Noise injection: adds small Gaussian noise to numeric columns
d_noise <- perturb_data(mtcars, method = "noise", noise_sd = 0.05)
cat("Noise-perturbed mpg (first 5):", round(d_noise$mpg[1:5], 3), "\n\n")


## ------------------------------------------------------------
## SECTION 2 - run_diagnostics()
## The main entry point: fit + perturb + refit B times
## ------------------------------------------------------------
cat("--- 2. run_diagnostics() ---\n")

# Linear model (lm) -- mtcars
mt_diag <- run_diagnostics(
  mpg ~ wt + hp + disp,
  data   = mtcars,
  B      = 150,
  method = "bootstrap",
  alpha  = 0.05
)

print(mt_diag)          # uses print.reprostat()
cat("\n")


## ------------------------------------------------------------
## SECTION 3 - Individual stability metrics
## ------------------------------------------------------------
cat("--- 3. Stability metrics ---\n")

cat("\nCoefficient variance (lower = more stable):\n")
print(round(coef_stability(mt_diag), 4))

cat("\nP-value significance frequency (0-1, extremes = stable):\n")
print(round(pvalue_stability(mt_diag), 3))

cat("\nSelection frequency (0-1, high = consistently selected):\n")
print(round(selection_stability(mt_diag), 3))

ps <- prediction_stability(mt_diag)
cat("\nMean prediction variance:", round(ps$mean_variance, 4), "\n\n")


## ------------------------------------------------------------
## SECTION 4 - Reproducibility index
## Composite 0-100 score
## ------------------------------------------------------------
cat("--- 4. reproducibility_index() ---\n")

ri <- reproducibility_index(mt_diag)
cat("RI:", round(ri$index, 2), "/ 100\n")
cat("Components:\n")
print(round(ri$components, 3))

# Bootstrap confidence interval for the RI
cat("\nBootstrap 95% CI for RI (R = 300 resamples):\n")
ci <- ri_confidence_interval(mt_diag, level = 0.95, R = 300)
cat(sprintf("  [%.2f, %.2f]\n\n", ci[1], ci[2]))


## ------------------------------------------------------------
## SECTION 5 - Visualizations
## ------------------------------------------------------------
cat("--- 5. plot_stability() ---\n")
cat("Opening plots...\n\n")

# Coefficient variance barplot
dev.new()
plot_stability(mt_diag, "coefficient")
title(sub = "mtcars bootstrap, B = 150", cex.sub = 0.8, col.sub = "grey50")

# Selection frequency barplot
dev.new()
plot_stability(mt_diag, "selection")
title(sub = "mtcars bootstrap, B = 150", cex.sub = 0.8, col.sub = "grey50")

# P-value significance frequency
dev.new()
plot_stability(mt_diag, "pvalue")

# Prediction variance histogram
dev.new()
plot_stability(mt_diag, "prediction")


## ------------------------------------------------------------
## SECTION 6 - Subsample and noise methods
## ------------------------------------------------------------
cat("--- 6. Alternative perturbation methods ---\n")

# Subsampling (75 % of rows)
mt_sub <- run_diagnostics(mpg ~ wt + hp + disp, data = mtcars,
                          B = 150, method = "subsample", frac = 0.75)
cat("Subsample RI:", round(reproducibility_index(mt_sub)$index, 2), "\n")

# Noise injection
mt_noise <- run_diagnostics(mpg ~ wt + hp + disp, data = mtcars,
                            B = 150, method = "noise", noise_sd = 0.05)
cat("Noise RI:     ", round(reproducibility_index(mt_noise)$index, 2), "\n\n")


## ------------------------------------------------------------
## SECTION 7 - cv_ranking_stability()
## Compare competing models via repeated K-fold CV
## ------------------------------------------------------------
cat("--- 7. cv_ranking_stability() ---\n")

cv_models <- list(
  baseline = mpg ~ wt + hp + disp,
  compact  = mpg ~ wt + hp,
  expanded = mpg ~ wt + hp + disp + qsec
)

mt_cv <- cv_ranking_stability(cv_models, mtcars, v = 5, R = 40,
                              seed = 20260307)
cat("CV ranking summary:\n")
print(mt_cv$summary)

dev.new()
plot_cv_stability(mt_cv, metric = "top1_frequency")

dev.new()
plot_cv_stability(mt_cv, metric = "mean_rank")


## ------------------------------------------------------------
## SECTION 8 - GLM support (binary outcome)
## ------------------------------------------------------------
cat("\n--- 8. GLM (logistic regression) ---\n")

mt_glm <- suppressWarnings(
  run_diagnostics(
    am ~ wt + hp + qsec,
    data   = mtcars,
    B      = 150,
    method = "bootstrap",
    family = stats::binomial()
  )
)

cat("GLM RI:", round(reproducibility_index(mt_glm)$index, 2), "\n")
cat("GLM selection stability:\n")
print(round(selection_stability(mt_glm), 3))

glm_ci <- ri_confidence_interval(mt_glm, R = 200)
cat(sprintf("GLM RI 95%% CI: [%.2f, %.2f]\n\n", glm_ci[1], glm_ci[2]))


## ------------------------------------------------------------
## SECTION 9 - iris dataset (noise perturbation)
## ------------------------------------------------------------
cat("--- 9. iris dataset ---\n")

iris_diag <- run_diagnostics(
  Sepal.Length ~ Sepal.Width + Petal.Length + Petal.Width,
  data     = iris,
  B        = 150,
  method   = "noise",
  noise_sd = 0.03
)

cat("iris RI:", round(reproducibility_index(iris_diag)$index, 2), "\n")
cat("iris selection stability:\n")
print(round(selection_stability(iris_diag), 3))

dev.new()
oldpar <- par(mfrow = c(1, 2))
plot_stability(iris_diag, "coefficient")
plot_stability(iris_diag, "selection")
par(oldpar)


## ------------------------------------------------------------
## SECTION 10 - airquality dataset (environmental data)
## ------------------------------------------------------------
cat("\n--- 10. airquality dataset ---\n")

aq <- na.omit(airquality[, c("Ozone", "Solar.R", "Wind", "Temp")])
cat("Complete cases:", nrow(aq), "\n")

aq_diag <- run_diagnostics(
  Ozone ~ Solar.R + Wind + Temp,
  data   = aq,
  B      = 150,
  method = "bootstrap"
)

cat("airquality RI:", round(reproducibility_index(aq_diag)$index, 2), "\n")
cat("95% CI: ")
aq_ci <- ri_confidence_interval(aq_diag, R = 300)
cat(sprintf("[%.2f, %.2f]\n", aq_ci[1], aq_ci[2]))

dev.new()
oldpar <- par(mfrow = c(1, 2))
plot_stability(aq_diag, "coefficient")
plot_stability(aq_diag, "prediction")
par(oldpar)

# CV model comparison for airquality
aq_models <- list(
  full      = Ozone ~ Solar.R + Wind + Temp,
  no_solar  = Ozone ~ Wind + Temp,
  quadratic = Ozone ~ Solar.R + Wind + Temp + I(Temp^2)
)
aq_cv <- cv_ranking_stability(aq_models, aq, v = 5, R = 30, seed = 20260307)
cat("\nairquality CV ranking:\n")
print(aq_cv$summary)

dev.new()
plot_cv_stability(aq_cv, metric = "top1_frequency")


## ------------------------------------------------------------
## SECTION 11 - Simulation study (four stress scenarios)
## ------------------------------------------------------------
cat("\n--- 11. Simulation study ---\n")

simulate_scenario <- function(n = 120, noise = 1, rho = 0.2) {
  x1 <- rnorm(n)
  x2 <- rho * x1 + sqrt(1 - rho^2) * rnorm(n)
  x3 <- rnorm(n)
  y  <- 3 + 2 * x1 - 1.5 * x3 + rnorm(n, sd = noise)
  data.frame(y = y, x1 = x1, x2 = x2, x3 = x3)
}

run_scenario <- function(label, n, noise, rho) {
  dat <- simulate_scenario(n = n, noise = noise, rho = rho)
  d   <- run_diagnostics(y ~ x1 + x2 + x3, data = dat, B = 100,
                         method = "subsample", frac = 0.75)
  ri  <- reproducibility_index(d)
  cat(sprintf("  %-20s  RI = %.1f\n", label, ri$index))
  invisible(ri)
}

cat("Scenario results:\n")
run_scenario("baseline",         n = 200, noise = 1.0, rho = 0.20)
run_scenario("multicollinearity", n = 200, noise = 1.0, rho = 0.98)
run_scenario("small_sample",     n = 40,  noise = 1.0, rho = 0.20)
run_scenario("high_noise",       n = 200, noise = 3.0, rho = 0.20)

cat("\n======================================================\n")
cat("  Demo complete.\n")
cat("  See vignette('ReproStat-intro') for a narrative guide.\n")
cat("======================================================\n")
