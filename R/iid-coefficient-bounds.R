.pr_iid_named_numeric <- function(x, criterion_ids, name, positive = TRUE) {
  .pr_assert(typeof(x) %in% c("integer", "double") && is.null(dim(x)) &&
    length(x) == length(criterion_ids) && !is.null(names(x)) &&
    !anyNA(names(x)) && !anyDuplicated(names(x)) && setequal(names(x), criterion_ids) &&
    all(is.finite(x)) && (!positive || all(x > 0)),
    paste(name, "must be a finite positive criterion-named vector covering every criterion"),
    "invalid_iid_design", paste0("$.", name))
  x[criterion_ids]
}

.pr_iid_sampling <- function(draws) {
  .pr_assert(identical(draws$input_kind, "equal_weight_draws"),
    "IID coefficient bounds require equal-weight draws, not an exact finite law",
    "unsupported_iid_input")
  criteria <- draws$criterion_ids
  if (identical(draws$dependence_mode, "joint_model")) {
    blocks <- rep(list(draws$joint_draws), length(criteria))
    sizes <- rep(draws$joint_draws$tensor$shape$S, length(criteria))
  } else {
    ids <- vapply(draws$criterion_blocks, `[[`, character(1), "criterion_id")
    blocks <- draws$criterion_blocks[match(criteria, ids)]
    sizes <- vapply(blocks, function(b) b$matrix$shape$S, numeric(1))
  }
  .pr_assert(all(vapply(blocks, function(b)
    identical(b$sampling$regime, "iid") && isTRUE(b$sampling$equal_weight), logical(1))),
    "Every criterion must declare IID equal-weight site-joint states; MCMC ESS is not an IID sample size",
    "unsupported_iid_input")
  stats::setNames(as.numeric(sizes), criteria)
}

.pr_iid_design <- function(design, criterion_ids, S) {
  fields <- c("sample_sizes_fixed_before_sampling", "alpha_fixed_before_sampling",
    "adaptive_stopping", "planned_sample_sizes", "declaration_note")
  .pr_fields(design, fields, path = "$.design")
  .pr_assert(identical(design$sample_sizes_fixed_before_sampling, TRUE) &&
    identical(design$alpha_fixed_before_sampling, TRUE) &&
    identical(design$adaptive_stopping, FALSE),
    "Fixed sample sizes and alpha allocation before sampling, with no adaptive stopping, are required",
    "unsupported_iid_design", "$.design")
  planned <- .pr_iid_named_numeric(design$planned_sample_sizes, criterion_ids,
    "design.planned_sample_sizes")
  .pr_safe_integer(planned, TRUE, "$.design.planned_sample_sizes")
  .pr_assert(all(planned == S), "Planned sample sizes must equal all actual retained criterion counts",
    "iid_sample_size_mismatch", "$.design.planned_sample_sizes")
  .pr_string(design$declaration_note, "$.design.declaration_note")
  design$planned_sample_sizes <- planned
  design
}

.pr_validate_iid_bounds <- function(bounds) {
  .pr_assert(inherits(bounds, "postrank_iid_bounds") && identical(bounds$schema_version, "0.1.0"),
    "Expected current postrank_iid_bounds", "invalid_iid_bounds")
  content <- bounds; content$bound_identity <- NULL
  .pr_assert(!is.null(bounds$bound_identity) && identical(.pr_identity(content), bounds$bound_identity),
    "IID bounds changed after construction; recompute from the original draws and design",
    "stale_iid_bound_identity")
  .pr_ids(bounds$entity_ids, 2L); .pr_ids(bounds$criterion_ids)
  .pr_string(bounds$input_identity)
  criteria <- bounds$criterion_ids
  S <- .pr_iid_named_numeric(bounds$S, criteria, "S")
  .pr_safe_integer(S, TRUE)
  .pr_assert(identical(names(bounds$S), criteria), "IID count order changed", "invalid_iid_bounds")
  allocation <- .pr_iid_named_numeric(bounds$alpha_by_criterion, criteria, "alpha_by_criterion")
  .pr_assert(typeof(bounds$alpha) %in% c("integer", "double") && is.null(dim(bounds$alpha)) &&
    length(bounds$alpha) == 1L && is.finite(bounds$alpha) && bounds$alpha > 0 && bounds$alpha < 1 &&
    sum(allocation) <= bounds$alpha, "Invalid alpha budget or allocation", "invalid_iid_bounds")
  M <- choose(length(bounds$entity_ids), 2)
  radius <- sqrt((log(2) + log(M) - log(allocation)) / (2 * S))
  .pr_assert(identical(bounds$M, M) && identical(bounds$raw_radius, radius) &&
    identical(bounds$epsilon, pmin(radius, 1)) &&
    identical(bounds$radius_interpretation, "theoretical_floating_reference") &&
    isTRUE(bounds$bound_computed) && identical(bounds$numerically_verified, FALSE) &&
    identical(bounds$numerical_certification, FALSE) && identical(bounds$guarantee_issued, FALSE) &&
    identical(bounds$finite_sample_certificate, FALSE) &&
    identical(bounds$guarantee_status, "conditional_bound"),
    "IID bound fields disagree with the theoretical floating reference", "invalid_iid_bounds")
  .pr_assert(is.list(bounds$assumptions) &&
    identical(bounds$assumptions$scientific_declarations_verified, FALSE) &&
    identical(bounds$assumptions$numerical_enclosure_verified, FALSE),
    "IID assumptions cannot be promoted to verified scientific or numerical claims", "invalid_iid_bounds")
  .pr_iid_design(bounds$design, criteria, S)
  invisible(TRUE)
}

