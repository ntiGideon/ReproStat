# Perturb a dataset

Generates a perturbed version of a dataset using one of three
strategies: bootstrap resampling, subsampling without replacement, or
Gaussian noise injection.

## Usage

``` r
perturb_data(
  data,
  method = c("bootstrap", "subsample", "noise"),
  frac = 0.8,
  noise_sd = 0.05,
  response_col = NULL
)
```

## Arguments

- data:

  A data frame.

- method:

  Character string specifying the perturbation method. One of
  `"bootstrap"` (default), `"subsample"`, or `"noise"`.

- frac:

  Fraction of rows to retain for subsampling. Ignored for other methods.
  Must be in \\(0, 1\]\\. Default is `0.8`.

- noise_sd:

  Noise level as a fraction of each column's standard deviation. Ignored
  unless `method = "noise"`. Default is `0.05`.

- response_col:

  Optional character string naming the response (outcome) column to
  *exclude* from noise injection. Useful when you want to perturb
  predictors only and leave the outcome unchanged. Ignored for
  `method = "bootstrap"` and `method = "subsample"`. When `NULL`
  (default) all numeric columns including the response receive noise.

## Value

A data frame with the same columns as `data`. The number of rows equals
`nrow(data)` for bootstrap and noise, and `floor(frac * nrow(data))` for
subsampling.

## Examples

``` r
set.seed(1)
d_boot <- perturb_data(mtcars, method = "bootstrap")
d_sub  <- perturb_data(mtcars, method = "subsample", frac = 0.7)
d_nois <- perturb_data(mtcars, method = "noise", noise_sd = 0.1)

# Perturb predictors only, leave the response (mpg) unchanged:
d_pred_only <- perturb_data(mtcars, method = "noise",
                            noise_sd = 0.1, response_col = "mpg")
```
