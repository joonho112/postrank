# Independent validation for the opt-in tie-aware domain. The numeric model
# shape/residual helpers are shared; the action loss and guard are checked here.

#' Validate a Candidate Solution to a Tie-Aware Problem
#'
#' `validate_postrank_tie_solution()` checks whether a raw primal solution
#' vector rounds to a feasible grading for a `postrank_tie_problem` and matches
#' the equality-neutral loss computed directly by [postrank_tie_evaluate()]. A
#' passing result confirms feasibility within numerical tolerances; it does not
#' test optimality, uniqueness, or scientific equality declarations.
#'
#' @param problem A validated `postrank_tie_problem` object from
#'   [postrank_tie_problem()].
#' @param solution Numeric primal vector in `problem$model` column order (such
#'   as `fit$raw_solution`), or `NULL` when no candidate solution was returned
#'   (which records issue `"no_incumbent"`).
#' @param tolerances Optional named list with `feasibility`, `integrality`, and
#'   `objective` tolerances; omitted entries use package defaults.
#' @return A `postrank_tie_solution_validation` list containing `valid`,
#'   `issues`, `warnings`, `raw_residuals`, `rounded_residuals`,
#'   `integrality_residual`, `rounded_solution`, `raw_labels`, `raw_pairs`,
#'   `grade` and `evaluation` (both `NULL` unless `valid` is `TRUE`),
#'   `recomputed_raw_objective`, `validity_basis`, and `tolerances`. An absent
#'   candidate (`solution = NULL`) has `valid = FALSE` and is distinct from a
#'   valid single-grade all-withheld grading.
#' @details
#' `validate_postrank_tie_solution()` rounds integer and binary variables,
#' checks `integrality_residual`, variable bounds, sparse linear constraints,
#' positive integer labels, consistency between pair variables and canonical
#' grade order `g[i] < g[j]`, `G <= G_max`, and the active-profile equality
#' constraint (`problem$guard$groups`, checked directly on `g` independently of
#' the sparse equality rows). It then evaluates `g` with
#' [postrank_tie_evaluate()] and checks that both the raw objective `Z` and
#' reconstructed risk `R0 + Z / M` agree within the scale-aware objective
#' tolerance.
#'
#' If the unrounded primal exceeds `feasibility` while the rounded integer
#' solution passes all checks, `valid` is `TRUE` and `warnings` records the raw
#' residual; [postrank_tie_solve()] additionally checks whether raw residuals
#' exceed integrality-rounding limits when deciding whether to keep a solver's
#' lower bound.
#' @seealso [postrank_tie_solve()], [postrank_tie_evaluate()],
#'   [postrank_tie_problem()]
#' @examplesIf requireNamespace("gmp", quietly = TRUE)
#' path <- system.file("examples", "synthetic-tie-aware.json", package = "postrank")
#' pw <- postrank_tie_pairwise(read_postrank_tie_draws(path))
#' problem <- postrank_tie_problem(pw, c(S = 0.6, C = 0.4), tau = 0.25, G_max = 3L)
#' absent <- validate_postrank_tie_solution(problem, NULL)
#' absent$valid
#' if (requireNamespace("highs", quietly = TRUE)) {
#'   fit <- postrank_tie_solve(
#'     problem,
#'     backend = "highs",
#'     control = postrank_control(strategy = "label_mip", time_limit = 10)
#'   )
#'   checked <- validate_postrank_tie_solution(problem, fit$raw_solution)
#'   checked$valid
#'   checked$grade
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
