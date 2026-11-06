# Order-restricted dynamic programme and candidate generation.
#
# For a fixed priority order of the entities, the best ordered partition into
# contiguous blocks minimises S_C = (sum of C over all ordered-ahead pairs) minus
# the within-block (tied) pairs. With U = C restricted to "earlier ahead of later"
# pairs in that order and W(a, b) the sum of U inside positions a..b,
#   S_C(partition) = sum(U) - sum_blocks W(block),
# so the DP maximises the within-block sums over at most G (or exactly G) blocks.
# Cost O(n^2 G). Exact for that order; a heuristic over orders.
.pr_engine_order_dp <- function(C, order, G, exact = FALSE) {
  n <- length(order); G <- min(as.integer(G), n)
  U <- C[order, order, drop = FALSE]; U[lower.tri(U, diag = TRUE)] <- 0
  P <- matrix(0, n + 1L, n + 1L)
  # Two-dimensional prefix sums: P[a+1, b+1] = sum(U[1:a, 1:b]).
  P[-1L, -1L] <- if (n == 1L) U else t(apply(apply(U, 2L, cumsum), 1L, cumsum))
  W <- function(a, b) P[b + 1L, b + 1L] - P[a, b + 1L] - P[b + 1L, a] + P[a, a]
  Fm <- matrix(-Inf, G, n); arg <- matrix(0L, G, n)
  for (b in seq_len(n)) Fm[1L, b] <- W(1L, b)
  if (G > 1L) for (g in 2L:G) for (b in g:n) {
    a <- g:b
    v <- Fm[g - 1L, a - 1L] + P[b + 1L, b + 1L] - P[a, b + 1L] - P[b + 1L, a] + P[cbind(a, a)]
    j <- which.max(v); Fm[g, b] <- v[j]; arg[g, b] <- a[j]
  }
  gbest <- if (exact) G else which.max(Fm[, n])
  if (!is.finite(Fm[gbest, n])) return(NULL)
  cuts <- integer(); b <- n; g <- gbest
  while (g > 1L) { a <- arg[g, b]; cuts <- c(a, cuts); b <- a - 1L; g <- g - 1L }
  starts <- c(1L, cuts); ends <- c(cuts - 1L, n)
  grade <- integer(n)
  for (q in seq_along(starts)) grade[order[starts[q]:ends[q]]] <- q
  grade
}

# Priority order from a pair-cost matrix: entity i is placed early when placing
# it ahead of others is cheap relative to the reverse.
.pr_engine_order_from_cost <- function(C) order(colSums(C) - rowSums(C), decreasing = TRUE)

.pr_engine_orders <- function(spec, cost_list) {
  orders <- lapply(cost_list, .pr_engine_order_from_cost)
  keys <- vapply(orders, paste, character(1L), collapse = ",")
  orders[!duplicated(keys)]
}

# Linear surrogate costs: the objective itself (linear) or convex combinations of
# the max-objective terms (vertices, uniform, the declared weights).
.pr_engine_surrogates <- function(spec, seed = 1L) {
  if (identical(spec$objective, "linear")) return(list(objective = spec$C))
  terms <- spec$terms; K <- length(terms)
  combos <- c(lapply(seq_len(K), function(k) replace(numeric(K), k, 1)), list(rep(1 / K, K)))
  w <- spec$weights[names(terms)]
  if (!anyNA(w) && sum(w) > 0) combos[[length(combos) + 1L]] <- as.numeric(w / sum(w))
  old <- if (exists(".Random.seed", envir = .GlobalEnv, inherits = FALSE)) get(".Random.seed", envir = .GlobalEnv) else NULL
  on.exit(if (is.null(old)) { if (exists(".Random.seed", envir = .GlobalEnv, inherits = FALSE)) rm(".Random.seed", envir = .GlobalEnv) } else assign(".Random.seed", old, envir = .GlobalEnv), add = TRUE)
  set.seed(seed)
  for (r in seq_len(3L)) { d <- stats::rexp(K); combos[[length(combos) + 1L]] <- d / sum(d) }
  out <- lapply(combos, function(l) Reduce(`+`, Map(function(a, m) a * m, l, terms)))
  names(out) <- paste0("combo", seq_along(out)); out
}

# Candidate generation with Lagrangian handling of linear rows: rows violated by
# every candidate receive increasing multipliers (cost + mu * A), the classical
# reweighting view of a constraint. All-tie (and, for exact-G, a balanced split
# along the first order) is always included.
.pr_engine_candidates <- function(spec, extra_orders = list(), max_rounds = 12L, seed = 1L, default_orders = TRUE,
                                  deadline = Inf) {
  G <- if (is.null(spec$exact_G)) spec$G_max else spec$exact_G
  exact <- !is.null(spec$exact_G)
  out <- list(); add <- function(g, source) if (!is.null(g)) out[[length(out) + 1L]] <<- list(grade = .pr_engine_canonical(g), source = source)
  if (!exact || G == 1L) add(rep(1L, spec$n), "all_tie")
  late <- function() length(out) > 0L && proc.time()[["elapsed"]] > deadline
  for (s in names(sur <- .pr_engine_surrogates(spec, seed))) {
    if (late()) break
    base <- sur[[s]]; mu <- numeric(length(spec$rows))
    for (round in seq_len(if (length(spec$rows)) max_rounds else 1L)) {
      if (late()) break
      cost <- base
      for (r in seq_along(spec$rows)) if (mu[r] > 0) cost <- cost + mu[r] * spec$rows[[r]]$A
      orders <- c(if (default_orders) .pr_engine_orders(spec, c(list(cost), lapply(spec$e, function(m) m - spec$tau))), extra_orders)
      feasible_any <- FALSE; violated <- rep(TRUE, length(spec$rows))
      for (o in seq_along(orders)) {
        g <- .pr_engine_order_dp(cost, orders[[o]], G, exact)
        if (is.null(g)) next
        add(g, sprintf("dp:%s:round%d:order%d", s, round, o))
        ev <- .pr_engine_evaluate(spec, g)
        if (ev$feasible) feasible_any <- TRUE
        violated <- violated & (ev$row_slack < 0)
      }
      if (feasible_any || !length(spec$rows)) break
      scale <- max(abs(base)) + 1e-12
      for (r in which(violated)) mu[r] <- if (mu[r] == 0) .5 * scale else 2 * mu[r]
      if (!any(violated)) break
    }
  }
  keys <- vapply(out, function(z) paste(z$grade, collapse = ","), character(1L))
  out[!duplicated(keys)]
}
