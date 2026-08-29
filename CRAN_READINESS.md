# CRAN readiness — simulab 0.4.0

## Completed locally

- Package metadata, maintainer identity, MIT license, and informative
  description validated.
- `NEWS.md`, `cran-comments.md`, `Language: en-US`, and `inst/WORDLIST` added.
- Documentation regenerated; 121 exports have matching Rd documentation and
  124 of 125 Rd files carry a runnable example.
- All test suites pass with zero failures or warnings (2 skips when
  {simstudy} is absent). Coverage is 90.79% (covr).
- Package spelling check reports no errors.
- Package URL check reports all URLs valid.
- Source package installs and loads from a clean temporary library.
- PDF and HTML reference manuals build successfully.
- Network-enabled `R CMD check --as-cran` reports:
  `0 errors | 0 warnings | 1 expected new-submission note`.
  A local `R CMD check --no-manual` reports `0 errors | 0 warnings | 0 notes`.
- Active CRAN, CRAN Archive, and Bioconductor package URLs for `simulab`
  return no existing package; CRAN incoming checks classify it as a new
  submission.

## Release artifact

Built 2026-08-29 at version 0.4.0, after the audit fixes (named validation messages,
solver convergence checks, the `read_definitions()` round-trip fix, and
examples on every export).

- File: `simulab_0.4.0.tar.gz`
- Size: 139,867 bytes
- SHA-256: `6cc486b458b8abca750894357857a7624c880211b4623cbbef0aa4f5225e26e0`
- `R CMD check --as-cran --no-manual` on this artifact (R 4.5.2,
  aarch64-apple-darwin20, `_R_CHECK_FORCE_SUGGESTS_=false` because {simstudy}
  is not installed locally): **Status: 1 NOTE** (new submission only).

## External checks recommended before upload

- Run Windows R-devel through Win-builder.
- Run at least one Linux R-devel/release environment through R-hub.
- If a public source repository is created, add its canonical `URL` and
  `BugReports` fields to `DESCRIPTION`, rebuild, and repeat the checks.

No package has been uploaded or submitted to CRAN.
