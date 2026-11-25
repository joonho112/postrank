#' Find Grades and Report Their Optimization Bounds
#'
#' `postrank_solve()` solves an optimization problem built by
#' [postrank_problem()], checks any candidate grading independently with
#' [validate_postrank_solution()], and returns the checked grades, recomputed
#' posterior expected loss, lower bound and solver status.
#'
#' Solving requires an optimization solver. HiGHS is free: install the `highs`
#' package (`install.packages("highs")`) and pass `backend = "highs"` or set
#' `options(postrank.backend = "highs")`. Gurobi (the default when no solver is
#' specified) is commercial software requiring a license. `postrank` never
#' switches solvers on its own.
#'
#' @param problem A `postrank_problem` object created by [postrank_problem()].
#' @param backend Solver to use, `"gurobi"` or `"highs"`. If `NULL` (the
#'   default), `getOption("postrank.backend")` is used, or `"gurobi"` if unset.
#'   The chosen solver and how it was selected (`"explicit"`, `"option"` or
#'   `"default"`) are recorded in `fit$backend`. If the chosen solver is not
#'   installed, cannot be loaded, or throws an uncaught R execution error (such
#'   as a missing Gurobi license under `strategy = "label_mip"` or LP setup),
#'   the call stops with an error.
#' @param control Solver controls from [postrank_control()] or a named list of
#'   options (`time_limit`, `threads`, `seed`, `absolute_risk_gap`,
#'   `relative_gap`, `strategy`, `engine`, `verbose`, `output`, `tolerances`).
#' @param strategy Search method, `"staged"` or `"label_mip"`. If `NULL` (the
#'   default), `control$strategy` is used, or `"staged"` when `control` is a
#'   list without `strategy`. A non-`NULL` `strategy` overrides
#'   `control$strategy`.
#' @returns A `postrank_fit` object, a list containing:
#'   * `has_incumbent` and `incumbent_validated`: whether the solver returned a
#'     candidate grading ("incumbent"), and whether it passed
#'     [validate_postrank_solution()];
#'   * `grade`, `evaluation` and `relations`: the checked integer grade vector,
#'     its loss summary from [postrank_evaluate()] and its pairwise relation
#'     matrix, each `NULL` when `incumbent_validated` is `FALSE`;
#'   * `solution_validation`: the [validate_postrank_solution()] record;
#'   * `status`: list with `raw_code`, `raw_message`, `normalized`
#'     (`"optimal"`, `"feasible_not_certified"`, `"time_limit"`,
#'     `"infeasible"`, `"unbounded"`, `"numerical_error"` or `"unknown"`) and
#'     `termination_reason`;
#'   * `objective`: list with `primary_action_risk` (upper bound `U`),
#'     `risk_upper_bound`, `risk_lower_bound` (`L`, a loss no feasible grading
#'     can beat up to solver and floating-point tolerances), `risk_absolute_gap`
#'     (`U - L`), raw objective values and `bound_source`;
#'   * `problem`, `settings`, `backend`, `engine`, `runtime`, `raw_solution`,
#'     `raw_backend_result`, `warnings`, `numerical_issues`, `input_identity`,
#'     `problem_identity`, `solution_identity` and `schema_version`;
#'   * `minimax_refine`: refinement record when
#'     `problem$settings$objective == "minimax"` (stage-by-stage results when
#'     `minimax_refine = "weighted"`, or `list(mode = "none", applied = FALSE)`
#'     when `minimax_refine = "none"`).
#' @section Optimization status and bounds:
#'   The solver's `status`, `risk_lower_bound` and `risk_absolute_gap` describe
#'   optimization over the supplied pairwise probabilities up to solver and
#'   floating-point tolerances (they are not exact numerical certificates,
#'   posterior uncertainty intervals, Monte Carlo error bounds, or proof that
#'   the optimal grading is unique). For weighted problems, raw solver
#'   objectives `Z` convert to normalized loss via `R = tau + Z / M`, so a raw
#'   `relative_gap` on centered `Z` differs from a relative gap in `R`; for
#'   minimax problems, `U` is the grade's recomputed largest selected criterion
#'   loss rather than a possibly slack auxiliary variable. In returned fields
#'   and printed output, `"risk"` means posterior expected loss, `"disclosed"`
#'   means ordered pairs, and `"withheld"` means unordered pairs.
#'
#'   For a solver-reported `"optimal"` result, a checked grading and a usable
#'   lower bound must meet the gap tolerances. A valid grading with a missing
#'   bound or a gap above tolerance gives `"feasible_not_certified"` when the
#'   numerical checks otherwise pass. A missing or invalid grading, or a serious
#'   numerical inconsistency, gives `"numerical_error"`. Check `incumbent_validated`
#'   before interpreting the grades. Invalid `problem`, `control` or
#'   `backend` arguments, an unavailable solver, and uncaught solver execution
#'   errors (such as `"label_mip"` or LP setup failing without an active Gurobi
#'   license) stop the call. Read `fit$status` for the overall outcome, including
#'   infeasibility, a time limit, or numerical termination. In staged search,
#'   caught LP round errors appear in `fit$engine$stages$lp$status` and its
#'   `trace`. A caught final MIP error appears in `fit$engine$stages$mip$error`
#'   and `fit$warnings`. When
#'   a time limit ends without a checked grading, `grade` and `evaluation` are
#'   `NULL` (`risk_absolute_gap = NA`), which is distinct from a valid
#'   one-grade report leaving all pairs unordered (loss `tau`). Small bound
#'   inversions (`L > U`) within the objective tolerance are clamped to `U`
#'   with a warning; larger inversions exclude the bound (`risk_lower_bound = NA`).
#'
#' @section Search strategies:
#'   `"staged"` (the default) first builds candidate gradings from contiguous
#'   cuts along priority orders and local search, then solves a linear
#'   programming (LP) relaxation with separated triangle inequalities
#'   (transitivity constraints on pairwise orderings) and grade-count bounds
#'   (limits on how many pairs `G_max` or `exact_G` can order) to obtain a
#'   whole-problem lower bound `L`, and finally runs a strengthened
#'   mixed-integer program (MIP) if a gap remains and `engine$mip` allows it
#'   (passing the best candidate to Gurobi as an initial starting grading).
#'   `"label_mip"` sends the integer-label MIP directly to the solver. Model
#'   construction, validation and refinement add overhead, so `time_limit` is
#'   not a strict wall-clock cap on the whole R call.
#'
#'   Defaults in `control$engine` are `local_search_passes = 20L`,
#'   `local_search_starts = 5L`, `max_cut_rounds = 60L`, `cuts_per_round = NULL`
#'   (`max(200, 10 * n)`), `lp_time_share = 0.5`, `mip = "auto"` (`"auto"`,
#'   `"always"` or `"never"`) and `mip_max_n = 200L` (`"auto"` runs the MIP
#'   stage when `n <= mip_max_n`). When the MIP stage may run, the LP gets
#'   `lp_time_share` of the remaining time; otherwise it gets the remaining
#'   time minus a reserve (`max(1, 0.01 * time_limit, 2 * elapsed_candidate_stage)`
#'   seconds), never less than `lp_time_share` of the remaining time.
#'   `fit$engine$stages` records each stage that ran.
#'
#' @section Minimax refinement:
#'   When `objective = "minimax"` and `minimax_refine = "weighted"`, stage 1
#'   (given `3/4` of `time_limit`) minimizes the largest selected criterion
#'   loss. Stage 2 minimizes the weighted loss subject to keeping the stage-1
#'   minimax cap; if any criterion has weight `0`, stage 3 minimizes the
#'   uniform average criterion loss while keeping both caps (splitting the
#'   remaining time, at least 1 second total after stage 1). Weights are never
#'   perturbed, and any candidate that violates earlier caps beyond rounding is
#'   discarded. Top-level `fit$status$normalized` and
#'   `fit$objective$risk_lower_bound` come from stage 1; skipped or uncertified
#'   later stages record a warning in `fit$warnings`. In `fit$minimax_refine`,
#'   `lexicographic_certified` indicates that both stage-1 minimax loss and
#'   stage-2 weighted loss met optimality tolerances, and `pareto_certified`
#'   requires stage-3 zero-weight refinement as well when applicable (both
#'   subject to solver gaps and floating-point tolerances).
#' @seealso [postrank()], [postrank_problem()], [postrank_control()],
#'   [validate_postrank_solution()], [get_risk()]
#' @examples
#' # Inspect the fit inside a stored example without running a solver:
#' stored_fit <- postrank_example("tutorial_one")$fit
#' stored_fit$status$normalized
#' get_risk(stored_fit)
#' @examplesIf requireNamespace("highs", quietly = TRUE)
#' # Solve a problem directly with the optional highs package:
#' problem <- postrank_problem(pr_tutorial$one, weights = c(score_A = 1),
#'   tau = 0.2, G_max = 3L)
#' fit <- postrank_solve(problem, backend = "highs",
#'   control = postrank_control(time_limit = 10))
#' fit$status$normalized
#' get_risk(fit)
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
