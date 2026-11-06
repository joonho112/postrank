# Shared-h conditional Gaussian mixtures, distinct from latent target draws.
.pr_cf_mixture_axes <- function(components) {
  .pr_assert(is.list(components) && !is.data.frame(components) && length(components) > 0L &&
    is.list(components[[1L]]) && is.matrix(components[[1L]]$means),
    "components require a nonempty named conditional-state list", "invalid_coefficients")
  list(ids = rownames(components[[1L]]$means), ks = colnames(components[[1L]]$means))
}
.pr_cf_mixture_add <- function(total, correction, value) {
  adjusted <- value - correction
  next_total <- total + adjusted
  list(total = next_total, correction = (next_total - total) - adjusted)
}

# Internal projection of an already structurally validated mathematical source.
# Mu/Sigma remain source declarations: this does not verify an actual Y/V fit.
.pr_cf_project_mixture <- function(source) {
  axes <- .pr_cf_mixture_axes(source$components)
  ids <- axes$ids; ks <- axes$ks; n <- length(ids); K <- length(ks)
  means <- matrix(0, n, K, dimnames = list(entity = ids, criterion = ks))
  e <- array(0, c(n, n, K), dimnames = list(entity_i = ids, entity_j = ids, criterion = ks))
  mean_correction <- means; e_correction <- e
  diagonal <- row(matrix(0, n, n)) == col(matrix(0, n, n))
  for (s in seq_along(source$components)) {
    state <- source$components[[s]]
    gaussian <- list(kind = "gaussian_conditional", means = state$means,
      covariance = state$covariance, conditional_independence = source$conditional_independence)
    projection <- .pr_cf_project_gaussian(gaussian)
    update <- .pr_cf_mixture_add(means, mean_correction, source$weights[s] * projection$means)
    means <- update$total; mean_correction <- update$correction
    state_e <- projection$e
    for (k in seq_len(K)) state_e[, , k][diagonal] <- 0
    update <- .pr_cf_mixture_add(e, e_correction, source$weights[s] * state_e)
    e <- update$total; e_correction <- update$correction
  }
  for (k in seq_len(K)) e[, , k][diagonal] <- NA_real_
  list(means = means, e = e)
}

