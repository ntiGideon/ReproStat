# Print a reprostat object

Print a reprostat object

## Usage

``` r
# S3 method for class 'reprostat'
print(x, ...)
```

## Arguments

- x:

  A `reprostat` object.

- ...:

  Further arguments (ignored).

## Value

Invisibly returns `x`.

## Examples

``` r
set.seed(1)
d <- run_diagnostics(mpg ~ wt + hp, data = mtcars, B = 20)
print(d)
#> ReproStat Diagnostics
#> ---------------------
#> Formula   : mpg ~ wt + hp 
#> Backend   : lm 
#> Method    : bootstrap 
#> Iterations: 20 
#> Terms     : (Intercept), wt, hp 
```
