.pr_payload <- function(x) {
  if (inherits(x, "postrank_draws")) {
    x <- unclass(x); x$schema_version <- x$input_schema_version
    x$input_schema_version <- NULL; x$validation <- NULL
  }
  x
}
.pr_identity <- function(x) digest::digest(x, algo = "sha256", serialize = TRUE)

#' Check a Posterior Input and Inspect Its Validation Results
#'
#' The validator checks the target definitions, numerical values, axes and
#' sampling history required by the ordinary input routes. Its `valid` and
#' `issues` fields report whether the input meets those requirements.
#'
#' @param x A canonical `applied-0.1` named-list payload or a `postrank_draws`.
#' @param source Reserved; leave `NULL`. To compare mapped values with a
#'   `posterior` source object, use [as_postrank_posterior()].
#' @return A `postrank_validation` list with logical `valid`, an `issues` list
#'   of error codes, paths and messages, and separate check flags. Invalid
#'   payloads are reported in this record rather than constructed as inputs.
#' @details
#' The checks cover the supported structures, ordered IDs, target and source
#' declarations, numeric values, zero-tie policy and sampling history. They
#' do not change the values or perform a fit. The function does not run a
#' general JSON Schema validator, so `schema_checked` is `FALSE` even for a
#' valid R input. The additional placeholder-text checks of
#' [postrank_declarations()] are not applied here.
#'
#' `source_values_checked`, `jointness_verified` and `convergence_verified`
#' are separate from `valid`. Source-value comparison is retained only when
#' an existing object's successful [as_postrank_posterior()] audit matches
#' its current input identity. Structural validity does not establish the
#' scientific truth of the declarations, model adequacy or convergence.
#' The tie-aware validator has a different return convention; see
#' [validate_postrank_tie_draws()].
#' @seealso [as_postrank_draws()], [postrank_draws()], [as_postrank_posterior()]
#' @concept input
#' @examples
#' check <- validate_postrank_draws(postrank_toy)
#' check$valid
#' check[c("source_values_checked", "jointness_verified", "convergence_verified")]
#'
#' # Deliberately omit required context to inspect the reported problem.
#' bad <- postrank_toy
#' bad$context <- NULL
#' validate_postrank_draws(bad)$issues
#' @export
validate_postrank_draws <- function(x, source = NULL) {
  payload <- .pr_payload(x)
  issue <- tryCatch({.pr_validate_common(payload); NULL}, error = function(e) e)
  valid <- is.null(issue)
  receipt <- list(valid = valid, schema_checked = FALSE,
    semantic_checks_completed = if (valid) sprintf("DC%02d", 1:15) else character(),
    source_values_checked = FALSE, jointness_verified = FALSE, convergence_verified = FALSE,
    eligible_functional = if (valid) "expected_rank_loss" else NA_character_,
    input_identity = .pr_identity(payload), validator_version = "0.1.0",
    check_results = list(schema = "not_checked", semantics = if (valid) "passed" else "failed",
                         source_values = "not_checked", jointness = "not_checked", convergence = "not_checked"),
    issues = if (valid) list() else list(list(code = if (is.null(issue$code)) "invalid_input" else issue$code,
      path = if (is.null(issue$path)) "$" else issue$path, message = conditionMessage(issue), severity = "error")),
    limitations = c("Scientific declarations are checked for presence, not truth.",
      "R semantic checks do not execute a general Draft 2020-12 schema validator."))
  if (!is.null(source)) .pr_abort("source audit requires the explicit posterior adapter", "unsupported_source_audit")
  if (valid && inherits(x, "postrank_draws") && isTRUE(x$validation$source_values_checked) &&
      identical(x$validation$input_identity, receipt$input_identity)) {
    receipt$source_values_checked <- TRUE; receipt$check_results$source_values <- "passed"
    receipt$source_audit <- x$validation$source_audit
  }
  class(receipt) <- c("postrank_validation", "list"); receipt
}

#' Prepare a Fully Described Posterior Input
#'
#' A complete posterior description is validated and prepared for directional
#' comparisons. This constructor accepts the full producer-supplied metadata,
#' including an exact finite law or separate criterion-wise blocks. For a
#' numeric joint array, [postrank_draws()] constructs the metadata from
#' explicit scientific declarations.
#'
#' @param x A canonical `applied-0.1` named-list payload, or an existing
#'   `postrank_draws` to revalidate.
#' @return A `postrank_draws` object containing the supplied values in their
#'   declared order and a `validation` record. Invalid input raises a
#'   structured error containing its code, path and message.
#' @details
#' The supported forms are joint equal-weight IID or MCMC draws
#' (`joint_draws`), separate equal-weight criterion blocks (`criterion_blocks`),
#' and a complete exact finite posterior (`finite_law`). Every form records
#' entity/criterion IDs, target definitions, context, identification, the
#' zero-equality policy and provenance. Joint arrays retain all three axes,
#' including `S x n x 1` for a single criterion. Values must already be oriented
#' so that larger means higher priority.
#'
#' MCMC inputs retain original chain IDs, iteration numbers, warmup and
#' selection history. Criterion-wise blocks preserve joint entity states within
#' each criterion without specifying dependence across criteria. An exact
#' finite law specifies every positive-mass state, safe-integer target values
#' and positive integer mass numerators summing to a common denominator. Such a
#' law describes the complete posterior rather than a Monte Carlo sample; its
#' evaluation requires the optional `gmp` package.
#'
#' The ordinary input domain assumes zero probability of within-criterion
#' equality between distinct entities and rejects observed ties. Recover
#' unrounded continuous values or use [as_postrank_tie_draws()] for genuine
#' equality mass. Validation checks the structure and presence of declarations;
#' it cannot verify their scientific truth or convergence. The extra
#' placeholder checks of [postrank_declarations()] are not applied here.
#' See [validate_postrank_draws()] for the separate check flags.
#' @seealso [postrank_draws()], [read_postrank_draws()],
#'   [validate_postrank_draws()],
#'   `vignette("m3-posterior-inputs", package = "postrank")`
#' @concept input
#' @examples
#' # The bundled generator supplies a complete two-criterion canonical input.
#' # source() only defines this synthetic generator; it does not fit a model.
#' generator <- new.env()
#' sys.source(system.file("examples", "make-synthetic-input.R",
#'   package = "postrank"), envir = generator)
#' payload <- generator$make_postrank_synthetic_input()
#' draws <- as_postrank_draws(payload)
#' draws$criterion_ids
#' dim(draws$joint_draws$tensor$values)
#' @export
as_postrank_draws <- function(x) {
  receipt <- validate_postrank_draws(x)
  if (!receipt$valid) {
    e <- receipt$issues[[1L]]; .pr_abort(e$message, e$code, e$path)
  }
  payload <- .pr_payload(x); payload$input_schema_version <- payload$schema_version
  payload$schema_version <- "0.1.0"; payload$validation <- receipt
  class(payload) <- c("postrank_draws", "list"); payload
}
