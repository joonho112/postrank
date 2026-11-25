# Explicit maintainer validation, with no solves and no ordinary-read writes.
# From the package source root, after source metadata is final:
# POSTRANK_VALIDATE_CACHE_READER_COMPATIBILITY=true Rscript inst/scripts/validate-cache-reader-compatibility.R
# Sourcing this file only defines functions. The authoring function requires the same flag
# and an already loaded candidate of the matching version. It never rebinds that namespace.
# The original 1.1.0 data files and manifests must be byte-identical. An original R file, or
# inst/scripts/build-cached-assets.R, may differ in bytes only when its code is unchanged:
# its code hash (comments and roxygen are not part of the parse result) must equal the entry
# in inst/extdata/manifests/origin-code-manifest.json, made from the unmodified 1.1.0 bytes.
.cache_compatibility_files <- function(root) {
  sort(c("DESCRIPTION", "LICENSE", "inst/extdata/case-studies/DATA-NOTICE.md",
    paste0("R/", list.files(file.path(root, "R"), "\\.R$")),
    paste0("data/", list.files(file.path(root, "data"), "\\.rda$")),
    paste0("inst/scripts/", list.files(file.path(root, "inst", "scripts"), "\\.R$"))), method = "radix")
}
.cache_compatibility_sha <- function(path) digest::digest(file = path, algo = "sha256")
.cache_code_sha <- function(path) tryCatch({
  exprs <- parse(path, keep.source = FALSE, encoding = "UTF-8")
  txt <- unlist(lapply(exprs, deparse, width.cutoff = 500L,
    control = c("keepInteger", "showAttributes", "keepNA", "niceNames", "hexNumeric")))
  digest::digest(paste(txt, collapse = "\n"), algo = "sha256", serialize = FALSE)
}, error = function(e) NA_character_)
# Code hashes of the original files, or NULL when the code manifest does not match the origin manifest.
.cache_origin_code <- function(path, src) {
  code <- jsonlite::read_json(path)
  origin <- Filter(function(e) startsWith(e$path, "R/") || identical(e$path, "inst/scripts/build-cached-assets.R"), src$entries)
  if (!identical(code$manifest_schema_version, "1") || !identical(code$origin_source_id, src$source_id) ||
      !identical(vapply(code$entries, `[[`, "", "path"), vapply(origin, `[[`, "", "path")) ||
      !identical(vapply(code$entries, `[[`, "", "origin_sha256"), vapply(origin, `[[`, "", "sha256"))) return(NULL)
  stats::setNames(vapply(code$entries, `[[`, "", "code_sha256"), vapply(code$entries, `[[`, "", "path"))
}
.cache_code_unchanged <- function(root, path, code) !is.na(code[path]) && identical(.cache_code_sha(file.path(root, path)), code[[path]])
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
  code_path <- file.path(mp, "origin-code-manifest.json")
  check(file.exists(code_path) && identical(.cache_compatibility_sha(code_path), receipt$origin_code_manifest_sha256), "origin_code_manifest_sha256")
  code <- .cache_origin_code(code_path, src)
  check(!is.null(code), "origin code manifest entries")
  fixed <- Filter(function(e) startsWith(e$path, "R/") || startsWith(e$path, "data/"), src$entries)
  check(sum(startsWith(vapply(fixed, `[[`, "", "path"), "R/")) == 96L &&
    sum(startsWith(vapply(fixed, `[[`, "", "path"), "data/")) == 8L, "96 original R and eight data paths")
  check(identical(vec(receipt$unchanged_origin_paths), unname(vapply(fixed, `[[`, "", "path"))), "unchanged_origin_paths")
  # Data must keep their bytes; original R files must keep their bytes or their code.
  check(all(vapply(fixed, function(e) identical(.cache_compatibility_sha(file.path(root, e$path)), e$sha256) ||
    .cache_code_unchanged(root, e$path, code), TRUE)), "unchanged original R/data hashes")
  changed <- vapply(Filter(function(e) !identical(.cache_compatibility_sha(file.path(root, e$path)), e$sha256), src$entries), `[[`, "", "path")
  check(identical(unname(changed), vec(receipt$allowed_origin_differences)), "allowed_origin_differences")
  comment_only <- changed[vapply(changed, function(p) .cache_code_unchanged(root, p, code), TRUE)]
  check(identical(unname(comment_only), as.character(vec(receipt$comment_only_origin_differences))), "comment_only_origin_differences")
  permitted <- c("DESCRIPTION", "LICENSE", "inst/scripts/_vignette-setup.R", "inst/extdata/case-studies/DATA-NOTICE.md")
  check(all(changed %in% c(permitted, comment_only)), "unapproved original source change")
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
  # Code identities of the unmodified original files, recorded once for 1.3.0 (see the header).
  code_path <- file.path(mp, "origin-code-manifest.json")
  origin_code <- "10f53b481ba55cbafb6c99999fb9b32773b631babb1e16e3e9f0f14b6c746ddb"
  if (!file.exists(code_path) || !identical(sha(code_path), origin_code))
    stop("Original code manifest bytes changed; compatibility cannot be sealed", call. = FALSE)
  man <- jsonlite::read_json(man_path); src <- jsonlite::read_json(src_path)
  code <- .cache_origin_code(code_path, src)
  if (is.null(code)) stop("Original code manifest does not match the origin source manifest", call. = FALSE)
  paths <- .cache_compatibility_files(root)
  entries <- lapply(paths, function(p) list(path = p, sha256 = sha(file.path(root, p))))
  origin_paths <- vapply(src$entries, `[[`, "", "path")
  fixed <- origin_paths[startsWith(origin_paths, "R/") | startsWith(origin_paths, "data/")]
  changed <- vapply(Filter(function(e) !identical(sha(file.path(root, e$path)), e$sha256), src$entries), `[[`, "", "path")
  comment_only <- changed[vapply(changed, function(p) .cache_code_unchanged(root, p, code), TRUE)]
  receipt <- list(compatibility_schema_version = "1",
    reader_package_version = as.character(read.dcf(file.path(root, "DESCRIPTION"))[1L, "Version"]),
    origin_package_version = man$package_version, origin_source_id = src$source_id,
    origin_cache_manifest_sha256 = origin_cache, origin_source_manifest_sha256 = origin_source,
    compatible_source_id = .cache_compatibility_id(entries), compatible_source_entries = entries,
    unchanged_origin_paths = unname(fixed), allowed_origin_differences = unname(changed),
    origin_code_manifest_sha256 = origin_code, comment_only_origin_differences = unname(comment_only),
    source_comparison = paste("Original data files and the 1.1.0 manifests are byte-identical. Original R files and",
      "inst/scripts/build-cached-assets.R are byte-identical or differ only in comments: their code hash equals",
      "origin-code-manifest.json. Other original differences are limited to DESCRIPTION, LICENSE, DATA-NOTICE.md",
      "and the reader inst/scripts/_vignette-setup.R."),
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
  # Validate every stored asset with the reader's validator first, without writing files,
  # before writing the compatibility manifest to a staging directory.
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
