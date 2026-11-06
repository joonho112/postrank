#' Find Grades and Report Their Optimization Bounds
#'
#' A grading is sought within the family specified by [postrank_problem()].
#' Returned grades must satisfy an independent feasibility check. The fit
#' retains the candidate, its directly recomputed posterior risk, the reported
#' lower bound and the termination status. These records distinguish the
#' available action from the numerical conclusions about optimality.
#'
#' @param problem A `postrank_problem` specifying the supplied probabilities,
#'   loss, grade limit and any supported error-budget or exact-count constraints.
#' @param backend `NULL` (default), `"gurobi"` or `"highs"`. An explicit choice
#'   takes precedence; otherwise `getOption("postrank.backend")` is used, then Gurobi if unset.
#'   The chosen name and source (`"explicit"`, `"option"` or `"default"`) are
#'   recorded in `fit$backend`. HiGHS must be chosen explicitly or through the
#'   option. A missing, failed or timed-out backend is never replaced automatically.
#' @param control A [postrank_control()] object or named list of time, thread,
#'   seed, gap and tolerance controls. `engine` contains staged-search options.
#'   Package progress messages and native solver logs have separate switches.
#' @param strategy `NULL` uses `control$strategy`, or `"staged"` if absent.
#'   An explicit `"staged"` or `"label_mip"` overrides the control object's choice.
#' @return A `postrank_fit`. `incumbent_validated` identifies whether `grade`
#'   and `evaluation` are available; `solution_validation` retains the independent
#'   check. `status` contains `raw_code`, `raw_message`, `normalized` and
#'   `termination_reason`. `objective` contains `primary_action_risk`,
#'   `risk_upper_bound`, `risk_lower_bound`, `risk_absolute_gap`, raw objective
#'   values and their conversion, and the `bound_source`.
#'   `problem`, `settings`, `backend`, `engine`, warnings and numerical issues
#'   preserve the calculation's context. Minimax refinement adds `minimax_refine`.
#' @section Candidate feasibility and optimization bounds:
#'   A validated candidate's recomputed primary risk is the upper bound U.
#'   A usable lower bound L concerns the whole declared problem; the absolute
#'   risk gap is U-L. For minimax, U is the grade's largest included criterion
#'   risk, not a possibly slack auxiliary variable. A weighted raw gap must be
#'   converted using `R = tau + Z/M`; a raw relative gap is not the same as a
#'   relative gap in risk.
#'
#'   `optimal` is a numerical conclusion subject to recorded gap controls and
#'   tolerances. A backend's optimal label becomes `feasible_not_certified`
#'   if a valid candidate lacks a usable bound or has an excessive gap.
#'   A `time_limit` result may
#'   or may not contain a validated grade. With no validated grade, action risk
#'   and gap are unavailable, even if a useful lower bound remains. This is
#'   different from a valid one-grade report withholding all comparisons.
#'
#'   Inconsistent bounds can be rejected while independently validated grades
#'   remain available. Small bound inversions within the recorded objective
#'   tolerance may instead be clamped with a warning. Inspect `bound_source`,
#'   numerical issues and warnings; these are not exact numerical certificates,
#'   posterior uncertainty intervals, or proof of a unique optimal grade.
#'
#' @section Search strategies:
#'   `"label_mip"` sends the integer-label model to the selected backend.
#'   `"staged"` first constructs candidates using contiguous cuts of several
#'   priority orders and local search. It then solves a linear relaxation with
#'   comparison constraints, including separated triangle inequalities and
#'   disclosure-count bounds implied by the grade limits. This can bound the
#'   full problem even though the initial candidate searches use fixed orders.
#'   If a gap remains and the size/settings permit, it runs a strengthened
#'   label MIP. Gurobi can use the candidate as a MIP start.
#'
#'   Staged-search defaults in `control$engine` are `local_search_passes = 20`,
#'   `local_search_starts = 5`, `max_cut_rounds = 60`, `cuts_per_round = NULL`
#'   (meaning `max(200, 10 * n)`), `lp_time_share = .5`, `mip = "auto"` and
#'   `mip_max_n = 200`. `mip` may also be `"always"` or `"never"`; `"auto"`
#'   runs the MIP only up to `mip_max_n`. With a possible MIP stage, the LP gets
#'   `lp_time_share` of the remaining budget. Otherwise it can use the remainder
#'   less a reserve for candidate construction and validation: the largest of
#'   one second, 1% of the time limit and twice the initial candidate-stage time.
#'   It receives at least the usual LP share. `fit$engine$stages` records what
#'   ran, including the LP `time_budget` and `time_budget_rule`.
#'
#' @section Interpretation of minimax refinement:
#'   With `minimax_refine = "weighted"`, the first stage minimizes the largest
#'   selected criterion risk. A second stage minimizes the original weighted
#'   risk while retaining the first-stage criterion caps. If any weight is zero,
#'   a third stage minimizes uniform criterion risk while also retaining a cap
#'   on the original weighted objective. No weight perturbation is used.
#'   Centered/scaled internal calculations retain the original public risk units.
#'
#'   Stage 1 receives three quarters of the time budget. Refinement shares
#'   the remainder, with at least one second in total after stage 1; with zero
#'   weights, stage 2 initially receives half and stage 3 the time left.
#'   Heuristic fallbacks share their stage's deadline. Construction and
#'   validation add overhead, so `time_limit` is not a strict wall-clock bound.
#'   The final primary status and lower bound come from stage 1 and are checked
#'   against the released action. A candidate that breaches primary caps or
#'   worsens the original weighted objective beyond machine rounding is excluded.
#'
#'   `fit$minimax_refine` records stage results, budgets and the released action.
#'   `lexicographic_certified` requires primary and original-weighted
#'   certification for that action; `pareto_certified` also requires the
#'   zero-weight third stage when applicable. These flags remain subject to
#'   solver gaps and floating-point tolerances. Skipped or uncertified refinement
#'   is reported with a warning when a first-stage action is available.
#'   `minimax_refine = "none"` keeps the first-stage action.
#'   `fit$backend$options` retains the first-stage options.
#' @seealso [postrank_problem()], [postrank_control()],
#'   [validate_postrank_solution()], [get_risk()]
#' @examples
#' problem <- postrank_problem(pr_tutorial$one, weights = c(score_A = 1),
#'   tau = .2, G_max = 3L)
#' if (requireNamespace("highs", quietly = TRUE)) {
#'   fit <- postrank_solve(problem, backend = "highs",
#'     control = postrank_control(time_limit = 10))
#'   fit$status$normalized
#'   fit$objective[c("risk_lower_bound", "risk_upper_bound", "risk_absolute_gap")]
#' }
#' @concept decision
#' @export
postrank_solve <- function(problem, backend = NULL, control = list(), strategy = NULL) {
  resolved <- .pr_resolve_backend(backend)
  cc <- .pr_core_control(control, strategy)
  progress <- isTRUE(cc$verbose) && !isTRUE(.pr_state$progress_suppressed)
  if (progress) message("postrank: finding grades with ", if (resolved$name == "highs") "HiGHS." else "Gurobi.")
  fit <- .pr_with_backend(resolved, .pr_solve_core(problem, resolved$name, cc$core, cc$strategy))
  fit <- .pr_fit_annotate(fit, resolved)
  if (progress) message(if (isTRUE(fit$incumbent_validated))
    "postrank: finished; a validated grade report is available." else
    "postrank: finished; no validated grade report is available.")
  fit
}

