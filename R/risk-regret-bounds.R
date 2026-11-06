.pr_regret_scalar <- function(x) {
  typeof(x) %in% c("integer", "double") && is.null(dim(x)) && length(x) == 1L && is.finite(x)
}

.pr_regret_gap <- function(fit, validation) {
  objective <- fit$objective; problem <- fit$problem
  if (!isTRUE(fit$incumbent_validated) || !isTRUE(validation$valid))
    return(list(eta = NA_real_, reason = "no_independently_validated_incumbent"))
  if (identical(fit$status$normalized, "numerical_error") || length(fit$numerical_issues))
    return(list(eta = NA_real_, reason = "fit_has_numerical_issues"))
  if (fit$status$normalized %in% c("infeasible", "unbounded"))
    return(list(eta = NA_real_, reason = "fit_status_incompatible_with_usable_whole_problem_gap"))
  required <- c("risk_upper_bound", "risk_lower_bound", "risk_absolute_gap", "raw_lower_bound")
  if (!all(vapply(objective[required], .pr_regret_scalar, logical(1))) ||
      !(is.character(objective$bound_source) && length(objective$bound_source) == 1L &&
        objective$bound_source %in% .pr_usable_bound_sources()))
    return(list(eta = NA_real_, reason = "usable_whole_problem_risk_absolute_gap_unavailable"))
  gap <- objective$risk_absolute_gap
  if (gap < 0 || !identical(as.numeric(gap), as.numeric(objective$risk_upper_bound - objective$risk_lower_bound)))
    return(list(eta = NA_real_, reason = "normalized_risk_gap_is_inconsistent"))
  tolerance <- validation$tolerances$objective
  expected_lower <- problem$objective_units$offset + problem$objective_units$scale * objective$raw_lower_bound
  clamped <- grepl("_clamped$", objective$bound_source)
  # The objective tolerance is in raw units; risk differences are compared with
  # its risk-unit equivalent (scale times the scale-aware raw tolerance).
  risk_tolerance <- problem$objective_units$scale *
    .pr_objective_tolerance_raw(tolerance, .pr_objective_reference(problem$model$objective, validation$rounded_solution))
  # A clamped bound equals the action risk and lies at most one objective
  # tolerance (in risk units) below the reported raw bound.
  lower_consistent <- if (clamped) isTRUE(objective$bound_inversion_within_tolerance) &&
      identical(as.numeric(objective$risk_lower_bound), as.numeric(objective$risk_upper_bound)) &&
      expected_lower >= objective$risk_upper_bound &&
      expected_lower - objective$risk_upper_bound <= risk_tolerance else
    identical(as.numeric(objective$risk_lower_bound), as.numeric(expected_lower))
  if (!.pr_regret_scalar(objective$scale) || !.pr_regret_scalar(objective$offset) ||
      objective$scale != problem$objective_units$scale || objective$offset != problem$objective_units$offset ||
      !identical(objective$raw_units, problem$objective_units$raw) ||
      abs(objective$risk_upper_bound - validation$evaluation$weighted_risk) > risk_tolerance ||
      !lower_consistent)
    return(list(eta = NA_real_, reason = "normalized_objective_units_or_values_are_inconsistent"))
  list(eta = as.numeric(gap), reason = NULL)
}

