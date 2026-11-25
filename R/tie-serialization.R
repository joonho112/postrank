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

#' Read a Tie-Aware Posterior Input from JSON
#'
#' `read_postrank_tie_draws()` reads a `"tie-aware-input-0.1"` JSON file into a
#' validated `postrank_tie_draws` object for tie-aware mode (the workflow for
#' posteriors in which distinct entities can be equal with positive probability
#' under equality-neutral loss, where true equality has zero loss). Files
#' written by [write_postrank_tie_draws()] round-trip with identical numerical
#' values, IDs, equality partitions, and `input_identity`.
#'
#' @param path Path to an existing `"tie-aware-input-0.1"` JSON file.
#' @return A validated `postrank_tie_draws` object from
#'   [as_postrank_tie_draws()].
#' @details
#' Supports both `input_kind = "equal_weight_draws"` (joint IID or MCMC draws,
#' preserving singleton criterion axes when `K = 1`) and
#' `"exact_finite_posterior"` (which requires optional package `gmp`). Before
#' floating-point conversion, `read_postrank_tie_draws()` scans the raw JSON
#' structure against `inst/schema/tie-draws-schema.json`, rejecting duplicate
#' object keys, malformed array shapes, and integer tokens outside safe-integer
#' range (`2^53 - 1`), and then runs [as_postrank_tie_draws()].
#'
#' Use [read_postrank_draws()] for ordinary zero-equality inputs; this reader
#' does not convert ordinary inputs or treat rounded continuous draws as a valid
#' equality model. Schema and R validation do not verify scientific equality or
#' MCMC convergence.
#' @seealso [write_postrank_tie_draws()], [as_postrank_tie_draws()],
#'   [read_postrank_draws()]
#' @concept tie-aware
#' @examplesIf requireNamespace("gmp", quietly = TRUE)
#' path <- system.file("examples", "synthetic-tie-aware.json", package = "postrank")
#' input <- read_postrank_tie_draws(path)
#' input$criterion_ids
#' input$equality$criterion_classes
#' validate_postrank_tie_draws(input)
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

#' Write a Tie-Aware Posterior Input to JSON
#'
#' `write_postrank_tie_draws()` validates and writes a tie-aware posterior input
#' (for posteriors with positive probability of exact equality under
#' equality-neutral loss) to a `"tie-aware-input-0.1"` JSON file readable by
#' [read_postrank_tie_draws()].
#'
#' @param x A plain `"tie-aware-input-0.1"` named list or an unmodified
#'   `postrank_tie_draws` object.
#' @param path Destination JSON file path; `dirname(path)` must already exist.
#' @param overwrite Logical scalar (`FALSE` by default). When `FALSE`, stops
#'   with an error if `path` already exists.
#' @return `path`, invisibly.
#' @details
#' Re-runs [as_postrank_tie_draws()] before writing, formats numbers to 17
#' significant digits while retaining all entities, singleton dimensions,
#' sampling histories, and criterion equality partitions, validates the JSON
#' output against `inst/schema/tie-draws-schema.json`, and writes to a temporary
#' file in `dirname(path)` before renaming into place. Modified
#' `postrank_tie_draws` objects fail validation rather than being written. Use
#' [write_postrank_draws()] for ordinary zero-equality inputs.
#' @seealso [read_postrank_tie_draws()], [validate_postrank_tie_draws()],
#'   [write_postrank_draws()]
#' @concept tie-aware
#' @examplesIf requireNamespace("gmp", quietly = TRUE)
#' input <- read_postrank_tie_draws(
#'   system.file("examples", "synthetic-tie-aware.json", package = "postrank")
#' )
#' path <- tempfile(fileext = ".json")
#' write_postrank_tie_draws(input, path)
#' restored <- read_postrank_tie_draws(path)
#' identical(restored$input_identity, input$input_identity)
#' identical(restored$equality, input$equality)
#' unlink(path)
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
