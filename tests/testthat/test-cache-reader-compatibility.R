cc_reader <- function(root = NULL) {
  env <- new.env()
  sys.source(system.file("scripts", "_vignette-setup.R", package = "postrank", mustWork = TRUE), env)
  if (!is.null(root)) env$system.file <- function(..., package = "postrank", mustWork = FALSE) {
    p <- file.path(root, ...); if (file.exists(p)) p else ""
  }
  env
}
cc_copy <- function() {
  tmp <- withr::local_tempdir(.local_envir = parent.frame())
  file.copy(system.file("extdata", package = "postrank", mustWork = TRUE), tmp, recursive = TRUE)
  dir.create(file.path(tmp, "scripts"))
  file.copy(system.file("scripts", "_vignette-setup.R", package = "postrank", mustWork = TRUE), file.path(tmp, "scripts"))
  tmp
}
cc_receipt_path <- function(root) file.path(root, "extdata", "manifests", "cache-reader-compatibility.json")
cc_edit <- function(path, f) {
  x <- f(jsonlite::read_json(path))
  writeLines(jsonlite::toJSON(x, auto_unbox = TRUE, pretty = TRUE, null = "null", digits = NA), path)
}

test_that("all 21 original objects pass an exactly versioned reader receipt", {
  man <- jsonlite::read_json(system.file("extdata", "manifests", "cache-manifest.json", package = "postrank"))
  receipt <- jsonlite::read_json(system.file("extdata", "manifests", "cache-reader-compatibility.json", package = "postrank"))
  expect_identical(receipt$reader_package_version, as.character(utils::packageVersion("postrank")))
  expect_identical(receipt$origin_package_version, "1.1.0")
  expect_identical(receipt$validation$status, "complete")
  expect_length(man$assets, 21L)
  reader <- cc_reader()
  for (k in names(man$assets)) {
    expect_s3_class(reader$load_or_compute(k), man$assets[[k]]$object_class)
    expect_true(receipt$validation$assets[[k]]$reader_validated, info = k)
  }
  note <- reader$cache_note("toy_analysis")
  expect_match(note, "postrank 1.1.0", fixed = TRUE)
  expect_match(note, man$assets$toy_analysis$created_at, fixed = TRUE)
})

test_that("missing and forged compatibility receipts fail closed with named fields", {
  root <- cc_copy(); unlink(cc_receipt_path(root))
  expect_error(cc_reader(root)$load_or_compute("toy_analysis"), "package_version")
  forge <- list(
    compatibility_schema_version = function(r) { r$compatibility_schema_version <- "2"; r },
    reader_package_version = function(r) { r$reader_package_version <- "1.1.0.9000"; r },
    package_version = function(r) { r$origin_package_version <- "0.0.0"; r },
    origin_source_id = function(r) { r$origin_source_id <- strrep("0", 64); r },
    origin_cache_manifest_sha256 = function(r) { r$origin_cache_manifest_sha256 <- strrep("0", 64); r },
    origin_source_manifest_sha256 = function(r) { r$origin_source_manifest_sha256 <- strrep("0", 64); r },
    compatible_source_id = function(r) { r$compatible_source_id <- strrep("0", 64); r },
    reader_sha256 = function(r) { r$reader_sha256 <- strrep("0", 64); r },
    validation = function(r) { r$validation$status <- "pending"; r })
  for (field in names(forge)) {
    root <- cc_copy(); cc_edit(cc_receipt_path(root), forge[[field]])
    expect_error(cc_reader(root)$load_or_compute("toy_analysis"), field, info = field)
  }
  root <- cc_copy()
  cat("\n# forged reader bytes\n", file = file.path(root, "scripts", "_vignette-setup.R"), append = TRUE)
  expect_error(cc_reader(root)$load_or_compute("toy_analysis"), "reader_sha256")
})

test_that("original per-asset versions schemas and source identities remain enforced", {
  for (field in c("package_version", "cache_schema_version", "source_id")) {
    root <- cc_copy()
    cc_edit(file.path(root, "extdata", "manifests", "cache-manifest.json"), function(m) {
      m$assets$toy_analysis[[field]] <- "forged"; m
    })
    expect_error(cc_reader(root)$load_or_compute("toy_analysis"), "asset metadata", info = field)
  }
})

