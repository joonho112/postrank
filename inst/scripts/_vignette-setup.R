# Reader of the sealed example assets. Vignettes source it with
#   source(system.file("scripts", "_vignette-setup.R", package = "postrank"), local = TRUE)
# load_or_compute() is not exported. It validates exact origin and reader versions, the
# installed source/cache manifests, the asset file bytes and SHA-256, the timestamp and the
# data/input identities, restores a stubbed bundled input losslessly and runs the class
# validators. It never writes, repairs or recomputes in ordinary reading. Only live = TRUE
# evaluates the caller's explicitly selected backend expression, after cache validation, and
# reports both results; it never retries with another backend. Cross-version reads require
# a separately sealed compatibility receipt; original computation provenance is unchanged.
`%||%` <- function(x, y) if (is.null(x)) y else x
.cache_source_id <- function(entries) digest::digest(paste(vapply(entries,
  function(e) paste0(e$path, "\t", e$sha256), ""), collapse = "\n"), algo = "sha256", serialize = FALSE)
.cache_asset_value <- function(key, rec, fail, pkg = "postrank") {
  if (!grepl("^[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}Z$", rec$created_at %||% "") ||
      is.na(as.POSIXct(rec$created_at, format = "%Y-%m-%dT%H:%M:%SZ", tz = "UTC"))) fail("created_at", "invalid UTC timestamp")
  path <- system.file(rec$file, package = pkg)
  if (!nzchar(path)) fail("file", "asset file missing")
  if (!identical(as.numeric(file.size(path)), as.numeric(rec$bytes))) fail("bytes", "asset byte count differs")
  if (!identical(digest::digest(file = path, algo = "sha256"), rec$sha256)) fail("sha256", "asset digest differs")
  env <- readRDS(path)
  if (!is.list(env) || !identical(names(env), c("value", "metadata")) || !identical(env$metadata$key, key)) fail("envelope", "malformed asset envelope")
  value <- env$value
  ns <- asNamespace(pkg)
  if (is.list(value$input) && isTRUE(value$input$postrank_cache_stub)) {
    holder <- new.env()
    utils::data(list = value$input$data_object, package = pkg, envir = holder)
    original <- get(value$input$data_object, envir = holder)
    if (!identical(ns$.pr_input_identity_of(original), value$input$input_identity)) fail("input_identity", "bundled data identity differs from the stub")
    value$input <- original
  }
  if (!identical(class(value)[1L], rec$object_class)) fail("object_class", "asset class differs")
  if (inherits(value, "postrank_analysis")) ns$.pr_validate_analysis(value)
  if (inherits(value, "postrank_fit")) ns$.pr_validate_problem(value$problem)
  if (inherits(value, "postrank_comparison")) ns$.pr_validate_comparison(value)
  value
}
.cache_receipt_gate <- function(receipt, man, src, man_path, src_path, version, fail) {
  if (!identical(digest::digest(file = man_path, algo = "sha256"), receipt$origin_cache_manifest_sha256))
    fail("origin_cache_manifest_sha256", "origin cache manifest bytes differ from the compatibility receipt")
  if (!identical(digest::digest(file = src_path, algo = "sha256"), receipt$origin_source_manifest_sha256))
    fail("origin_source_manifest_sha256", "origin source manifest bytes differ from the compatibility receipt")
  if (!identical(.cache_source_id(receipt$compatible_source_entries), receipt$compatible_source_id))
    fail("compatible_source_id", "reader source inventory is inconsistent")
  reader <- system.file("scripts", "_vignette-setup.R", package = "postrank")
  if (!nzchar(reader) || !identical(digest::digest(file = reader, algo = "sha256"), receipt$reader_sha256))
    fail("reader_sha256", "installed reader differs from the compatibility receipt")
  checks <- receipt$validation$assets
  keys <- sort(names(man$assets), method = "radix")
  if (!identical(receipt$validation$status, "complete") || !identical(names(checks), keys) ||
      !all(vapply(keys, function(k) identical(checks[[k]]$object_class, man$assets[[k]]$object_class) &&
        identical(checks[[k]]$sha256, man$assets[[k]]$sha256) && isTRUE(checks[[k]]$reader_validated), TRUE)))
    fail("validation", "compatibility validation is incomplete")
  invisible(TRUE)
}
load_or_compute <- function(key, expr = NULL, live = FALSE) {
  stopifnot(is.character(key), length(key) == 1L, is.logical(live), length(live) == 1L)
  fail <- function(field, msg) stop(sprintf("cached asset '%s': %s (%s). Rebuild with POSTRANK_BUILD_CACHED_ASSETS=true Rscript inst/scripts/build-cached-assets.R",
    key, msg, field), call. = FALSE)
  pkg <- "postrank"
  man_path <- system.file("extdata", "manifests", "cache-manifest.json", package = pkg)
  src_path <- system.file("extdata", "manifests", "source-manifest.json", package = pkg)
  if (!nzchar(man_path) || !nzchar(src_path)) fail("manifest", "installed cache/source manifest missing")
  man <- jsonlite::read_json(man_path); src <- jsonlite::read_json(src_path)
  version <- as.character(utils::packageVersion(pkg))
  if (!identical(man$manifest_schema_version, "1") || !identical(src$manifest_schema_version, "1")) fail("manifest_schema_version", "unsupported manifest schema")
  if (!identical(man$package_version, src$package_version)) fail("package_version", "cache/source manifest versions differ")
  receipt <- NULL
  if (!identical(man$package_version, version)) {
    receipt_path <- system.file("extdata", "manifests", "cache-reader-compatibility.json", package = pkg)
    if (!nzchar(receipt_path)) fail("package_version", "another origin version requires a compatibility receipt")
    receipt <- jsonlite::read_json(receipt_path)
    if (!identical(receipt$compatibility_schema_version, "1")) fail("compatibility_schema_version", "unsupported compatibility receipt schema")
    if (!identical(receipt$reader_package_version, version)) fail("reader_package_version", "compatibility receipt names another reader version")
    if (!identical(receipt$origin_package_version, man$package_version)) fail("package_version", "compatibility receipt names another origin version")
  }
  recomputed <- .cache_source_id(src$entries)
  if (!identical(recomputed, src$source_id) || !identical(man$source_id, src$source_id)) fail("source_id", "source manifest inconsistent")
  if (!is.null(receipt) && !identical(receipt$origin_source_id, src$source_id)) fail("origin_source_id", "compatibility receipt names another origin source")
  rec <- man$assets[[key]]
  if (is.null(rec)) fail("key", "no such cached asset")
  if (!identical(rec$source_id, src$source_id) || !identical(rec$package_version, man$package_version) || !identical(rec$cache_schema_version, "1"))
    fail("asset metadata", "asset version, schema or source ID mismatch")
  value <- .cache_asset_value(key, rec, fail, pkg)
  if (!is.null(receipt)) .cache_receipt_gate(receipt, man, src, man_path, src_path, version, fail)
  if (isTRUE(live)) {
    if (missing(expr)) stop("live = TRUE needs an explicit expression with an explicitly selected backend", call. = FALSE)
    fresh <- eval(substitute(expr), parent.frame())
    attr(value, "live_comparison") <- asNamespace(pkg)$.pr_live_comparison(value, fresh)
  }
  value
}
# One sentence naming the source of a cached result, read from the installed cache manifest:
# key, package version, explicitly selected backend and version, UTC build time, solves, status.
cache_note <- function(key) {
  man <- jsonlite::read_json(system.file("extdata", "manifests", "cache-manifest.json", package = "postrank", mustWork = TRUE))
  rec <- man$assets[[key]]
  if (is.null(rec)) stop(sprintf("cached asset '%s': no such cached asset (key)", key), call. = FALSE)
  note <- sprintf("Cached asset `%s`: built by the maintainer with postrank %s and the explicitly selected %s backend (version %s) at %s; %d solve%s%s. Reading it here solves nothing.",
    key, rec$package_version, rec$backend, rec$backend_version %||% "NA", rec$created_at, as.integer(rec$solves),
    if (identical(as.integer(rec$solves), 1L)) "" else "s",
    if (is.null(rec$status)) "" else paste0(", recorded status ", rec$status))
  if (!is.null(rec$data_distribution)) note <- paste(note,
    sprintf("Case data: %s; source conditions, attribution and modification notices are recorded in the installed DATA-NOTICE.md and case provenance.", rec$data_distribution))
  note
}
