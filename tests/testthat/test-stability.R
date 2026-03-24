## ── run_diagnostics ──────────────────────────────────────────────────────────

test_that("run_diagnostics returns a reprostat object", {
  set.seed(1)
  d <- run_diagnostics(mpg ~ wt + hp, data = mtcars, B = 10)
  expect_s3_class(d, "reprostat")
  expect_equal(nrow(d$coef_mat), 10L)
  expect_equal(colnames(d$coef_mat), c("(Intercept)", "wt", "hp"))
})

test_that("run_diagnostics stores y_train", {
  set.seed(1)
  d <- run_diagnostics(mpg ~ wt + hp, data = mtcars, B = 10)
  expect_equal(unname(d$y_train), mtcars$mpg)
})

test_that("run_diagnostics stores formula and call", {
  set.seed(1)
  d <- run_diagnostics(mpg ~ wt + hp, data = mtcars, B = 10)
  expect_true(inherits(d$formula, "formula"))
  expect_type(d$call, "language")
})

test_that("print.reprostat runs without error", {
  set.seed(1)
  d <- run_diagnostics(mpg ~ wt + hp, data = mtcars, B = 10)
  expect_output(print(d), "ReproStat Diagnostics")
})

test_that("run_diagnostics invalid B errors", {
  expect_error(run_diagnostics(mpg ~ wt + hp, mtcars, B = 1))
  expect_error(run_diagnostics(mpg ~ wt + hp, mtcars, B = 0))
  expect_error(run_diagnostics(mpg ~ wt + hp, mtcars, B = -5))
})

test_that("run_diagnostics invalid alpha errors", {
  expect_error(run_diagnostics(mpg ~ wt + hp, mtcars, B = 10, alpha = 0))
  expect_error(run_diagnostics(mpg ~ wt + hp, mtcars, B = 10, alpha = 1))
})

test_that("run_diagnostics non-data-frame errors", {
  expect_error(run_diagnostics(mpg ~ wt + hp, as.matrix(mtcars), B = 10))
})

test_that("perturb_response = FALSE leaves response unchanged under noise", {
  set.seed(1)
  d <- run_diagnostics(mpg ~ wt + hp, data = mtcars, B = 10,
                       method = "noise", noise_sd = 0.5,
                       perturb_response = FALSE)
  expect_s3_class(d, "reprostat")
  # y_train must be the original unperturbed response
  expect_equal(unname(d$y_train), mtcars$mpg)
})

test_that("perturb_response = TRUE is accepted without error", {
  set.seed(1)
  d <- run_diagnostics(mpg ~ wt + hp, data = mtcars, B = 10,
                       method = "noise", noise_sd = 0.05,
                       perturb_response = TRUE)
  expect_s3_class(d, "reprostat")
})

## ── coef_stability ───────────────────────────────────────────────────────────

test_that("coef_stability returns non-negative variances", {
  set.seed(1)
  d  <- run_diagnostics(mpg ~ wt + hp, data = mtcars, B = 20)
  cs <- coef_stability(d)
  expect_named(cs)
  expect_true(all(cs >= 0, na.rm = TRUE))
})

test_that("coef_stability names match formula terms", {
  set.seed(1)
  d  <- run_diagnostics(mpg ~ wt + hp, data = mtcars, B = 20)
  cs <- coef_stability(d)
  expect_equal(names(cs), c("(Intercept)", "wt", "hp"))
})

## ── pvalue_stability ─────────────────────────────────────────────────────────

test_that("pvalue_stability returns values in [0, 1]", {
  set.seed(1)
  d  <- run_diagnostics(mpg ~ wt + hp, data = mtcars, B = 20)
  ps <- pvalue_stability(d)
  expect_true(all(ps >= 0 & ps <= 1, na.rm = TRUE))
})

test_that("pvalue_stability excludes the intercept", {
  set.seed(1)
  d  <- run_diagnostics(mpg ~ wt + hp, data = mtcars, B = 20)
  ps <- pvalue_stability(d)
  expect_false("(Intercept)" %in% names(ps))
  expect_equal(names(ps), c("wt", "hp"))
})

test_that("pvalue_stability returns all NA/NaN for glmnet backend", {
  skip_if_not_installed("glmnet")
  set.seed(1)
  d  <- run_diagnostics(mpg ~ wt + hp + disp, data = mtcars, B = 10,
                        backend = "glmnet", lambda = 0.1)
  ps <- pvalue_stability(d)
  expect_true(all(is.na(ps)))
})

## ── selection_stability ──────────────────────────────────────────────────────

test_that("selection_stability excludes intercept and values in [0, 1]", {
  set.seed(1)
  d  <- run_diagnostics(mpg ~ wt + hp, data = mtcars, B = 20)
  ss <- selection_stability(d)
  expect_false("(Intercept)" %in% names(ss))
  expect_true(all(ss >= 0 & ss <= 1, na.rm = TRUE))
})

