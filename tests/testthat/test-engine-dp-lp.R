# 014 repair Phase 2: building blocks of the staged engine.
# (1) The fixed-order dynamic programme is exact over contiguous partitions of
#     that order (brute force over all cut sets).
# (2) Every ordered partition satisfies all triangle inequalities, and the
#     separation routine returns exactly the violated ones.
# (3) The weak-order relaxation never exceeds the exact optimum.
pr_contiguous_best <- function(C, order, G, exact) {
  n <- length(order); best <- Inf
  for (m in 0:(2^(n - 1) - 1)) {
    cuts <- which(bitwAnd(m, 2^(0:(n - 2))) > 0)
    blocks <- length(cuts) + 1L
    if (blocks > G || (exact && blocks != G)) next
    lab <- integer(n); lab[order] <- cumsum(c(1L, as.integer(seq_len(n - 1L) %in% cuts)))
    best <- min(best, sum(C[outer(lab, lab, `<`)]))
  }
  best
}

testthat::test_that("order DP equals brute force over contiguous partitions (n <= 9)", {
  set.seed(20261019)
  for (rep in 1:40) {
    n <- sample(2:9, 1); C <- matrix(stats::rnorm(n * n), n, n); diag(C) <- 0
    order <- sample(n); G <- sample(seq_len(n), 1); exact <- stats::runif(1) < .4
    g <- .pr_engine_order_dp(C, order, G, exact)
    label <- paste("rep", rep, "n", n, "G", G, "exact", exact)
    testthat::expect_equal(sum(C[outer(g, g, `<`)]), pr_contiguous_best(C, order, G, exact), tolerance = 1e-10, info = label)
    testthat::expect_true(max(g) <= G, info = label)
    if (exact) testthat::expect_identical(max(g), as.integer(G), info = label)
    testthat::expect_true(all(diff(g[order]) >= 0), info = label)
  }
})

testthat::test_that("ordered partitions satisfy every triangle inequality", {
  set.seed(7)
  for (rep in 1:30) {
    n <- sample(3:8, 1); g <- sample(seq_len(sample(seq_len(n), 1)), n, replace = TRUE)
    Y <- outer(g, g, `<`) * 1
    testthat::expect_identical(nrow(.pr_engine_separate(Y, eps = 0, max_cuts = 1e6)), 0L)
  }
})

testthat::test_that("separation returns exactly the violated triangle inequalities", {
  set.seed(8)
  key <- function(m) if (!nrow(m)) character() else sort(unname(apply(m, 1L, paste, collapse = ",")))
  for (rep in 1:20) {
    n <- sample(3:7, 1); Y <- matrix(stats::runif(n * n), n, n); diag(Y) <- 0
    cuts <- .pr_engine_separate(Y, eps = 1e-7, max_cuts = 1e6)
    brute <- matrix(integer(), 0L, 3L)
    for (k in seq_len(n)) for (i in seq_len(n)) for (j in seq_len(n))
      if (length(unique(c(k, i, j))) == 3L && Y[k, i] - Y[k, j] - Y[j, i] > 1e-7) brute <- rbind(brute, c(k, i, j))
    testthat::expect_identical(key(cuts[, c("k", "i", "j"), drop = FALSE]), key(brute))
    testthat::expect_equal(unname(cuts[, "violation"]),
      Y[cbind(cuts[, "k"], cuts[, "i"])] - Y[cbind(cuts[, "k"], cuts[, "j"])] - Y[cbind(cuts[, "j"], cuts[, "i"])])
    testthat::expect_true(all(diff(cuts[, "violation"]) <= 0))
  }
})

