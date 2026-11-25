#' Calculate Directional-Error Probabilities
#'
#' `postrank_pairwise()` computes pairwise directional-error probabilities
#' \eqn{e_{ij,k} = P(\theta_{i,k} \le \theta_{j,k})} (the probability that
#' grading entity `i` above entity `j` is in the wrong order, with larger
#' target values meaning higher priority) from posterior draws or an exact
#' finite posterior. Diagonal entries are `NA`. Normal/mixture posterior
#' coefficients and precomputed comparison probabilities are validated and
#' returned unchanged.
#'
#' @param draws A `postrank_draws` object (or complete `"applied-0.1"` input
#'   list), or an already computed `postrank_coefficients` or
#'   [postrank_probabilities()] object. When passing `postrank_coefficients` or
#'   `postrank_probabilities`, omit `method` and `block_size`.
#' @param method Aggregation algorithm for Monte Carlo draws: `"blocks"` (the
#'   default, summing bounded blocks of ordered pairs) or `"reference"` (one
#'   pair at a time). Both compute identical equal-weight empirical
#'   frequencies; exact finite posteriors ignore `method` and sum their exact
#'   state probabilities.
#' @param block_size Positive integer maximum block size for `method = "blocks"`
#'   (default `128L`). Controls working memory without changing `e`.
#' @returns For draw or exact finite-posterior inputs, a `postrank_pairwise`
#'   object containing the `n x n x K` array `e`, per-criterion `sample_sizes`
#'   (`NA` for exact finite posteriors), `exact` rational coefficients when
#'   applicable, and source identities. For `postrank_coefficients` or
#'   `postrank_probabilities`, the validated input object unchanged.
#' @details
#' `postrank_pairwise()` assumes zero probability of exact equality between
#' distinct entities within each criterion, so off-diagonal complements satisfy
#' `e[i, j, k] + e[j, i, k] = 1` (for posteriors with positive tie probability,
#' use [postrank_tie_pairwise()]). In IID or MCMC draws, an empirical frequency
#' of `0` or `1` is a finite-sample summary rather than proof of posterior
#' certainty, whereas an exact finite posterior computes exact rational
#' probabilities using the optional `gmp` package.
#'
#' Criterion-wise draw inputs (`criterion_blocks`) retain each criterion's own
#' draw count `S_k`; their probabilities support additive criterion losses
#' without defining a cross-criterion joint posterior.
#' @seealso [postrank_problem()], [postrank_evaluate()],
#'   [postrank_probabilities()], [postrank_tie_pairwise()]
#' @examples
#' # Normal posterior coefficients are validated and returned unchanged:
#' one <- postrank_pairwise(pr_tutorial$one)
#' identical(one, pr_tutorial$one)
#'
#' # Empirical wrong-order frequencies from IID posterior draws:
#' pw <- postrank_pairwise(postrank_toy)
#' pw$sample_sizes
#' pw$e[, , "need_A"]
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
