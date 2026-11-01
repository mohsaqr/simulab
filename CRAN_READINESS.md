# CRAN readiness — simulab 0.4.10

Checked 2026-10-03 on R 4.5.2, aarch64-apple-darwin20, macOS Tahoe
26.3.1.

## R CMD check

`LC_ALL=C _R_CHECK_FORCE_SUGGESTS_=true _R_CHECK_CRAN_INCOMING_=true R CMD check --as-cran simulab_0.4.7.tar.gz`,
including the PDF reference manual, run with the output directory
outside the repository:

**0 errors, 0 warnings, 1 NOTE** (`New submission`), on the final
tarball below. The `unable to verify current time` NOTE seen on
2026-09-25 did not recur. Examples, tests, vignette re-build, PDF and
HTML manual, and the incoming URL/DOI checks all pass.

## Tests

- With every suggested package installed: **1188 passed, 0 failed, 0
  errors, 0 skips, 0 warnings**.
- With `tna`, `igraph`, `simstudy` and `survival` made unavailable:
  **1089 passed, 0 failed, 0 errors, 19 skips**; every Rd example and
  the vignette run.

The no-Suggests environment is reproduced by tracing
[`loadNamespace()`](https://rdrr.io/r/base/ns-load.html) so that it
raises `packageNotFoundError` for the hidden packages, before running
`devtools::test()` and `devtools::run_examples(run_donttest = TRUE)`:

``` r

trace(loadNamespace, tracer = quote(
  if (as.character(package) %in% c("tna", "igraph", "simstudy", "survival"))
    stop(errorCondition("hidden", class = "packageNotFoundError"))),
  print = FALSE, where = baseenv())
```

This pass found a real defect, which is now fixed: the seed-contract
test errored without `tna` because
[`simulate_group_tna()`](https://pak.dynasite.org/simulab/reference/simulate_group_tna.md)
calls
[`fit_tna()`](https://pak.dynasite.org/simulab/reference/fit_tna.md).

## Posit extra checks (posit-dev/skills, r-lib/cran-extrachecks)

| Item | State |
|----|----|
| `NEWS.md`, `cran-comments.md` present | yes |
| README.Rmd edited, then knitted to README.md (cran-extrachecks item 3) | yes |
| README gives `install.packages("simulab")` | added this pass |
| README has no relative links | yes |
| Title in title case, no redundancy, \< 65 chars (64: “Simulates a Wide Variety of Data Shapes, Sizes and Distributions”) | yes |
| Description does not open with “This package” / package name; 4 sentences; no unexpanded acronyms | yes |
| `Authors@R` has a `cph` role | yes; Sonsoles López-Pernas added as `aut`, `cph` with ORCID (2026-10-04); LICENSE names both |
| `LICENSE` year 2026 | yes |
| Every export has `\value` and `\examples` (128 Rd topics, 124 exports; only `simulab-package.Rd` lacks them, as expected) | yes |
| No `\dontrun`, `\donttest`, `:::` or commented-out code in examples | yes |
| Every example using a Suggests package guarded with [`requireNamespace()`](https://rdrr.io/r/base/ns-load.html) | yes, and verified by execution with them hidden |
| `urlchecker::url_check()` | all URLs correct |
| All URLs `https://` | yes |
| Methods reference | explained in `cran-comments.md`; [`simulate_ml_lpa()`](https://pak.dynasite.org/simulab/reference/simulate_ml_lpa.md) cites Vermunt (2003) with a DOI |
| Spelling under `Language: en-US` (`spelling::spell_check_package()`) | clean (2026-10-03: `labelling` fixed, vignette terms added to WORDLIST) |
| Package name free on CRAN (current and archive) | yes, checked 2026-10-03 |
| [`pkgdown::check_pkgdown()`](https://pkgdown.r-lib.org/reference/check_pkgdown.html) | no problems. Site served at <https://pak.dynasite.org/simulab/> (Dynasite mirrors the `gh-pages` branch; `deploy/sites.conf`), now in DESCRIPTION `URL:` and `_pkgdown.yml` |
| `inst/CITATION` | added; version read from DESCRIPTION |
| README | generated from `README.Rmd` (in `.Rbuildignore`), every output run; rewritten 2026-10-04 |
| Upstream posit-dev skill re-read 2026-10-03 | no items beyond this table |

## Release artifact

- File: `simulab_0.4.9.tar.gz`, 325,542 bytes, built 2026-10-04
- SHA-256:
  `e86c63bf9a9f4dfdf308e1171922a574c78086c08c7248040d3c299169ee968d`

## Submission

- **Submitted 2026-10-04 15:01:59 UTC:** simulab 0.4.10, commit df0e976,
  uploaded with `devtools:::upload_cran()` and cran-comments.md
  (`CRAN-SUBMISSION` written). Pending: the maintainer clicks the
  confirmation link CRAN emails to <saqr@saqr.me>. Tag v0.4.10 once
  accepted.

## External checks

- **0.4.10, commit df0e976:** four large-sample calibration tests now
  `skip_on_cran()` (they run on CI). CRAN-mode test time 24.6 s -\> 9.1
  s locally; win-builder 0.4.8 R-release showed tests at 68 s of a 240 s
  check. Local check 0/0/1 NOTE. Win-builder R-devel (2026-09-30 r90605
  ucrt): 1 NOTE, New submission only; check 200 s, tests 43 s
  (<https://win-builder.r-project.org/EKLy0L5ieFS8>). R-release:
  awaiting email.

- **0.4.9, commit ad355b1:** documentation-only change from 0.4.8 (NEWS
  cut to one entry, lineage references removed, version bump). Local
  check 0/0/1 NOTE. R-hub and win-builder results below are for 0.4.8,
  whose code is identical.

- **0.4.8, commit 49756e5 (2026-10-04):** GitHub Actions R-CMD-check
  green on all 6 jobs, test-coverage and pkgdown green; site live at
  pak.dynasite.org/simulab showing 0.4.8. R-hub `glandular-shorebird`
  (37208272659): linux, macos, macos-arm64, windows (R-devel),
  nosuggests, donttest all `Status: OK`; vnu passed. Win-builder
  R-release (R 4.6.1, x86_64-w64-mingw32): 1 NOTE, New submission only
  (<https://win-builder.r-project.org/TDJ988ly3dsG>). Win-builder
  R-devel: awaiting email.

- **0.4.7, commit 91d2bab (2026-10-03):** GitHub Actions R-CMD-check
  green on all 6 jobs (Ubuntu release + PDF manual, release, devel,
  oldrel-1; macOS and Windows release), plus test-coverage and pkgdown.
  R-hub run `unauthorized-quoll` (37153091808): linux, macos,
  macos-arm64, windows (R-devel), nosuggests and donttest all
  `Status: OK`; vnu passed. Win-builder R-devel and R-release uploads
  queued (confirmed on the FTP listing); results go to the maintainer by
  email.

- R-hub v2 on 0.4.5 (run unthinking-antelope): linux, macos,
  macos-arm64, windows (all R-devel), donttest and vnu passed;
  nosuggests failed on the vignette, fixed in 0.4.6 by
  `VignetteBuilder: knitr, rmarkdown` and passed on re-run
  (eastern-pupfish).

- GitHub Actions on 0.4.6 (6e68c74): R-CMD-check, test-coverage, pkgdown
  green.

- Win-builder devel and release submitted for 0.4.4; results go by
  email.

## Still to do before upload

- Read the two win-builder emails (R-devel, R-release) and add their
  result lines to `cran-comments.md`.
- `devtools::submit_cran()`, then confirm the CRAN email.

Submitted to CRAN on 2026-10-04 (0.4.10).
