# T-base-02 / T-api-07 / T-base-03: the cut DP equals brute-force enumeration of every
# contiguous partition of the declared order, and the full family is never worse.
co_random_e <- function(n, K, seed) {
  set.seed(seed); ids <- sprintf("e%d", seq_len(n)); e <- array(NA_real_, c(n, n, K), dimnames = list(ids, ids, paste0("k", seq_len(K))))
  for (k in seq_len(K)) for (i in 1:(n - 1)) for (j in (i + 1):n) { p <- stats::runif(1); e[i, j, k] <- p; e[j, i, k] <- 1 - p }
  e
}
co_Z <- function(e, g, w, tau) { n <- length(g); Z <- 0
  for (i in 1:(n - 1)) for (j in (i + 1):n) if (g[i] != g[j]) { hi <- if (g[i] < g[j]) i else j; lo <- if (hi == i) j else i
    Z <- Z + sum(w * e[hi, lo, ]) - tau }
  Z }
# All contiguous partitions of the block order into g segments (cut subsets of size g - 1).
co_contiguous_best <- function(e, order, blocks, w, tau, G_max, exact_G = NULL) {
  B <- max(blocks); best <- Inf
  gs <- if (is.null(exact_G)) seq_len(min(G_max, B)) else exact_G
  for (g in gs) {
    cutsets <- if (g == 1L) list(integer()) else utils::combn(B - 1L, g - 1L, simplify = FALSE)
    for (cs in cutsets) {
      bg <- 1L + findInterval(seq_len(B) - 1L, cs)
      grade <- integer(length(order)); grade[order] <- bg[blocks]
      best <- min(best, co_Z(e, grade, w, tau))
    }
  }
  best
}

test_that("DP optimum equals contiguous-partition enumeration for n <= 8 (T-base-02, T-api-07)", {
  for (seed in 1:12) {
    n <- 3 + seed %% 6; K <- 1 + seed %% 3; e <- co_random_e(n, K, seed)
    set.seed(100 + seed); w <- stats::runif(K); w <- w / sum(w); w[K] <- 1 - sum(w[-K]); names(w) <- dimnames(e)[[3]]
    tau <- stats::runif(1, .05, .5)
    sc <- stats::setNames(stats::rnorm(n), dimnames(e)[[1]])
    if (seed %% 4 == 0) sc[2] <- sc[1]  # injected exact tie
    order <- order(sc, dimnames(e)[[1]], method = "radix")
    blocks <- cumsum(c(TRUE, unname(sc[order])[-1] != unname(sc[order])[-n]))
    for (G in seq_len(n)) {
      o <- .pr_cuts_core(e, sc, w, tau, G, NULL, "ascending", "optimal")
      expect_lt(abs(o$objective - co_contiguous_best(e, order, blocks, w, tau, G)), 1e-12)
      expect_lt(abs(o$objective - co_Z(e, o$grades, w, tau)), 1e-12)
      if (G <= max(blocks)) {
        x <- .pr_cuts_core(e, sc, w, tau, n, G, "ascending", "optimal")
        expect_identical(max(x$grades), as.integer(G))
        expect_lt(abs(x$objective - co_contiguous_best(e, order, blocks, w, tau, n, exact_G = G)), 1e-12)
      }
    }
  }
})

test_that("the full action family is never worse than the ER family (T-base-03)", {
  for (seed in 1:6) {
    n <- 4 + seed %% 2; e <- co_random_e(n, 2, 50 + seed); w <- c(k1 = .5, k2 = .5); tau <- .3
    sc <- { r <- matrix(0, n, 2); for (k in 1:2) { s <- e[, , k]; diag(s) <- 0; r[, k] <- 1 + rowSums(s) }; stats::setNames(as.vector(r %*% w), dimnames(e)[[1]]) }
    o <- .pr_cuts_core(e, sc, w, tau, n, NULL, "ascending", "optimal")
    full <- pr_oracle_solve(e, w, tau, n)
    expect_lte(full$optimum, o$risk + 1e-12)
    # If a full-family optimum is ER-contiguous the two minima agree.
    best <- full$actions[which(abs(full$values - full$optimum) <= 1e-12)]
    ord <- order(sc, method = "radix")
    if (any(vapply(best, function(g) !is.unsorted(g[ord]), TRUE))) expect_lt(abs(full$optimum - o$risk), 1e-12)
  }
})