# Unchanged 0.0.1.9002 body, moved behind the public adapter (freeze manifest: moved_from postrank_solve).
.pr_solve_core <- function(problem, backend = c("gurobi", "highs"), control = list(),
                           strategy = c("staged", "label_mip")) {
  .pr_validate_problem(problem); backend <- match.arg(backend); strategy <- match.arg(strategy)
  control <- .pr_control(control); started <- proc.time()[["elapsed"]]
  refine <- identical(problem$settings$objective, "minimax") && identical(problem$settings$minimax_refine, "weighted")
  # With the minimax second stage, stage 1 gets three quarters of the budget.
  control1 <- control; if (refine) control1$time_limit <- .pr_minimax_stage1_share * control$time_limit
  fit <- .pr_normalize_solver_result(problem, .pr_solve_raw(problem, backend, control1, strategy), control1)
  if (identical(problem$settings$objective, "minimax")) {
    if (refine)
      fit <- .pr_minimax_refine(problem, fit, backend, control, strategy, started)
    else fit$minimax_refine <- list(mode = if (is.null(problem$settings$minimax_refine)) "none_legacy_problem" else "none", applied = FALSE)
  }
  fit
}

# One raw solve of one problem. seed_grades are feasible-candidate grades: the
# staged engine evaluates them with its own candidates; for the label MIP the
# first one becomes a Gurobi MIP start (HiGHS takes no start).
.pr_solve_raw <- function(problem, backend, control, strategy, seed_grades = list()) {
  if (identical(strategy, "staged")) return(.pr_engine_staged(problem, backend, control, seed_grades = seed_grades))
  out <- switch(backend,
    gurobi = .pr_backend_gurobi(problem, control, start = if (length(seed_grades)) .pr_engine_primal(problem, seed_grades[[1L]]) else NULL),
    highs = .pr_backend_highs(problem, control))
  out$engine <- list(strategy = "label_mip")
  out
}
