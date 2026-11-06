# Lower-bound sources that may be used as a whole-problem lower bound by gap,
# regret and protection-envelope calculations. "_clamped" marks a reported bound
# that exceeded the validated action risk by at most the objective tolerance and
# was set equal to it (floating-point rounding or solver tolerances; not a
# numerical certificate). A clamped inversion larger than the requested absolute
# risk gap is reported with an extra warning (014 repair, Phase 5 review of L5).
.pr_usable_bound_sources <- function() c("backend_reported_dual_bound", "backend_reported_dual_bound_clamped",
  "engine_lp_relaxation_bound", "engine_lp_relaxation_bound_clamped")

# Lower-bound sources a backend or the staged engine may report.
.pr_reported_bound_sources <- function() c("backend_reported_dual_bound", "engine_lp_relaxation_bound")

# Scale-aware objective tolerance in raw units. The reference is the objective
# magnitude sum_j |c_j x_j| of the solution being compared (it cannot cancel
# toward zero), so the tolerance is absolute below one and relative above.
.pr_objective_reference <- function(objective, x) {
  if (!is.numeric(x) || length(x) != length(objective) || !all(is.finite(x))) return(0)
  sum(abs(objective * x))
}
.pr_objective_tolerance_raw <- function(tolerance, reference) {
  reference <- if (length(reference) == 1L && is.finite(reference)) abs(reference) else 0
  tolerance * max(1, reference)
}