#' Average Comparisons Across Shared Gaussian States
#'
#' Means and directional-error probabilities are obtained by averaging
#' conditional Gaussian laws over supplied shared states. Each state is common
#' to all entities. Consequently, averaging over the states can retain
#' dependence between entities that are independent conditional on a state. The
#' model and shared states are supplied externally; the package neither fits
#' nor samples the model.
#'
#' Each conditional probability is the error for reporting entity i above
#' entity j: \eqn{P(\theta_{i,k}\leq\theta_{j,k}\mid h)}. Positive variances
#' and conditional independence make pairwise equality have probability zero.
#' The output has `NA` diagonals because self-comparisons are unused.
#'
#' @param components Nonempty named list of state records, each with exactly
#'   `mu`, `Sigma`, `means`, and `covariance`. `mu` is a criterion-named vector;
#'   `Sigma` is a symmetric positive definite matrix with dimension names
#'   `criterion_i` and `criterion_j`. Conditional `means` and `covariance` use
#'   the entity and criterion axes described in
#'   [postrank_gaussian_coefficients()]. Within-entity covariance may connect
#'   criteria; between-entity dependence enters through the shared state.
#' @param weights Nonnegative state-named probability weights in component
#'   order, summing to one within `1e-12`. They are not normalized automatically.
#'   These mixture masses describe the law, not criterion-loss weights.
#' @param state_index Plain data.frame in component order. A fixed finite
#'   mixture has only `state_id`; hyperparameter MCMC has `state_id`, `chain_id`,
#'   and original `iteration`, with unique positive integer chain/iteration
#'   coordinates. Chain coordinates are inapplicable to a fixed mixture.
#' @param source_regime `"fixed_finite_mixture"` for an explicitly supplied
#'   finite mixture, or `"hyperparameter_mcmc"` for retained shared-state MCMC
#'   output. The MCMC regime requires uniform weights over retained states.
#' @param conditional_independence Explicitly `"entities_given_shared_h"`.
#'   Independence is conditional on the same state for all entities; it is not
#'   inferred from marginal moments.
#' @param provenance Named list with `producer_id`, `producer_version`,
#'   `posterior_id`, `input_payload_sha256`, `source_sha256`, and `config_sha256`;
#'   `model_sha256` is optional. Supply actual source descriptions and lowercase
#'   SHA-256 digests. These records do not authenticate the scientific source.
#' @return A `postrank_coefficients` object with mixture `means`, directional
#'   probabilities `e`, the supplied states and provenance, and supported-operation
#'   indicators. No target draws or target sample sizes are generated.
#' @details The constructor averages conditional probabilities and means using
#'   compensated summation. It does not replace the mixture with a moment-matched
#'   Gaussian. A finite mixture of continuous Gaussian target laws is also
#'   different from a finite law of target atoms; these coefficients use
#'   floating-point arithmetic, not exact rational finite-law masses.
#'
#'   `mu`, `Sigma`, and the conditional moments are supplied declarations. Their
#'   structural checks do not establish that one dataset or a converged sampler
#'   produced them. Empirical Bayes quantities held fixed remain conditioned on;
#'   only uncertainty represented by the supplied states is averaged over.
#'
#'   The native [postrank_problem()] route supports weighted expected loss with
#'   an upper grade-count limit, not minimax, `q` protections, or exact-G there.
#'   [postrank_coefficient_diagnose()] can describe conditional expected-risk
#'   variation across states; MCMC metrics additionally require original history.
#'   Neither those metrics nor this calculation certify numerical or model error.
#' @seealso [postrank_gaussian_coefficients()], [validate_postrank_coefficients()],
#'   [postrank_coefficient_capabilities()]
#' @examples
#' # A specified one-criterion law, not the output of a fitted model or sampler.
#' state <- function(d) {
#'   ks <- "score"; ids <- c("A", "B")
#'   list(mu = c(score = d),
#'     Sigma = matrix(1, 1, 1,
#'       dimnames = list(criterion_i = ks, criterion_j = ks)),
#'     means = matrix(c(d, .4), 2, 1,
#'       dimnames = list(entity = ids, criterion = ks)),
#'     covariance = array(.5, c(1, 1, 2),
#'       dimnames = list(criterion_i = ks, criterion_j = ks, entity = ids)))
#' }
#' components <- list(low = state(-1), high = state(.5))
#' config <- list(weights = c(low = .5, high = .5),
#'   state_index = data.frame(state_id = c("low", "high")),
#'   source_regime = "fixed_finite_mixture",
#'   conditional_independence = "entities_given_shared_h")
#' provenance <- list(producer_id = "postrank_mixture_coefficients help example",
#'   producer_version = "1", posterior_id = "specified-two-state-normal-law",
#'   input_payload_sha256 = digest::digest(components, algo = "sha256"),
#'   source_sha256 = digest::digest(body(state), algo = "sha256"),
#'   config_sha256 = digest::digest(config, algo = "sha256"))
#' x <- postrank_mixture_coefficients(components, config$weights,
#'   config$state_index, config$source_regime, config$conditional_independence,
#'   provenance)
#' x$e[, , "score"]
#' validate_postrank_coefficients(x, recompute = TRUE)
#' @concept coefficients
#' @export
postrank_mixture_coefficients <- function(components, weights, state_index,
    source_regime, conditional_independence, provenance) {
  axes <- .pr_cf_mixture_axes(components)
  .pr_cf_ids(axes$ids, 2L); .pr_cf_ids(axes$ks)
  source <- list(kind = "shared_hyperstate_mixture", components = components,
    weights = weights, state_index = state_index, source_regime = source_regime,
    conditional_independence = conditional_independence)
  .pr_cf_mixture_source(source, axes$ids, axes$ks)
  .pr_cf_provenance(provenance)
  projection <- .pr_cf_project_mixture(source)
  .pr_coefficient_assemble(source, projection$means, projection$e, provenance)
}
