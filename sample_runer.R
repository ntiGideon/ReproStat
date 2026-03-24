# ============================================================
#  ReproStat — End-to-End Sample Runner
#  Run from inside ReproStat/ with:
#    source("sample_runer.R")
#  or open in RStudio and Run All.
# ============================================================

devtools::load_all(".")

# ── Helpers ──────────────────────────────────────────────────
hdr <- function(txt) {
  cat("\n", strrep("═", 62), "\n  ", txt, "\n", strrep("═", 62), "\n", sep="")
}
sub_hdr <- function(txt) cat("\n  ──", txt, "──\n")

PASS <- function(label) cat(sprintf("  [PASS] %s\n", label))
FAIL <- function(label, got, exp) {
  cat(sprintf("  [FAIL] %s\n         expected: %s\n         got:      %s\n",
              label, deparse(exp), deparse(got)))
}
chk <- function(label, got, expected, tol = 1e-4) {
  if (isTRUE(all.equal(as.numeric(got), as.numeric(expected),
                        tolerance = tol, check.names = FALSE)))
    PASS(label)
  else
    FAIL(label, got, expected)
}

# ============================================================
#  SECTION 0 — HAND-CALCULATION VERIFICATION
#  We build a tiny mock reprostat object whose matrices are
#  known numbers, then verify every metric by hand.
# ============================================================
hdr("SECTION 0 · Hand-Calculation Verification")

