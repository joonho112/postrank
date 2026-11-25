# Commonality-cost and tau/q frontier sweeps over a fixed posterior.

.pr_relation_agreement <- function(a, b) {
  ra <- sign(outer(unname(a), unname(a), `-`)); rb <- sign(outer(unname(b), unname(b), `-`)); up <- upper.tri(ra)
  mean(ra[up] == rb[up])
}

#' Criterion-Wise Cost of a Common Grade
#'
#' `postrank_commonality_cost()` measures how much posterior expected loss a
#' single common grading adds on each criterion compared with grading that
#' criterion on its own under the same `tau` and grade-count rules. It solves
#' one single-criterion optimization problem per criterion, seeding each search
#' with the common grading.
#'
#' Solving requires an optimization solver: install the free `highs` package
#' (`install.packages("highs")`) and use `backend = "highs"` or
#' `options(postrank.backend = "highs")`, or provide a licensed Gurobi
#' installation (the default). `postrank` never switches solvers on its own.
#'
#' @param fit A `postrank_fit` or `postrank_analysis` object of a public
#'   common-grade problem with a checked grading (`incumbent_validated = TRUE`).
#' @param backend,control,strategy Solver, controls and search strategy used
#'   for each criterion solve, resolved as in [postrank_solve()].
#' @param protection How `q` error budgets from `fit` are treated in the
#'   single-criterion problems: `"drop"` (the default, solving without `q` rows)
#'   or `"keep"` (retaining all `q` rows). In either case, the common grading
#'   is feasible for every criterion problem.
#' @returns A `postrank_commonality_cost` list containing `table` (one row per
#'   criterion with `criterion_id`, `common_grade_risk`, `own_best_risk` `U`,
#'   `own_lower_bound` `L`, `cost_lower` `max(0, common - U)`, `cost_upper`
#'   `common - L`, `own_status`, `own_G`, `own_disclosures` and
#'   `relation_agreement`), plus `settings`, `protection`, `backend`,
#'   `strategy`, `interpretation`, `input_identity`, `problem_identity` and
#'   `schema_version`.
#' @details
#' For criterion `k`, the cost of imposing the common grading lies in
#' `[max(0, common_k - U_k), common_k - L_k]`, whose width is at most the
#' solver's absolute gap `U_k - L_k` on criterion `k`'s own problem. That
#' interval reflects optimization bounds on criterion `k`'s solve, not
#' posterior uncertainty about the cost.
#' @seealso [postrank_plot_commonality()], [postrank_compare()],
#'   [postrank_frontier()]
#' @examples
#' # Inspect a stored commonality-cost result without running a solver:
#' cc <- postrank_example("toy_commonality")
#' cc$table[, c("criterion_id", "common_grade_risk", "own_best_risk",
#'   "cost_lower", "cost_upper")]
#' @examplesIf requireNamespace("highs", quietly = TRUE)
#' # Solve directly with the optional highs package:
#' toy <- postrank_example("toy_analysis")
#' postrank_commonality_cost(toy, backend = "highs",
#'   control = postrank_control(time_limit = 10))
#' @concept grids
#' @export
postrank_commonality_cost <- function(fit, backend = NULL, control = list(), strategy = NULL,
                                      protection = c("drop", "keep")) {
  if (inherits(fit, "postrank_analysis")) fit <- fit$fit
  resolved <- .pr_resolve_backend(backend)
  cc <- .pr_core_control(control, strategy)
  .pr_with_backend(resolved, .pr_commonality_core(fit, resolved$name, cc$core, cc$strategy, protection))
}

