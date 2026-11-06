# Minimax as a secondary mode (014 repair, decision 3).
#
# Stage 1 finds the minimax value t* (the validated action's maximum selected
# criterion risk). Stage 2 minimises the weighted risk over actions whose
# selected criterion risks are all at most t* (the same grade-count and
# protection rows). The minimax argmin is often large; without stage 2 a solver
# may return an action that another minimax-optimal action improves on every
# criterion. Stage 2 preserves the original weights. If any weight is zero,
# stage 3 minimizes uniform criterion risk under a cap on the original weighted
# optimum, preserving the exact declared objective order without perturbation.

# Share of control$time_limit given to stage 1 when the second stage is on;
# refinement gets the rest (at least one second shared by stages 2/3).
.pr_minimax_stage1_share <- .75

# A selected criterion is degenerate when no disclosure can lower its risk:
# every directional error probability is at least tau, so its risk is at least
# tau for every action. When all-tie is allowed (no exact grade count above one)
# the minimax value is then tau and all-tie attains it.
.pr_minimax_degenerate_criteria <- function(pairwise, tau, selected) {
  selected[vapply(selected, function(k) {
    e <- pairwise$e[, , match(k, pairwise$criterion_ids)]
    all(e[row(e) != col(e)] >= tau)
  }, logical(1L))]
}

.pr_minimax_diagnostics <- function(pairwise, tau, selected) {
  list(degenerate_criteria = .pr_minimax_degenerate_criteria(pairwise, tau, selected),
    rule = "A selected criterion is degenerate when e_ijk >= tau for every ordered pair: no disclosure lowers its risk below tau.")
}

.pr_minimax_degeneracy_warning <- function(problem) {
  degenerate <- problem$minimax_diagnostics$degenerate_criteria
  if (!identical(problem$settings$objective, "minimax") || !length(degenerate)) return(character())
  exact <- problem$settings$exact_G
  sprintf("Minimax criterion %s is degenerate: every directional error probability is at least tau, so no action brings its risk below tau and the minimax value is at least tau. %s",
    paste(degenerate, collapse = ", "),
    if (is.null(exact) || exact <= 1L) "Because abstaining on every pair is allowed, the minimax value is tau and all-tie attains it (uniquely when every inequality is strict); the second stage cannot disclose a pair with error above tau on that criterion."
    else "With an exact grade count all-tie is not allowed, so the minimax value can exceed tau.")
}

# Rows sum_{i != j} x_ij (e_ijk - tau) <= M (cap_k - tau), i.e. R_k <= cap_k.
.pr_add_risk_caps <- function(problem, caps) {
  pairwise <- problem$pairwise; tau <- problem$settings$tau
  criteria <- match(names(caps), pairwise$criterion_ids)
  .pr_assert(!anyNA(criteria), "risk cap criterion absent from pairwise coefficients", "invalid_problem")
  index <- problem$index; P <- length(index$pairs); R <- length(caps); columns <- ncol(problem$model$A)
  M <- choose(length(pairwise$entity_ids), 2)
  coefficients <- unlist(lapply(seq_len(R), function(r)
    pairwise$e[, , criteria[r]][cbind(index$pair_i, index$pair_j)] - tau), use.names = FALSE)
  rows <- Matrix::sparseMatrix(i = rep(seq_len(R), each = P), j = rep(index$pairs, times = R),
    x = coefficients, dims = c(R, columns))
  problem$model$A <- methods::as(rbind(problem$model$A, Matrix::drop0(rows)), "CsparseMatrix")
  problem$model$row_lower <- c(problem$model$row_lower, rep(-Inf, R))
  problem$model$row_upper <- c(problem$model$row_upper, M * (unname(caps) - tau))
  problem$model$row_names <- c(problem$model$row_names, paste0("risk_cap_", criteria))
  problem
}

# Stage-2 problem: the original weighted problem, not a perturbed objective.
# Centering before weighting retains small nonzero contributions when a large
# weight multiplies a constant criterion. A positive scale makes the native
# objective order one; bounds are converted back before public normalization.
.pr_minimax_refine_problem <- function(problem, caps, weights = problem$settings$weights) {
  s <- problem$settings
  out <- postrank_problem(problem$pairwise, weights, s$tau, s$G_max, objective = "weighted", q = s$q, exact_G = s$exact_G)
  out$problem_identity <- NULL
  out <- .pr_add_risk_caps(out, caps)
  out$settings$risk_caps <- caps
  out$minimax_refine_of <- problem$problem_identity
  index <- out$index
  out$model$objective[index$pairs] <- vapply(seq_along(index$pairs), function(h)
    sum(weights * (problem$pairwise$e[index$pair_i[h], index$pair_j[h], ] - s$tau)) +
      s$tau * (sum(weights) - 1), numeric(1L))
  out$problem_identity <- .pr_identity(out)
  .pr_validate_problem(out)
  out
}