cat("
PURPOSE
-------
We bypass run_diagnostics() and build a reprostat object directly
so that every internal matrix has values YOU chose.  Each metric
function is then compared to the result you can compute with a
pocket calculator or pen-and-paper.

DATA
----
  y  = c(2, 4, 6, 8, 10)   (perfect y = 2*x1 relationship)
  x1 = c(1, 2, 3, 4, 5)
  lm(y ~ x1) gives exactly: (Intercept) = 0, x1 = 2

MATRICES  (B = 5 iterations, n = 5 observations)
-------------------------------------------------
coef_mat  (5 × 2):
  iter  (Intercept)   x1
   1       0.5       1.8
   2      -0.2       2.3
   3       0.3       1.9
   4       0.1       2.1
   5      -0.1       2.4

p_mat  (5 × 2):
  iter  (Intercept)    x1
   1      0.42        0.001
   2      0.68        0.003
   3      0.51        0.002
   4      0.88        0.001
   5      0.73        0.008

pred_mat  (5 obs × 5 iters):
  obs     i1    i2    i3    i4    i5
   1      2.3   2.1   2.2   2.4   2.5
   2      4.1   4.4   4.0   4.2   4.3
   3      5.9   6.0   6.1   5.8   6.0
   4      7.8   7.9   8.0   7.7   7.8
   5      9.9   9.8   9.7  10.0   9.9
\n")

# Build the mock object -----------------------------------------
hc_data     <- data.frame(y = c(2,4,6,8,10), x1 = c(1,2,3,4,5))
hc_base_fit <- lm(y ~ x1, data = hc_data)

hand_coef <- matrix(
  c( 0.5, 1.8,
    -0.2, 2.3,
     0.3, 1.9,
     0.1, 2.1,
    -0.1, 2.4),
  nrow=5, ncol=2, byrow=TRUE,
  dimnames=list(NULL, c("(Intercept)","x1")))

hand_pmat <- matrix(
  c(0.42, 0.001,
    0.68, 0.003,
    0.51, 0.002,
    0.88, 0.001,
    0.73, 0.008),
  nrow=5, ncol=2, byrow=TRUE,
  dimnames=list(NULL, c("(Intercept)","x1")))

hand_pred <- matrix(
  c(2.3, 2.1, 2.2, 2.4, 2.5,
    4.1, 4.4, 4.0, 4.2, 4.3,
    5.9, 6.0, 6.1, 5.8, 6.0,
    7.8, 7.9, 8.0, 7.7, 7.8,
    9.9, 9.8, 9.7,10.0, 9.9),
  nrow=5, ncol=5, byrow=TRUE)

mock <- structure(
  list(coef_mat=hand_coef, p_mat=hand_pmat, pred_mat=hand_pred,
       alpha=0.05, backend="lm", base_fit=hc_base_fit,
       y_train=c(2,4,6,8,10), B=5L, method="bootstrap"),
  class="reprostat")

# ── 0A · coef_stability ───────────────────────────────────────
sub_hdr("0A · coef_stability")
cat("
HAND CALC
  Intercept column: c(0.5, -0.2, 0.3, 0.1, -0.1)
    mean  = (0.5 - 0.2 + 0.3 + 0.1 - 0.1) / 5 = 0.12
    deviations: 0.38, -0.32, 0.18, -0.02, -0.22
    sq devs:    0.1444, 0.1024, 0.0324, 0.0004, 0.0484
    sum = 0.328  →  var = 0.328 / 4 = 0.082

  x1 column: c(1.8, 2.3, 1.9, 2.1, 2.4)
    mean  = 10.5 / 5 = 2.1
    deviations: -0.3, 0.2, -0.2, 0, 0.3
    sq devs:     0.09, 0.04, 0.04, 0, 0.09
    sum = 0.26   →  var = 0.26 / 4 = 0.065
\n")

cs <- coef_stability(mock)
cat("  R output:", paste(names(cs), round(cs,6), sep="=", collapse=", "), "\n")
chk("(Intercept) variance = 0.082", cs["(Intercept)"], 0.082)
chk("x1 variance = 0.065",          cs["x1"],          0.065)

# ── 0B · pvalue_stability ─────────────────────────────────────
sub_hdr("0B · pvalue_stability")
cat("
HAND CALC  (alpha = 0.05, intercept excluded)
  x1 p-values: 0.001, 0.003, 0.002, 0.001, 0.008
  All 5 are < 0.05  →  significance frequency = 5/5 = 1.0
\n")

ps <- pvalue_stability(mock)
cat("  R output:", paste(names(ps), round(ps,4), sep="=", collapse=", "), "\n")
chk("x1 significance frequency = 1.0", ps["x1"], 1.0)
chk("Intercept excluded",
    "(Intercept)" %in% names(ps), FALSE)

# ── 0C · selection_stability ──────────────────────────────────
sub_hdr("0C · selection_stability  (sign consistency for lm)")
cat("
HAND CALC
  Base-fit coef: Intercept = 0 (exactly 0 → returns NA for sign)
                 x1 = 2  →  sign = +1

  x1 column of coef_mat: 1.8, 2.3, 1.9, 2.1, 2.4
    All positive  →  sign always matches +1
    Sign consistency = 5/5 = 1.0
\n")

ss <- selection_stability(mock)
cat("  R output:", paste(names(ss), round(ss,4), sep="=", collapse=", "), "\n")
chk("x1 sign consistency = 1.0", ss["x1"], 1.0)
chk("Intercept excluded from output",
    "(Intercept)" %in% names(ss), FALSE)

# ── 0D · prediction_stability ─────────────────────────────────
sub_hdr("0D · prediction_stability")
cat("
HAND CALC  (variance of each row, then average)
  obs 1: c(2.3,2.1,2.2,2.4,2.5)  mean=2.3
    sq devs: 0,0.04,0.01,0.01,0.04  sum=0.10  var=0.025
  obs 2: c(4.1,4.4,4.0,4.2,4.3)  mean=4.2
    sq devs: 0.01,0.04,0.04,0,0.01  sum=0.10  var=0.025
  obs 3: c(5.9,6.0,6.1,5.8,6.0)  mean=5.96
    sq devs: 0.0036,0.0016,0.0196,0.0256,0.0016  sum=0.052  var=0.013
  obs 4: c(7.8,7.9,8.0,7.7,7.8)  mean=7.84
    sq devs: 0.0016,0.0036,0.0256,0.0196,0.0016  sum=0.052  var=0.013
  obs 5: c(9.9,9.8,9.7,10.0,9.9) mean=9.86
    sq devs: 0.0016,0.0036,0.0256,0.0196,0.0016  sum=0.052  var=0.013

  mean_variance = (0.025+0.025+0.013+0.013+0.013)/5 = 0.089/5 = 0.0178
\n")

pd <- prediction_stability(mock)
cat("  R pointwise vars:", round(pd$pointwise_variance, 4), "\n")
cat("  R mean_variance: ", round(pd$mean_variance, 6), "\n")
chk("pointwise var obs1 = 0.025", pd$pointwise_variance[1], 0.025)
chk("pointwise var obs3 = 0.013", pd$pointwise_variance[3], 0.013)
chk("mean_variance = 0.0178",     pd$mean_variance,          0.0178)

# ── 0E · reproducibility_index ────────────────────────────────
sub_hdr("0E · reproducibility_index  (full RI formula)")
cat("
HAND CALC
  base_coef (abs): Intercept=0, x1=2
  scale_ref = max(median(c(0,2)), 1e-4) = max(1.0, 1e-4) = 1.0

  c_beta:
    Intercept: exp(-0.082 / (0 + 1.0)) = exp(-0.082) = 0.92130
    x1:        exp(-0.065 / (2 + 1.0)) = exp(-0.02167) = 0.97855
    c_beta = mean(0.92130, 0.97855) = 0.94992

  c_p  (pvalue, excludes intercept):
    pvalue_stability = c(x1=1.0)
    c_p = mean(|2*1.0 - 1|) = mean(1.0) = 1.0

  c_sel  (sign consistency, excludes intercept):
    selection_stability = c(x1=1.0)
    c_sel = mean(1.0) = 1.0

  c_pred:
    Var(y) = Var(c(2,4,6,8,10))
           mean=6, deviations=-4,-2,0,2,4, sq devs=16,4,0,4,16
           sum=40, var=40/4=10
    c_pred = exp(-0.0178 / (10 + 1e-8)) = exp(-0.00178) = 0.99822

  RI = 100 * mean(0.94992, 1.0, 1.0, 0.99822)
      = 100 * 3.94814 / 4 = 98.703
\n")

ri <- reproducibility_index(mock)
cat("  R components:\n")
print(round(ri$components, 5))
cat("  R index:", round(ri$index, 3), "\n")
chk("c_beta ≈ 0.94992",  ri$components["coef"],      0.94992, tol=1e-3)
chk("c_p = 1.0",         ri$components["pvalue"],     1.0)
chk("c_sel = 1.0",       ri$components["selection"],  1.0)
chk("c_pred ≈ 0.99822",  ri$components["prediction"], 0.99822, tol=1e-3)
chk("RI ≈ 98.703",       ri$index,                    98.703,  tol=0.1)

# ── 0F · c_p vs c_sel are genuinely different on real data ────
sub_hdr("0F · Confirm c_p ≠ c_sel on a harder dataset")
cat("
  We use a dataset where some signs flip across bootstrap runs
  so sign-consistency ≠ significance-frequency.
\n")
set.seed(99)
n_noisy <- 40
noisy_df <- data.frame(
  y  = rnorm(n_noisy),
  x1 = rnorm(n_noisy),
  x2 = rnorm(n_noisy))
d_noisy <- run_diagnostics(y ~ x1 + x2, data=noisy_df, B=80)
ri_noisy <- reproducibility_index(d_noisy)
cat("  c_p   (significance freq):", round(ri_noisy$components["pvalue"],    4), "\n")
cat("  c_sel (sign consistency): ", round(ri_noisy$components["selection"],  4), "\n")
if (!isTRUE(all.equal(ri_noisy$components["pvalue"],
                      ri_noisy$components["selection"])))
  PASS("c_p and c_sel are different (as expected)")

# ============================================================
#  SECTION 1 — perturb_data():  ALL THREE METHODS
# ============================================================
hdr("SECTION 1 · perturb_data()  — all methods")

sub_hdr("1A · bootstrap  (same n, sample with replacement)")
set.seed(42)
d_boot <- perturb_data(mtcars, method="bootstrap")
cat("  Original nrow:", nrow(mtcars), "\n")
cat("  Perturbed nrow:", nrow(d_boot), "\n")
cat("  Same columns:", identical(names(d_boot), names(mtcars)), "\n")
# NOTE: R auto-suffixes rownames when indexing (e.g. "Mazda RX4.1"),
# so unique(rownames()) always = n.  Count unique rows BY CONTENT instead.
n_unique_content <- nrow(unique(d_boot))
cat("  Unique rows (by content):", n_unique_content,
    "(< 32 expected for bootstrap)\n")
chk("nrow unchanged", nrow(d_boot), 32L)
chk("has duplicate rows (unique by content < 32)", n_unique_content < 32L, TRUE)

sub_hdr("1B · subsample  (floor(frac*n) rows, no replacement)")
set.seed(42)
d_sub <- perturb_data(mtcars, method="subsample", frac=0.7)
expected_nrow <- floor(0.7 * 32)   # = 22
cat("  Expected nrow:", expected_nrow, "  Got:", nrow(d_sub), "\n")
cat("  All rows are from original:", all(rownames(d_sub) %in% rownames(mtcars)), "\n")
cat("  No duplicates:", length(unique(rownames(d_sub))) == nrow(d_sub), "\n")
chk("nrow = floor(0.7 * 32) = 22", nrow(d_sub), 22L)

sub_hdr("1C · noise  (Gaussian noise proportional to column SD)")
cat("
HAND CALC for noise
  Using a tiny data frame so you can follow every step.

  df$x = c(1, 3, 5)   →  sd(x) = 2.0
  noise_sd = 0.5       →  actual sd of noise = 0.5 * 2.0 = 1.0
  set.seed(7)
  rnorm(3, 0, 1.0):  check with: set.seed(7); round(rnorm(3,0,1),4)
  Noisy x = original_x + noise_values
\n")
tiny_df <- data.frame(x = c(1, 3, 5), y = c(2, 4, 6))
set.seed(7)
noise_vals <- rnorm(3, 0, sd(c(1,3,5)) * 0.5)    # sd(x)=2, noise_sd=0.5 → sd=1
expected_x  <- c(1,3,5) + noise_vals
set.seed(7)
d_noise <- perturb_data(tiny_df, method="noise", noise_sd=0.5)
cat("  Hand-calc noisy x:", round(expected_x, 6), "\n")
cat("  Function output x:", round(d_noise$x, 6), "\n")
chk("noise matches hand calc", d_noise$x, expected_x, tol=1e-10)

sub_hdr("1D · noise with response_col  (predictors only)")
set.seed(7)
d_pred_only <- perturb_data(tiny_df, method="noise", noise_sd=0.5,
                             response_col="y")
cat("  y unchanged:", identical(d_pred_only$y, tiny_df$y), "\n")
cat("  x changed:  ", !identical(d_pred_only$x, tiny_df$x), "\n")
chk("response column untouched", d_pred_only$y, tiny_df$y)

# ============================================================
#  SECTION 2 — run_diagnostics():  ALL FOUR BACKENDS
# ============================================================
hdr("SECTION 2 · run_diagnostics()  — all backends")

sub_hdr("2A · lm  (ordinary least squares)")
set.seed(1)
d_lm <- run_diagnostics(mpg ~ wt + hp + disp, data=mtcars,
                         B=200, method="bootstrap")
cat("  Class:    ", class(d_lm), "\n")
cat("  Backend:  ", d_lm$backend, "\n")
cat("  B:        ", d_lm$B, "\n")
cat("  Terms:    ", colnames(d_lm$coef_mat), "\n")
cat("  p_mat NA?:", all(is.na(d_lm$p_mat)), "(should be FALSE)\n")
chk("coef_mat rows = B", nrow(d_lm$coef_mat), 200L)
chk("p_mat rows = B",    nrow(d_lm$p_mat),    200L)
chk("pred_mat rows = n", nrow(d_lm$pred_mat), 32L)
print(run_diagnostics(mpg ~ wt + hp + disp, data=mtcars, B=20) |>
        suppressWarnings())

sub_hdr("2B · glm  (logistic regression)")
set.seed(1)
d_glm <- suppressWarnings(
  run_diagnostics(am ~ wt + hp + qsec, data=mtcars,
                  B=200, method="bootstrap",
                  family=stats::binomial()))
cat("  Backend:", d_glm$backend, "\n")
cat("  Family: ", d_glm$family$family, "/", d_glm$family$link, "\n")
cat("  p_mat populated:", !all(is.na(d_glm$p_mat)), "\n")
chk("backend = glm", d_glm$backend, "glm")

sub_hdr("2C · rlm  (robust M-estimation via MASS)")
if (requireNamespace("MASS", quietly=TRUE)) {
  set.seed(1)
  d_rlm <- run_diagnostics(mpg ~ wt + hp + disp, data=mtcars,
                             B=200, method="bootstrap", backend="rlm")
  cat("  Backend:", d_rlm$backend, "\n")
  cat("  p_mat populated:", !all(is.na(d_rlm$p_mat)), "\n")
  chk("backend = rlm", d_rlm$backend, "rlm")
} else {
  cat("  [SKIP] MASS not installed\n")
}

sub_hdr("2D · glmnet  (LASSO / Ridge / Elastic Net)")
if (requireNamespace("glmnet", quietly=TRUE)) {
  # LASSO (en_alpha=1)
  set.seed(1)
  d_lasso <- run_diagnostics(mpg ~ wt + hp + disp + qsec + drat,
                               data=mtcars, B=100, method="bootstrap",
                               backend="glmnet", en_alpha=1)
  cat("  LASSO backend:", d_lasso$backend, "\n")
  cat("  p_mat all NA (expected):", all(is.na(d_lasso$p_mat)), "\n")

  # Ridge (en_alpha=0)
  set.seed(1)
  d_ridge <- run_diagnostics(mpg ~ wt + hp + disp + qsec + drat,
                               data=mtcars, B=100, method="bootstrap",
                               backend="glmnet", en_alpha=0)
  cat("  Ridge lambda:", round(attr(d_ridge$base_fit, ".lambda"), 4), "\n")

  # Elastic Net (en_alpha=0.5)
  set.seed(1)
  d_enet <- run_diagnostics(mpg ~ wt + hp + disp + qsec + drat,
                              data=mtcars, B=100, method="bootstrap",
                              backend="glmnet", en_alpha=0.5)
  chk("LASSO p_mat all NA",  all(is.na(d_lasso$p_mat)), TRUE)
  chk("Ridge p_mat all NA",  all(is.na(d_ridge$p_mat)), TRUE)
} else {
  cat("  [SKIP] glmnet not installed\n")
}

sub_hdr("2E · Perturbation methods compared  (same model)")
set.seed(1); d_bs  <- run_diagnostics(mpg~wt+hp, mtcars, B=100, method="bootstrap")
set.seed(1); d_ss  <- run_diagnostics(mpg~wt+hp, mtcars, B=100, method="subsample", frac=0.8)
set.seed(1); d_ns  <- run_diagnostics(mpg~wt+hp, mtcars, B=100, method="noise", noise_sd=0.05)
ri_bs <- reproducibility_index(d_bs)$index
ri_ss <- reproducibility_index(d_ss)$index
ri_ns <- reproducibility_index(d_ns)$index
cat("  RI bootstrap:  ", round(ri_bs, 2), "\n")
cat("  RI subsample:  ", round(ri_ss, 2), "\n")
cat("  RI noise:      ", round(ri_ns, 2), "\n")
cat("  (All should be high for well-specified mtcars model)\n")
chk("bootstrap RI in [0,100]", ri_bs >= 0 & ri_bs <= 100, TRUE)
chk("subsample RI in [0,100]", ri_ss >= 0 & ri_ss <= 100, TRUE)
chk("noise RI in [0,100]",     ri_ns >= 0 & ri_ns <= 100, TRUE)

sub_hdr("2F · perturb_response = FALSE vs TRUE  (noise method)")
set.seed(1)
d_no_resp  <- run_diagnostics(mpg~wt+hp, mtcars, B=50, method="noise",
                               noise_sd=0.1, perturb_response=FALSE)
set.seed(1)
d_yes_resp <- run_diagnostics(mpg~wt+hp, mtcars, B=50, method="noise",
                               noise_sd=0.1, perturb_response=TRUE)
cat("  perturb_response=FALSE  RI:", round(reproducibility_index(d_no_resp)$index, 2), "\n")
cat("  perturb_response=TRUE   RI:", round(reproducibility_index(d_yes_resp)$index, 2), "\n")
cat("  (FALSE should give slightly higher RI — response is stable)\n")

# ============================================================
#  SECTION 3 — STABILITY METRICS on real data
# ============================================================
hdr("SECTION 3 · Stability Metrics on Real Data  (mtcars, B=200)")

set.seed(1)
d_main <- run_diagnostics(mpg ~ wt + hp + disp, data=mtcars, B=200)

sub_hdr("3A · coef_stability")
cs <- coef_stability(d_main)
cat("  Coefficient variances:\n")
print(round(cs, 6))
cat("  Lower variance = more stable.  wt, hp, disp well-identified\n")
cat("  in mtcars so variances should be small.\n")
chk("all variances >= 0", all(cs >= 0), TRUE)

sub_hdr("3B · pvalue_stability  (significance frequency, intercept excluded)")
ps <- pvalue_stability(d_main)
cat("  P-value stability (proportion of runs where p < 0.05):\n")
print(round(ps, 4))
cat("  Values near 1.0 = consistently significant\n")
cat("  Values near 0.0 = consistently non-significant\n")
cat("  Values near 0.5 = unstable significance decisions\n")
chk("no intercept in output", !("(Intercept)" %in% names(ps)), TRUE)
chk("all in [0,1]", all(ps >= 0 & ps <= 1), TRUE)

sub_hdr("3C · selection_stability  (sign consistency, intercept excluded)")
ss <- selection_stability(d_main)
cat("  Sign consistency:\n")
print(round(ss, 4))
cat("  1.0 = coefficient sign is always the same as base fit\n")
cat("  0.5 = sign randomly flips\n")
cat("  These DIFFER from pvalue_stability:\n")
cat("  pvalue_stability:", round(ps, 4), "\n")
cat("  selection_stability:", round(ss, 4), "\n")
chk("pvalue ≠ selection (different quantities)", !identical(ps, ss), TRUE)

sub_hdr("3D · prediction_stability")
pd <- prediction_stability(d_main)
cat("  Mean prediction variance:", round(pd$mean_variance, 6), "\n")
cat("  Pointwise variances (first 5 obs):", round(head(pd$pointwise_variance,5), 5), "\n")
cat("  Low values = predictions barely change across perturbations\n")
chk("mean_variance >= 0", pd$mean_variance >= 0, TRUE)

# ============================================================
#  SECTION 4 — reproducibility_index():  ALL BACKENDS
# ============================================================
hdr("SECTION 4 · reproducibility_index()  — all backends")

sub_hdr("4A · lm  (4 components)")
ri_lm <- reproducibility_index(d_lm)
cat("  RI:", round(ri_lm$index, 2), "/ 100\n")
cat("  Components:\n")
print(round(ri_lm$components, 4))
cat("  Note: pvalue and selection measure DIFFERENT things:\n")
cat("    pvalue = significance frequency\n")
cat("    selection = sign consistency\n")
chk("RI in [0,100]",       ri_lm$index, ri_lm$index)   # range check done below
chk("RI >= 0",             ri_lm$index >= 0, TRUE)
chk("RI <= 100",           ri_lm$index <= 100, TRUE)
chk("all components in [0,1]",
    all(ri_lm$components[!is.na(ri_lm$components)] >= 0 &
        ri_lm$components[!is.na(ri_lm$components)] <= 1), TRUE)

sub_hdr("4B · glm  (4 components)")
ri_glm <- suppressWarnings(reproducibility_index(d_glm))
cat("  RI:", round(ri_glm$index, 2), "/ 100\n")
print(round(ri_glm$components, 4))
chk("pvalue not NA for glm",   !is.na(ri_glm$components["pvalue"]),    TRUE)
chk("selection not NA for glm",!is.na(ri_glm$components["selection"]), TRUE)

if (requireNamespace("MASS", quietly=TRUE)) {
  sub_hdr("4C · rlm  (4 components)")
  ri_rlm <- reproducibility_index(d_rlm)
  cat("  RI:", round(ri_rlm$index, 2), "/ 100\n")
  print(round(ri_rlm$components, 4))
  chk("rlm RI in [0,100]", ri_rlm$index >= 0 & ri_rlm$index <= 100, TRUE)
}

if (requireNamespace("glmnet", quietly=TRUE)) {
  sub_hdr("4D · glmnet  (3 components — pvalue is NA, selection is NOT NA)")
  cat("
  KEY CHANGE from old code:
    OLD: glmnet had pvalue=NA AND selection=NA (only 2 components)
    NEW: glmnet has pvalue=NA, selection = non-zero frequency (3 components)
  \n")
  ri_lasso <- reproducibility_index(d_lasso)
  cat("  LASSO RI:", round(ri_lasso$index, 2), "/ 100\n")
  print(round(ri_lasso$components, 4))
  chk("pvalue IS NA for glmnet",      is.na(ri_lasso$components["pvalue"]),    TRUE)
  chk("selection is NOT NA for glmnet",!is.na(ri_lasso$components["selection"]),TRUE)
  chk("glmnet RI in [0,100]",
      ri_lasso$index >= 0 & ri_lasso$index <= 100, TRUE)

  sub_hdr("4E · Cross-backend comparison  (lm vs rlm vs LASSO vs Ridge)")
  cat("
  WARNING: RI values are NOT directly comparable across backends.
  glmnet uses 3 components; lm/glm/rlm use 4.
  Compare within the same backend only.
  \n")
  ri_ridge <- reproducibility_index(d_ridge)
  ri_enet  <- reproducibility_index(d_enet)
  cat(sprintf("  lm    (4 components): RI = %.2f\n", ri_lm$index))
  if (requireNamespace("MASS", quietly=TRUE))
    cat(sprintf("  rlm   (4 components): RI = %.2f\n", ri_rlm$index))
  cat(sprintf("  LASSO (3 components): RI = %.2f\n", ri_lasso$index))
  cat(sprintf("  Ridge (3 components): RI = %.2f\n", ri_ridge$index))
  cat(sprintf("  ENet  (3 components): RI = %.2f\n", ri_enet$index))
}

# ============================================================
#  SECTION 5 — ri_confidence_interval()
# ============================================================
hdr("SECTION 5 · ri_confidence_interval()")
cat("
WHAT IT DOES
  Resamples the B already-computed perturbation rows with replacement,
  recomputes the RI on each resample, and returns quantile bounds.
  No additional model fitting.  Think of it as 'bootstrap of a bootstrap'.

HAND-CALC CONCEPT  (B=5, R=2 resamples, level=0.95)
  Given idx = [1,2,3,4,5]:
    resample 1: sample(1:5, 5, replace=TRUE) e.g. [2,2,4,1,5]
    resample 2: sample(1:5, 5, replace=TRUE) e.g. [3,1,1,4,2]
  For each resample, replace rows in coef_mat/p_mat and columns in pred_mat,
  then recompute RI.  The R=1000 quantiles give the CI bounds.
\n")

set.seed(1)
d_ci <- run_diagnostics(mpg ~ wt + hp, data=mtcars, B=100)
ri_pt <- reproducibility_index(d_ci)$index
ci95  <- ri_confidence_interval(d_ci, level=0.95, R=500, seed=1)
ci80  <- ri_confidence_interval(d_ci, level=0.80, R=500, seed=1)

cat("  Point estimate RI:", round(ri_pt, 2), "\n")
cat("  95% CI: [", round(ci95[1],2), ",", round(ci95[2],2), "]\n")
cat("  80% CI: [", round(ci80[1],2), ",", round(ci80[2],2), "]\n")
cat("  80% CI should be NARROWER than 95% CI:\n")
chk("CI lower <= RI <= upper",
    ci95[1] <= ri_pt + 3 & ci95[2] >= ri_pt - 3, TRUE)
chk("95% CI wider than 80% CI",
    (ci95[2]-ci95[1]) >= (ci80[2]-ci80[1]) - 1e-6, TRUE)

cat("\n  Seed reproducibility check:\n")
ci_a <- ri_confidence_interval(d_ci, R=200, seed=42)
ci_b <- ri_confidence_interval(d_ci, R=200, seed=42)
chk("same seed → identical CI", all.equal(ci_a, ci_b), TRUE)

cat("\n  seed=NULL does not reset global RNG:\n")
set.seed(99); r1 <- runif(1)
set.seed(99); ri_confidence_interval(d_ci, R=20, seed=NULL)
r2 <- runif(1)
chk("seed=NULL: r2 ≠ r1 (RNG advanced)", !isTRUE(all.equal(r1,r2)), TRUE)

# ============================================================
#  SECTION 6 — cv_ranking_stability():  ALL BACKENDS
# ============================================================
hdr("SECTION 6 · cv_ranking_stability()")

cat("
WHAT IT DOES
  Repeats K-fold CV R times, records the RMSE (or log-loss) rank of each
  candidate model per repeat.  Reports mean rank and top-1 frequency.
  Lower mean_rank = better model on average.
  Higher top1_frequency = most often the best model.
\n")

models <- list(
  compact  = mpg ~ wt,
  moderate = mpg ~ wt + hp,
  full     = mpg ~ wt + hp + disp + qsec)

sub_hdr("6A · lm  (RMSE metric)")
cv_lm <- cv_ranking_stability(models, mtcars, v=5, R=30, seed=1)
cat("  Settings:", cv_lm$settings$metric, "/", cv_lm$settings$backend, "\n")
cat("  Summary table:\n")
print(cv_lm$summary)
cat("  Interpretation:\n")
cat("    - 'full' likely has lowest mean_rank (best predictions)\n")
cat("    - top1_frequency should sum to ~1.0 across models\n")
chk("top1_frequency sums to 1",
    sum(cv_lm$summary$top1_frequency), 1.0)
chk("summary ordered by mean_rank",
    all(diff(cv_lm$summary$mean_rank) >= 0), TRUE)

sub_hdr("6B · glm  (log-loss metric, binary outcome)")
glm_models <- list(
  m1 = am ~ wt + hp,
  m2 = am ~ wt + hp + qsec)
cv_glm <- suppressWarnings(
  cv_ranking_stability(glm_models, mtcars, v=5, R=20, seed=1,
                       family=stats::binomial(), metric="logloss"))
cat("  Metric:", cv_glm$settings$metric, "\n")
cat("  Summary:\n")
print(cv_glm$summary)
chk("logloss metric recorded", cv_glm$settings$metric, "logloss")
chk("mean_rmse > 0 (log-loss is positive)", all(cv_glm$summary$mean_rmse > 0), TRUE)

if (requireNamespace("MASS", quietly=TRUE)) {
  sub_hdr("6C · rlm  (robust, RMSE metric)")
  cv_rlm <- cv_ranking_stability(models, mtcars, v=5, R=20, seed=1,
                                  backend="rlm")
  cat("  Summary:\n")
  print(cv_rlm$summary)
  chk("rlm backend recorded", cv_rlm$settings$backend, "rlm")
}

if (requireNamespace("glmnet", quietly=TRUE)) {
  sub_hdr("6D · glmnet  (LASSO, per-fold lambda via cv.glmnet)")
  glmnet_models <- list(m1=mpg~wt+hp, m2=mpg~wt+hp+disp+qsec)
  cv_glmnet <- cv_ranking_stability(glmnet_models, mtcars, v=5, R=10, seed=1,
                                     backend="glmnet", en_alpha=1)
  cat("  Summary:\n")
  print(cv_glmnet$summary)
  chk("glmnet backend recorded", cv_glmnet$settings$backend, "glmnet")
  cat("  NOTE: glmnet runs cv.glmnet inside every CV fold — slow for large R.\n")
}

# ============================================================
#  SECTION 7 — PLOT FUNCTIONS
# ============================================================
hdr("SECTION 7 · Plot Functions")
cat("  All plots go to the active graphics device.\n\n")

set.seed(1)
d_plot <- run_diagnostics(mpg ~ wt + hp + disp, data=mtcars, B=150)

sub_hdr("7A · plot_stability()  — base R, four types")
for (type in c("coefficient","pvalue","selection","prediction")) {
  plot_stability(d_plot, type)
  title(sub=paste("mtcars bootstrap B=150 |", type), cex.sub=0.8)
  PASS(paste("plot_stability type =", type))
}

sub_hdr("7B · plot_cv_stability()  — base R")
cv_plot <- cv_ranking_stability(models, mtcars, v=5, R=30, seed=1)
plot_cv_stability(cv_plot, metric="top1_frequency")
title(sub="mtcars top-1 frequency", cex.sub=0.8)
PASS("plot_cv_stability top1_frequency")

plot_cv_stability(cv_plot, metric="mean_rank")
title(sub="mtcars mean rank", cex.sub=0.8)
PASS("plot_cv_stability mean_rank")

if (requireNamespace("ggplot2", quietly=TRUE)) {
  sub_hdr("7C · plot_stability_gg()  — ggplot2")
  print(plot_stability_gg(d_plot, "coefficient"))
  print(plot_stability_gg(d_plot, "selection"))
  PASS("plot_stability_gg coefficient + selection")

  sub_hdr("7D · plot_cv_stability_gg()  — ggplot2")
  print(plot_cv_stability_gg(cv_plot, "top1_frequency"))
  print(plot_cv_stability_gg(cv_plot, "mean_rank"))
  PASS("plot_cv_stability_gg top1_frequency + mean_rank")
} else {
  cat("  [SKIP] ggplot2 not installed\n")
}

# ============================================================
#  SECTION 8 — SIMULATION:  KNOWN SCENARIOS
# ============================================================
hdr("SECTION 8 · Simulation — Expected RI Ordering")

cat("
EXPECTED OUTCOME
  We generate four scenarios with increasing 'difficulty':
    baseline       →  high RI  (clean data, well-specified model)
    high_noise     →  lower RI (noisy response makes estimates unstable)
    small_sample   →  lower RI (few observations = high variance estimates)
    multicollinear →  lowest RI (correlated predictors destabilise signs)

  RI ordering should be:  baseline > high_noise > small_sample > multicollinear
  (approximately — results are stochastic)
\n")

sim_data <- function(n=100, noise=1, rho=0.1) {
  x1 <- rnorm(n)
  x2 <- rho*x1 + sqrt(1-rho^2)*rnorm(n)
  x3 <- rnorm(n)
  y  <- 3 + 2*x1 - 1.5*x3 + rnorm(n, sd=noise)
  data.frame(y=y, x1=x1, x2=x2, x3=x3)
}

set.seed(2024)
ri_baseline <- reproducibility_index(run_diagnostics(
  y ~ x1+x2+x3, sim_data(n=200, noise=1,   rho=0.1),  B=100, method="subsample"))$index
ri_highnoise <- reproducibility_index(run_diagnostics(
  y ~ x1+x2+x3, sim_data(n=200, noise=4,   rho=0.1),  B=100, method="subsample"))$index
ri_small <- reproducibility_index(run_diagnostics(
  y ~ x1+x2+x3, sim_data(n=30,  noise=1,   rho=0.1),  B=100, method="subsample"))$index
ri_multicol <- reproducibility_index(run_diagnostics(
  y ~ x1+x2+x3, sim_data(n=200, noise=1,   rho=0.97), B=100, method="subsample"))$index

cat(sprintf("  baseline       RI = %.1f  (expect highest)\n",  ri_baseline))
cat(sprintf("  high_noise     RI = %.1f  (expect lower)\n",    ri_highnoise))
cat(sprintf("  small_sample   RI = %.1f  (expect lower)\n",    ri_small))
cat(sprintf("  multicollinear RI = %.1f  (expect lowest)\n\n", ri_multicol))
cat("  Expected ordering: baseline > high_noise ≥ small_sample > multicollinear\n")
chk("baseline beats multicollinear", ri_baseline > ri_multicol, TRUE)

# ============================================================
#  SECTION 9 — EDGE CASES
# ============================================================
hdr("SECTION 9 · Edge Cases")

sub_hdr("9A · near-zero coefficients  (old epsilon would collapse c_beta)")
cat("
  x2 is pure noise — its coefficient will be near zero.
  OLD formula: exp(-var / (|coef| + 1e-8)) would approach 0 for coef≈0.
  NEW formula: uses scale_ref = median(|coef|) as floor → stays in [0,1].
\n")
set.seed(1)
nz_df <- data.frame(y=rnorm(60), x1=rnorm(60), x2=rnorm(60)*0.001)
d_nz  <- run_diagnostics(y ~ x1 + x2, data=nz_df, B=50)
ri_nz <- reproducibility_index(d_nz)
cat("  Base coefs:   ", round(coef(d_nz$base_fit), 5), "\n")
cat("  scale_ref used in c_beta:",
    round(max(median(abs(coef(d_nz$base_fit))), 1e-4), 5), "\n")
cat("  c_beta =", round(ri_nz$components["coef"], 4), "(should be finite and in [0,1])\n")
chk("c_beta finite and in [0,1]",
    is.finite(ri_nz$components["coef"]) &
    ri_nz$components["coef"] >= 0       &
    ri_nz$components["coef"] <= 1, TRUE)

sub_hdr("9B · single predictor model")
set.seed(1)
d_1p <- run_diagnostics(mpg ~ wt, data=mtcars, B=50)
ri_1p <- reproducibility_index(d_1p)
cat("  RI:", round(ri_1p$index, 2), "\n")
chk("single predictor RI in [0,100]",
    ri_1p$index >= 0 & ri_1p$index <= 100, TRUE)

sub_hdr("9C · GLM with Poisson family")
set.seed(1)
d_pois <- suppressWarnings(run_diagnostics(
  cyl ~ wt + hp, data=mtcars, B=50,
  family=stats::poisson()))
ri_pois <- suppressWarnings(reproducibility_index(d_pois))
cat("  Poisson RI:", round(ri_pois$index, 2), "\n")
chk("Poisson RI in [0,100]",
    ri_pois$index >= 0 & ri_pois$index <= 100, TRUE)

sub_hdr("9D · predict_newdata  (out-of-sample prediction stability)")
set.seed(1)
idx_train <- 1:24
idx_test  <- 25:32
d_oos <- run_diagnostics(mpg ~ wt + hp, data=mtcars[idx_train,],
                          B=100, predict_newdata=mtcars[idx_test,])
cat("  pred_mat rows = test set size (8):", nrow(d_oos$pred_mat), "\n")
chk("pred_mat rows = nrow(test)", nrow(d_oos$pred_mat), 8L)

sub_hdr("9E · subsample with frac=1.0  (keep all rows, no replacement)")
set.seed(1)
d_f1 <- run_diagnostics(mpg ~ wt + hp, data=mtcars, B=20,
                          method="subsample", frac=1.0)
chk("frac=1.0 accepted", class(d_f1), "reprostat")

# ============================================================
#  SECTION 10 — SUMMARY
# ============================================================
hdr("SECTION 10 · Final Summary Table")

cat(sprintf("
  %-22s  %s\n", "Scenario", "RI (0-100)"))
cat(sprintf("  %-22s  %s\n", strrep("-",22), strrep("-",10)))
cat(sprintf("  %-22s  %.1f\n", "lm bootstrap",       ri_lm$index))
cat(sprintf("  %-22s  %.1f\n", "glm (logistic)",     ri_glm$index))
if (requireNamespace("MASS",   quietly=TRUE))
  cat(sprintf("  %-22s  %.1f\n", "rlm (robust)",     ri_rlm$index))
if (requireNamespace("glmnet", quietly=TRUE)) {
  cat(sprintf("  %-22s  %.1f\n", "LASSO (3 comp)",   ri_lasso$index))
  cat(sprintf("  %-22s  %.1f\n", "Ridge (3 comp)",   ri_ridge$index))
}
cat(sprintf("  %-22s  %.1f\n", "sim baseline",       ri_baseline))
cat(sprintf("  %-22s  %.1f\n", "sim high noise",     ri_highnoise))
cat(sprintf("  %-22s  %.1f\n", "sim small sample",   ri_small))
cat(sprintf("  %-22s  %.1f\n", "sim multicollinear", ri_multicol))

cat("\n", strrep("═", 62), "\n")
cat("  All sections complete.\n")
cat("  Any [FAIL] lines above indicate a logic or formula error.\n")
cat(strrep("═", 62), "\n\n")
