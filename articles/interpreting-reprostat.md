# Interpreting ReproStat Outputs

## Why interpretation matters

ReproStat does not just return a single score. It returns a collection
of stability summaries, each reflecting a different way a model result
can vary under perturbation.

This article explains how to read those outputs in a way that is useful
for real analysis work.

## The question ReproStat answers

The package asks:

> If I perturb the observed data in reasonable ways and refit the same
> model many times, how much do the key outputs move?

That is different from:

- classical uncertainty around one fitted model
- external replication across studies
- causal identification
- model adequacy in a broader scientific sense

ReproStat is focused on **stability of fitted outputs under repeated
data perturbation**.

## Running a diagnostic object

``` r
diag_obj <- run_diagnostics(
  mpg ~ wt + hp + disp,
  data = mtcars,
  B = 150,
  method = "bootstrap"
)
```

Everything else in the package builds from this object.

## Coefficient stability

``` r
coef_stability(diag_obj)
#>  (Intercept)           wt           hp         disp 
#> 5.766188e+00 9.574906e-01 1.350558e-04 8.814208e-05
```

This measures how much estimated coefficients vary across perturbation
runs.

Interpretation:

- lower values indicate more stable coefficient estimates
- large values suggest the estimated effect size is sensitive to the
  data
- coefficients can be unstable even when the average fitted model looks
  strong

Use this when you care about the **magnitude** of effects, not only
whether they are statistically significant.

## P-value stability

``` r
pvalue_stability(diag_obj)
#>         wt         hp       disp 
#> 0.90666667 0.86666667 0.02666667
```

This reports the proportion of perturbation runs in which each
coefficient is significant at the chosen `alpha`.

Interpretation:

- values near `1` mean the term is almost always significant
- values near `0` mean the term is almost never significant
- values near `0.5` mean the significance decision is unstable

This is especially helpful when a predictor looks “significant” in the
base fit but may be borderline under small perturbations.

## Selection stability

``` r
selection_stability(diag_obj)
#>        wt        hp      disp 
#> 1.0000000 1.0000000 0.4466667
```

For standard regression backends, this reflects sign consistency across
perturbations. For `glmnet`, it reflects non-zero selection frequency.

Interpretation:

- high values suggest the direction or inclusion pattern is stable
- low values suggest the predictor is not behaving consistently

This is often the most intuitive measure when the practical question is:
“Does this variable keep showing up in the same way?”

## Prediction stability

``` r
prediction_stability(diag_obj)
#> $pointwise_variance
#>  [1] 0.3662248 0.3309453 0.5611693 0.6449963 0.8857157 0.4844340 0.6296128
#>  [8] 0.7715900 0.5702159 0.6549459 0.6549459 0.7078378 0.3601373 0.3973861
#> [15] 2.0421895 2.1812327 2.0343783 0.7530433 1.4530479 1.0200743 0.4814946
#> [22] 0.5898336 0.4856211 0.6416806 1.1922447 0.9322830 0.6916174 1.3695036
#> [29] 1.0020490 0.9246772 3.3817941 0.5130429
#> 
#> $mean_variance
#> [1] 0.9284364
```

Prediction stability summarizes how much the model’s predictions vary
across perturbation runs.

Interpretation:

- lower mean prediction variance indicates more stable predictive
  behavior
- unstable predictions can occur even when some coefficient summaries
  look fine

This is useful when the model will be used for scoring, ranking, or
decision support rather than only interpretation.

## The Reproducibility Index

``` r
reproducibility_index(diag_obj)
#> $index
#> [1] 88.71268
#> 
#> $components
#>       coef     pvalue  selection prediction 
#>  0.9270762  0.8311111  0.8155556  0.9747641
```

The Reproducibility Index aggregates multiple stability dimensions into
a single 0-100 score.

A practical reading guide is:

- `90-100`: highly stable under the chosen perturbation scheme
- `70-89`: reasonably stable overall
- `50-69`: mixed stability; inspect components carefully
- `< 50`: low stability; the model is sensitive in ways worth
  investigating

These are not universal cutoffs. They are interpretive anchors.

## Do not read the RI alone

Two models can have similar RI values for different reasons:

- one may have stable coefficients but unstable predictions
- another may have stable predictions but unstable significance
  decisions

For that reason, the RI should be treated as a summary, not a
replacement for the component-level diagnostics.

## Confidence intervals for the RI

``` r
ri_confidence_interval(diag_obj, R = 300, seed = 1)
#>     2.5%    97.5% 
#> 87.00194 90.40639
```

This interval reflects uncertainty in the RI induced by the stored
perturbation draws. It is useful when you want to know whether the
reported RI is itself stable or highly variable.

## Choosing a perturbation method

Different perturbation schemes answer different questions.

### Bootstrap

Use `"bootstrap"` when you want a broad sense of ordinary sampling
variability.

### Subsample

Use `"subsample"` when you want to know whether the result depends
heavily on which observations happen to be included.

### Noise

Use `"noise"` when you want to stress test sensitivity to small
measurement error or recording noise in numeric predictors.

## When a low score is useful

A low RI is not a failure of the package. It is a result.

It can tell you that:

- the model is over-sensitive to the observed data
- the effect structure is weak or unstable
- a simpler or more robust specification may be preferable
- the analysis should be reported with more caution

## What to report in practice

For applied work, a compact reporting pattern is:

1.  describe the perturbation method and `B`
2.  report the RI and its confidence interval
3.  mention which components were most and least stable
4.  include at least one stability plot
5.  note any sensitivity that affects substantive conclusions

## Next steps

After reading this article, the most useful follow-up pages are:

- [`vignette("ReproStat-intro")`](https://ntiGideon.github.io/ReproStat/articles/ReproStat-intro.md)
  for the basic workflow
- the backend guide for model-family differences
- the workflow patterns article for practical usage designs
