# Independent brute-force oracle for package tests (014 repair, VA-1).
# Written from the loss definitions only: it enumerates every canonical ordered
# partition with at most G blocks and evaluates risks from directional-error
# probabilities computed directly from the draw array (not from package code).
pr_oracle_ordered_partitions <- function(n, G) {
  parts <- list()
  grow <- function(i, a, m) {
    if (i > n) { parts[[length(parts) + 1L]] <<- a; return(invisible()) }
    for (b in seq_len(min(m + 1L, G))) { a[i] <- b; grow(i + 1L, a, max(m, b)) }
  }
  grow(1L, integer(n), 0L)
  perms <- function(v) if (length(v) <= 1L) list(v) else
    unlist(lapply(seq_along(v), function(j) lapply(perms(v[-j]), function(p) c(v[j], p))), recursive = FALSE)
  out <- list()
  for (a in parts) for (p in perms(seq_len(max(a)))) out[[length(out) + 1L]] <- p[a]
  out
}

pr_oracle_e_from_draws <- function(values) {
  n <- dim(values)[2L]; K <- dim(values)[3L]; e <- array(NA_real_, c(n, n, K))
  for (k in seq_len(K)) for (i in seq_len(n)) for (j in seq_len(n)) if (i != j)
    e[i, j, k] <- mean(values[, i, k] <= values[, j, k])
  e
}

# Returns the exact optimum value and every action's objective for one setting.
pr_oracle_solve <- function(e, w, tau, G_max, objective = "weighted", q = NULL, exact_G = NULL) {
  n <- dim(e)[1L]; K <- dim(e)[3L]; M <- choose(n, 2)
  actions <- pr_oracle_ordered_partitions(n, if (is.null(exact_G)) G_max else exact_G)
  values <- vapply(actions, function(g) {
    if (!is.null(exact_G) && max(g) != exact_G) return(NA_real_)
    x <- outer(g, g, `<`); N <- sum(x)
    E <- vapply(seq_len(K), function(k) sum(e[, , k][x]), numeric(1L))
    if (!is.null(q)) for (k in names(q)) if (E[as.integer(k)] > q[[k]] * N + 1e-12) return(NA_real_)
    Rk <- (E + tau * (M - N)) / M
    if (objective == "minimax") max(Rk) else (sum(w * E) + tau * (M - N)) / M
  }, numeric(1L))
  list(optimum = min(values, na.rm = TRUE), values = values, actions = actions)
}

# Random joint draws with a shared component (and, optionally, conflicting
# criteria) for oracle and engine tests. Within-criterion ties have probability 0.
pr_random_payload <- function(seed, S, n, K, conflict = FALSE) {
  set.seed(seed)
  x <- pr_test_payload(S = S, n = n, K = K)
  mu <- matrix(stats::rnorm(n * K, 0, .8), n, K)
  if (conflict && K >= 2L) mu[, 2] <- -mu[, 1]
  v <- x$joint_draws$tensor$values
  for (s in seq_len(S)) { z <- stats::rnorm(1L); for (k in seq_len(K)) v[s, , k] <- mu[, k] + .4 * z + stats::rnorm(n, 0, .6) }
  x$joint_draws$tensor$values <- v
  x
}
