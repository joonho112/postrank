# Independent main-study coefficient oracles for the typed-coefficient tests.
# The verbatim copies live in tests/fixtures/coefficient-oracles/ (provenance and
# SHA-256 in its README.md). They are loaded only into this private environment,
# whose parent is baseenv(), so no package function is visible to the oracles and
# the package never sees them. Replaces the former MAIN_STUDY_ROOT /
# POSTRANK_CANDIDATE_ROOT lookups of the 0.0.1.9003 tests.
pr_cf_fixture_root <- function() {
  candidates <- c(testthat::test_path("..", ".."), testthat::test_path(".."))
  found <- candidates[file.exists(file.path(candidates, "tests", "fixtures", "gaussian-fixed.json"))]
  if (!length(found)) stop("packaged coefficient fixture tests/fixtures/gaussian-fixed.json not found", call. = FALSE)
  normalizePath(found[[1L]], mustWork = TRUE)
}
pr_cf_oracle <- local({
  env <- new.env(parent = baseenv())
  dir <- file.path(pr_cf_fixture_root(), "tests", "fixtures", "coefficient-oracles")
  for (f in c("identity.R", "input-boundary.R", "gaussian-conditional.R", "gaussian-coefficients.R",
              "evaluate-fixed-action.R", "gaussian-fixtures.R", "mixture-oracle.R"))
    sys.source(file.path(dir, f), env)
  env
})