#' Compute a Conditional Fixed-Sample IID Probability Bound
#'
#' `postrank_iid_bounds()` computes an analytic simultaneous error radius for
#' pairwise directional-error probabilities estimated from a fixed number of
#' independent posterior draws. The `1 - alpha` probability statement applies to
#' repeated Monte Carlo draw generation from the same fixed posterior
#' distribution; it is not a posterior probability that a grading is right and
#' does not assess model specification or performance on new datasets.
#'
#' @param draws Independent equal-weight posterior draws prepared as an
#'   `S x n x K` array via `postrank_draws(..., regime = "iid")` or as separate
#'   per-criterion IID entity-draw matrices via [as_postrank_draws()]
#'   (`equal_weight = TRUE`, with `dependence_mode = "joint_model"` or
#'   `"criterionwise_expected_only"`). MCMC draws (effective sample size ESS
#'   cannot replace an IID draw count), exact finite laws, Gaussian or mixture
#'   coefficients, pre-computed [postrank_probabilities()], and tie-mode inputs
#'   are rejected.
#' @param alpha Overall failure-probability budget, a finite scalar strictly
#'   between `0` and `1` fixed before generating the draws.
#' @param alpha_by_criterion Finite positive numeric vector named by every
#'   criterion in `draws`, summing to at most `alpha` and fixed before
#'   generating the draws. Values are ordered to `draws$criterion_ids` and are
#'   never rescaled automatically.
#' @param design Named list with exactly five elements (extra fields stop with
#'   an error): `sample_sizes_fixed_before_sampling = TRUE`,
#'   `alpha_fixed_before_sampling = TRUE`, `adaptive_stopping = FALSE`,
#'   criterion-named positive integer `planned_sample_sizes` equal to the actual
#'   retained draw counts `S` on every criterion, and a non-empty character
#'   scalar `declaration_note`. These fields record how the simulation was
#'   designed prior to sampling; `postrank` checks internal consistency but
#'   cannot verify external sampling history, and setting these flags on an
#'   adaptive or dependent sample does not make the bound valid.
#' @return A `postrank_iid_bounds` list containing `schema_version`,
#'   `input_identity`, `bound_identity`, `entity_ids`, `criterion_ids`,
#'   `dependence_mode`, criterion sample sizes `S`, unordered pair count
#'   `M = choose(n, 2)`, `alpha`, `alpha_by_criterion`, unclipped `raw_radius`,
#'   capped `epsilon = pmin(raw_radius, 1)`,
#'   `radius_interpretation = "theoretical_floating_reference"`, `design`,
#'   `assumptions`, `guarantee_reason`, `numerical_verification_reason`, and
#'   status flags (`guarantee_status = "conditional_bound"`,
#'   `bound_computed = TRUE`, while `guarantee_issued`, `numerically_verified`,
#'   `numerical_certification`, and `finite_sample_certificate` are `FALSE`).
#' @details
#' With \eqn{M = n(n - 1) / 2} unordered pairs, the radius on criterion \eqn{k}
#' is
#' \deqn{\varepsilon_k = \min\left\{1, \sqrt{\frac{\log(2M / \alpha_k)}{2 S_k}}\right\}.}
#' Under the stated assumptions, with Monte Carlo probability at least
#' \eqn{1 - \alpha} simultaneously across all directed entity pairs and all
#' declared criteria, every empirical directional-error probability lies within
#' \eqn{\varepsilon_k} of its true value under the supplied posterior.
#' Independence is required across whole-state draws \eqn{s = 1, \dots, S_k}
#' within each criterion, not across entity pairs or across criteria.
#'
#' The factor \eqn{2M} uses the zero-equality complement identity
#' \eqn{e_{ji,k} = 1 - e_{ij,k}}, so bounding one direction per unordered pair
#' bounds the reverse direction by the same absolute error. That identity
#' requires zero posterior probability of exact pairwise equality (not
#' necessarily continuous marginal densities) and does not apply unchanged when
#' exact ties have positive probability. All draws must target one fixed proper
#' posterior; empirical Bayes hyperparameters held fixed during draw generation
#' are part of that conditioning.
#'
#' Adaptive stopping and substituting MCMC ESS for \eqn{S_k} are not supported.
#' Radii are evaluated in ordinary floating-point arithmetic without outward
#' interval-arithmetic enclosures, so this function does not issue a formal
#' numerical certificate.
#' @seealso [postrank_guarantee_capabilities()], [postrank_regret_bound()],
#'   [postrank_protection_envelopes()]
#' @examples
#' bounds <- postrank_iid_bounds(
#'   postrank_toy,
#'   alpha = 0.05,
#'   alpha_by_criterion = c(need_A = 0.025, need_B = 0.025),
#'   design = list(
#'     sample_sizes_fixed_before_sampling = TRUE,
#'     alpha_fixed_before_sampling = TRUE,
#'     adaptive_stopping = FALSE,
#'     planned_sample_sizes = c(need_A = 32L, need_B = 32L),
#'     declaration_note = "Prespecified in the bundled synthetic Normal generator"
#'   )
#' )
#' bounds$epsilon
#' bounds[c("guarantee_status", "guarantee_issued", "numerically_verified")]
#' @concept reference
#' @export
postrank_iid_bounds <- function(draws, alpha, alpha_by_criterion, design) {
  if(inherits(draws,"postrank_coefficients")) {
    validate_postrank_coefficients(draws)
    .pr_abort("typed Gaussian/mixture coefficients are not fixed-S IID latent target draws", "unsupported_coefficient_iid_bound")
  }
  .pr_assert(!missing(alpha) && !missing(alpha_by_criterion) && !missing(design),
    "alpha, alpha_by_criterion and design must all be explicit", "missing_iid_design")
  draws <- as_postrank_draws(draws)
  S <- .pr_iid_sampling(draws); criteria <- draws$criterion_ids
  .pr_assert(typeof(alpha) %in% c("integer", "double") && is.null(dim(alpha)) &&
    length(alpha) == 1L && is.finite(alpha) && alpha > 0 && alpha < 1,
    "alpha must be a finite scalar strictly between zero and one", "invalid_alpha")
  allocation <- .pr_iid_named_numeric(alpha_by_criterion, criteria, "alpha_by_criterion")
  .pr_assert(sum(allocation) <= alpha, "Criterion alpha allocations exceed alpha; no normalization is applied",
    "invalid_alpha_allocation")
  design <- .pr_iid_design(design, criteria, S)
  M <- choose(length(draws$entity_ids), 2)
  raw_radius <- sqrt((log(2) + log(M) - log(allocation)) / (2 * S))
  assumptions <- list(
    target = "fixed_data_and_proper_tie_free_posterior",
    sampling = "within_each_criterion_IID_equal_weight_site_joint_states",
    sample_sizes = "fixed_before_sampling_and_actual_retained_counts",
    alpha_allocation = "fixed_before_sampling_with_sum_at_most_alpha",
    pair_count = "M_unordered_pairs_opposite_directions_are_complements",
    simultaneous_scope = "all_directed_pairs_and_all_declared_criteria",
    cross_pair_or_criterion_independence_required = FALSE,
    probability_interpretation = "MC_generation_repetitions_conditional_on_fixed_data_and_posterior",
    scientific_declarations_verified = FALSE,
    adaptive_stopping_supported = FALSE, ESS_substitution_supported = FALSE,
    numerical_enclosure_verified = FALSE)
  out <- c(list(schema_version = "0.1.0", input_identity = draws$validation$input_identity,
    entity_ids = draws$entity_ids, criterion_ids = criteria, dependence_mode = draws$dependence_mode,
    S = S, M = M, alpha = alpha, alpha_by_criterion = allocation,
    raw_radius = raw_radius, epsilon = pmin(raw_radius, 1),
    radius_interpretation = "theoretical_floating_reference", design = design),
    .pr_guarantee_status("conditional_bound", bound_computed = TRUE,
      reason = "Fixed-S IID formula evaluated as an uncertified floating reference",
      assumptions = assumptions))
  class(out) <- c("postrank_iid_bounds", "list")
  out$bound_identity <- .pr_identity(out)
  .pr_validate_iid_bounds(out)
  out
}
