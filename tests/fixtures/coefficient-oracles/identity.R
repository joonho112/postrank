# Narrow, versioned content identities. No universal R-object serialization.
.identity_fail <- function(message) stop(paste0("Main identity: ", message), call. = FALSE)

.identity_plain <- function(x, label, list_names = FALSE) {
  attrs <- names(attributes(x))
  allowed <- if (list_names) "names" else character()
  if (length(setdiff(attrs, allowed))) .identity_fail(paste(label, "has unsupported attributes"))
  invisible(TRUE)
}

.identity_string <- function(x, label, scalar = TRUE) {
  .identity_plain(x, label)
  if (!is.character(x) || !length(x) || (scalar && length(x) != 1L) ||
      anyNA(x) || any(!nzchar(x)) || anyNA(iconv(x, to = "UTF-8"))) {
    .identity_fail(paste(label, "must be nonempty valid UTF-8 character values"))
  }
  invisible(TRUE)
}

.identity_sha <- function(x, label) {
  .identity_string(x, label)
  if (!grepl("^[0-9a-f]{64}$", x)) .identity_fail(paste(label, "must be a lowercase SHA256 digest"))
  invisible(TRUE)
}

.identity_spec <- function(kind) {
  .identity_string(kind, "kind")
  required <- switch(kind,
    dataset = "dgp_id",
    posterior = c("dataset_id", "arm", "producer_version"),
    coefficients = c("posterior_id", "coefficient_version", "means_sha256", "pairwise_sha256"),
    action = c("coefficients_id", "setting_id", "method"),
    request = c("coefficients_id", "setting_id", "method"),
    .identity_fail("unknown kind"))
  optional <- switch(kind,
    dataset = c("replicate_id", "seed_key", "generator_version"),
    posterior = c("model_sha256", "hyperdraws_sha256", "posterior_version"),
    coefficients = character(),
    action = c("request_id", "weights", "tau", "G_max"),
    request = c("weights", "tau", "G_max", "solver_policy_sha256"))
  list(required = c("source_sha256", "config_sha256", "entity_ids", "criterion_ids", required),
       optional = c("code_sha256", "n", "K", optional))
}

.identity_metadata <- function(metadata, kind) {
  .identity_plain(metadata, "metadata", list_names = TRUE)
  if (!is.list(metadata) || is.null(names(metadata)) || anyNA(names(metadata)) ||
      any(!nzchar(names(metadata))) || anyDuplicated(names(metadata))) {
    .identity_fail("metadata must be a uniquely named plain list")
  }
  spec <- .identity_spec(kind)
  if (length(setdiff(spec$required, names(metadata)))) .identity_fail("metadata is missing required fields")
  if (length(setdiff(names(metadata), c(spec$required, spec$optional)))) .identity_fail("metadata has unknown fields")
  for (field in names(metadata)) {
    x <- metadata[[field]]
    .identity_plain(x, paste("metadata", field))
    if (grepl("_sha256$", field)) {
      .identity_sha(x, field)
    } else if (field %in% c("entity_ids", "criterion_ids")) {
      .identity_string(x, field, scalar = FALSE)
      if (anyDuplicated(x)) .identity_fail(paste(field, "must have unique ordered axis IDs"))
    } else if (field %in% c("n", "K", "replicate_id", "G_max", "weights", "tau")) {
      if (!typeof(x) %in% c("integer", "double") || !length(x) || anyNA(x) || any(!is.finite(x)) ||
          (field != "weights" && length(x) != 1L)) {
        .identity_fail(paste(field, "must contain finite numeric values"))
      }
      if (field %in% c("n", "K", "replicate_id", "G_max") &&
          (x < 1 || x != floor(x))) .identity_fail(paste(field, "must be a positive integer"))
      if (field == "tau" && x < 0) .identity_fail("tau must be nonnegative")
      if (field == "weights" && (length(x) != length(metadata$criterion_ids) ||
          any(x < 0) || abs(sum(x) - 1) > 1e-12)) .identity_fail("weights must match criterion axes and sum to one")
    } else {
      .identity_string(x, field)
    }
  }
  if (!is.null(metadata$n) && metadata$n != length(metadata$entity_ids)) .identity_fail("n disagrees with entity_ids")
  if (!is.null(metadata$K) && metadata$K != length(metadata$criterion_ids)) .identity_fail("K disagrees with criterion_ids")
  if (kind == "posterior" && !metadata$arm %in%
      c("known_correct", "known_omit", "learned_correct", "learned_omit")) {
    .identity_fail("arm must identify an explicit known/learned by correct/omit arm")
  }
  metadata[sort(names(metadata), method = "radix")]
}

