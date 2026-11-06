.pr_tie_serialization_schema <- function() {
  path <- ""
  if (!isNamespace(environment(.pr_tie_serialization_schema))) {
    candidates <- file.path(c(".", "..", "../.."), "inst/schema/tie-draws-schema.json")
    found <- candidates[file.exists(candidates)]
    if (length(found)) path <- found[[1L]]
  }
  if (!nzchar(path)) path <- system.file("schema", "tie-draws-schema.json", package = "postrank")
  if (!nzchar(path)) .pr_abort("tie-aware serialization schema unavailable", "schema_unavailable")
  jsonlite::fromJSON(path, simplifyVector = FALSE)
}

.pr_tie_json_bind <- function(x) {
  x <- .pr_json_bind_payload(x)
  classes <- x$equality$criterion_classes
  if (!is.null(classes)) {
    .pr_fields(classes, x$criterion_ids, path = "$.equality.criterion_classes")
    x$equality$criterion_classes <- lapply(classes, function(z) {
      .pr_fields(z, x$entity_ids, path = "$.equality.criterion_classes")
      .pr_assert(all(vapply(z, function(a) is.character(a) && length(a) == 1L && is.null(dim(a)), logical(1L))),
        "class labels must be JSON strings", "invalid_json_type", "$.equality.criterion_classes")
      unlist(z, use.names = TRUE)
    })
  }
  x
}

.pr_tie_json_unbind <- function(x) {
  x <- .pr_json_unbind_payload(x)
  if (!is.null(x$equality$criterion_classes))
    x$equality$criterion_classes <- lapply(x$equality$criterion_classes, as.list)
  x
}

#' Read an Equality-Neutral Posterior Input from JSON
#'
#' The reader imports posterior values, declarations of genuine equality and
#' original source histories for a tie-aware analysis. Files produced by
#' [write_postrank_tie_draws()] preserve the numerical targets and IDs.
#'
#' @param path Path to an existing `tie-aware-input-0.1` JSON file.
#' @return A validated `postrank_tie_draws` from [as_postrank_tie_draws()].
#' @details
#' The reader supports joint equal-weight IID/MCMC draws and complete exact
#' finite laws. It preserves the `K = 1` criterion axis and performs no target
#' transformation. It does not convert ordinary inputs or reinterpret rounded
#' continuous values as a scientific equality model.
#'
#' Duplicate decoded keys, malformed supported array shapes and unsafe
#' finite-law integer tokens are rejected before floating conversion. Shape
#' checks cover the supported JSON binding; the R validator checks the
#' corresponding metadata, values and equality partition. These checks do not
#' verify scientific equality, jointness or convergence. Complete finite laws
#' require the optional `gmp` package.
#' @seealso [write_postrank_tie_draws()], [as_postrank_tie_draws()],
#'   [read_postrank_draws()]
#' @concept tie-aware
#' @examples
#' if (requireNamespace("gmp", quietly = TRUE)) {
#'   path <- system.file("examples", "synthetic-tie-aware.json", package = "postrank")
#'   input <- read_postrank_tie_draws(path)
#'   input$criterion_ids
#'   input$equality$criterion_classes
#'   validate_postrank_tie_draws(input)
#' }
#' @export
read_postrank_tie_draws <- function(path) {
  .pr_string(path, "$.path")
  .pr_assert(file.exists(path) && !dir.exists(path), "JSON file does not exist", "input_file_missing", path)
  text <- paste(readLines(path, warn = FALSE, encoding = "UTF-8"), collapse = "\n")
  node <- .pr_tie_json_scan(text); schema <- .pr_tie_serialization_schema()
  .pr_json_shape_guard(node, schema, schema)
  x <- tryCatch(jsonlite::fromJSON(text, simplifyVector = FALSE),
    error = function(e) .pr_abort(conditionMessage(e), "invalid_json"))
  x <- .pr_tie_json_restore_numbers(x, node)
  as_postrank_tie_draws(.pr_tie_json_bind(x))
}

#' Save an Equality-Neutral Posterior Input as JSON
#'
#' The writer stores a tie-aware input with its numerical values, target
#' definitions and equality classes. The file can be read by
#' [read_postrank_tie_draws()] with all entities and their original order
#' retained.
#'
#' @param x A complete canonical `tie-aware-input-0.1` payload or an unchanged
#'   `postrank_tie_draws` object.
#' @param path Destination JSON file; its parent directory must exist.
#' @param overwrite Logical; allow replacement of an existing file.
#'   Defaults to `FALSE`.
#' @return The destination path, invisibly.
#' @details
#' Validation is repeated before writing. Values use 17 significant digits;
#' all entities, singleton dimensions, sampling histories and named criterion
#' equality partitions are retained. A temporary file in the destination
#' directory is renamed into place after the supported JSON checks pass.
#'
#' The file stores the canonical input, not a claim of scientific verification.
#' Reading it repeats validation and recreates its content identity. Changed
#' objects fail validation rather than being silently accepted. Use
#' [write_postrank_draws()] for the ordinary zero-equality input domain.
#' @seealso [read_postrank_tie_draws()], [validate_postrank_tie_draws()]
#' @concept tie-aware
#' @examples
#' if (requireNamespace("gmp", quietly = TRUE)) {
#'   input <- read_postrank_tie_draws(system.file("examples", "synthetic-tie-aware.json",
#'     package = "postrank"))
#'   path <- tempfile(fileext = ".json")
#'   write_postrank_tie_draws(input, path)
#'   restored <- read_postrank_tie_draws(path)
#'   identical(restored$input_identity, input$input_identity)
#'   identical(restored$equality, input$equality)
#'   unlink(path)
#' }
#' @export
write_postrank_tie_draws <- function(x, path, overwrite = FALSE) {
  .pr_string(path, "$.path")
  .pr_assert(is.logical(overwrite) && length(overwrite) == 1L && !is.na(overwrite),
    "overwrite must be TRUE or FALSE")
  if (file.exists(path) && !overwrite) .pr_abort("output already exists; set overwrite=TRUE explicitly", "output_exists", path)
  .pr_assert(dir.exists(dirname(path)), "output directory does not exist", "output_directory_missing", path)
  source <- as_postrank_tie_draws(x)
  tree <- .pr_tie_json_unbind(.pr_tie_input_payload(source))
  text <- as.character(jsonlite::toJSON(tree, auto_unbox = TRUE, null = "null", na = "null", digits = 17, pretty = TRUE))
  schema <- .pr_tie_serialization_schema()
  .pr_json_shape_guard(.pr_tie_json_scan(text), schema, schema)
  temp <- tempfile(".postrank-tie-json-", tmpdir = dirname(path)); on.exit(unlink(temp), add = TRUE)
  writeLines(text, temp, useBytes = TRUE)
  .pr_assert(file.rename(temp, path), "atomic JSON replacement failed", "output_write_failed", path)
  invisible(path)
}
