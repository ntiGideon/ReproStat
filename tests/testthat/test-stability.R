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

test_that("pvalue_stability returns values in [0, 1]", {
  set.seed(1)
  d  <- run_diagnostics(mpg ~ wt + hp, data = mtcars, B = 20)
  ps <- pvalue_stability(d)
  expect_true(all(ps >= 0 & ps <= 1, na.rm = TRUE))
})

test_that("pvalue_stability returns all NA for glmnet backend", {
  skip_if_not_installed("glmnet")
  set.seed(1)
  d  <- run_diagnostics(mpg ~ wt + hp + disp, data = mtcars, B = 10,
                         backend = "glmnet", lambda = 0.1)
  ps <- pvalue_stability(d)
  expect_true(all(is.na(ps)))
})

test_that("selection_stability excludes intercept", {
  set.seed(1)
  d  <- run_diagnostics(mpg ~ wt + hp, data = mtcars, B = 20)
  ss <- selection_stability(d)
  expect_false("(Intercept)" %in% names(ss))
  expect_true(all(ss >= 0 & ss <= 1, na.rm = TRUE))
})

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

test_that("reproducibility_index glmnet returns NA p-value and selection components", {
  skip_if_not_installed("glmnet")
  set.seed(1)
  d  <- run_diagnostics(mpg ~ wt + hp + disp, data = mtcars, B = 10,
                         backend = "glmnet", lambda = 0.1)
  ri <- reproducibility_index(d)
  expect_true(is.na(ri$components["pvalue"]))
  expect_true(is.na(ri$components["selection"]))
  expect_false(is.na(ri$components["coef"]))
  expect_false(is.na(ri$components["prediction"]))
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

test_that("ri_confidence_interval returns two-element vector in [0, 100]", {
  set.seed(1)
  d  <- run_diagnostics(mpg ~ wt + hp, data = mtcars, B = 20)
  ci <- ri_confidence_interval(d, R = 50)
  expect_length(ci, 2L)
  expect_true(ci[1] <= ci[2])
  expect_gte(ci[1], 0)
  expect_lte(ci[2], 100)
})

test_that("ri_confidence_interval respects level argument", {
  set.seed(1)
  d    <- run_diagnostics(mpg ~ wt + hp, data = mtcars, B = 20)
  ci90 <- ri_confidence_interval(d, level = 0.90, R = 50)
  ci99 <- ri_confidence_interval(d, level = 0.99, R = 50)
  expect_gte(ci99[2] - ci99[1], ci90[2] - ci90[1] - 1e-6)
})

test_that("ri_confidence_interval lower <= RI <= upper (approximately)", {
  set.seed(1)
  d  <- run_diagnostics(mpg ~ wt + hp, data = mtcars, B = 30)
  ri <- reproducibility_index(d)$index
  ci <- ri_confidence_interval(d, R = 200)
  expect_lte(ci[1], ri + 5)  # allow small MC noise
  expect_gte(ci[2], ri - 5)
})

test_that("plot_stability runs without error for all types", {
  set.seed(1)
  d <- run_diagnostics(mpg ~ wt + hp, data = mtcars, B = 20)
  expect_silent(plot_stability(d, "coefficient"))
  expect_silent(plot_stability(d, "pvalue"))
  expect_silent(plot_stability(d, "selection"))
  expect_silent(plot_stability(d, "prediction"))
})
