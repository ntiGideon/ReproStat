## Resubmission

This is a resubmission addressing all issues raised by the CRAN reviewer.  Changes since the previous submission:

1. **References added to DESCRIPTION** — the Description field now cites the
   three core methods using the required `authors (year) <doi:...>` format:
   Efron & Tibshirani (1993, ISBN:9780412042317), Meinshausen & Buhlmann
   (2010) <doi:10.1111/j.1467-9868.2010.00740.x>, and Peng (2011)
   <doi:10.1126/science.1213847>.

2. **`\dontrun{}` replaced with `\donttest{}`** — `plot_stability_gg.Rd` and
   `plot_cv_stability_gg.Rd` now use `\donttest{}` with a
   `requireNamespace()` guard around optional-package examples.

3. **`par()` save/restore pattern applied** — all `par(mfrow = ...)` calls in
   `demo/reprostat.R` and `vignettes/ReproStat-intro.Rmd` now follow the
   `oldpar <- par(...); ...; par(oldpar)` pattern.

---

## R CMD check results

0 errors | 0 warnings | 0 notes

## Test environments

- Windows 11 Pro, R 4.4.1 (local)
- win-builder: R-devel, R-release
- GitHub Actions: ubuntu-latest

## Downstream dependencies

This is a new package. There are no downstream dependencies.