.pr_minimax_fit_summary <- function(fit) list(status = fit$status$normalized,
  incumbent_validated = isTRUE(fit$incumbent_validated),
  primary_risk = fit$objective$primary_action_risk, weighted_risk = fit$objective$weighted_auxiliary_risk,
  risk_lower_bound = fit$objective$risk_lower_bound, risk_absolute_gap = fit$objective$risk_absolute_gap,
  criterion_risk = if (is.null(fit$evaluation)) NULL else fit$evaluation$criterion_risk,
  relation_identity = if (is.null(fit$solution_identity)) NULL else fit$solution_identity$relation_identity)

.pr_minimax_centered_value <- function(problem, grade) {
  x <- grade[problem$index$pair_i] < grade[problem$index$pair_j]
  sum(problem$model$objective[problem$index$pairs][x])
}

# Machine-rounding allowance in centered objective units. It deliberately has
# no absolute 1e-12 floor: that floor can erase an entire small positive weight.
.pr_minimax_roundoff <- function(problem, grades) {
  c <- problem$model$objective[problem$index$pairs]
  reference <- max(vapply(grades, function(g)
    sum(abs(c[g[problem$index$pair_i] < g[problem$index$pair_j]])), numeric(1L)), .Machine$double.xmin)
  64 * .Machine$double.eps * reference
}

# Tertiary Pareto optimization keeps the ORIGINAL secondary objective fixed.
# Scale this cap separately, so a tiny original weight cannot disappear under
# an absolute model-row feasibility tolerance.
.pr_minimax_add_weighted_cap <- function(problem3, problem2, grade2) {
  c <- problem2$model$objective[problem2$index$pairs]
  magnitude <- max(abs(c)); if (!is.finite(magnitude) || magnitude == 0) magnitude <- 1
  c <- c / magnitude
  rhs <- sum(c[grade2[problem2$index$pair_i] < grade2[problem2$index$pair_j]])
  row <- Matrix::sparseMatrix(i = rep(1L, length(c)), j = problem3$index$pairs,
    x = c, dims = c(1L, ncol(problem3$model$A)))
  problem3$problem_identity <- NULL
  problem3$model$A <- methods::as(rbind(problem3$model$A, Matrix::drop0(row)), "CsparseMatrix")
  problem3$model$row_lower <- c(problem3$model$row_lower, -Inf)
  problem3$model$row_upper <- c(problem3$model$row_upper, rhs)
  problem3$model$row_names <- c(problem3$model$row_names, "original_weighted_risk_cap")
  A <- matrix(0, length(grade2), length(grade2))
  A[cbind(problem3$index$pair_i, problem3$index$pair_j)] <- c
  problem3$settings$linear_caps <- list(list(A = A, b = rhs, id = "original_weighted_risk_cap"))
  problem3$settings$original_weighted_cap <- list(centered_raw = rhs * magnitude,
    coefficient_magnitude = magnitude, scaled_rhs = rhs)
  problem3$problem_identity <- .pr_identity(problem3)
  problem3
}