test_that("selection_stability for lm returns sign-consistency values", {
  set.seed(1)
  d  <- run_diagnostics(mpg ~ wt + hp, data = mtcars, B = 50)
  ss <- selection_stability(d)
  # wt and hp have well-identified effects in mtcars;
  # sign should be consistent most of the time
  expect_gte(ss["wt"], 0.5)
  expect_gte(ss["hp"], 0.5)
})

test_that("selection_stability and pvalue_stability measure different things", {
  set.seed(1)
  d  <- run_diagnostics(mpg ~ wt + hp, data = mtcars, B = 50)
  ps <- pvalue_stability(d)    # significance frequency
  ss <- selection_stability(d) # sign consistency
  expect_equal(names(ps), names(ss))
  # They compute different quantities so values should differ
  expect_false(identical(as.numeric(ps), as.numeric(ss)))
})

test_that("selection_stability for glmnet returns non-zero frequency", {
  skip_if_not_installed("glmnet")
  set.seed(1)
  d  <- run_diagnostics(mpg ~ wt + hp + disp, data = mtcars, B = 20,
                        backend = "glmnet", lambda = 0.1)
  ss <- selection_stability(d)
  expect_false("(Intercept)" %in% names(ss))
  expect_true(all(ss >= 0 & ss <= 1, na.rm = TRUE))
  # Values are non-zero frequencies, not all NA
  expect_false(all(is.na(ss)))
})

## ── prediction_stability ─────────────────────────────────────────────────────

test_that("prediction_stability returns list with non-negative mean_variance", {
  set.seed(1)
  d  <- run_diagnostics(mpg ~ wt + hp, data = mtcars, B = 20)
  ps <- prediction_stability(d)
  expect_type(ps, "list")
  expect_named(ps, c("pointwise_variance", "mean_variance"))
  expect_gte(ps$mean_variance, 0)
})

test_that("prediction_stability pointwise length equals nrow(data)", {
  set.seed(1)
  d  <- run_diagnostics(mpg ~ wt + hp, data = mtcars, B = 20)
  ps <- prediction_stability(d)
  expect_equal(length(ps$pointwise_variance), nrow(mtcars))
})

## ── reproducibility_index ────────────────────────────────────────────────────

test_that("reproducibility_index is in [0, 100]", {
  set.seed(1)
  d  <- run_diagnostics(mpg ~ wt + hp, data = mtcars, B = 20)
  ri <- reproducibility_index(d)
  expect_gte(ri$index, 0)
  expect_lte(ri$index, 100)
  expect_named(ri$components, c("coef", "pvalue", "selection", "prediction"))
})

test_that("reproducibility_index components are in [0, 1]", {
  set.seed(1)
  d  <- run_diagnostics(mpg ~ wt + hp, data = mtcars, B = 20)
  ri <- reproducibility_index(d)
  comps <- ri$components[!is.na(ri$components)]
  expect_true(all(comps >= 0 & comps <= 1))
})

test_that("c_p and c_sel are genuinely distinct components", {
  set.seed(1)
  d  <- run_diagnostics(mpg ~ wt + hp, data = mtcars, B = 50)
  ri <- reproducibility_index(d)
  # pvalue component uses abs(2*sig_freq - 1); selection uses sign consistency.
  # They measure different things and must not be identical.
  expect_false(isTRUE(all.equal(
    unname(ri$components["pvalue"]),
    unname(ri$components["selection"])
  )))
})

test_that("reproducibility_index glmnet: pvalue NA, selection NOT NA", {
  skip_if_not_installed("glmnet")
  set.seed(1)
  d  <- run_diagnostics(mpg ~ wt + hp + disp, data = mtcars, B = 20,
                        backend = "glmnet", lambda = 0.1)
  ri <- reproducibility_index(d)
  # pvalue is NA (no p-values for penalized regression)
  expect_true(is.na(ri$components["pvalue"]))
  # selection (non-zero frequency) is now always available
  expect_false(is.na(ri$components["selection"]))
  expect_false(is.na(ri$components["coef"]))
  expect_false(is.na(ri$components["prediction"]))
  # RI based on 3 components: still in [0, 100]
  expect_gte(ri$index, 0)
  expect_lte(ri$index, 100)
})

test_that("c_beta handles near-zero base coefficients without collapse", {
  # Pure-noise predictor: base coefficient near zero after regression.
  # With the old eps = 1e-8, exp(-var / (0 + 1e-8)) -> 0 catastrophically.
  # With scale_ref = median(|coef|), c_beta stays in [0, 1] and is finite.
  set.seed(42)
  n  <- 50
  df <- data.frame(y = rnorm(n), x1 = rnorm(n))
  d  <- run_diagnostics(y ~ x1, data = df, B = 30)
  ri <- reproducibility_index(d)
  expect_gte(ri$components["coef"], 0)
  expect_lte(ri$components["coef"], 1)
  expect_true(is.finite(ri$components["coef"]))
})