.pr_commonality_core <- function(fit, backend = c("gurobi", "highs"), control = list(),
                                      strategy = c("staged", "label_mip"), protection = c("drop", "keep")) {
  .pr_assert(inherits(fit, "postrank_fit") && isTRUE(fit$incumbent_validated) && !is.null(fit$grade),
    "a postrank_fit with a validated grade is required", "invalid_fit")
  .pr_validate_problem(fit$problem)
  .pr_assert(is.null(fit$problem$protection_envelope) && is.null(fit$problem$settings$risk_caps),
    "commonality cost needs a public problem", "invalid_fit")
  backend <- match.arg(backend); strategy <- match.arg(strategy); protection <- match.arg(protection)
  s <- fit$problem$settings; pw <- fit$problem$pairwise; ids <- pw$criterion_ids
  rows <- lapply(ids, function(k) {
    w <- stats::setNames(as.numeric(ids == k), ids)
    own_problem <- postrank_problem(pw, w, s$tau, s$G_max, "weighted", q = if (protection == "keep") s$q else NULL,
      exact_G = s$exact_G)
    # The common grade is feasible for the criterion's own problem. It seeds the
    # staged engine (whose incumbent is then never worse than the common grade)
    # and Gurobi's label MIP; HiGHS's label MIP takes no start, so cost_lower is
    # also clipped at zero.
    ctrl <- .pr_control(control)
    own <- .pr_normalize_solver_result(own_problem, .pr_solve_raw(own_problem, backend, ctrl, strategy,
      seed_grades = list(unname(fit$grade[pw$entity_ids]))), ctrl)
    common <- fit$evaluation$criterion_risk[[k]]
    U <- own$objective$risk_upper_bound; L <- own$objective$risk_lower_bound
    data.frame(criterion_id = k, common_grade_risk = common, own_best_risk = U, own_lower_bound = L,
      cost_lower = max(0, common - U), cost_upper = if (is.finite(L)) common - L else NA_real_,
      own_status = own$status$normalized, own_G = if (is.null(own$evaluation)) NA_integer_ else own$evaluation$G,
      own_disclosures = if (is.null(own$evaluation)) NA_real_ else own$evaluation$N,
      relation_agreement = if (is.null(own$grade)) NA_real_ else .pr_relation_agreement(own$grade[pw$entity_ids], fit$grade[pw$entity_ids]),
      stringsAsFactors = FALSE)
  })
  out <- list(schema_version = "0.1.0", input_identity = fit$input_identity, problem_identity = fit$problem_identity,
    settings = s, protection = protection, table = do.call(rbind, rows), backend = backend, strategy = strategy,
    interpretation = c("cost = criterion risk of the common grade minus the criterion's own minimum risk under the same tau and grade-count settings.",
      "The cost interval uses the own problem's validated upper bound and solver-reported lower bound; its width is at most that problem's risk gap (less when the lower end is clipped at zero), and a certified problem's gap is within the gap controls."))
  class(out) <- c("postrank_commonality_cost", "list")
  out
}

