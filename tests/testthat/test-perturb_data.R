test_that("bootstrap returns same dimensions", {
  set.seed(1)
  d <- perturb_data(mtcars, method = "bootstrap")
  expect_equal(nrow(d), nrow(mtcars))
  expect_equal(ncol(d), ncol(mtcars))
  expect_identical(names(d), names(mtcars))
})

test_that("bootstrap samples with replacement (may have duplicates)", {
  set.seed(42)
  d <- perturb_data(mtcars, method = "bootstrap")
  # With 32 rows and replacement, duplicates are very likely
  expect_lte(length(unique(rownames(d))), nrow(mtcars))
})

test_that("subsample returns fewer or equal rows", {
  set.seed(1)
  d <- perturb_data(mtcars, method = "subsample", frac = 0.8)
  expect_lte(nrow(d), nrow(mtcars))
  expect_gte(nrow(d), 2L)
  expect_equal(ncol(d), ncol(mtcars))
})

test_that("subsample row count equals floor(frac * n)", {
  set.seed(1)
  expected <- floor(0.6 * nrow(mtcars))
  d <- perturb_data(mtcars, method = "subsample", frac = 0.6)
  expect_equal(nrow(d), expected)
})

test_that("subsample rows are a subset of original", {
  set.seed(1)
  d <- perturb_data(mtcars, method = "subsample", frac = 0.7)
  rn <- rownames(d)
  expect_true(all(rn %in% rownames(mtcars)))
})

test_that("noise does not change dimensions", {
  set.seed(1)
  d <- perturb_data(mtcars, method = "noise", noise_sd = 0.1)
  expect_equal(dim(d), dim(mtcars))
})

test_that("noise changes numeric values", {
  set.seed(1)
  d <- perturb_data(mtcars, method = "noise", noise_sd = 0.5)
  expect_false(identical(d$mpg, mtcars$mpg))
})

test_that("noise does not change non-numeric columns", {
  df <- data.frame(x = 1:5, grp = letters[1:5], stringsAsFactors = FALSE)
  set.seed(1)
  d <- perturb_data(df, method = "noise", noise_sd = 0.5)
  expect_identical(d$grp, df$grp)
})

test_that("noise does not alter zero-variance columns", {
  df <- data.frame(x = rep(1, 10), y = rnorm(10))
  set.seed(1)
  d <- perturb_data(df, method = "noise", noise_sd = 0.5)
  expect_identical(d$x, df$x)  # constant column unchanged
})

test_that("invalid method errors", {
  expect_error(perturb_data(mtcars, method = "bad"))
})

test_that("non-data-frame input errors", {
  expect_error(perturb_data(as.matrix(mtcars)))
})

test_that("invalid frac errors", {
  expect_error(perturb_data(mtcars, method = "subsample", frac = 0))
  expect_error(perturb_data(mtcars, method = "subsample", frac = -0.1))
  expect_error(perturb_data(mtcars, method = "subsample", frac = 1.5))
})

test_that("negative noise_sd errors", {
  expect_error(perturb_data(mtcars, method = "noise", noise_sd = -0.1))
})
