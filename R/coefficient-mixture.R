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
#' `postrank_mixture_coefficients()` computes posterior means and pairwise
#' directional-error probabilities by averaging conditional normal (Gaussian)
#' posteriors across shared parameter states `h` (such as hyperparameter MCMC
#' draws or discrete mixture components). Because every entity shares each state
#' `h`, averaging across states preserves cross-entity dependence induced by `h`
#' even when entities are independent conditional on `h`. For distinct entities
#' `i` and `j`, \eqn{e_{ij,k} = \sum_s w_s P(\theta_{i,k} \le \theta_{j,k} \mid h_s)}
#' is the expected error if `i` is graded above `j` (diagonals are `NA`).
#' `postrank` does not fit or sample the model.
#'
#' @param components Non-empty plain named list of state records
#'   (`names(components)` are unique state IDs). Every state must share the
#'   exact same `entity_ids` (`n >= 2`) and `criterion_ids` (`K >= 1`) in
#'   identical order, and no element may carry extra R attributes:
#'   * `mu`: finite numeric vector named by `criterion_ids` recording the shared
#'     state `h`'s criterion-level hyperparameter mean (checked and stored for
#'     provenance/identity);
#'   * `Sigma`: finite symmetric positive-definite `K x K` matrix (`Sigma ==
#'     t(Sigma)` with zero tolerance) with
#'     `dimnames = list(criterion_i = criterion_ids, criterion_j =
#'     criterion_ids)`, recording the shared state `h`'s criterion-level
#'     hyperparameter covariance;
#'   * `means`: finite `n x K` precomputed entity conditional posterior mean
#'     matrix given `h`, with
#'     `dimnames = list(entity = entity_ids, criterion = criterion_ids)` (larger
#'     values mean higher priority; used directly to compute mixture `means` and
#'     `e`);
#'   * `covariance`: finite symmetric positive-definite `K x K x n` array of
#'     within-entity conditional posterior covariances given `h` (every slice
#'     must satisfy `S == t(S)` with zero tolerance; symmetrize `(V + t(V)) / 2`
#'     beforehand if needed), with `dimnames` named `criterion_i`,
#'     `criterion_j`, and `entity` (`criterion_ids`, `criterion_ids`,
#'     `entity_ids`). `covariance` links criteria within an entity only;
#'     cross-entity dependence enters through the shared state `h`.
#' @param weights Nonnegative finite plain numeric state probabilities named by
#'   `names(components)` in component order, summing to one within `1e-12`
#'   (never rescaled automatically, with no extra R attributes). When
#'   `source_regime = "hyperparameter_mcmc"`, all weights must equal
#'   `1 / length(components)`. These are mixture probabilities over states, not
#'   criterion loss weights.
#' @param state_index Base `data.frame` (no tibble or extra attributes) in
#'   component order, with `state_id` matching `names(components)`. When
#'   `source_regime = "fixed_finite_mixture"`, `state_id` is the only column;
#'   when `source_regime = "hyperparameter_mcmc"`, columns must be
#'   `c("state_id", "chain_id", "iteration")` with positive integer chain and
#'   original iteration numbers and unique `(chain_id, iteration)` pairs.
#' @param source_regime `"fixed_finite_mixture"` for a specified finite mixture
#'   or quadrature rule, or `"hyperparameter_mcmc"` for retained hyperparameter
#'   MCMC states.
#' @param conditional_independence Must be `"entities_given_shared_h"`, an
#'   explicit model declaration (not inferred from marginal moments) stating
#'   that entities are conditionally independent given each shared state `h`.
#' @param provenance Plain named list of non-empty character strings (with no
#'   extra R attributes): `producer_id`, `producer_version`, `posterior_id`,
#'   `input_payload_sha256`, `source_sha256`, and `config_sha256`, plus optional
#'   `model_sha256`. Every `*_sha256` entry must be a 64-character lowercase
#'   hexadecimal SHA-256 digest.
#' @returns A `postrank_coefficients` object
#'   (`input_kind = "shared_hyperstate_mixture"`) containing `entity_ids`,
#'   `criterion_ids`, mixture `means`, the `n x n x K` directional-error array
#'   `e`, `source`, `provenance`, `capabilities`, `validation`,
#'   `coefficient_identity`, `input_identity`, `pairwise_identity`, and
#'   `schema_version` (`"coefficient-0.1.0"`). No entity-level target draws are
#'   generated.
#' @details
#' Conditional probabilities and means are combined across states with
#' compensated summation (to reduce floating-point rounding error) rather than
#' replacing the mixture by a single moment-matched normal distribution. Unlike
#' a discrete finite law of target atoms (`exact_finite_posterior`), each
#' mixture state here is a continuous normal distribution with positive
#' variances, so distinct entities have zero probability of exact equality;
#' calculations use ordinary floating-point arithmetic rather than exact
#' rational arithmetic.
#'
#' In [postrank()] and [postrank_problem()], mixture coefficients support the
#' weighted expected-loss objective with `G_max` (minimax, `q` error budgets,
#' and `exact_G` are unavailable there, while [postrank_cuts()] also supports
#' `exact_G` along a score order; see [postrank_coefficient_capabilities()]).
#' [postrank_coefficient_diagnose()] evaluates conditional expected loss across
#' the supplied states and, when `source_regime = "hyperparameter_mcmc"` and
#' `chain_history` is supplied (providing each chain's ordered retained
#' iterations so equal chain lengths and regular thinning spacing can be checked
#' before computing R-hat, ESS, and MCSE), computes MCMC integration
#' diagnostics. Any empirical-Bayes quantities held fixed outside `components`
#' remain conditioned on; neither this constructor nor
#' [postrank_coefficient_diagnose()] verifies that one coherent dataset produced
#' the moments, checks external files, or certifies numerical or model error.
#' @seealso [postrank_gaussian_coefficients()],
#'   [validate_postrank_coefficients()], [postrank_coefficient_capabilities()],
#'   [postrank_coefficient_diagnose()]
#' @examples
#' state <- function(d) {
#'   ks <- "score"; ids <- c("A", "B")
#'   list(mu = c(score = d),
#'     Sigma = matrix(1, 1, 1,
#'       dimnames = list(criterion_i = ks, criterion_j = ks)),
#'     means = matrix(c(d, 0.4), 2, 1,
#'       dimnames = list(entity = ids, criterion = ks)),
#'     covariance = array(0.5, c(1, 1, 2),
#'       dimnames = list(criterion_i = ks, criterion_j = ks, entity = ids)))
#' }
#' comps <- list(low = state(-1), high = state(0.5))
#' cfg <- list(weights = c(low = 0.5, high = 0.5),
#'   state_index = data.frame(state_id = c("low", "high")),
#'   source_regime = "fixed_finite_mixture",
#'   conditional_independence = "entities_given_shared_h")
#' prov <- list(producer_id = "postrank_mixture_coefficients help example",
#'   producer_version = "1", posterior_id = "two-state-normal-mixture",
#'   input_payload_sha256 = digest::digest(comps, algo = "sha256"),
#'   source_sha256 = digest::digest(body(state), algo = "sha256"),
#'   config_sha256 = digest::digest(cfg, algo = "sha256"))
#' x <- postrank_mixture_coefficients(comps, cfg$weights, cfg$state_index,
#'   cfg$source_regime, cfg$conditional_independence, prov)
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