test_that("subsample method works", {
  set.seed(1)
  d <- run_diagnostics(mpg ~ wt + hp, data = mtcars, B = 10,
                       method = "subsample", frac = 0.7)
  expect_s3_class(d, "reprostat")
})

test_that("noise method works", {
  set.seed(1)
  d <- run_diagnostics(mpg ~ wt + hp, data = mtcars, B = 10,
                       method = "noise", noise_sd = 0.05)
  expect_s3_class(d, "reprostat")
})

test_that("glm backend works and p_mat is populated", {
  set.seed(1)
  d <- suppressWarnings(
    run_diagnostics(am ~ wt + hp, data = mtcars, B = 10,
                    family = stats::binomial())
  )
  expect_s3_class(d, "reprostat")
  expect_equal(d$backend, "glm")
  expect_false(all(is.na(d$p_mat)))
})

test_that("rlm backend works if MASS available", {
  skip_if_not_installed("MASS")
  set.seed(1)
  d <- run_diagnostics(mpg ~ wt + hp, data = mtcars, B = 10,
                       backend = "rlm")
  expect_s3_class(d, "reprostat")
  expect_equal(d$backend, "rlm")
  ri <- reproducibility_index(d)
  expect_gte(ri$index, 0)
  expect_lte(ri$index, 100)
})

test_that("glmnet backend works if glmnet available", {
  skip_if_not_installed("glmnet")
  set.seed(1)
  d <- run_diagnostics(mpg ~ wt + hp + disp, data = mtcars, B = 10,
                       backend = "glmnet", lambda = 0.1)
  expect_s3_class(d, "reprostat")
  expect_equal(d$backend, "glmnet")
  expect_true(all(is.na(d$p_mat)))
})

## ── ri_confidence_interval ───────────────────────────────────────────────────

test_that("ri_confidence_interval returns two-element vector in [0, 100]", {
  set.seed(1)
  d  <- run_diagnostics(mpg ~ wt + hp, data = mtcars, B = 20)
  ci <- ri_confidence_interval(d, R = 50, seed = 1)
  expect_length(ci, 2L)
  expect_true(ci[1] <= ci[2])
  expect_gte(ci[1], 0)
  expect_lte(ci[2], 100)
})

test_that("ri_confidence_interval respects level argument", {
  set.seed(1)
  d    <- run_diagnostics(mpg ~ wt + hp, data = mtcars, B = 30)
  ci90 <- ri_confidence_interval(d, level = 0.90, R = 500, seed = 1)
  ci99 <- ri_confidence_interval(d, level = 0.99, R = 500, seed = 1)
  expect_gte(ci99[2] - ci99[1], ci90[2] - ci90[1] - 1e-6)
})

test_that("ri_confidence_interval lower <= RI <= upper (approximately)", {
  set.seed(1)
  d  <- run_diagnostics(mpg ~ wt + hp, data = mtcars, B = 30)
  ri <- reproducibility_index(d)$index
  ci <- ri_confidence_interval(d, R = 200, seed = 1)
  expect_lte(ci[1], ri + 5)
  expect_gte(ci[2], ri - 5)
})

test_that("ri_confidence_interval seed = NULL works without error", {
  set.seed(1)
  d  <- run_diagnostics(mpg ~ wt + hp, data = mtcars, B = 20)
  ci <- ri_confidence_interval(d, R = 50, seed = NULL)
  expect_length(ci, 2L)
  expect_lte(ci[1], ci[2])
})

test_that("ri_confidence_interval explicit seed gives reproducible results", {
  set.seed(1)
  d   <- run_diagnostics(mpg ~ wt + hp, data = mtcars, B = 20)
  ci1 <- ri_confidence_interval(d, R = 100, seed = 42)
  ci2 <- ri_confidence_interval(d, R = 100, seed = 42)
  expect_equal(ci1, ci2)
})

test_that("ri_confidence_interval seed = NULL does not override global RNG", {
  set.seed(99)
  r1 <- runif(1)
  set.seed(99)
  d  <- run_diagnostics(mpg ~ wt + hp, data = mtcars, B = 10)
  # Call with seed = NULL — must NOT reset the RNG to a fixed state
  ri_confidence_interval(d, R = 10, seed = NULL)
  # After the call the next value should NOT equal r1
  # (because internal sampling advanced the RNG)
  r2 <- runif(1)
  expect_false(isTRUE(all.equal(r1, r2)))
})

## ── plot_stability ───────────────────────────────────────────────────────────

test_that("plot_stability runs without error for all types", {
  set.seed(1)
  d <- run_diagnostics(mpg ~ wt + hp, data = mtcars, B = 20)
  expect_silent(plot_stability(d, "coefficient"))
  expect_silent(plot_stability(d, "pvalue"))
  expect_silent(plot_stability(d, "selection"))
  expect_silent(plot_stability(d, "prediction"))
})
