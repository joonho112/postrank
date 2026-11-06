# Single-entity move local search over ordered partitions.
#
# Moving entity i from level a to target b changes only the relations of i with
# the other entities. With level one-hot matrix H, Rq = Q %*% H and Cq = t(Q) %*% H
# give, for each entity and level, the pair sums of i ahead of / behind that level;
#   dS_Q(i -> b) = sum_l Rq[i,l] (1{b<l} - 1{a<l}) + sum_l Cq[i,l] (1{l<b} - 1{l<a}).
# Targets b are existing levels l and new singleton levels inserted before level l
# (encoded b = l - 1/2). Rows must stay feasible; G must stay admissible.
#
# A move to an existing level that leaves the source level nonempty keeps every
# label, so Rq and Cq change only in columns a and b (incremental update). Moves
# that create or empty a level relabel the levels and recompute the sums. Exact
# sums are refreshed after every pass so incremental updates cannot drift.
.pr_engine_local_search <- function(spec, g, max_passes = 20L, deadline = Inf, tolerance = 1e-12,
                                    incremental = TRUE) {
  g <- .pr_engine_canonical(g); n <- spec$n
  linear <- identical(spec$objective, "linear")
  mats <- if (linear) list(spec$C) else spec$terms
  row_mats <- lapply(spec$rows, `[[`, "A"); row_b <- vapply(spec$rows, `[[`, numeric(1L), "b")
  all_mats <- c(mats, row_mats); n_obj <- length(mats)
  feas_tol <- spec$feasibility_tolerance
  value_of <- function(S) {
    if (linear) c(S[1L], 0) else {
      r <- spec$tau + S[seq_len(n_obj)] / spec$M
      c(max(r), sum(r))
    }
  }
  prepare <- function(g) {
    G <- max(g); H <- matrix(0, n, G); H[cbind(seq_len(n), g)] <- 1
    list(G = G, R = lapply(all_mats, function(Q) Q %*% H), Cm = lapply(all_mats, function(Q) crossprod(Q, H)),
         S = vapply(all_mats, function(Q) sum(Q[outer(g, g, `<`)]), numeric(1L)),
         size = tabulate(g, G))
  }
  st <- prepare(g); current <- value_of(st$S); moves <- 0L; timed_out <- FALSE; pass <- 0L
  for (pass in seq_len(max_passes)) {
    improved <- FALSE
    for (i in seq_len(n)) {
      if (proc.time()[["elapsed"]] > deadline) { timed_out <- TRUE; break }
      a <- g[i]; G <- st$G
      targets <- c(setdiff(seq_len(G), a), seq_len(G + 1L) - .5)
      new_G <- G + (targets != floor(targets)) - (st$size[a] == 1L)
      ok <- if (is.null(spec$exact_G)) new_G <= spec$G_max else new_G == spec$exact_G
      # Moving a singleton into an adjacent new slot recreates the same partition.
      if (st$size[a] == 1L) ok <- ok & !(targets %in% c(a - .5, a + .5))
      targets <- targets[ok]
      if (!length(targets)) next
      levels <- seq_len(G)
      ahead <- outer(targets, levels, `<`) - matrix(a < levels, length(targets), G, byrow = TRUE)
      behind <- outer(targets, levels, `>`) - matrix(levels < a, length(targets), G, byrow = TRUE)
      delta <- vapply(seq_along(all_mats), function(m)
        as.numeric(ahead %*% st$R[[m]][i, ] + behind %*% st$Cm[[m]][i, ]), numeric(length(targets)))
      delta <- matrix(delta, nrow = length(targets))
      best <- NULL; best_value <- current
      for (t in seq_along(targets)) {
        S_new <- st$S + delta[t, ]
        if (length(row_mats) && any(S_new[n_obj + seq_along(row_mats)] > row_b + feas_tol)) next
        v <- value_of(S_new)
        better <- v[1L] < best_value[1L] - tolerance ||
          (!linear && abs(v[1L] - best_value[1L]) <= tolerance && v[2L] < best_value[2L] - tolerance)
        if (better) { best <- t; best_value <- v }
      }
      if (is.null(best)) next
      b <- targets[best]
      if (incremental && b == floor(b) && st$size[a] > 1L) {
        b <- as.integer(b)
        for (m in seq_along(all_mats)) {
          Q <- all_mats[[m]]
          st$R[[m]][, a] <- st$R[[m]][, a] - Q[, i]; st$R[[m]][, b] <- st$R[[m]][, b] + Q[, i]
          st$Cm[[m]][, a] <- st$Cm[[m]][, a] - Q[i, ]; st$Cm[[m]][, b] <- st$Cm[[m]][, b] + Q[i, ]
        }
        st$S <- st$S + delta[best, ]
        st$size[a] <- st$size[a] - 1L; st$size[b] <- st$size[b] + 1L
        g[i] <- b
      } else {
        g_new <- g; g_new[i] <- b; g <- .pr_engine_canonical(g_new)
        st <- prepare(g)
      }
      current <- value_of(st$S)
      moves <- moves + 1L; improved <- TRUE
    }
    if (timed_out || !improved) break
    if (incremental) { st <- prepare(g); current <- value_of(st$S) }
  }
  list(grade = g, moves = moves, passes = pass, value = current, timed_out = timed_out)
}
