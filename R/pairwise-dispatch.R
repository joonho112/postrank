#' Calculate Directional-Error Probabilities
#'
#' Posterior draws or a specified finite law are aggregated into comparison
#' probabilities for one or several criteria. For distinct entities,
#' \eqn{e_{ij,k}=P(\theta_{i,k}\leq\theta_{j,k})} is the error for reporting
#' entity i above entity j, with larger target values having higher priority.
#' Diagonal entries are `NA` because self-comparisons are unused.
#'
#' @param draws An object from [postrank_draws()] or [as_postrank_draws()], a
#'   supported canonical input payload, or already calculated coefficients from
#'   [postrank_gaussian_coefficients()], [postrank_mixture_coefficients()], or
#'   [postrank_probabilities()]. For already calculated inputs, omit `method`
#'   and `block_size`.
#' @param method For Monte Carlo draws, `"blocks"` (default) aggregates bounded
#'   blocks of ordered pairs; `"reference"` aggregates one pair at a time.
#'   Both use equal-weight empirical frequencies and preserve the input draws.
#'   Exact finite laws instead use their declared masses.
#' @param block_size Positive integer maximum ordered-pair block size for the
#'   block algorithm. It changes working storage, not the probability event.
#' @return For draw or finite-law input, a `postrank_pairwise` object containing
#'   the directional-error array `e`, criterion-specific `sample_sizes`, and
#'   source records. Exact finite laws also retain rational coefficients and
#'   a floating-point projection, with sample sizes marked unavailable.
#'   Already calculated coefficient or probability inputs are validated and
#'   returned unchanged, with their original class and source information.
#' @details The ordinary route requires zero equality probability for each pair
#'   of distinct entities. Continuity of every marginal is neither necessary
#'   nor sufficient: a finite law with no pairwise equality is admissible,
#'   whereas identical continuous targets have equality probability one.
#'   Use [postrank_tie_pairwise()] for the separate equality-neutral loss when
#'   genuine equality is present. With zero equality, reverse off-diagonal
#'   probabilities sum to one.
#'
#'   For IID or MCMC output, a frequency of zero or one does not establish that
#'   the underlying posterior event is impossible or certain. A declared exact
#'   finite law instead defines the probabilities through its complete states
#'   and masses; it requires the optional `gmp` package for exact arithmetic.
#'
#'   Criterion-wise inputs retain each criterion's own draw count and history.
#'   Within a criterion, all entity values must refer to the same state. The
#'   resulting coefficients suffice for additive expected risk, but separate
#'   criterion blocks do not establish a cross-criterion joint trace for
#'   composite-score or simultaneous-event calculations.
#' @seealso [postrank_evaluate()], [postrank_probabilities()],
#'   [postrank_tie_pairwise()]
#' @examples
#' # A one-criterion analytic input is already calculated.
#' one <- postrank_pairwise(pr_tutorial$one)
#' one$e[, , "score_A"]
#' identical(one, pr_tutorial$one)
#'
#' # Empirical frequencies from the bundled joint posterior-draw example.
#' pw <- postrank_pairwise(postrank_toy)
#' pw$sample_sizes
#' @concept coefficients
#' @export
postrank_pairwise <- function(draws, method = c("blocks", "reference"), block_size = 128L) {
  if (inherits(draws, "postrank_probabilities")) {
    .pr_assert(missing(method) && missing(block_size),
      "supplied probabilities are already calculated; omit draw aggregation controls",
      "unsupported_probability_aggregation")
    validate_postrank_probabilities(draws)
    return(draws)
  }
  if(inherits(draws,"postrank_coefficients")) {
    .pr_assert(missing(method)&&missing(block_size),"typed coefficients are already projected; draw aggregation controls are unsupported","unsupported_coefficient_aggregation")
    validate_postrank_coefficients(draws);return(draws)
  }
  method <- match.arg(method)
  .pr_assert(typeof(block_size) %in% c("integer", "double") && length(block_size) == 1L &&
               is.null(dim(block_size)), "block_size must be a positive scalar integer", "invalid_block_size")
  .pr_safe_integer(block_size, TRUE, "$.block_size")
  draws <- as_postrank_draws(draws)
  if (draws$input_kind == "exact_finite_posterior") return(.pr_pairwise_exact(draws))
  matrices <- .pr_draw_matrices(draws)
  e <- .pr_empty_e(draws$entity_ids, draws$criterion_ids)
  for (k in seq_along(draws$criterion_ids)) {
    values <- matrices[[draws$criterion_ids[k]]]
    e[, , k] <- if (method == "reference") .pr_pairwise_reference_one(values) else
      .pr_pairwise_blocks_one(values, block_size)
  }
  .pr_new_pairwise(draws, e, vapply(matrices, nrow, integer(1L)), method)
}