.identity_version <- function(schema_version) {
  .identity_plain(schema_version, "schema_version")
  if (!typeof(schema_version) %in% c("integer", "double") || length(schema_version) != 1L ||
      is.na(schema_version) || !is.finite(schema_version) || schema_version != 1) {
    .identity_fail("unsupported schema_version")
  }
  1L
}

.identity_encode <- function(x) {
  # JSON's usual decimal formatting can collapse adjacent binary64 numbers.
  # Encode each number by its exact big-endian IEEE binary64 bytes instead.
  if (is.numeric(x)) {
    value <- vapply(x, function(value) {
      if (value == 0) value <- 0 # Deliberately identify -0 and +0.
      paste(sprintf("%02x", as.integer(writeBin(as.double(value), raw(),
            size = 8L, endian = "big"))), collapse = "")
    }, character(1), USE.NAMES = FALSE)
    list(type = "number_binary64", value = value)
  } else {
    list(type = "string", value = enc2utf8(x))
  }
}

.identity_digest <- function(kind, metadata, payload_sha256, schema_version) {
  object <- list(schema = "p1-main-content-identity", schema_version = as.character(schema_version),
                 kind = kind, metadata = lapply(metadata, .identity_encode), payload_sha256 = payload_sha256)
  encoded <- as.character(jsonlite::toJSON(object, auto_unbox = FALSE,
                                          pretty = FALSE, null = "null"))
  digest::digest(enc2utf8(encoded), algo = "sha256", serialize = FALSE)
}

#' Construct a versioned identity binding explicit metadata and payload SHA256.
#' request means a decision request, not an input-generation or planning request.
main_identity <- function(kind, metadata, payload_sha256, schema_version = 1L) {
  schema_version <- .identity_version(schema_version)
  .identity_sha(payload_sha256, "payload_sha256")
  metadata <- .identity_metadata(metadata, kind)
  list(schema = "p1-main-content-identity", schema_version = schema_version,
       kind = kind, metadata = metadata, payload_sha256 = payload_sha256,
       identity_sha256 = .identity_digest(kind, metadata, payload_sha256, schema_version))
}

#' Check a stored identity without overwriting its digest or blessing mutations.
validate_main_identity <- function(x) {
  .identity_plain(x, "identity", list_names = TRUE)
  fields <- c("schema", "schema_version", "kind", "metadata", "payload_sha256", "identity_sha256")
  if (!is.list(x) || anyDuplicated(names(x)) || !setequal(names(x), fields)) {
    .identity_fail("identity has missing, duplicate or unknown fields")
  }
  .identity_string(x$schema, "schema")
  if (x$schema != "p1-main-content-identity") .identity_fail("unknown schema")
  .identity_sha(x$identity_sha256, "identity_sha256")
  expected <- main_identity(x$kind, x$metadata, x$payload_sha256, x$schema_version)
  if (!identical(x$identity_sha256, expected$identity_sha256)) .identity_fail("stale or mutated identity digest")
  invisible(TRUE)
}

#' SHA256 of exact bytes; arbitrary R objects are deliberately unsupported.
main_payload_sha256 <- function(bytes) {
  if (!is.raw(bytes)) .identity_fail("bytes must be a raw vector")
  .identity_plain(bytes, "bytes")
  digest::digest(bytes, algo = "sha256", serialize = FALSE)
}

#' SHA256 of exact file bytes, without parsing or loading file contents.
.identity_regular_file <- function(path) {
  .identity_string(path,"path")
  if(!requireNamespace("fs",quietly=TRUE)) .identity_fail("fs is required for a nonblocking regular-file type check")
  type<-tryCatch(as.character(fs::file_info(path,fail=FALSE,follow=FALSE)$type),error=function(e)NA_character_)
  if(!identical(type,"file")) .identity_fail("path must identify a regular file; symlinks and special files rejected before open")
  invisible(TRUE)
}
main_file_sha256 <- function(path) {
  .identity_string(path, "path")
  if (!file.exists(path) || dir.exists(path)) .identity_fail("path must identify an existing file")
  .identity_regular_file(path)
  digest::digest(file = path, algo = "sha256", serialize = FALSE)
}
