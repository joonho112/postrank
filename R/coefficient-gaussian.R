# Conditional Gaussian mathematical-law projection; no target draws or sampler.
.pr_cf_project_gaussian <- function(source) {
  .pr_cf_numeric(source$means)
  axes <- dimnames(source$means)
  .pr_assert(is.matrix(source$means) && identical(names(axes), c("entity", "criterion")),
    "Gaussian means require explicit entity/criterion axis roles", "invalid_coefficients")
  ids <- axes$entity; ks <- axes$criterion
  .pr_cf_ids(ids, 2L); .pr_cf_ids(ks)
  .pr_cf_gaussian_source(source, ids, ks)
  n <- length(ids); K <- length(ks)
  e <- array(NA_real_, c(n, n, K),
    dimnames = list(entity_i = ids, entity_j = ids, criterion = ks))
  for (k in seq_len(K)) for (i in seq_len(n)) for (j in seq_len(n)) {
    if (i == j) next
    vi <- source$covariance[k, k, i]; vj <- source$covariance[k, k, j]
    # sqrt(vi+vj) without overflowing the sum of two finite variances.
    sd_difference <- sqrt(max(vi, vj)) * sqrt(1 + min(vi, vj) / max(vi, vj))
    z <- (source$means[j, k] - source$means[i, k]) / sd_difference
    # Every direction is a direct lower-tail calculation: no 1-pnorm(z).
    e[i, j, k] <- stats::pnorm(z)
  }
  list(means = source$means, e = e)
}

#' Compute Comparisons from a Conditional Gaussian Law
#'
#' Directional-error probabilities are calculated from conditional means and
#' covariance matrices without simulation of the target values. The input may
#' contain one or several criteria, with dependence among criteria within an
#' entity. Entities are assumed independent conditional on the supplied shared
#' state.
#'
#' For distinct entities, \eqn{e_{ij,k}=P(\theta_{i,k}\leq\theta_{j,k})}
#' is the error probability for reporting entity i above entity j. Positive
#' conditional variances and between-entity independence make equality have
#' probability zero. Diagonals are `NA`: self-comparisons are not used.
#'
#' @param means Finite numeric matrix with dimension names
#'   `list(entity = entity_ids, criterion = criterion_ids)`. Supply at least
#'   two unique entity IDs and one criterion. Targets must already be oriented
#'   so that larger values mean higher reporting priority, in the declared units.
#' @param covariance Finite, symmetric, positive definite conditional covariance
#'   array with dimensions criterion-by-criterion-by-entity and dimension names
#'   `list(criterion_i = criterion_ids, criterion_j = criterion_ids,
#'   entity = entity_ids)`. Each matrix describes dependence among criteria
#'   within one entity; it cannot encode covariance between entities. For one
#'   criterion, each matrix is its positive conditional variance. No jitter or
#'   covariance repair is applied.
#' @param conditional_independence Explicitly `"entities_given_shared_h"`.
#'   This is a model assumption, not something inferred from marginal moments.
#' @param provenance Named list with `producer_id`, `producer_version`,
#'   `posterior_id`, `input_payload_sha256`, `source_sha256`, and
#'   `config_sha256`; `model_sha256` is optional. Hashes must be lowercase
#'   SHA-256 strings describing the actual source and calculation. They record
#'   provenance but do not authenticate the fit or its scientific assumptions.
#' @return A `postrank_coefficients` object containing posterior `means`, an
#'   entity-by-entity-by-criterion directional-error array `e`, the supplied
#'   conditional law and provenance, and supported-operation indicators.
#'   No target draws or Monte Carlo sample sizes are created.
#' @details The normal difference uses the sum of the two conditional marginal
#'   variances. Both directions use the normal CDF directly to retain small
#'   tails. These are floating-point analytic calculations, not exact rational
#'   arithmetic or certified numerical error bounds.
#'
#'   The native joint search through [postrank_problem()] supports weighted
#'   expected loss with an upper grade-count limit for this input. It does not
#'   support minimax, criterion protections `q`, or an exact grade count there.
#'   [postrank_evaluate()] can score a fixed report; scoring does not check its
#'   membership in a constrained action family. Other operations have their
#'   own documented support; see [postrank_coefficient_capabilities()].
#'
#'   The package does not fit the model or verify that the supplied law follows
#'   from observed data. If an empirical Bayes prior estimate is held fixed,
#'   these probabilities condition on that estimate. Use
#'   [postrank_mixture_coefficients()] to average conditional probabilities over
#'   explicitly supplied shared states; matching only their moments changes
#'   the law in general.
#' @seealso [validate_postrank_coefficients()], [postrank_mixture_coefficients()],
#'   [postrank_coefficient_diagnose()]
#' @examples
#' # Reconstruct the documented one-criterion tutorial law with its own provenance.
#' law <- pr_tutorial$law
#' x <- postrank_gaussian_coefficients(
#'   means = law$means[, "score_A", drop = FALSE],
#'   covariance = law$covariance["score_A", "score_A", , drop = FALSE],
#'   conditional_independence = "entities_given_shared_h",
#'   provenance = pr_tutorial$one$provenance)
#' x$e[, , "score_A"]
#' @concept coefficients
#' @export
postrank_gaussian_coefficients <- function(means, covariance, conditional_independence, provenance) {
  source <- list(kind = "gaussian_conditional", means = means, covariance = covariance,
                 conditional_independence = conditional_independence)
  .pr_cf_provenance(provenance)
  projected <- .pr_cf_project_gaussian(source)
  .pr_coefficient_assemble(source, projected$means, projected$e, provenance)
}