# Solve a positively scaled copy, then normalize in the unscaled problem's
# units. Both strategies use the same sparse objective and cap rows. A fallback
# shares this stage's deadline; it never grants an extra two-second budget.
.pr_minimax_solve_stage <- function(problem, backend, control, strategy, seed_grade) {
  started <- proc.time()[["elapsed"]]
  scaled <- problem; scaled$problem_identity <- NULL
  magnitude <- max(abs(problem$model$objective)); if (!is.finite(magnitude) || magnitude == 0) magnitude <- 1
  scaled$model$objective <- problem$model$objective / magnitude
  scaled$objective_units$scale <- problem$objective_units$scale * magnitude
  scaled$problem_identity <- .pr_identity(scaled)
  ctrl <- control
  # In scaled raw units request at most 1e-9, even if the public absolute risk
  # tolerance is larger than the complete range of the secondary objective.
  ctrl$absolute_risk_gap <- min(ctrl$absolute_risk_gap, scaled$objective_units$scale * 1e-9)
  ctrl$relative_gap <- min(ctrl$relative_gap, 1e-9)
  run <- function(ctrl, engine_only = FALSE) tryCatch({
    if (engine_only) .pr_engine_staged(scaled, backend, ctrl, seed_grades = list(seed_grade))
    else .pr_solve_raw(scaled, backend, ctrl, strategy, seed_grades = list(seed_grade))
  }, error = function(e) e)
  raw <- run(ctrl)
  fallback <- FALSE
  has_action <- function(raw) !inherits(raw, "error") && !is.null(raw$primal) &&
    isTRUE(validate_postrank_solution(problem, raw$primal, control$tolerances)$valid)
  remaining <- control$time_limit - (proc.time()[["elapsed"]] - started)
  if (!has_action(raw) && remaining > .02) {
    quick <- ctrl; quick$time_limit <- remaining
    quick$engine <- utils::modifyList(control$engine, list(max_cut_rounds = 0L, mip = "never"), keep.null = TRUE)
    candidate <- run(quick, engine_only = TRUE)
    if (has_action(candidate)) { raw <- candidate; fallback <- TRUE }
  }
  if (inherits(raw, "error")) return(list(error = conditionMessage(raw), fallback = fallback))
  native <- raw
  raw$raw_objective <- raw$raw_objective * magnitude
  raw$raw_lower_bound <- raw$raw_lower_bound * magnitude
  fit <- tryCatch(.pr_normalize_solver_result(problem, raw, control), error = function(e) e)
  if (inherits(fit, "error")) return(list(error = conditionMessage(fit), fallback = fallback))
  U <- if (isTRUE(fit$incumbent_validated)) sum(scaled$model$objective * fit$solution_validation$rounded_solution) else NA_real_
  L <- .pr_solver_number(native$raw_lower_bound)
  rounding <- if (isTRUE(fit$incumbent_validated))
    64 * .Machine$double.eps * max(1, .pr_objective_reference(scaled$model$objective, fit$solution_validation$rounded_solution)) else 0
  gap_target <- max(ctrl$absolute_risk_gap / scaled$objective_units$scale, ctrl$relative_gap * abs(U))
  certified <- identical(fit$status$normalized, "optimal") && is.finite(U) && is.finite(L) &&
    U - L >= -rounding && U - L <= gap_target + rounding
  list(fit = fit, certified = isTRUE(certified), fallback = fallback,
    optimization = list(coefficient_magnitude = magnitude, scaled_raw_upper = U, scaled_raw_lower = L,
      scaled_raw_gap = U - L, scaled_raw_gap_target = gap_target,
      scaled_raw_roundoff = rounding, absolute_risk_gap = ctrl$absolute_risk_gap,
      relative_gap = ctrl$relative_gap, original_risk_scale = problem$objective_units$scale,
      scaled_risk_scale = scaled$objective_units$scale, time_limit = ctrl$time_limit))
}

