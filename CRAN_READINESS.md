# CRAN readiness — simulab 0.4.2

## Completed locally

- Package metadata, maintainer identity, MIT license, and informative
  description validated.
- `NEWS.md` and `cran-comments.md` updated for 0.4.2; `Language: en-US` and
  `inst/WORDLIST` present.
- `DESCRIPTION` declares `Imports: stats, utils`, the only two namespaces the
  `NAMESPACE` imports from. There are no non-base hard dependencies.
- Documentation regenerated into 127 Rd topics. All 123 exports have matching
  Rd documentation; every documented `\usage` argument corresponds to a real
  formal and every export carries `\value` and a runnable example, verified by
  walking `tools::Rd_db()` against `formals()` rather than by inspection.
- Every exported function's documentation was audited against its
  implementation this release, and the five behavioural defects that audit
  exposed were fixed. See `NEWS.md` for the list.
- All test suites pass: **785 assertions, zero failures, zero errors, zero
  skips** with every suggested package installed. 30 test files.
- Coverage **90.9%** of package lines, measured with `covr` on this commit.
- All 127 Rd topics' examples were additionally executed with `igraph`, `tna`
  and `simstudy` reported as unavailable, to confirm that every use of a
  suggested package is guarded. All pass.
- `LC_ALL=C _R_CHECK_FORCE_SUGGESTS_=true R CMD check --as-cran` on the built artifact,
  including the PDF reference manual, reports **Status: 1 NOTE** — the
  new-submission note only. The C locale is used deliberately: the package
  sources and all 127 Rd files are ASCII-only, so the check does not depend
  on a UTF-8 locale.
  R 4.5.2 (oldrel-1), aarch64-apple-darwin20.

  Note: when the check is run inside the repository directory on macOS, a
  second NOTE reports `.DS_Store` in the check directory. That file is created
  by the operating system inside `simulab.Rcheck/` during the run; it is absent
  from the tarball, and the note does not appear when the check writes its
  output elsewhere with `-o`. It will not occur on CRAN's machines.

## PDF reference manual

- The PDF reference manual builds successfully with TinyTeX. The TinyTeX binary
  directory is not in the default shell `PATH`, so local checks prepend
  `~/Library/TinyTeX/bin/universal-darwin` explicitly. A dedicated CI job
  installs TinyTeX and runs the complete manual-enabled check.

## Continuous integration

`R-CMD-check` covers five matrix entries: ubuntu-latest (release, devel,
oldrel-1), macos-latest (release) and windows-latest (release), plus a separate
Ubuntu release job that performs the full manual-enabled check. The
cross-platform matrix uses `--no-manual`.

The submission commit must pass both jobs, including current R release and
R-devel, before upload. CI has not yet been run on this commit.

## Release artifact

Built 2026-09-13 at version 0.4.2, after the documentation audit and the
correctness fixes it exposed.

- File: `simulab_0.4.2.tar.gz`
- Size: 248,998 bytes
- SHA-256: `48bc5b0967f62f7951a7564069e49e1cac5234bb41d244ed2d46d32cf7e92dd0`

## External checks recommended before upload

- Win-builder for Windows R-devel, and R-hub for a Linux R-devel image, as a
  cross-check on the GitHub Actions matrix.
- Confirm both GitHub Actions jobs pass on the submission commit.
- `URL` and `BugReports` point at https://github.com/mohsaqr/simulab.

No package has been uploaded or submitted to CRAN.
