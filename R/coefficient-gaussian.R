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
#' `postrank_gaussian_coefficients()` computes pairwise directional-error
#' probabilities analytically from entity posterior means and within-entity
#' covariance matrices under a normal (Gaussian) posterior, without simulating
#' draws. For distinct entities `i` and `j` on criterion `k`,
#' \eqn{e_{ij,k} = P(\theta_{i,k} \le \theta_{j,k})} is the probability that
#' reporting `i` above `j` is in the wrong order (diagonal entries are `NA`).
#'
#' @param means Finite plain numeric `n x K` matrix (`n >= 2`, `K >= 1`) with
#'   named `dimnames`: `list(entity = entity_ids, criterion = criterion_ids)`.
#'   Larger values must already mean higher priority toward grade 1.
#' @param covariance Finite symmetric positive-definite plain numeric `K x K x n`
#'   array with named `dimnames`:
#'   `list(criterion_i = criterion_ids, criterion_j = criterion_ids, entity = entity_ids)`.
#'   Each `K x K` slice gives within-entity covariance across criteria (positive
#'   variance when `K = 1`) and must satisfy exact symmetry `S == t(S)` with
#'   zero tolerance (symmetrize `(V + t(V)) / 2` beforehand if needed);
#'   cross-entity covariance cannot be encoded here, and singular or asymmetric
#'   matrices stop the call without repair.
#' @param conditional_independence Must be `"entities_given_shared_h"`, an
#'   explicit model declaration (not inferred from marginal moments) stating
#'   that entities are conditionally independent given the fixed conditioning
#'   state.
#' @param provenance Plain named list of non-empty character strings:
#'   `producer_id`, `producer_version`, `posterior_id`, `input_payload_sha256`,
#'   `source_sha256` and `config_sha256`, plus optional `model_sha256`. Every
#'   `*_sha256` entry must be a 64-character lowercase hexadecimal SHA-256
#'   digest.
#' @returns A `postrank_coefficients` object (`input_kind = "gaussian_conditional"`)
#'   containing `entity_ids`, `criterion_ids`, `means`, the `n x n x K`
#'   directional-error array `e`, `source`, `provenance`, `capabilities`,
#'   `validation`, `coefficient_identity`, `input_identity`, `pairwise_identity`,
#'   and `schema_version` (`"coefficient-0.1.0"`).
#' @details
#' Each off-diagonal probability is computed directly in the lower tail of the
#' normal distribution from `(means[j, k] - means[i, k]) / sqrt(v_i + v_j)` to
#' preserve small tail values; positive variances and conditional independence
#' across entities imply zero probability of exact equality. These are ordinary
#' floating-point analytic calculations, not exact rational arithmetic or
#' interval-verified bounds.
#'
#' In [postrank()] and [postrank_problem()], normal posterior coefficients
#' support the weighted expected-loss objective with `G_max` (minimax, `q` error
#' budgets and `exact_G` are not available there; see
#' [postrank_coefficient_capabilities()]). If an empirical-Bayes prior is held
#' fixed, these probabilities condition on that estimate; to average over
#' hyperparameter states, use [postrank_mixture_coefficients()] rather than
#' moment-matching to a single normal distribution. `postrank` does not fit the
#' model or verify `provenance` hashes against external files.
#' @seealso [postrank_mixture_coefficients()],
#'   [validate_postrank_coefficients()], [postrank_coefficient_capabilities()],
#'   [postrank_coefficient_diagnose()]
#' @examples
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