# Preserve primary minimax -> ORIGINAL weighted risk -> positive-weight Pareto
# tie-breaking. The final certificate refers to the actual released action and
# requires every applicable stage, finite bounds/gaps and strict post-solve caps.
.pr_minimax_refine <- function(problem, fit1, backend, control, strategy, started) {
  elapsed <- function() proc.time()[["elapsed"]] - started
  record <- list(mode = "weighted", applied = FALSE, improved = FALSE, lexicographic_certified = FALSE,
    weighted_stage_certified = FALSE, pareto_stage_certified = FALSE, pareto_certified = FALSE, stage2_weights_perturbed = FALSE,
    stage1 = .pr_minimax_fit_summary(fit1),
    time_limits = list(total = control$time_limit, stage1 = .pr_minimax_stage1_share * control$time_limit,
      stage2 = NA_real_, stage3 = NA_real_))
  finish <- function(fit, reason, warn = TRUE) {
    record$reason <- reason; record$elapsed <- elapsed()
    record$released_relation_identity <- if (is.null(fit$solution_identity)) NULL else fit$solution_identity$relation_identity
    fit$minimax_refine <- record; fit$runtime <- elapsed()
    if (warn) fit$warnings <- unique(c(fit$warnings,
      "Minimax refinement was not certified for the released action; its weighted or Pareto tie-breaking may remain incomplete."))
    fit
  }
  if (!isTRUE(fit1$incumbent_validated)) return(finish(fit1, "stage1_without_validated_incumbent", FALSE))
  if (identical(fit1$status$normalized, "numerical_error")) return(finish(fit1, "stage1_numerical_issue"))
  weights <- problem$settings$weights; ids <- problem$pairwise$criterion_ids
  selected <- problem$settings$minimax_criteria
  if (is.null(selected)) selected <- ids
  caps <- stats::setNames(rep(fit1$objective$risk_upper_bound, length(selected)), selected)
  record$caps <- caps
  cap_tolerance <- 64 * .Machine$double.eps * max(1, abs(caps))
  cap_ok <- function(fit) isTRUE(fit$incumbent_validated) &&
    all(fit$evaluation$criterion_risk[selected] <= caps + cap_tolerance)
  # Preserve the historical one-second minimum for refinement after a starved
  # first stage, shared across stages 2/3 and any fallback, not renewed per call.
  deadline <- max(started + control$time_limit, proc.time()[["elapsed"]] + 1)
  record$time_limits$refinement_deadline_from_start <- deadline - started
  remaining <- function() max(0, deadline - proc.time()[["elapsed"]])
  third_needed <- any(weights == 0)
  stage2 <- tryCatch(.pr_minimax_refine_problem(problem, caps), error = function(e) e)
  if (inherits(stage2, "error")) return(finish(fit1, paste("stage2_construction_error", conditionMessage(stage2))))
  grade <- function(fit) unname(fit$grade[problem$pairwise$entity_ids])
  grade1 <- grade(fit1); best <- fit1
  ctrl2 <- control; ctrl2$time_limit <- remaining() * if (third_needed) .5 else 1
  record$time_limits$stage2 <- ctrl2$time_limit
  if (ctrl2$time_limit <= 0) return(finish(fit1, "refinement_budget_exhausted"))
  solved2 <- .pr_minimax_solve_stage(stage2, backend, ctrl2, strategy, grade1)
  record$stage2_heuristic_fallback <- isTRUE(solved2$fallback)
  record$stage2_optimization <- solved2$optimization
  if (is.null(solved2$fit)) return(finish(fit1, paste("stage2_error", solved2$error)))
  fit2 <- solved2$fit; record$stage2 <- .pr_minimax_fit_summary(fit2)
  record$stage2_problem_identity <- stage2$problem_identity
  if (!cap_ok(fit2)) return(finish(fit1, "stage2_action_violates_primary_cap"))
  record$applied <- TRUE
  z1 <- .pr_minimax_centered_value(stage2, grade1); z2 <- .pr_minimax_centered_value(stage2, grade(fit2))
  tolerance2 <- .pr_minimax_roundoff(stage2, list(grade1, grade(fit2)))
  if (z2 <= z1 + tolerance2) best <- fit2
  record$weighted_stage_certified <- isTRUE(solved2$certified)
  solved3 <- NULL; stage3 <- NULL
  if (third_needed && remaining() > 0) {
    uniform <- stats::setNames(rep(1 / length(ids), length(ids)), ids)
    stage3 <- .pr_minimax_refine_problem(problem, caps, uniform)
    stage3 <- .pr_minimax_add_weighted_cap(stage3, stage2, grade(best))
    record$original_weighted_cap <- stage3$settings$original_weighted_cap
    ctrl3 <- control; ctrl3$time_limit <- remaining(); record$time_limits$stage3 <- ctrl3$time_limit
    solved3 <- .pr_minimax_solve_stage(stage3, backend, ctrl3, strategy, grade(best))
    record$stage3_heuristic_fallback <- isTRUE(solved3$fallback)
    record$stage3_optimization <- solved3$optimization
    if (!is.null(solved3$fit)) {
      fit3 <- solved3$fit; record$stage3 <- .pr_minimax_fit_summary(fit3)
      record$stage3_problem_identity <- stage3$problem_identity
      if (cap_ok(fit3)) {
        g_best <- grade(best); g3 <- grade(fit3)
        zb <- .pr_minimax_centered_value(stage2, g_best); z3 <- .pr_minimax_centered_value(stage2, g3)
        t2 <- .pr_minimax_roundoff(stage2, list(g_best, g3))
        ub <- .pr_minimax_centered_value(stage3, g_best); u3 <- .pr_minimax_centered_value(stage3, g3)
        t3 <- .pr_minimax_roundoff(stage3, list(g_best, g3))
        # Never exchange an original-weighted improvement for a tertiary gain.
        if (z3 < zb - t2 || (z3 <= zb + t2 && u3 <= ub + t3)) best <- fit3
      }
    } else record$stage3_error <- solved3$error
  }
  r <- best$evaluation$criterion_risk[ids]
  # Normalize the selected grade in the ORIGINAL minimax problem. The only
  # reusable primary lower bound remains stage 1's minimax bound.
  status <- fit1$status$normalized; L1 <- fit1$objective$risk_lower_bound; U <- max(r[selected])
  primary_target <- max(control$absolute_risk_gap, control$relative_gap * abs(U))
  if (identical(status, "optimal") && (!is.finite(L1) || U - L1 > primary_target + cap_tolerance))
    status <- "feasible_not_certified"
  primal <- .pr_engine_primal(problem, grade(best))
  usable <- isTRUE(fit1$objective$bound_source %in% .pr_usable_bound_sources())
  raw <- list(primal = primal, raw_status = fit1$status$raw_code,
    raw_message = paste("minimax with original weighted refinement; stage 1:", fit1$status$raw_message),
    status_normalized = status, termination_reason = fit1$status$termination_reason,
    has_incumbent = TRUE, raw_objective = sum(problem$model$objective * primal),
    raw_lower_bound = if (usable) fit1$objective$raw_lower_bound else NA_real_,
    bound_source = if (usable) sub("_clamped$", "", fit1$objective$bound_source) else NULL,
    relative_gap = NA_real_, runtime = elapsed(), backend = fit1$backend,
    engine = c(fit1$engine, list(second_stage = fit2$engine,
      third_stage = if (!is.null(solved3$fit)) solved3$fit$engine else NULL)),
    raw = list(stage1 = fit1$raw_backend_result, stage2 = fit2$raw_backend_result,
      stage3 = if (!is.null(solved3$fit)) solved3$fit$raw_backend_result else NULL),
    warnings = unique(c(fit1$warnings, if (length(fit2$warnings)) paste("Second stage:", fit2$warnings),
      if (!is.null(solved3$fit) && length(solved3$fit$warnings)) paste("Third stage:", solved3$fit$warnings))))
  final <- tryCatch(.pr_normalize_solver_result(problem, raw, control), error = function(e) e)
  if (inherits(final, "error")) return(finish(fit1, paste("final_normalization_error", conditionMessage(final))))
  g <- grade(final)
  same_secondary <- abs(.pr_minimax_centered_value(stage2, g) - z2) <=
    .pr_minimax_roundoff(stage2, list(g, grade(fit2)))
  primary_certified <- identical(fit1$status$normalized, "optimal") && identical(final$status$normalized, "optimal") &&
    is.finite(final$objective$risk_absolute_gap) && cap_ok(final) &&
    final$objective$risk_absolute_gap <= primary_target + cap_tolerance
  weighted_certified <- record$weighted_stage_certified && same_secondary
  pareto_certified <- if (!third_needed) weighted_certified else
    !is.null(solved3$fit) && isTRUE(solved3$certified) && cap_ok(solved3$fit) &&
    .pr_minimax_centered_value(stage2, grade(solved3$fit)) <=
      stage3$settings$original_weighted_cap$centered_raw +
        .pr_minimax_roundoff(stage2, list(g, grade(solved3$fit))) &&
    abs(.pr_minimax_centered_value(stage3, g) - .pr_minimax_centered_value(stage3, grade(solved3$fit))) <=
      .pr_minimax_roundoff(stage3, list(g, grade(solved3$fit)))
  record$pareto_stage_certified <- isTRUE(pareto_certified)
  record$lexicographic_certified <- isTRUE(primary_certified && weighted_certified)
  record$pareto_certified <- isTRUE(record$lexicographic_certified && pareto_certified)
  record$certification <- list(primary = primary_certified, original_weighted = weighted_certified,
    pareto = isTRUE(pareto_certified), basis = "solver_reported_bounds_with_scaled_gap_controls_and_post_solve_caps",
    numerical_certificate = FALSE, primary_cap_tolerance = cap_tolerance,
    released_centered_secondary = .pr_minimax_centered_value(stage2, g),
    stage2_centered_secondary = z2)
  record$improved <- !identical(final$solution_identity$relation_identity, fit1$solution_identity$relation_identity)
  finish(final, if (record$pareto_certified) "released_action_lexicographic_and_pareto_certified" else
    if (record$lexicographic_certified) "released_action_lexicographic_certified_pareto_not_certified" else
    "released_action_refinement_not_certified", warn = !record$pareto_certified)
}
