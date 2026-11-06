# Ordered-partition engine: specification, evaluation and primal construction.
#
# The engine works on plain matrices so that it can later be shared with other
# grade packages. An action is a grade vector g (smaller = higher priority);
# x[i,j] = 1{g_i < g_j}. For an n x n matrix Q (diagonal ignored) the pair sum is
# S_Q(g) = sum_{i != j} x[i,j] Q[i,j].
#
# spec fields
#   n, M, tau, entity_ids, e (criterion matrices), weights
#   objective   "linear": minimise S_C(g)                       (raw units)
#               "max":    minimise max_t (tau + S_{A_t}(g) / M)  (risk units)
#   C           linear cost matrix (objective "linear")
#   terms       list of matrices A_t (objective "max")
#   rows        list of list(A, b, id): feasibility S_A(g) <= b (protection
#               thresholds and the minimax second stage's risk caps)
#   G_max, exact_G
#   scale, offset            raw -> risk conversion of the public problem
#   feasibility_tolerance    absolute row tolerance; the staged solver keeps it
#                            below the independent validator's tolerance

.pr_engine_matrix <- function(m) { m <- unname(m); diag(m) <- 0; m[is.na(m)] <- 0; m }

.pr_engine_spec <- function(problem, caps = problem$settings$risk_caps, feasibility_tolerance = 5e-8) {
  pw <- problem$pairwise; s <- problem$settings
  n <- length(pw$entity_ids); M <- choose(n, 2); tau <- s$tau
  e <- lapply(pw$criterion_ids, function(k) .pr_engine_matrix(pw$e[, , k])); names(e) <- pw$criterion_ids
  rows <- list()
  thresholds <- .pr_problem_q_thresholds(problem)
  if (!is.null(thresholds)) for (k in names(thresholds))
    rows[[length(rows) + 1L]] <- list(A = .pr_engine_matrix(e[[k]] - thresholds[[k]]), b = 0, id = paste0("protection_", k))
  if (!is.null(caps)) for (k in names(caps))
    rows[[length(rows) + 1L]] <- list(A = .pr_engine_matrix(e[[k]] - tau), b = M * (caps[[k]] - tau), id = paste0("risk_cap_", k))
  # Internal refinement caps are stored in the same units and coefficients as
  # their sparse model rows. Keeping these in the engine specification makes
  # the LP, heuristic and label-MIP feasible sets identical.
  if (length(s$linear_caps)) for (cap in s$linear_caps)
    rows[[length(rows) + 1L]] <- list(A = cap$A, b = cap$b, id = cap$id)
  spec <- list(n = n, M = M, tau = tau, entity_ids = pw$entity_ids, G_max = as.integer(s$G_max),
    exact_G = if (is.null(s$exact_G)) NULL else as.integer(s$exact_G), rows = rows,
    scale = problem$objective_units$scale, offset = problem$objective_units$offset, e = e, weights = s$weights,
    feasibility_tolerance = feasibility_tolerance)
  if (identical(s$objective, "minimax")) {
    selected <- if (is.null(s$minimax_criteria)) pw$criterion_ids else s$minimax_criteria
    spec$objective <- "max"
    spec$terms <- lapply(selected, function(k) .pr_engine_matrix(e[[k]] - tau)); names(spec$terms) <- selected
  } else {
    spec$objective <- "linear"
    # Use the actual model coefficients, including the positive objective
    # scaling used internally for very small minimax secondary weights.
    C <- matrix(0, n, n)
    C[cbind(problem$index$pair_i, problem$index$pair_j)] <- problem$model$objective[problem$index$pairs]
    spec$C <- .pr_engine_matrix(C)
  }
  spec
}

# Canonical dense labels 1..G preserving order (smaller = higher priority).
.pr_engine_canonical <- function(g) as.integer(match(g, sort(unique(g))))

.pr_engine_pair_sum <- function(Q, x) sum(Q[x])

.pr_engine_evaluate <- function(spec, g) {
  g <- .pr_engine_canonical(g); x <- outer(g, g, `<`)
  row_sums <- vapply(spec$rows, function(r) .pr_engine_pair_sum(r$A, x), numeric(1L))
  row_slack <- vapply(seq_along(spec$rows), function(r) spec$rows[[r]]$b - row_sums[r], numeric(1L))
  G <- max(g)
  structural <- G <= spec$G_max && (is.null(spec$exact_G) || G == spec$exact_G)
  feasible <- structural && all(row_slack >= -spec$feasibility_tolerance)
  if (identical(spec$objective, "linear")) {
    raw <- .pr_engine_pair_sum(spec$C, x); risk <- spec$offset + spec$scale * raw
    term_risks <- NULL
  } else {
    term_risks <- vapply(spec$terms, function(A) spec$tau + .pr_engine_pair_sum(A, x) / spec$M, numeric(1L))
    raw <- max(term_risks); risk <- raw
  }
  list(grade = g, raw = raw, risk = risk, feasible = feasible, structural = structural,
       row_sums = row_sums, row_slack = row_slack, term_risks = term_risks, N = sum(x), G = G)
}

# Primal vector for problem$model columns that encodes grade g exactly.
.pr_engine_primal <- function(problem, g) {
  g <- .pr_engine_canonical(g); index <- problem$index
  z <- numeric(length(problem$model$objective))
  z[index$labels] <- g
  z[index$pairs] <- as.numeric(g[index$pair_i] < g[index$pair_j])
  if (!is.null(index$assignment)) for (i in seq_along(g)) z[index$assignment[i, g[i]]] <- 1
  if (length(index$t) == 1L) z[index$t] <- .pr_minimax_needed_t(problem, z[index$pairs])
  z
}
