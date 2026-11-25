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

#' Bound Weighted Risk Regret Under Fixed-Sample IID Draws
#'
#' `postrank_regret_bound()` combines simultaneous IID probability radii from
#' [postrank_iid_bounds()] with a solver's whole-problem risk gap to compute an
#' analytic upper bound on posterior weighted-risk regret over a fixed grading
#' family. The bound applies to posterior expected loss rather than differences
#' between grade vectors.
#'
#' @param fit A `postrank_fit` (for example `analysis$fit`) solved on the exact
#'   same input as `bounds` with `objective = "weighted"` and no criterion error
#'   budgets (`q = NULL`). Both `at-most-G_max` and `exact_G` families are
#'   supported when fixed beforehand; `objective = "minimax"` and empirical `q`
#'   constraints stop with an error.
#' @param bounds A matching `postrank_iid_bounds` object from
#'   [postrank_iid_bounds()].
#' @return A `postrank_regret_bound` list containing `weights`, `epsilon`,
#'   weighted probability error `delta_w`, whole-problem solver gap `eta`,
#'   `regret_upper_bound` (`2 * delta_w + eta` when established, otherwise
#'   `NA_real_`), `eta_source`, `unavailable_reason`, `action_space`, and status
#'   flags. When `eta` is usable, `guarantee_status` is `"conditional_bound"`
#'   (`guarantee_issued` and `numerically_verified` remain `FALSE`); when `eta`
#'   is missing or inconsistent, `regret_upper_bound` is `NA_real_` with
#'   `guarantee_status = "not_established"` and `unavailable_reason` stating
#'   why. Invalid or mismatched inputs stop with an error.
#' @details
#' Let \eqn{\delta_w = \sum_k w_k \varepsilon_k}. On the simultaneous
#' \eqn{1 - \alpha} coefficient event of `bounds`, and given a valid absolute
#' risk gap \eqn{\eta = U - L} for the complete empirical problem, the chosen
#' grading's true posterior weighted risk exceeds the minimum true posterior
#' weighted risk over the same fixed grading family by at most
#' \eqn{2 \delta_w + \eta}. Both the selected grading and the comparator must
#' belong to the same non-empty grading family fixed prior to sampling;
#' `postrank` records that assumption without verifying prior fixation.
#'
#' `postrank_regret_bound()` re-runs [validate_postrank_solution()] on
#' `fit$raw_solution` and checks that `fit` has a verified grading, no numerical
#' issues, and a whole-problem lower bound consistent with `fit`'s risk units
#' (including lower bounds clamped within one objective tolerance when
#' `bound_inversion_within_tolerance` is `TRUE`). An unfinished solve (such as
#' `"time_limit"`) is usable when it retains a valid whole-problem lower bound;
#' a raw objective gap, relative gap, restricted candidate-set bound, or solver
#' status label alone is never substituted.
#'
#' Empirical error budgets `q` depend on estimated probabilities and can change
#' which gradings are feasible, so use [postrank_protection_envelopes()] and
#' [postrank_protection_analysis()] when `q` is set. Because the formula is
#' evaluated in ordinary floating-point arithmetic from solver-reported bounds,
#' it does not provide a formal numerical certificate or imply a unique optimal
#' grading.
#' @seealso [postrank_iid_bounds()], [postrank_protection_analysis()],
#'   [postrank_guarantee_capabilities()]
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
#' toy <- postrank_example("toy_analysis")
#' ref <- postrank_regret_bound(toy$fit, bounds)
#' ref[c("delta_w", "eta", "regret_upper_bound", "guarantee_issued")]
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
