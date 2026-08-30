# CRAN readiness — simulab 0.4.1

## Completed locally

- Package metadata, maintainer identity, MIT license, and informative
  description validated.
- `NEWS.md` and `cran-comments.md` updated for 0.4.1; `Language: en-US`
  and `inst/WORDLIST` present.
- `DESCRIPTION` now declares `Imports: stats, utils`, which the
  `NAMESPACE` imported from without declaring.
- Documentation regenerated. 123 exports have matching Rd documentation,
  and every one carries a runnable example (verified by walking
  [`tools::Rd_db()`](https://rdrr.io/r/tools/Rdutils.html) rather than
  by inspection).
- All test suites pass: **612 assertions, zero failures, zero skips**
  with every suggested package installed. 26 test files.
- Coverage 89.9% of package lines, measured with `covr`.
- `_R_CHECK_FORCE_SUGGESTS_=true R CMD check --as-cran --no-manual` on
  the built artifact reports **Status: 1 NOTE** — the new-submission
  note only. R 4.5.2, aarch64-apple-darwin20.

## Not checkable in this environment

- **The PDF reference manual could not be built locally: no TeX is
  installed on this machine** (`pdflatex not found`). A full
  `R CMD check --as-cran` therefore reports one ERROR and one WARNING
  that are both this missing dependency and nothing else; `--no-manual`
  is clean. GitHub Actions builds the manual on its own runners, and its
  checks are green. Install TeX locally, or rely on the CI result,
  before submitting.

## Continuous integration

`R-CMD-check` is green on all five matrix entries as of run 33251450716:
ubuntu-latest (release, devel, oldrel-1), macos-latest (release) and
windows-latest (release). `test-coverage` is green. This retires the
Windows and Linux items that earlier releases listed as outstanding.

`actions/checkout` was bumped to `@v5` in both workflows, which clears
the Node.js 20 deprecation annotation. That bump has not yet been
exercised by a CI run, because nothing is committed; confirm the next
run is green.

## Release artifact

Built 2026-08-29 at version 0.4.1, after the call-lane, catalogue and
calibration work.

- File: `simulab_0.4.1.tar.gz`
- Size: 194,294 bytes
- SHA-256:
  `31bc08db2fb74acfd0ab61405cefbf2ae421bdb3dbcc7521ca31b9d36dcddb1d`

## External checks recommended before upload

- Win-builder for Windows R-devel, and R-hub for a Linux R-devel image,
  as a cross-check on the GitHub Actions matrix.
- Confirm the PDF manual builds somewhere with TeX available.
- `URL` and `BugReports` point at <https://github.com/mohsaqr/simulab>.

No package has been uploaded or submitted to CRAN.
