# T-doc-08: the installed cache reader validates every manifest field, restores stubbed
# inputs losslessly, rejects forgeries with the field named, and never writes.
cf_reader <- function(root = NULL) {
  env <- new.env()
  sys.source(system.file("scripts", "_vignette-setup.R", package = "postrank", mustWork = TRUE), env)
  if (!is.null(root)) env$system.file <- function(..., package = "postrank", mustWork = FALSE) {
    p <- file.path(root, ...); if (file.exists(p)) p else ""
  }
  env
}
cf_copy <- function() {
  tmp <- withr::local_tempdir(.local_envir = parent.frame())
  src <- system.file("extdata", package = "postrank", mustWork = TRUE)
  dir.create(file.path(tmp, "extdata")); file.copy(list.files(src, full.names = TRUE), file.path(tmp, "extdata"), recursive = TRUE)
  dir.create(file.path(tmp, "scripts"))
  file.copy(system.file("scripts", "_vignette-setup.R", package = "postrank", mustWork = TRUE), file.path(tmp, "scripts"))
  tmp
}
cf_edit <- function(path, f) { x <- jsonlite::read_json(path); x <- f(x); writeLines(jsonlite::toJSON(x, auto_unbox = TRUE, pretty = TRUE, null = "null", digits = NA), path) }

test_that("the installed reader returns validated objects with restored inputs", {
  r <- cf_reader()
  a <- r$load_or_compute("analysis_30x3")
  expect_s3_class(a, "postrank_analysis")
  expect_identical(a$input, pr_example_draws)
  expect_true(.pr_validate_analysis(a))
  g <- r$load_or_compute("gaussian_analysis_30x3")
  expect_identical(g$input$coefficient_identity, pr_example_gaussian$coefficient_identity)
  for (k in c("frontier_30x3", "commonality_30x3", "comparison_30x3_tau35", "toy_analysis", "toy_minimax", "toy_crossfit"))
    expect_false(is.null(r$load_or_compute(k)), info = k)
  expect_error(r$load_or_compute("no_such_key"), "no such cached asset")
})

test_that("forged manifests, digests, timestamps and identities are rejected with the field named", {
  forge <- list(
    package_version = function(m) { m$package_version <- "0.0.0"; m },
    manifest_schema_version = function(m) { m$manifest_schema_version <- "2"; m },
    created_at = function(m) { m$assets$toy_analysis$created_at <- "2026-10-dd"; m },
    sha256 = function(m) { m$assets$toy_analysis$sha256 <- strrep("0", 64); m },
    bytes = function(m) { m$assets$toy_analysis$bytes <- 1; m },
    source_id = function(m) { m$source_id <- strrep("1", 64); m })
  for (field in names(forge)) {
    root <- cf_copy()
    cf_edit(file.path(root, "extdata", "manifests", "cache-manifest.json"), forge[[field]])
    expect_error(cf_reader(root)$load_or_compute("toy_analysis"), field, info = field)
  }
  # A forged stub identity, with a re-sealed digest so only the identity check can catch it.
  root <- cf_copy()
  f <- file.path(root, "extdata", "cached", "toy_analysis.rds")
  env <- readRDS(f); env$value$input$input_identity <- strrep("a", 64); saveRDS(env, f)
  cf_edit(file.path(root, "extdata", "manifests", "cache-manifest.json"), function(m) {
    m$assets$toy_analysis$sha256 <- digest::digest(file = f, algo = "sha256"); m$assets$toy_analysis$bytes <- file.size(f); m })
  expect_error(cf_reader(root)$load_or_compute("toy_analysis"), "input_identity")
})

test_that("reading writes nothing", {
  src <- system.file("extdata", package = "postrank", mustWork = TRUE)
  before <- tools::md5sum(list.files(src, recursive = TRUE, full.names = TRUE))
  r <- cf_reader(); invisible(r$load_or_compute("analysis_30x3_tau35"))
  expect_identical(tools::md5sum(list.files(src, recursive = TRUE, full.names = TRUE)), before)
})

test_that("maintainer checkout: historical origin and current reader sources are both fresh", {
  root <- pr_source_root()
  skip_if(is.null(root), "not a source checkout")
  src <- jsonlite::read_json(file.path(root, "inst", "extdata", "manifests", "source-manifest.json"))
  if (identical(src$package_version, as.character(utils::packageVersion("postrank")))) {
    stale <- Filter(function(e) !identical(digest::digest(file = file.path(root, e$path), algo = "sha256"), e$sha256), src$entries)
    expect_identical(vapply(stale, `[[`, "", "path"), character())
  } else {
    env <- new.env()
    sys.source(file.path(root, "inst", "scripts", "validate-cache-reader-compatibility.R"), env)
    receipt <- jsonlite::read_json(file.path(root, "inst", "extdata", "manifests", "cache-reader-compatibility.json"))
    expect_true(env$.cache_assert_compatibility_sources(root, receipt))
  }
})