test_that("semantic checks precede final byte binding and failed reads never evaluate live", {
  root <- cc_copy()
  cc_edit(file.path(root, "extdata", "manifests", "cache-manifest.json"), function(m) {
    m$assets$toy_analysis$created_at <- "2026-11-01T00:00:00Z"; m
  })
  ran <- FALSE
  expect_error(cc_reader(root)$load_or_compute("toy_analysis", { ran <- TRUE }, live = TRUE), "origin_cache_manifest_sha256")
  expect_false(ran)
  root <- cc_copy()
  f <- file.path(root, "extdata", "cached", "toy_analysis.rds")
  x <- readRDS(f); x$metadata$diagnostic_test <- TRUE; saveRDS(x, f)
  cc_edit(file.path(root, "extdata", "manifests", "cache-manifest.json"), function(m) {
    m$assets$toy_analysis$sha256 <- digest::digest(file = f, algo = "sha256")
    m$assets$toy_analysis$bytes <- file.size(f); m
  })
  expect_error(cc_reader(root)$load_or_compute("toy_analysis"), "origin_cache_manifest_sha256")
  root <- cc_copy()
  before <- tools::md5sum(list.files(root, recursive = TRUE, full.names = TRUE))
  invisible(cc_reader(root)$load_or_compute("toy_analysis", { ran <- TRUE }))
  expect_false(ran)
  expect_identical(tools::md5sum(list.files(root, recursive = TRUE, full.names = TRUE)), before)
})

test_that("compatibility authoring is inert and requires an explicit maintainer flag", {
  env <- new.env()
  withr::local_envvar(POSTRANK_VALIDATE_CACHE_READER_COMPATIBILITY = "false")
  path <- system.file("scripts", "validate-cache-reader-compatibility.R", package = "postrank", mustWork = TRUE)
  expect_silent(sys.source(path, env))
  expect_error(env$validate_cache_reader_compatibility(), "Explicit POSTRANK_VALIDATE_CACHE_READER_COMPATIBILITY=true")
})

test_that("source validation catches missing additions and re-sealed changes to original R", {
  root <- pr_source_root()
  skip_if(is.null(root), "not a source checkout")
  stage <- withr::local_tempdir()
  file.copy(file.path(root, c("DESCRIPTION", "LICENSE", "R", "data", "inst")), stage, recursive = TRUE)
  env <- new.env()
  sys.source(file.path(stage, "inst", "scripts", "validate-cache-reader-compatibility.R"), env)
  path <- file.path(stage, "inst", "extdata", "manifests", "cache-reader-compatibility.json")
  receipt <- jsonlite::read_json(path)
  expect_true(env$.cache_assert_compatibility_sources(stage, receipt))
  incomplete <- receipt
  incomplete$compatible_source_entries <- head(incomplete$compatible_source_entries, -1L)
  expect_error(env$.cache_assert_compatibility_sources(stage, incomplete), "compatible_source_entries membership")
  original <- file.path(stage, "R", "accessors.R")
  cat("\n# unexpected original source change\n", file = original, append = TRUE)
  for (i in seq_along(receipt$compatible_source_entries))
    if (identical(receipt$compatible_source_entries[[i]]$path, "R/accessors.R"))
      receipt$compatible_source_entries[[i]]$sha256 <- digest::digest(file = original, algo = "sha256")
  receipt$compatible_source_id <- env$.cache_compatibility_id(receipt$compatible_source_entries)
  expect_error(env$.cache_assert_compatibility_sources(stage, receipt), "unchanged original R/data hashes")
  before <- tools::md5sum(path)
  withr::local_envvar(POSTRANK_VALIDATE_CACHE_READER_COMPATIBILITY = "true")
  expect_error(env$validate_cache_reader_compatibility(stage), "unchanged original R/data hashes")
  expect_identical(tools::md5sum(path), before)
})


test_that("temporary receipt authoring preserves the current package namespace", {
  root <- pr_source_root()
  skip_if(is.null(root), "source-only authoring check")
  builder <- new.env(parent=globalenv())
  sys.source(file.path(root,"inst/scripts/validate-cache-reader-compatibility.R"),builder)
  stage <- withr::local_tempdir()
  file.copy(list.files(root, full.names=TRUE, all.files=TRUE, no..=TRUE), stage, recursive=TRUE)
  before <- getNamespaceInfo(asNamespace("postrank"), "path")
  before_file <- system.file(package="postrank")
  withr::local_envvar(POSTRANK_VALIDATE_CACHE_READER_COMPATIBILITY="true")
  expect_no_error(builder$validate_cache_reader_compatibility(stage))
  expect_identical(getNamespaceInfo(asNamespace("postrank"), "path"), before)
  expect_identical(system.file(package="postrank"), before_file)
})