#' Disclosure and Error Frontier Over Tau or One Budget
#'
#' `postrank_frontier()` solves a grading problem across a grid of unordered-pair
#' costs `tau` (and/or a grid of error budgets `q_grid` on one criterion
#' `q_criterion`), summarizing how the fraction of ordered pairs `N / M` and
#' expected wrong-order rates `E_k / N` vary across settings.
#'
#' Solving requires an optimization solver: install the free `highs` package
#' (`install.packages("highs")`) and use `backend = "highs"` or
#' `options(postrank.backend = "highs")`, or provide a licensed Gurobi
#' installation (the default). `postrank` never switches solvers on its own.
#'
#' @param pairwise Pairwise directional-error source accepted by
#'   [postrank_problem()], or a `postrank_fit` / `postrank_analysis` whose
#'   pairwise probabilities and base policy are reused (when reusing a fit or
#'   analysis, supply only `tau` and/or `q_criterion` + `q_grid`).
#' @param weights,G_max,objective,q,exact_G,minimax_criteria,minimax_refine
#'   Policy arguments passed to [postrank_problem()] when neither `settings` nor
#'   a fit/analysis is supplied.
#' @param tau Numeric vector of unordered-pair costs in `(0, 0.5]`. May be
#'   omitted only when `q_criterion` and `q_grid` are supplied together with
#'   `settings` or a fit/analysis (whose `tau` is then held fixed).
#' @param q_criterion,q_grid Optional criterion ID and numeric vector of
#'   expected-error budgets in `[0, 1]` (supply both together or omit both).
#'   When both `tau` and `q_grid` have multiple values, all combinations are
#'   solved.
#' @param backend,control,strategy Solver, controls and search strategy,
#'   resolved as in [postrank_solve()].
#' @param settings Optional [postrank_settings()] object supplying the base
#'   policy (`tau` and/or `q_criterion` + `q_grid` may accompany it, whereas
#'   separate policy arguments stop with `settings_conflict`).
#' @returns A `postrank_frontier` list whose `table` has one row per solved
#'   setting with columns `tau`, `q_value`, `status`, `G`, `N`,
#'   `disclosure_rate` (`N / M`), `primary_risk`, `weighted_risk`,
#'   `risk_absolute_gap`, `relation_identity`, `E_over_N_<k>` and `risk_<k>`,
#'   alongside `weights`, `G_max`, `objective`, `q`, `exact_G`, `q_criterion`,
#'   `backend`, `strategy`, `interpretation`, `input_identity` and
#'   `schema_version`.
#' @details
#' Because changing `tau` changes the loss definition itself, compare frontier
#' rows by their ordered pair counts `N`, error rates `E_k / N` and grade
#' relations rather than ranking rows by `primary_risk`. Holding the input and
#' constraint family fixed, exact optima have nondecreasing `N` as `tau`
#' increases; if two rows at `tau_2 > tau_1` both have valid `risk_absolute_gap`
#' at most \eqn{\epsilon}, then \eqn{N_2 - N_1 \ge -2 \epsilon M / (\tau_2 - \tau_1)}.
#' Rows without a checked grading record `NA` action metrics.
#' @seealso [postrank_plot_frontier()], [postrank_sensitivity()],
#'   [postrank_commonality_cost()]
#' @examples
#' # Inspect a stored frontier without running a solver:
#' fr <- postrank_example("toy_frontier")
#' fr$table[, c("tau", "G", "N", "disclosure_rate", "primary_risk", "status")]
#' @examplesIf requireNamespace("highs", quietly = TRUE)
#' # Solve a three-point tau frontier with the optional highs package:
#' pw <- postrank_pairwise(postrank_toy)
#' postrank_frontier(pw, c(need_A = 0.6, need_B = 0.4), tau = c(0.1, 0.25, 0.4),
#'   G_max = 3L, backend = "highs", control = postrank_control(time_limit = 10))
#' @concept grids
#' @export
postrank_frontier <- function(pairwise, weights = NULL, tau, G_max = NULL, objective = c("weighted", "minimax"), q = NULL,
                              exact_G = NULL, minimax_criteria = NULL, q_criterion = NULL, q_grid = NULL,
                              backend = NULL, control = list(), strategy = NULL,
                              minimax_refine = c("weighted", "none"), settings = NULL) {
  loose <- .pr_supplied(c("weights", "G_max", "objective", "q", "exact_G", "minimax_criteria", "minimax_refine"))
  policy <- NULL
  if (inherits(pairwise, c("postrank_fit", "postrank_analysis"))) {
    fit <- if (inherits(pairwise, "postrank_analysis")) pairwise$fit else pairwise
    .pr_assert(inherits(fit, "postrank_fit"), "expected a postrank_fit or postrank_analysis", "invalid_fit")
    .pr_validate_problem(fit$problem)
    .pr_assert(is.null(fit$problem$protection_envelope) && is.null(fit$problem$settings$risk_caps),
      "postrank_frontier() reuses the policy of a public problem; internal envelope or second-stage fits are not accepted",
      "invalid_fit", "$.pairwise")
    .pr_settings_conflict(c(loose, if (!is.null(settings)) "settings"), "a fit/analysis (whose policy is reused)")
    s <- fit$problem$settings; pairwise <- fit$problem$pairwise
    policy <- list(weights = s$weights, tau = s$tau, G_max = s$G_max, objective = s$objective, q = s$q,
      exact_G = s$exact_G, minimax_criteria = if (identical(s$objective, "minimax")) s$minimax_criteria else NULL,
      minimax_refine = if (is.null(s$minimax_refine)) "weighted" else s$minimax_refine)
  } else if (!is.null(settings)) {
    .pr_settings_conflict(loose)
    .pr_validate_pairwise(pairwise)
    policy <- .pr_settings_bind(settings, pairwise)$policy
  }
  if (missing(tau)) {
    .pr_assert(!is.null(q_criterion) && !is.null(q_grid) && !is.null(policy),
      "postrank_frontier() needs a tau grid, or a complete q_criterion/q_grid with tau taken from settings or a fit",
      "invalid_frontier", "$.tau")
    tau <- policy$tau
  }
  resolved <- .pr_resolve_backend(backend)
  cc <- .pr_core_control(control, strategy)
  if (is.null(policy))
    return(.pr_with_backend(resolved, .pr_frontier_core(pairwise, weights, tau, G_max, objective, q, exact_G,
      minimax_criteria, q_criterion, q_grid, resolved$name, cc$core, cc$strategy, minimax_refine)))
  .pr_with_backend(resolved, .pr_frontier_core(pairwise, policy$weights, tau, policy$G_max, policy$objective, policy$q,
    policy$exact_G, policy$minimax_criteria, q_criterion, q_grid, resolved$name, cc$core, cc$strategy, policy$minimax_refine))
}

