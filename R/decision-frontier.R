# Guardrail and commonality-cost tools (014 repair, decisions 1-2: documented
# side contributions, not the core claim of the applied paper).

.pr_relation_agreement <- function(a, b) {
  ra <- sign(outer(unname(a), unname(a), `-`)); rb <- sign(outer(unname(b), unname(b), `-`)); up <- upper.tri(ra)
  mean(ra[up] == rb[up])
}

#' Criterion-Wise Cost of a Common Grade
#'
#' The criterion-wise posterior-risk cost of a common grading is assessed by
#' solving a separate problem for each criterion. Each optimization assigns all
#' weight to that criterion while retaining the common problem's tau and
#' grade-count settings. A working optimizer backend is required.
#' @param fit A `postrank_fit` or `postrank_analysis` of the common weighted
#'   or minimax problem, with a validated grade.
#' @param backend,control,strategy Resolved as in \code{\link{postrank_solve}} (\code{backend = NULL}:
#'   option, then Gurobi; \code{strategy = NULL}: \code{control$strategy}) and used for
#'   the criterion problems.
#' @param protection \code{"drop"} (default) solves each criterion problem
#'   without the common problem's q rows; \code{"keep"} keeps them. Either way
#'   the common grade is feasible for the criterion problem. These choices
#'   define different own-criterion comparison families; record which was used.
#' @return A \code{postrank_commonality_cost} list whose \code{table} has, per
#'   criterion: the common grade's criterion risk, the criterion's own best
#'   risk (upper bound U) and lower bound L, the cost interval
#'   \code{[common - U, common - L]} (its width is at most the criterion
#'   problem's risk gap, less when the lower end is clipped at zero; a
#'   certified problem's gap is within the absolute or relative gap control),
#'   the own grade's status, grade count and disclosures, and
#'   the relation agreement between the own and common grades. The interval
#'   reflects optimization bounds, not posterior uncertainty about the cost.
#' @details The cost is the increase in criterion risk associated with imposing
#' a common grade. This is a descriptive comparison under the same posterior
#' and has no welfare interpretation. The lower endpoint is clipped at zero
#' because the common action belongs to each comparison family. An unfinished
#' solve may yield an interval rather than a single cost. With one criterion
#' there is no conflict between criteria, although an unfinished common solve
#' can still be suboptimal.
#' @examples
#' draws <- read_postrank_draws(system.file("examples", "synthetic-iid.json",
#'   package = "postrank", mustWork = TRUE))
#' pairwise <- postrank_pairwise(draws)
#' weights <- c(need_A = .6, need_B = .4)
#' if (requireNamespace("highs", quietly = TRUE)) {
#'   problem <- postrank_problem(pairwise, weights, tau = .25, G_max = 3L)
#'   fit <- postrank_solve(problem, backend = "highs", control = list(time_limit = 10))
#'   postrank_commonality_cost(fit, backend = "highs", control = list(time_limit = 10))
#' }
#' @concept grids
#' @export
postrank_commonality_cost <- function(fit, backend = NULL, control = list(), strategy = NULL,
                                      protection = c("drop", "keep")) {
  if (inherits(fit, "postrank_analysis")) fit <- fit$fit
  resolved <- .pr_resolve_backend(backend)
  cc <- .pr_core_control(control, strategy)
  .pr_with_backend(resolved, .pr_commonality_core(fit, resolved$name, cc$core, cc$strategy, protection))
}

# Unchanged 0.0.1.9002 body, moved behind the public adapter (freeze manifest: moved_from postrank_commonality_cost).
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
#' A grading problem is solved at each withholding-cost or error-budget
#' setting. The resulting disclosure, criterion error ratios, risks and grade
#' relations are compared. A working optimizer backend is required. Since a
#' change in tau changes the loss function, raw risks at different tau values
#' cannot be used to rank decisions under a common loss.
#' @param pairwise A directional-error source accepted by
#'   [postrank_problem()], or a \code{postrank_fit} /
#'   \code{postrank_analysis} whose pairwise object and policy are reused (then
#'   only \code{tau} or \code{q_criterion}/\code{q_grid} may be supplied).
#' @param weights,G_max,objective,q,exact_G,minimax_criteria As in
#'   \code{\link{postrank_problem}}.
#' @param tau A vector of abstention costs.
#' @param q_criterion,q_grid Optional criterion ID and vector of q values; each
#'   grid value replaces that criterion's q.
#' @param backend,control,strategy Resolved as in \code{\link{postrank_solve}}
#'   (\code{backend = NULL}: option, then Gurobi; no fallback).
#' @param settings Optional \code{\link{postrank_settings}} supplying the policy;
#'   \code{tau} (the grid axis) may accompany it, other loose policy arguments
#'   may not (\code{settings_conflict}). For a q-grid with \code{tau} omitted,
#'   the base tau comes from \code{settings} or the reused fit.
#' @return A \code{postrank_frontier} list whose \code{table} has one row per
#'   setting: tau, q value, status, grade count, disclosures N, disclosure rate
#'   N/M, criterion error ratios E_k/N, criterion risks, primary and weighted
#'   risk, the absolute gap and the grade's relation identity.
#' @param minimax_refine Passed to \code{\link{postrank_problem}} for minimax.
#' @details Holding the input and feasible family fixed, exact optima have
#'   nondecreasing disclosure counts as tau increases. If both actions have
#'   valid absolute risk gaps at most \eqn{\epsilon}, then for
#'   \eqn{\tau_2 > \tau_1} the weaker bound is
#'   \eqn{N_2-N_1\ge-2\epsilon M/(\tau_2-\tau_1)}. Assessment requires both the stored
#'   `risk_absolute_gap` and status; a status label alone does not
#'   establish that bound. Changing q or the grade family at the same time
#'   removes the fixed-family comparison. Missing action metrics remain `NA`.
#'   The input-specific restrictions of [postrank_problem()] apply to each
#'   new problem; this function does not extend those capabilities.
#' @examples
#' draws <- read_postrank_draws(system.file("examples", "synthetic-iid.json",
#'   package = "postrank", mustWork = TRUE))
#' pairwise <- postrank_pairwise(draws)
#' weights <- c(need_A = .6, need_B = .4)
#' if (requireNamespace("highs", quietly = TRUE)) {
#'   postrank_frontier(pairwise, weights, tau = c(.1, .25, .4), G_max = 3L,
#'     backend = "highs", control = list(time_limit = 10))
#' }
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

# Unchanged 0.0.1.9002 body, moved behind the public adapter (freeze manifest: moved_from postrank_frontier).
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


