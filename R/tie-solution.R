# Independent validation for the opt-in tie-aware domain. The numeric model
# shape/residual helpers are shared; the action loss and guard are checked here.

#' Check a Candidate Solution to a Tie-Aware Problem
#'
#' A numerical candidate is checked for feasible grades under the requested
#' tie-aware problem and for agreement between its objective and the directly
#' evaluated loss. A passing result establishes feasibility of the rounded
#' action within the specified tolerances. Optimality, uniqueness and the
#' scientific validity of declared equality classes are outside the scope of
#' this check.
#'
#' @param problem A validated object from [postrank_tie_problem()].
#' @param solution Numeric primal vector in sparse-model column order, such
#'   as a tie-aware fit's `raw_solution`. `NULL` means no candidate was supplied.
#' @param tolerances Named list with optional `feasibility`, `integrality`
#'   and `objective` tolerances; omitted values use package defaults.
#' @return A `postrank_tie_solution_validation` list recording `valid`,
#'   `issues`, `warnings`, raw and rounded residuals, integrality residual,
#'   rounded solution, raw labels/pairs, tolerances and recomputed objective.
#'   Only a valid candidate has a `grade` and `evaluation`; otherwise both are
#'   `NULL`. An absent candidate records `no_incumbent` and is distinct from
#'   a valid all-withheld grade.
#' @details Validation checks rounded variable bounds, sparse constraints,
#'   grade counts, pair relations and the full active-profile guard. It checks
#'   class membership independently of the model's equality rows. The
#'   evaluator then sums strict reversal and distinct-withholding losses
#'   directly, independently of the sparse objective coefficients, and checks
#'   the reconstruction `R0 + Z/M`.
#'
#'   Raw residuals are retained even when the rounded action passes. A solver
#'   result may therefore contain a usable grade with numerical warnings or
#'   an unusable bound. Read its status, lower bound and risk gap separately;
#'   this function checks the candidate, not the solver's optimality claim.
#' @seealso [postrank_tie_solve()], [postrank_tie_evaluate()]
#' @examples
#' if (requireNamespace("gmp", quietly = TRUE)) {
#'   path <- system.file("examples", "synthetic-tie-aware.json", package = "postrank")
#'   pw <- postrank_tie_pairwise(read_postrank_tie_draws(path))
#'   problem <- postrank_tie_problem(pw, c(S = .6, C = .4), tau = .25, G_max = 3L)
#'   absent <- validate_postrank_tie_solution(problem, NULL)
#'   absent$valid
#'   if (requireNamespace("highs", quietly = TRUE)) {
#'     fit <- postrank_tie_solve(problem, backend = "highs",
#'       control = postrank_control(strategy = "label_mip", time_limit = 10))
#'     checked <- validate_postrank_tie_solution(problem, fit$raw_solution)
#'     checked$valid
#'     checked$grade
#'   }
#' }
#' @concept tie-aware
#' @export
validate_postrank_tie_solution <- function(problem, solution, tolerances = list()) {
  .pr_validate_tie_problem(problem)
  .pr_solution_model_dimensions(problem)
  tol <- .pr_solution_tolerances(tolerances)
  out <- list(valid = FALSE, issues = list(), warnings = character(),
    raw_residuals = NULL, rounded_residuals = NULL,
    integrality_residual = NA_real_, rounded_solution = NULL,
    raw_labels = NULL, raw_pairs = NULL, grade = NULL, evaluation = NULL,
    recomputed_raw_objective = NA_real_,
    validity_basis = "rounded_integer_solution_and_active_profile_guard",
    tolerances = tol)
  issues <- list()
  issue <- function(code, message) {
    issues[[length(issues) + 1L]] <<- list(code = code, path = "$.solution",
      message = message, severity = "error")
  }
  finish <- function() {
    out$issues <- issues
    out$valid <- !length(issues)
    if (!out$valid) out[c("grade", "evaluation")] <- list(NULL, NULL)
    class(out) <- c("postrank_tie_solution_validation", "list")
    out
  }
  if (is.null(solution)) {
    issue("no_incumbent", "No primal incumbent was supplied.")
    return(finish())
  }
  model <- problem$model; ix <- problem$index
  if (!typeof(solution) %in% c("integer", "double") || !is.null(dim(solution))) {
    issue("invalid_primal_type", "Primal must be one real numeric vector.")
    return(finish())
  }
  if (length(solution) != length(model$objective)) {
    issue("invalid_primal_length", "Primal length differs from model columns.")
    return(finish())
  }
  out$raw_labels <- solution[ix$labels]; out$raw_pairs <- solution[ix$pairs]
  if (anyNA(solution) || any(!is.finite(solution))) {
    issue("nonfinite_primal", "Primal contains missing or nonfinite values.")
    return(finish())
  }
  integer <- which(model$types %in% c("I", "B"))
  out$integrality_residual <- max(c(0, abs(solution[integer] - round(solution[integer]))))
  z <- solution; z[integer] <- round(z[integer])
  out$rounded_solution <- z
  out$raw_residuals <- .pr_solution_residuals(model, solution)
  out$rounded_residuals <- .pr_solution_residuals(model, z)
  out$recomputed_raw_objective <- sum(model$objective * z)
  if (out$integrality_residual > tol$integrality)
    issue("integrality_violation", "Primal is not sufficiently close to integers.")
  if (out$raw_residuals$bounds_max > tol$feasibility ||
      out$raw_residuals$rows_max > tol$feasibility)
    out$warnings <- "Raw primal has a residual above tolerance; validity uses the rounded integer action."
  if (out$rounded_residuals$bounds_max > tol$feasibility)
    issue("rounded_bound_violation", "Rounded primal violates a variable bound.")
  if (out$rounded_residuals$rows_max > tol$feasibility)
    issue("rounded_row_violation", "Rounded primal violates a linear constraint.")
  if (any(!z[model$types == "B"] %in% c(0, 1)))
    issue("binary_violation", "Rounded binary variable is not zero or one.")
  if (!is.finite(out$recomputed_raw_objective))
    issue("nonfinite_objective", "Recomputed raw objective is not finite.")
  if (any(z[ix$labels] < 1)) {
    issue("invalid_label", "Rounded labels must be positive integers regardless of numeric tolerances.")
    return(finish())
  }
  ids <- problem$pairwise$entity_ids
  g <- canonical_postrank_grade(stats::setNames(z[ix$labels], ids), ids)
  if (!identical(as.numeric(z[ix$pairs]), as.numeric(g[ix$pair_i] < g[ix$pair_j])))
    issue("pair_relation_mismatch", "Pair variables differ from reconstructed grade relations.")
  if (length(unique(g)) > problem$settings$G_max)
    issue("grade_limit_violation", "Canonical grade exceeds G_max.")
  # This explicit action check does not rely on the backend's equality rows.
  if (any(vapply(problem$guard$groups, function(members)
      length(unique(g[members])) != 1L, logical(1L))))
    issue("full_profile_guard_violation", "A declared full active-profile identity class was split.")
  ev <- postrank_tie_evaluate(g, problem$pairwise,
    problem$settings$weights, problem$settings$tau)
  raw_tol <- .pr_objective_tolerance_raw(tol$objective,
    .pr_objective_reference(model$objective, z))
  if (abs(out$recomputed_raw_objective - ev$weighted_raw_objective) > raw_tol)
    issue("objective_reconstruction_mismatch", "Sparse objective differs from direct tie-aware action loss.")
  reconstructed <- problem$objective_units$offset +
    problem$objective_units$scale * out$recomputed_raw_objective
  if (abs(reconstructed - ev$primary_risk) >
      max(.Machine$double.eps, problem$objective_units$scale * raw_tol))
    issue("risk_reconstruction_mismatch", "R0 plus scaled objective differs from direct risk.")
  if (!length(issues)) { out$grade <- g; out$evaluation <- ev }
  finish()
}

.pr_tie_primal <- function(problem, grade) {
  .pr_validate_tie_problem(problem)
  g <- canonical_postrank_grade(grade, problem$pairwise$entity_ids)
  z <- numeric(length(problem$model$objective))
  z[problem$index$labels] <- g
  z[problem$index$pairs] <- as.numeric(g[problem$index$pair_i] < g[problem$index$pair_j])
  z
}