.pr_normalize_solver_result <- function(problem, raw, control) {
  .pr_validate_problem(problem)
  .pr_assert(is.list(raw), "backend result must be a raw result record", "invalid_backend_result")
  normalized_enum <- c("optimal", "feasible_not_certified", "infeasible", "unbounded", "time_limit", "numerical_error", "unknown")
  .pr_assert(is.character(raw$status_normalized) && length(raw$status_normalized) == 1L &&
               !is.na(raw$status_normalized) && raw$status_normalized %in% normalized_enum,
             "backend normalized status is outside the public status enum", "invalid_backend_result")
  validation <- validate_postrank_solution(problem, raw$primal, control$tolerances)
  warnings <- if (is.null(raw$warnings)) character() else as.character(raw$warnings)
  issues <- list()
  issue <- function(code, message) {
    issues[[length(issues) + 1L]] <<- list(code = code, message = message)
    warnings <<- c(warnings, message)
  }
  has_incumbent <- isTRUE(raw$has_incumbent) || !is.null(raw$primal)
  if (!identical(isTRUE(raw$has_incumbent), !is.null(raw$primal)))
    issue("incumbent_flag_mismatch", "Backend incumbent flag and returned primal presence disagree.")
  valid <- has_incumbent && isTRUE(validation$valid)
  if (has_incumbent && !valid) issue("invalid_primal", "Returned incumbent failed independent solution validation; no grade is released.")
  if (valid && length(validation$warnings)) warnings <- c(warnings, validation$warnings)
  warnings <- c(warnings, .pr_minimax_degeneracy_warning(problem))
  raw_incumbent <- .pr_solver_number(raw$raw_objective)
  raw_lower <- .pr_solver_number(raw$raw_lower_bound)
  recomputed <- if (valid) .pr_solver_number(validation$recomputed_raw_objective) else NA_real_
  scale <- problem$objective_units$scale; offset <- problem$objective_units$offset
  .pr_assert(length(scale) == 1L && is.finite(scale) && scale > 0 && length(offset) == 1L && is.finite(offset),
             "invalid objective-to-risk scale or offset", "invalid_objective_units")
  # The upper bound is the risk of the independently validated action itself
  # (for minimax: max_k R_k of the grade, not a possibly slack epigraph value).
  upper <- if (valid) .pr_solver_number(validation$evaluation$primary_risk) else NA_real_
  lower_candidate <- if (is.finite(raw_lower)) offset + scale * raw_lower else NA_real_
  objective_tolerance <- validation$tolerances$objective
  if (is.null(objective_tolerance)) objective_tolerance <- 1e-7
  # Objective comparisons are scale-aware (raw objectives grow with the number
  # of pairs). The backend objective is compared like with like: with the
  # objective of the backend's own unrounded primal.
  raw_primal_objective <- if (valid) sum(problem$model$objective * raw$primal) else NA_real_
  mismatch_tolerance <- .pr_objective_tolerance_raw(objective_tolerance,
    .pr_objective_reference(problem$model$objective, raw$primal))
  raw_tolerance <- .pr_objective_tolerance_raw(objective_tolerance,
    if (valid) .pr_objective_reference(problem$model$objective, validation$rounded_solution) else 0)
  risk_bound_difference <- if (is.finite(lower_candidate) && is.finite(upper)) lower_candidate - upper else NA_real_
  raw_bound_difference <- if (is.finite(risk_bound_difference)) risk_bound_difference / scale else NA_real_
  bound_inversion <- FALSE
  if (valid && !is.finite(raw_incumbent))
    issue("missing_incumbent_objective", "Backend omitted a finite incumbent objective; independent feasible-grade risk is retained without an optimality claim.")
  if (valid && is.finite(raw_incumbent) && abs(raw_incumbent - raw_primal_objective) > mismatch_tolerance)
    issue("objective_mismatch", "Backend objective differs from the objective of its own returned primal beyond the scale-aware objective tolerance.")
  # Raw residuals are warnings (validity is judged on the rounded action), but a
  # residual that integrality rounding cannot explain makes the run untrustworthy.
  if (valid) {
    tol <- validation$tolerances
    coefficient <- if (length(problem$model$A@x)) max(abs(problem$model$A@x)) else 1
    residual <- max(validation$raw_residuals$rows_max, validation$raw_residuals$bounds_max)
    if (is.finite(residual) && residual > tol$feasibility + tol$integrality * max(1, coefficient))
      issue("raw_primal_residual_excessive", "Raw primal residuals exceed what the integrality tolerance can explain; the backend bound is excluded from gap calculations.")
  }
  # Known source labels only; an unknown label is an adapter contract violation.
  reported_source <- if (is.null(raw$bound_source)) "backend_reported_dual_bound" else raw$bound_source
  if (is.finite(raw_lower) && !(is.character(reported_source) && length(reported_source) == 1L &&
      !is.na(reported_source) && reported_source %in% .pr_reported_bound_sources())) {
    issue("unrecognized_bound_source", "Backend reported a lower bound with an unrecognized source label; the bound is excluded from gap calculations.")
    reported_source <- "unrecognized"
  }
  if (is.finite(raw_bound_difference) && raw_bound_difference > 0) {
    if (raw_bound_difference > raw_tolerance)
      issue("bound_above_incumbent", "Reported lower bound exceeds the validated action risk beyond objective tolerance; the bound is excluded from gap calculations.")
    else bound_inversion <- TRUE
  }
  normalized <- raw$status_normalized
  if (identical(normalized, "optimal") && !valid)
    issue("optimal_without_valid_incumbent", "Backend optimal status has no independently validated incumbent.")
  if (valid && normalized %in% c("infeasible", "unbounded"))
    issue("status_incumbent_contradiction", "Backend reported an infeasible or unbounded problem together with an independently validated incumbent; the grade is released without an optimality or bound claim.")
  # A numerical termination cannot establish a reusable lower bound even when
  # its independently checked candidate is feasible.
  if (identical(normalized, "numerical_error") && !length(issues))
    issue("backend_numerical_termination", "Backend reported numerical termination; its bound is excluded from gap calculations.")
  if (length(issues)) normalized <- "numerical_error"
  # A clamped bound is used only without issues; only then are the clamp
  # warnings relevant. The second compares the inversion with the gap controls
  # (absolute, or relative on the raw objective) in risk units.
  if (bound_inversion && !length(issues)) {
    warnings <- c(warnings, "Reported lower bound exceeded the validated action risk by at most the objective tolerance; it was clamped to the action risk (absolute gap 0). This reflects floating-point rounding or solver tolerances, not a numerical certificate.")
    gap_control <- max(if (is.numeric(control$absolute_risk_gap)) control$absolute_risk_gap else 0,
      if (is.numeric(control$relative_gap)) control$relative_gap * abs(upper - offset) else 0)
    if (risk_bound_difference > gap_control)
      warnings <- c(warnings, sprintf("The clamped bound inversion (%.3g in risk units) is larger than the requested gap (%.3g in risk units); the solver's tolerances were looser than the gap controls, so the reported optimality rests on those tolerances.",
        risk_bound_difference, gap_control))
  }
  # An infeasible problem has no action to bound, so no lower bound is reported
  # whatever the backend returned (the raw value stays in raw_lower_bound). A
  # validated incumbent with an infeasible status is already a numerical issue.
  infeasible <- identical(normalized, "infeasible")
  lower <- if (length(issues) || infeasible || !is.finite(lower_candidate)) NA_real_ else if (bound_inversion) upper else lower_candidate
  gap <- if (is.finite(upper) && is.finite(lower)) upper - lower else NA_real_
  bound_source <- if (!is.finite(raw_lower) || infeasible) "missing" else if (length(issues)) "backend_reported_rejected_numerical_issue" else
    if (bound_inversion) paste0(reported_source, "_clamped") else reported_source
  # Qualify a backend optimal status using the bounds of the released action.
  # Missing or wide bounds do not invalidate a feasible grade or a valid lower
  # bound. Relative stopping gaps refer to the centered raw objective, so the
  # risk-unit threshold uses upper - offset, not upper. Allow only arithmetic
  # roundoff here; the separate objective tolerance still governs clamping.
  if (identical(normalized, "optimal") && valid) {
    if (!is.finite(lower) || !(bound_source %in% .pr_usable_bound_sources())) {
      normalized <- "feasible_not_certified"
      warnings <- c(warnings, "Backend reported optimal, but no usable whole-problem lower bound is available; the validated grade is retained without an optimality claim.")
    } else {
      gap_control <- max(control$absolute_risk_gap, control$relative_gap * abs(upper - offset))
      gap_roundoff <- 64 * .Machine$double.eps * max(1, abs(upper), abs(lower), abs(offset))
      if (gap > gap_control + gap_roundoff) {
        normalized <- "feasible_not_certified"
        warnings <- c(warnings, sprintf("Backend reported optimal, but the available risk gap (%.3g) exceeds the requested gap (%.3g in risk units); the validated grade and lower bound are retained without an optimality claim.",
          gap, gap_control))
      }
    }
  }
  minimax <- identical(problem$settings$objective, "minimax")
  out <- list(schema_version = "0.1.0", problem_identity = problem$problem_identity,
    input_identity = problem$input_identity, settings = problem$settings, problem = problem,
    backend = raw$backend, engine = raw$engine, status = list(raw_code = raw$raw_status, raw_message = raw$raw_message,
      normalized = normalized, termination_reason = raw$termination_reason),
    has_incumbent = has_incumbent, incumbent_validated = valid,
    raw_solution = raw$primal, solution_validation = validation,
    grade = if (valid) validation$grade else NULL, evaluation = if (valid) validation$evaluation else NULL,
    solution_identity = if(valid).pr_solution_identity(validation$grade,problem$pairwise$entity_ids) else NULL,
    objective = list(primary_action_risk = if(valid)validation$evaluation$primary_risk else NA_real_,
      weighted_auxiliary_risk = if(valid)validation$evaluation$weighted_risk else NA_real_,
      raw_incumbent = raw_incumbent, recomputed_raw_incumbent = recomputed,
      epigraph_value = if (minimax && valid) recomputed else NA_real_,
      raw_lower_bound = raw_lower, raw_units = problem$objective_units$raw,
      risk_upper_bound = upper, upper_bound_source = if (valid) "validated_action_primary_risk" else "missing",
      risk_lower_bound = lower, risk_absolute_gap = gap,
      bound_source = bound_source, scale = scale, offset = offset,
      solver_relative_gap = .pr_solver_number(raw$relative_gap),
      raw_primal_objective = raw_primal_objective,
      incumbent_objective_absolute_difference = if (valid && is.finite(raw_incumbent)) abs(raw_incumbent - raw_primal_objective) else NA_real_,
      incumbent_objective_validation_tolerance = mismatch_tolerance,
      objective_validation_tolerance = objective_tolerance,
      raw_bound_minus_action_raw = raw_bound_difference,
      risk_bound_minus_action_risk = risk_bound_difference,
      bound_inversion_within_tolerance = bound_inversion,
      bound_validation_raw_tolerance = raw_tolerance,
      bound_validation_risk_tolerance = scale * raw_tolerance,
      numerical_certification = FALSE),
    runtime = .pr_solver_number(raw$runtime), raw_backend_result = raw$raw,
    numerical_issues = issues, warnings = unique(warnings))
  class(out) <- c("postrank_fit", "list")
  out
}
