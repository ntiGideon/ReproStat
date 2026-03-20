## R CMD check results

0 errors | 0 warnings | 3 notes

## Notes

**Note 1:** `unable to verify current time`
- Environmental — no internet access to a time server in the build environment.
- Not a package issue.

**Note 2:** `Skipping checking math rendering: package 'V8' unavailable`
- V8 is not installed in the local build environment.
- Not a package issue; does not affect CRAN checks.

**Note 3:** `Found the following files/directories: 'lastMiKTeXException'`
- Windows/MiKTeX artifact created during LaTeX rendering.
- Not a package issue.

## Test environments

- Windows 11 Pro, R 4.x (local)
- win-builder: R-devel, R-release
- GitHub Actions: ubuntu-latest

## Downstream dependencies

This is a new package. There are no downstream dependencies.