.pr_frontier_core <- function(pairwise, weights, tau, G_max, objective = c("weighted", "minimax"), q = NULL, exact_G = NULL,
                              minimax_criteria = NULL, q_criterion = NULL, q_grid = NULL,
                              backend = c("gurobi", "highs"), control = list(), strategy = c("staged", "label_mip"),
                              minimax_refine = c("weighted", "none")) {
  .pr_validate_pairwise(pairwise); objective <- match.arg(objective); backend <- match.arg(backend); strategy <- match.arg(strategy)
  minimax_refine <- match.arg(minimax_refine)
  .pr_assert(typeof(tau) %in% c("integer", "double") && is.null(dim(tau)) && length(tau) >= 1L && all(is.finite(tau)),
    "tau must be a finite numeric vector", "invalid_frontier")
  for (t in tau) .pr_loss_settings(pairwise, weights, t)
  if (!is.null(q_grid)) .pr_assert(typeof(q_grid) %in% c("integer", "double") && all(is.finite(q_grid)) && all(q_grid >= 0 & q_grid <= 1),
    "q_grid values must be in [0, 1]", "invalid_frontier")
  .pr_assert(is.null(q_grid) == is.null(q_criterion), "q_grid and q_criterion go together", "invalid_frontier")
  if (!is.null(q_criterion)) .pr_assert(is.character(q_criterion) && length(q_criterion) == 1L && q_criterion %in% pairwise$criterion_ids &&
    typeof(q_grid) %in% c("integer", "double") && length(q_grid) >= 1L && all(is.finite(q_grid)),
    "q_criterion must name one criterion and q_grid must be numeric", "invalid_frontier")
  grid <- expand.grid(tau = tau, q_value = if (is.null(q_grid)) NA_real_ else q_grid, KEEP.OUT.ATTRS = FALSE)
  ids <- pairwise$criterion_ids; M <- choose(length(pairwise$entity_ids), 2)
  rows <- lapply(seq_len(nrow(grid)), function(r) {
    qr <- q
    if (!is.null(q_criterion)) { qr <- if (is.null(qr)) numeric() else qr; qr[[q_criterion]] <- grid$q_value[r] }
    fit <- postrank_solve(postrank_problem(pairwise, weights, grid$tau[r], G_max, objective, qr, exact_G, minimax_criteria,
      minimax_refine), backend, control, strategy)
    ev <- fit$evaluation
    base <- data.frame(tau = grid$tau[r], q_value = grid$q_value[r], status = fit$status$normalized,
      G = if (is.null(ev)) NA_integer_ else ev$G, N = if (is.null(ev)) NA_real_ else ev$N,
      disclosure_rate = if (is.null(ev)) NA_real_ else ev$N / M,
      primary_risk = fit$objective$primary_action_risk, weighted_risk = fit$objective$weighted_auxiliary_risk,
      risk_absolute_gap = fit$objective$risk_absolute_gap,
      relation_identity = if (is.null(fit$solution_identity)) NA_character_ else fit$solution_identity$relation_identity,
      stringsAsFactors = FALSE)
    ratio <- if (is.null(ev)) stats::setNames(rep(NA_real_, length(ids)), ids) else ev$E_over_N[ids]
    risk <- if (is.null(ev)) stats::setNames(rep(NA_real_, length(ids)), ids) else ev$criterion_risk[ids]
    cbind(base, stats::setNames(as.data.frame(as.list(unname(ratio))), paste0("E_over_N_", ids)),
      stats::setNames(as.data.frame(as.list(unname(risk))), paste0("risk_", ids)))
  })
  out <- list(schema_version = "0.1.0", input_identity = pairwise$input_identity, weights = weights, G_max = G_max,
    objective = objective, q = q, exact_G = exact_G, q_criterion = q_criterion, table = do.call(rbind, rows),
    backend = backend, strategy = strategy,
    interpretation = c("disclosure_rate = N/M, the share of entity pairs ordered by the grade.",
      "E_over_N_k is the posterior expected share of erroneous orderings among disclosed pairs for criterion k (NA without disclosures)."))
  class(out) <- c("postrank_frontier", "list")
  out
}


