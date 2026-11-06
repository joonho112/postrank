# Explicit maintainer validation, with no solves and no ordinary-read writes.
# From the package source root, after source metadata is final:
# POSTRANK_VALIDATE_CACHE_READER_COMPATIBILITY=true Rscript inst/scripts/validate-cache-reader-compatibility.R
# Sourcing this file only defines functions. The authoring function requires the same flag
# and an already loaded candidate of the matching version. It never rebinds that namespace.
.cache_compatibility_files <- function(root) {
  sort(c("DESCRIPTION", "LICENSE", "inst/extdata/case-studies/DATA-NOTICE.md",
    paste0("R/", list.files(file.path(root, "R"), "\\.R$")),
    paste0("data/", list.files(file.path(root, "data"), "\\.rda$")),
    paste0("inst/scripts/", list.files(file.path(root, "inst", "scripts"), "\\.R$"))), method = "radix")
}
.cache_compatibility_sha <- function(path) digest::digest(file = path, algo = "sha256")
.cache_compatibility_id <- function(entries) digest::digest(paste(vapply(entries,
  function(e) paste0(e$path, "\t", e$sha256), ""), collapse = "\n"), algo = "sha256", serialize = FALSE)
.cache_assert_compatibility_sources <- function(root, receipt) {
  check <- function(ok, field) if (!isTRUE(ok)) stop("cache compatibility source validation failed: ", field, call. = FALSE)
  vec <- function(x) unname(unlist(x, use.names = FALSE))
  paths <- .cache_compatibility_files(root)
  entries <- receipt$compatible_source_entries
  check(identical(vapply(entries, `[[`, "", "path"), paths), "compatible_source_entries membership")
  check(identical(.cache_compatibility_id(entries), receipt$compatible_source_id), "compatible_source_id")
  check(all(vapply(entries, function(e) identical(.cache_compatibility_sha(file.path(root, e$path)), e$sha256), TRUE)), "current source hashes")
  mp <- file.path(root, "inst", "extdata", "manifests")
  check(identical(.cache_compatibility_sha(file.path(mp, "cache-manifest.json")), receipt$origin_cache_manifest_sha256), "origin_cache_manifest_sha256")
  check(identical(.cache_compatibility_sha(file.path(mp, "source-manifest.json")), receipt$origin_source_manifest_sha256), "origin_source_manifest_sha256")
  src <- jsonlite::read_json(file.path(mp, "source-manifest.json"))
  check(identical(.cache_compatibility_id(src$entries), src$source_id) && identical(src$source_id, receipt$origin_source_id), "origin_source_id")
  fixed <- Filter(function(e) startsWith(e$path, "R/") || startsWith(e$path, "data/"), src$entries)
  check(sum(startsWith(vapply(fixed, `[[`, "", "path"), "R/")) == 96L &&
    sum(startsWith(vapply(fixed, `[[`, "", "path"), "data/")) == 8L, "96 original R and eight data paths")
  check(identical(vec(receipt$unchanged_origin_paths), unname(vapply(fixed, `[[`, "", "path"))), "unchanged_origin_paths")
  check(all(vapply(fixed, function(e) identical(.cache_compatibility_sha(file.path(root, e$path)), e$sha256), TRUE)), "unchanged original R/data hashes")
  changed <- vapply(Filter(function(e) !identical(.cache_compatibility_sha(file.path(root, e$path)), e$sha256), src$entries), `[[`, "", "path")
  check(identical(unname(changed), vec(receipt$allowed_origin_differences)), "allowed_origin_differences")
  permitted <- c("DESCRIPTION", "LICENSE", "inst/scripts/_vignette-setup.R", "inst/extdata/case-studies/DATA-NOTICE.md")
  check(all(changed %in% permitted), "unapproved original source change")
  check(identical(vec(receipt$added_source_paths), setdiff(paths, vapply(src$entries, `[[`, "", "path"))), "added_source_paths")
  check(identical(as.character(read.dcf(file.path(root, "DESCRIPTION"))[1L, "Version"]), receipt$reader_package_version), "reader_package_version")
  check(identical(.cache_compatibility_sha(file.path(root, "inst", "scripts", "_vignette-setup.R")), receipt$reader_sha256), "reader_sha256")
  invisible(TRUE)
}
validate_cache_reader_compatibility <- function(root = ".") {
  if (!identical(Sys.getenv("POSTRANK_VALIDATE_CACHE_READER_COMPATIBILITY"), "true"))
    stop("Explicit POSTRANK_VALIDATE_CACHE_READER_COMPATIBILITY=true is required", call. = FALSE)
  root <- normalizePath(root, mustWork = TRUE)
  mp <- file.path(root, "inst", "extdata", "manifests")
  man_path <- file.path(mp, "cache-manifest.json"); src_path <- file.path(mp, "source-manifest.json")
  sha <- .cache_compatibility_sha
  # These are the actual inherited public 1.1.0 manifest bytes, not a relabelled origin.
  origin_cache <- "26a3c067229d000be41c624975c2b8f777b0d2f887e96555694399808a2aae28"
  origin_source <- "fbc44fcc363bb01f7f9e9d7697be479ad0ca1a2b1d5af1b04876992df8f251cd"
  if (!identical(sha(man_path), origin_cache) || !identical(sha(src_path), origin_source))
    stop("Original public 1.1.0 manifest bytes changed; compatibility cannot be sealed", call. = FALSE)
  man <- jsonlite::read_json(man_path); src <- jsonlite::read_json(src_path)
  paths <- .cache_compatibility_files(root)
  entries <- lapply(paths, function(p) list(path = p, sha256 = sha(file.path(root, p))))
  origin_paths <- vapply(src$entries, `[[`, "", "path")
  fixed <- origin_paths[startsWith(origin_paths, "R/") | startsWith(origin_paths, "data/")]
  changed <- vapply(Filter(function(e) !identical(sha(file.path(root, e$path)), e$sha256), src$entries), `[[`, "", "path")
  receipt <- list(compatibility_schema_version = "1",
    reader_package_version = as.character(read.dcf(file.path(root, "DESCRIPTION"))[1L, "Version"]),
    origin_package_version = man$package_version, origin_source_id = src$source_id,
    origin_cache_manifest_sha256 = origin_cache, origin_source_manifest_sha256 = origin_source,
    compatible_source_id = .cache_compatibility_id(entries), compatible_source_entries = entries,
    unchanged_origin_paths = unname(fixed), allowed_origin_differences = unname(changed),
    added_source_paths = setdiff(paths, origin_paths), reader_sha256 = sha(file.path(root, "inst", "scripts", "_vignette-setup.R")))
  .cache_assert_compatibility_sources(root, receipt)
  if (!isNamespaceLoaded("postrank"))
    stop("Load the candidate package before explicit receipt validation", call. = FALSE)
  if (!identical(as.character(utils::packageVersion("postrank")), receipt$reader_package_version))
    stop("Loaded package version differs from candidate source version", call. = FALSE)
  stage <- tempfile("postrank-cache-reader-"); dir.create(stage)
  on.exit(unlink(stage, recursive = TRUE), add = TRUE)
  file.copy(file.path(root, "inst", "extdata"), stage, recursive = TRUE)
  dir.create(file.path(stage, "scripts"))
  file.copy(file.path(root, "inst", "scripts", "_vignette-setup.R"), file.path(stage, "scripts"))
  reader <- new.env(parent = globalenv())
  sys.source(file.path(stage, "scripts", "_vignette-setup.R"), reader)
  reader$system.file <- function(..., package = "postrank", mustWork = FALSE) {
    p <- file.path(stage, ...); if (file.exists(p)) p else ""
  }
  keys <- sort(names(man$assets), method = "radix")
  if (length(keys) != 21L) stop("Expected exactly 21 original assets", call. = FALSE)
  # First use the actual reader's asset validation function, without a receipt or writes.
  # The resulting claims are true before a provisional receipt is written to staging.
  checks <- lapply(keys, function(k) {
    value <- reader$.cache_asset_value(k, man$assets[[k]], function(field, msg)
      stop(sprintf("%s: %s (%s)", k, msg, field), call. = FALSE))
    list(object_class = class(value)[1L], sha256 = man$assets[[k]]$sha256, reader_validated = TRUE,
      checks = c("file_bytes_sha256", "envelope_key_class", "restore_stub_input_identity_if_present",
        if (inherits(value, "postrank_analysis")) ".pr_validate_analysis",
        if (inherits(value, "postrank_fit")) ".pr_validate_problem",
        if (inherits(value, "postrank_comparison")) ".pr_validate_comparison"))
  }); names(checks) <- keys
  receipt$validation <- list(status = "complete", assets = checks,
    method = "Actual reader asset validation followed by all 21 full cross-version reads in isolated staging; no solves.")
  receipt$validated_at <- format(Sys.time(), "%Y-%m-%dT%H:%M:%SZ", tz = "UTC")
  json <- function(x) jsonlite::toJSON(x, auto_unbox = TRUE, pretty = TRUE, null = "null", digits = NA)
  staged_receipt <- file.path(stage, "extdata", "manifests", "cache-reader-compatibility.json")
  writeLines(json(receipt), staged_receipt)
  invisible(lapply(keys, reader$load_or_compute))
  # Reject metadata/source changes made while validation was running.
  .cache_assert_compatibility_sources(root, receipt)
  receipt$validated_at <- format(Sys.time(), "%Y-%m-%dT%H:%M:%SZ", tz = "UTC")
  output <- file.path(mp, "cache-reader-compatibility.json")
  writeLines(json(receipt), output)
  message("Validated 21 original cached assets for reader ", receipt$reader_package_version,
    "; original RDS/manifests unchanged; compatible_source_id ", receipt$compatible_source_id)
  invisible(receipt)
}
if (identical(Sys.getenv("POSTRANK_VALIDATE_CACHE_READER_COMPATIBILITY"), "true") && sys.nframe() == 0L) {
  suppressMessages(pkgload::load_all(".", quiet = TRUE, export_all = FALSE))
  validate_cache_reader_compatibility()
}
