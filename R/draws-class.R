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
#' `validate_postrank_draws()` checks whether a `postrank_draws` object or an
#' `applied-0.1` input list satisfies `postrank`'s structural, numeric and
#' description requirements, returning a report rather than stopping on an
#' invalid input.
#'
#' @param x A `postrank_draws` object or an `applied-0.1` named list.
#' @param source Reserved; leave `NULL` (any non-`NULL` value stops with
#'   `unsupported_source_audit`). To check values against a `posterior` package
#'   object, use [as_postrank_posterior()].
#' @returns A `postrank_validation` list with components:
#'   * `valid`: `TRUE` if all R structural and semantic checks passed, `FALSE`
#'     otherwise;
#'   * `issues`: empty list when `valid` is `TRUE`, otherwise a list containing
#'     the error `code`, `path`, `message` and `severity`;
#'   * `semantic_checks_completed`: check IDs `"DC01"` through `"DC15"` when
#'     `valid` is `TRUE`, otherwise `character()`;
#'   * `eligible_functional`, `input_identity`, `validator_version`,
#'     `check_results` and `limitations`;
#'   * `schema_checked` (`FALSE`), `source_values_checked`,
#'     `jointness_verified` (`FALSE`) and `convergence_verified` (`FALSE`).
#' @details
#' The checks verify axis order, entity and criterion IDs, target and source
#' descriptions, finite numeric values, absence of within-criterion ties, and
#' MCMC chain-history consistency. They do not run an external Draft 2020-12
#' JSON Schema validator (`schema_checked` is always `FALSE`), and they do not
#' apply the placeholder-word list of [postrank_declarations()].
#'
#' `source_values_checked` is `TRUE` only when `x` is an unchanged
#' `postrank_draws` object created by [as_postrank_posterior()], in which case
#' `source_audit` is also retained. `valid = TRUE` means the input's structure
#' and required descriptions are complete; it does not verify scientific
#' identification, joint sampling or MCMC convergence. For exact-tie inputs,
#' see [validate_postrank_tie_draws()], which uses a different return format.
#' @seealso [as_postrank_draws()], [postrank_draws()], [as_postrank_posterior()]
#' @concept input
#' @examples
#' check <- validate_postrank_draws(postrank_toy)
#' check$valid
#' check[c("source_values_checked", "jointness_verified", "convergence_verified")]
#'
#' # Omit required context to inspect the reported issue without throwing an error:
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
#' `as_postrank_draws()` validates a complete `applied-0.1` posterior input
#' list (or revalidates an existing `postrank_draws` object) and returns a
#' `postrank_draws` object. Use it when constructing separate criterion-wise
#' draw blocks, an exact finite posterior law, or custom MCMC draw histories;
#' for an ordinary numeric array of joint draws, [postrank_draws()] with
#' [postrank_describe()] is simpler.
#'
#' @param x A complete `applied-0.1` named list, or an existing
#'   `postrank_draws` object to revalidate.
#' @returns A `postrank_draws` object storing the input fields in their
#'   declared order, `input_schema_version` (`"applied-0.1"`), `schema_version`
#'   (`"0.1.0"`), and a `validation` record from [validate_postrank_draws()].
#'   Invalid input stops with the first reported issue (`code`, `path` and
#'   `message`).
#' @details
#' Three posterior forms are accepted:
#' * `joint_draws`: equal-weight IID or MCMC draws in an `S x n x K` array
#'   (keeping `S x n x 1` when `K = 1`), with MCMC chain IDs, iteration numbers
#'   and warmup/thinning history;
#' * `criterion_blocks`: separate equal-weight `S_k x n` matrices per
#'   criterion, preserving joint entity states within each criterion without
#'   specifying dependence across criteria;
#' * `finite_law`: an exact discrete posterior listing every positive-mass
#'   state with safe-integer target values and positive integer probability
#'   numerators summing to a common denominator (not a Monte Carlo sample;
#'   evaluating it with [postrank_pairwise()] requires the optional `gmp`
#'   package).
#'
#' Values must already be oriented so that larger values mean higher priority.
#' Distinct entities must have zero probability of exact equality within each
#' criterion, and observed ties stop the call; for posteriors with positive
#' probability on ties, use [as_postrank_tie_draws()]. Required descriptions
#' are checked for structure and non-empty text without the placeholder-word
#' list of [postrank_declarations()].
#' @seealso [postrank_draws()], [postrank_describe()], [read_postrank_draws()],
#'   [validate_postrank_draws()],
#'   `vignette("m3-posterior-inputs", package = "postrank")`
#' @concept input
#' @examples
#' # Build a complete synthetic two-criterion input list from the bundled script:
#' generator <- new.env()
#' sys.source(system.file("examples", "make-synthetic-input.R",
#'   package = "postrank"), envir = generator)
#' input_list <- generator$make_postrank_synthetic_input()
#' draws <- as_postrank_draws(input_list)
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
