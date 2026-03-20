test_that("cv_ranking_stability returns expected structure", {
  models <- list(
    m1 = mpg ~ wt + hp,
    m2 = mpg ~ wt + hp + disp
  )
  cv <- cv_ranking_stability(models, mtcars, v = 5, R = 10, seed = 1)

  expect_type(cv, "list")
  expect_named(cv, c("settings", "rmse_mat", "rank_mat", "summary"))
  expect_equal(nrow(cv$rmse_mat), 10L)
  expect_equal(ncol(cv$rmse_mat), 2L)
  expect_equal(nrow(cv$summary), 2L)
  expect_named(cv$summary,
               c("model", "mean_rmse", "sd_rmse", "mean_rank", "top1_frequency"))
})

test_that("top1_frequency values sum to approximately 1", {
  models <- list(m1 = mpg ~ wt, m2 = mpg ~ wt + hp)
  cv <- cv_ranking_stability(models, mtcars, v = 5, R = 20, seed = 42)
  expect_equal(sum(cv$summary$top1_frequency), 1, tolerance = 1e-6)
})

test_that("mean_rank values sum to M*(M+1)/2 / M = (M+1)/2", {
  models <- list(m1 = mpg ~ wt, m2 = mpg ~ wt + hp, m3 = mpg ~ wt + hp + disp)
  cv <- cv_ranking_stability(models, mtcars, v = 5, R = 10, seed = 1)
  # For M models, sum of mean ranks = M*(M+1)/2 / R * R = M*(M+1)/2 but
  # colMeans of ranks: each row sums to M*(M+1)/2, so colMeans sum to (M+1)/2 * M
  # More simply: sum(colMeans(rank_mat)) should equal M*(M+1)/2
  expect_equal(sum(cv$summary$mean_rank), 3 * (3 + 1) / 2, tolerance = 1e-6)
})

test_that("rmse values are non-negative", {
  models <- list(m1 = mpg ~ wt, m2 = mpg ~ wt + hp)
  cv <- cv_ranking_stability(models, mtcars, v = 5, R = 10, seed = 1)
  expect_true(all(cv$summary$mean_rmse >= 0))
  expect_true(all(cv$summary$sd_rmse >= 0))
})

test_that("unnamed formulas get auto-names", {
  models <- list(mpg ~ wt, mpg ~ wt + hp)
  cv <- cv_ranking_stability(models, mtcars, v = 5, R = 5, seed = 1)
  expect_true(all(grepl("model_", cv$summary$model)))
})

test_that("non-list formulas error", {
  expect_error(cv_ranking_stability(mpg ~ wt, mtcars))
})

test_that("v > n errors", {
  models <- list(m1 = mpg ~ wt)
  expect_error(cv_ranking_stability(models, mtcars, v = 100))
})

test_that("v < 2 errors", {
  models <- list(m1 = mpg ~ wt)
  expect_error(cv_ranking_stability(models, mtcars, v = 1))
})

test_that("R < 1 errors", {
  models <- list(m1 = mpg ~ wt, m2 = mpg ~ wt + hp)
  expect_error(cv_ranking_stability(models, mtcars, v = 5, R = 0))
})

test_that("glm backend with logloss works", {
  models <- list(
    m1 = am ~ wt + hp,
    m2 = am ~ wt + hp + qsec
  )
  # GLM convergence warnings on small CV folds are expected and suppressed here
  cv <- suppressWarnings(
    cv_ranking_stability(models, mtcars, v = 5, R = 10, seed = 1,
                         family = stats::binomial(), metric = "logloss")
  )
  expect_equal(cv$settings$metric, "logloss")
  expect_equal(cv$settings$backend, "glm")
  expect_true(all(cv$summary$mean_rmse > 0))
})

test_that("auto metric selects logloss for binomial glm", {
  models <- list(m1 = am ~ wt, m2 = am ~ wt + hp)
  cv <- suppressWarnings(
    cv_ranking_stability(models, mtcars, v = 5, R = 5, seed = 1,
                         family = stats::binomial(), metric = "auto")
  )
  expect_equal(cv$settings$metric, "logloss")
})

test_that("auto metric selects rmse for lm", {
  models <- list(m1 = mpg ~ wt, m2 = mpg ~ wt + hp)
  cv <- cv_ranking_stability(models, mtcars, v = 5, R = 5, seed = 1)
  expect_equal(cv$settings$metric, "rmse")
})

test_that("rlm backend works if MASS available", {
  skip_if_not_installed("MASS")
  models <- list(m1 = mpg ~ wt + hp, m2 = mpg ~ wt + hp + disp)
  cv <- cv_ranking_stability(models, mtcars, v = 5, R = 5, seed = 1,
                              backend = "rlm")
  expect_equal(cv$settings$backend, "rlm")
  expect_equal(nrow(cv$summary), 2L)
})

test_that("plot_cv_stability runs without error", {
  models <- list(m1 = mpg ~ wt, m2 = mpg ~ wt + hp)
  cv <- cv_ranking_stability(models, mtcars, v = 5, R = 10, seed = 1)
  expect_silent(plot_cv_stability(cv, metric = "top1_frequency"))
  expect_silent(plot_cv_stability(cv, metric = "mean_rank"))
})

test_that("summary is ordered by mean_rank", {
  models <- list(m1 = mpg ~ wt, m2 = mpg ~ wt + hp, m3 = mpg ~ wt + hp + disp)
  cv <- cv_ranking_stability(models, mtcars, v = 5, R = 10, seed = 1)
  expect_true(all(diff(cv$summary$mean_rank) >= 0))
})