#' Bound Weighted Risk with IID and Optimization Errors
#'
#' A conditional regret reference is calculated for a weighted report selected
#' from the same fixed action family as its comparator. Probability
#' approximation error is combined with an absolute optimization gap for the
#' complete empirical problem. The resulting bound concerns risk rather than
#' differences between grade vectors.
#'
#' @param fit A normalized `postrank_fit` for the weighted problem on exactly
#'   the input used for `bounds`. At-most-G and exact-G families are supported
#'   when held fixed. Empirical `q` protections and minimax are unsupported here.
#' @param bounds A matching object from [postrank_iid_bounds()].
#' @return A `postrank_regret_bound` object containing `delta_w`, the usable
#'   absolute risk gap `eta`, and `regret_upper_bound` when established.
#'   Missing or unusable gap information produces `NA` with
#'   `guarantee_status = "not_established"` and an explicit reason. Invalid or
#'   mismatched inputs raise an error. A computed result remains an uncertified
#'   conditional floating-point reference.
#' @details Write \eqn{\delta_w=\sum_k w_k\varepsilon_k}. On the simultaneous
#'   coefficient event, true supplied-law regret is at most
#'   \eqn{2\delta_w+\eta}, assuming a valid empirical whole-problem gap
#'   \eqn{\eta=U-L}. Both the chosen action and the true-risk comparator must
#'   belong to the same nonempty fixed family. The function records that
#'   assumption; it cannot verify that the analyst fixed the family in advance.
#'
#'   The fit's incumbent is independently revalidated. The gap must be the
#'   normalized absolute gap in risk units from the same complete problem.
#'   A raw objective gap, relative gap, restricted candidate-set lower bound,
#'   or status label alone is insufficient. A numerically validated but
#'   unfinished solve can be usable when it retains the required whole-problem
#'   bound. Numerical issues or inconsistent bounds prevent the calculation.
#'
#'   Empirical protection constraints can change the feasible family when
#'   coefficients change, so the common-family argument does not apply to them.
#'   Use [postrank_protection_envelopes()] and [postrank_protection_analysis()]
#'   for that separate construction. The reference certifies neither arithmetic
#'   nor backend bounds, posterior calibration, or a unique selected grade.
#' @seealso [postrank_iid_bounds()], [postrank_guarantee_capabilities()]
#' @examples
#' bounds <- postrank_iid_bounds(postrank_toy, alpha = .05,
#'   alpha_by_criterion = c(need_A = .025, need_B = .025),
#'   design = list(sample_sizes_fixed_before_sampling = TRUE,
#'     alpha_fixed_before_sampling = TRUE, adaptive_stopping = FALSE,
#'     planned_sample_sizes = c(need_A = 32L, need_B = 32L),
#'     declaration_note = "Prespecified in the bundled synthetic Normal generator"))
#' problem <- postrank_problem(postrank_pairwise(postrank_toy),
#'   weights = c(need_A = .6, need_B = .4), tau = .25, G_max = 3L)
#' \dontrun{
#' # Optional native solve; requires an installed HiGHS backend.
#' fit <- postrank_solve(problem, backend = "highs",
#'   control = postrank_control(time_limit = 10, threads = 1))
#' reference <- postrank_regret_bound(fit, bounds)
#' reference[c("delta_w", "eta", "regret_upper_bound", "guarantee_issued")]
#' }
#' @concept reference
#' @export
postrank_regret_bound <- function(fit, bounds) {
  .pr_validate_iid_bounds(bounds)
  .pr_assert(inherits(fit, "postrank_fit") && identical(fit$schema_version, "0.1.0"),
    "Expected current postrank_fit", "invalid_fit")
  problem <- fit$problem; .pr_validate_problem(problem)
  .pr_assert(identical(fit$problem_identity, problem$problem_identity) &&
    identical(fit$input_identity, problem$input_identity) && identical(fit$settings, problem$settings),
    "Fit problem, input identity or settings changed after normalization", "stale_fit")
  .pr_assert(identical(bounds$input_identity, problem$input_identity) &&
    identical(bounds$entity_ids, problem$pairwise$entity_ids) &&
    identical(bounds$criterion_ids, problem$pairwise$criterion_ids),
    "IID bounds and fit must use exactly the same input", "iid_bound_input_mismatch")
  .pr_assert(identical(problem$settings$objective, "weighted"),
    "The weighted regret formula does not support minimax", "unsupported_regret_objective")
  .pr_assert(is.null(problem$settings$q),
    "Empirical q constraints change the feasible set; use the separate inner/outer analysis",
    "unsupported_regret_protection")
  .pr_assert(is.list(fit$status) && is.character(fit$status$normalized) &&
    length(fit$status$normalized) == 1L && !is.na(fit$status$normalized),
    "Fit has no normalized status", "invalid_fit")
  tolerances <- if (is.list(fit$solution_validation)) fit$solution_validation$tolerances else list()
  validation <- validate_postrank_solution(problem, fit$raw_solution, tolerances)
  if (isTRUE(validation$valid) && isTRUE(fit$incumbent_validated))
    .pr_assert(identical(fit$grade, validation$grade),
      "Fit grade differs from the independently reconstructed primal", "stale_fit")
  connection <- .pr_regret_gap(fit, validation)
  delta <- sum(problem$settings$weights * bounds$epsilon)
  computed <- is.null(connection$reason)
  out <- c(list(schema_version = "0.1.0", input_identity = problem$input_identity,
    problem_identity = problem$problem_identity, bound_identity = bounds$bound_identity,
    entity_ids = bounds$entity_ids, criterion_ids = bounds$criterion_ids,
    weights = problem$settings$weights, epsilon = bounds$epsilon,
    delta_w = delta, eta = connection$eta,
    regret_upper_bound = if (computed) 2 * delta + connection$eta else NA_real_,
    reference_interpretation = "theoretical_floating_reference",
    eta_source = if (computed) "normalized_whole_problem_risk_absolute_gap" else NULL,
    unavailable_reason = connection$reason,
    action_space = list(type = if (is.null(problem$settings$exact_G)) "at_most_G_max" else "exact_G",
      G_max = problem$settings$G_max, exact_G = problem$settings$exact_G,
      empirical_q_constraints = FALSE, fixed_space_assumed = TRUE,
      prior_fixation_verified = FALSE)),
    .pr_guarantee_status(if (computed) "conditional_bound" else "not_established",
      bound_computed = computed, reason = if (computed)
        "2 * delta_w + eta evaluated as an uncertified conditional floating reference" else connection$reason,
      assumptions = c(bounds$assumptions, list(
      fixed_action_space = "same_nonempty_fixed_space_for_true_and_empirical_risk",
      empirical_gap = "valid_lower_bound_for_the_same_complete_problem_not_a_restricted_candidate_set",
      numerical_validity = "coefficient_enclosure_and_solver_bound_validity_not_numerically_certified",
      statistical_interpretation = "conditional_reference_not_model_validity_or_posterior_probability"))))
  class(out) <- c("postrank_regret_bound", "list")
  out$regret_identity <- .pr_identity(out)
  out
}
