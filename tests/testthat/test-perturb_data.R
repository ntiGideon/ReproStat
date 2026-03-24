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

test_that("noise changes numeric values by default (including response)", {
  set.seed(1)
  d <- perturb_data(mtcars, method = "noise", noise_sd = 0.5)
  # Without response_col, ALL numeric columns including mpg are perturbed
  expect_false(identical(d$mpg, mtcars$mpg))
  expect_false(identical(d$wt,  mtcars$wt))
})

test_that("noise with response_col leaves that column unchanged", {
  set.seed(1)
  d <- perturb_data(mtcars, method = "noise", noise_sd = 0.5,
                    response_col = "mpg")
  expect_identical(d$mpg, mtcars$mpg)       # response protected
  expect_false(identical(d$wt, mtcars$wt))  # predictors still perturbed
})

test_that("noise response_col does not affect bootstrap or subsample", {
  # response_col is silently ignored for non-noise methods
  set.seed(1)
  d_boot <- perturb_data(mtcars, method = "bootstrap", response_col = "mpg")
  expect_equal(nrow(d_boot), nrow(mtcars))

  d_sub <- perturb_data(mtcars, method = "subsample", frac = 0.8,
                        response_col = "mpg")
  expect_lte(nrow(d_sub), nrow(mtcars))
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

test_that("response_col not in data raises an error", {
  expect_error(
    perturb_data(mtcars, method = "noise", noise_sd = 0.1,
                 response_col = "nonexistent"),
    "not found"
  )
})

test_that("response_col must be a single string", {
  expect_error(
    perturb_data(mtcars, method = "noise", noise_sd = 0.1,
                 response_col = c("mpg", "wt")),
    "single character"
  )
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
