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

#' Calculate a Conditional Fixed-Sample IID Probability Bound
#'
#' A simultaneous reference radius is calculated for directional-error
#' probabilities estimated from a fixed number of IID posterior draws. The
#' associated probability statement concerns repeated Monte Carlo generation
#' conditional on the same supplied posterior law. It does not give a posterior
#' probability that a grade is correct.
#'
#' @param draws Ordinary posterior input from [postrank_draws()] or
#'   [as_postrank_draws()], with equal-weight IID whole-entity states within
#'   every criterion. Joint-model and criterion-wise inputs are supported.
#'   MCMC, exact finite laws, Gaussian/mixture coefficients, supplied probabilities,
#'   and equality-neutral inputs are not fixed-sample IID target-draw inputs.
#' @param alpha Overall failure-probability budget, strictly between zero and one.
#'   It must have been fixed before generating the draws.
#' @param alpha_by_criterion Positive criterion-named allocations covering every
#'   criterion, summing to at most `alpha`. They must also have been fixed before
#'   sampling; they are not normalized automatically.
#' @param design List with `sample_sizes_fixed_before_sampling = TRUE`,
#'   `alpha_fixed_before_sampling = TRUE`, `adaptive_stopping = FALSE`,
#'   criterion-named integer `planned_sample_sizes`, and a substantive
#'   `declaration_note`. Planned sizes must equal the actual retained counts.
#'   These are declarations about the real sampling design, not switches that
#'   make an adaptive or dependent sample eligible.
#' @return A `postrank_iid_bounds` object with criterion sample sizes `S`, pair
#'   count `M`, allocations, unclipped `raw_radius`, and capped `epsilon`.
#'   `guarantee_status` is `"conditional_bound"`, but `guarantee_issued`,
#'   `numerically_verified`, and `finite_sample_certificate` remain `FALSE`.
#' @details With \eqn{M=n(n-1)/2}, the criterion radius is
#'   \eqn{\varepsilon_k=\min\{1,\sqrt{\log(2M/\alpha_k)/(2S_k)}\}}.
#'   Under the assumptions, the simultaneous event bounds the absolute error
#'   of every directed-pair coefficient on every criterion with probability at
#'   least \eqn{1-\alpha}. Independence is required across whole-state draws
#'   within each criterion, not across pairs or criteria.
#'
#'   The factor `2M` uses the ordinary zero-equality condition: reverse
#'   directional errors are complements. It must not be applied unchanged to
#'   positive-equality probabilities. The relevant assumption is zero pairwise
#'   equality, not continuous marginals. All draws must target the same fixed
#'   proper posterior; fitted empirical Bayes quantities held fixed remain part
#'   of that conditioning.
#'
#'   No adaptive stopping or replacement of `S` by MCMC ESS is supported.
#'   Passing the structural checks does not verify IID sampling or prior fixation
#'   of the design. The computed radii are floating-point references, not
#'   verified outward enclosures. They do not assess model misspecification or
#'   frequentist performance across new observed datasets.
#' @seealso [postrank_guarantee_capabilities()], [postrank_regret_bound()],
#'   [postrank_protection_envelopes()]
#' @examples
#' # These choices were fixed before generation in the bundled toy producer.
#' bounds <- postrank_iid_bounds(postrank_toy, alpha = .05,
#'   alpha_by_criterion = c(need_A = .025, need_B = .025),
#'   design = list(sample_sizes_fixed_before_sampling = TRUE,
#'     alpha_fixed_before_sampling = TRUE, adaptive_stopping = FALSE,
#'     planned_sample_sizes = c(need_A = 32L, need_B = 32L),
#'     declaration_note = "Prespecified in the bundled synthetic Normal generator"))
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