testthat::test_that("weak-order relaxation bound never exceeds the exact optimum", {
  testthat::skip_if_not_installed("highs")
  control <- .pr_control(list(time_limit = 20, threads = 1L, seed = 1L))
  for (case in list(list(seed = 21L, S = 30L, n = 5L, K = 2L, conflict = TRUE, tau = .25),
                    list(seed = 22L, S = 30L, n = 6L, K = 3L, conflict = FALSE, tau = .25),
                    list(seed = 24L, S = 30L, n = 6L, K = 2L, conflict = TRUE, tau = .05),
                    list(seed = 25L, S = 30L, n = 5L, K = 2L, conflict = FALSE, tau = .5))) {
    tau <- case$tau; case$tau <- NULL
    x <- do.call(pr_random_payload, case); pw <- postrank_pairwise(x)
    e <- pr_oracle_e_from_draws(x$joint_draws$tensor$values)
    w <- rep(1 / case$K, case$K); names(w) <- pw$criterion_ids
    for (s in list(list(G_max = 2L), list(G_max = case$n), list(G_max = 3L, objective = "minimax"),
                   list(G_max = 3L, q = stats::setNames(.15, pw$criterion_ids[1])))) {
      objective <- if (is.null(s$objective)) "weighted" else s$objective
      problem <- postrank_problem(pw, w, tau, s$G_max, objective = objective, q = s$q)
      spec <- .pr_engine_spec(problem)
      lp <- .pr_engine_lp_bound(spec, "highs", control, time_budget = 20)
      q_index <- if (is.null(s$q)) NULL else stats::setNames(list(s$q[[1L]]), as.character(match(names(s$q), pw$criterion_ids)))
      oracle <- pr_oracle_solve(e, w, tau, s$G_max, objective, q_index)
      label <- paste("case", case$seed, "tau", tau, objective, paste(names(s), unlist(s), collapse = " "))
      testthat::expect_identical(lp$status, "no_violated_triangle", info = label)
      testthat::expect_true(spec$offset + spec$scale * lp$bound_raw <= oracle$optimum + 1e-9, info = label)
    }
  }
})

testthat::test_that("disclosure-count limits equal the enumerated range for each grade-count mode", {
  for (n in 2:6) for (G in seq_len(n)) {
    parts <- pr_oracle_ordered_partitions(n, G)
    count <- vapply(parts, function(g) sum(outer(g, g, `<`)), numeric(1L))
    blocks <- vapply(parts, max, numeric(1L))
    at_most <- .pr_engine_disclosure_limits(n, G)
    testthat::expect_equal(unname(at_most), c(0, max(count)), info = paste("at most", G, "of", n))
    exact <- .pr_engine_disclosure_limits(n, G, G)
    testthat::expect_equal(unname(exact), range(count[blocks == G]), info = paste("exactly", G, "of", n))
  }
})

testthat::test_that("relaxation bounds stay valid with exact grade counts", {
  testthat::skip_if_not_installed("highs")
  control <- .pr_control(list(time_limit = 20, threads = 1L, seed = 1L))
  x <- pr_random_payload(23L, 30L, 6L, 2L, conflict = TRUE); pw <- postrank_pairwise(x)
  e <- pr_oracle_e_from_draws(x$joint_draws$tensor$values); w <- c(need1 = .5, need2 = .5)
  for (G in c(1L, 2L, 4L, 6L)) for (objective in c("weighted", "minimax")) {
    problem <- postrank_problem(pw, w, .25, G, objective = objective, exact_G = G)
    spec <- .pr_engine_spec(problem)
    lp <- .pr_engine_lp_bound(spec, "highs", control, time_budget = 20)
    oracle <- pr_oracle_solve(e, w, .25, G, objective, NULL, G)
    testthat::expect_true(spec$offset + spec$scale * lp$bound_raw <= oracle$optimum + 1e-9, info = paste(objective, "exact", G))
  }
})

testthat::test_that("the dense disclosure-count row enters the relaxation only when violated", {
  testthat::skip_if_not_installed("highs")
  control <- .pr_control(list(time_limit = 20, threads = 1L, seed = 1L))
  x <- pr_random_payload(26L, 30L, 6L, 2L, conflict = TRUE); pw <- postrank_pairwise(x); w <- c(need1 = .5, need2 = .5)
  exact <- .pr_engine_lp_bound(.pr_engine_spec(postrank_problem(pw, w, .25, 4L, exact_G = 4L)), "highs", control, time_budget = 20)
  testthat::expect_true(exact$disclosure_row_added)
  free <- .pr_engine_lp_bound(.pr_engine_spec(postrank_problem(pw, w, .25, 6L)), "highs", control, time_budget = 20)
  testthat::expect_false(free$disclosure_row_added)
})
