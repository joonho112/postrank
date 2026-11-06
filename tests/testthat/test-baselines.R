# T-base-01, -04, -07, -08, -09, -12: score baselines and cut rules.
bl_three <- function() {
  ids <- c("A", "B", "C"); e <- array(NA_real_, c(3, 3, 2), dimnames = list(ids, ids, c("k1", "k2")))
  for (k in 1:2) { e["A", "B", k] <- 0; e["B", "A", k] <- 1; e["A", "C", k] <- 0; e["C", "A", k] <- 1; e["B", "C", k] <- .3; e["C", "B", k] <- .7 }
  e
}
bl_er <- function(e, b) { n <- dim(e)[1]; r <- matrix(0, n, dim(e)[3]); for (k in seq_len(dim(e)[3])) { s <- e[, , k]; diag(s) <- 0; r[, k] <- 1 + rowSums(s) }
  stats::setNames(as.vector(r %*% b), dimnames(e)[[1]]) }

test_that("methods-book three-site example: optimal and quantile cuts (T-base-01)", {
  e <- bl_three(); w <- c(k1 = .5, k2 = .5)
  sc <- bl_er(e, w); expect_equal(as.numeric(sc), c(1, 23 / 10, 27 / 10), tolerance = 1e-12)
  comp <- c(A = 3, B = 17 / 10, C = 13 / 10)
  for (dir in list(list(sc, "ascending"), list(comp, "descending"))) {
    o <- .pr_cuts_core(e, dir[[1]], w, .25, 3L, NULL, dir[[2]], "optimal")
    expect_identical(unname(o$grades), c(1L, 2L, 2L))
    expect_equal(o$objective, -1 / 2, tolerance = 1e-12); expect_equal(o$risk, 1 / 12, tolerance = 1e-12)
    q <- .pr_cuts_core(e, dir[[1]], w, .25, 3L, NULL, dir[[2]], "quantile", 2L)
    expect_identical(unname(q$grades), c(1L, 1L, 2L)); expect_equal(q$risk, 11 / 60, tolerance = 1e-12)
  }
})

test_that("public cuts return a validated baseline whose risk equals its evaluation (T-base-08)", {
  pw <- postrank_pairwise(postrank_toy); s <- postrank_settings(c(need_A = .6, need_B = .4), .25, 3L)
  b <- postrank_cuts(postrank_expected_rank(pw, s$weights), pw, s)
  expect_s3_class(b, "postrank_baseline")
  expect_identical(names(b), c("method", "scores", "direction", "order", "score_blocks", "cut_rule", "cuts", "grade",
    "evaluation", "objective", "risk", "optimality_scope", "tie_policy", "settings", "input_identity", "schema_version",
    "provenance", "warnings"))
  expect_identical(b$method, "expected_rank")
  M <- choose(3, 2)
  expect_lt(abs(b$risk - (s$tau + b$objective / M)), 1e-12)
  expect_lt(abs(b$risk - b$evaluation$weighted_risk), 1e-12)
  expect_identical(get_grades(b), b$grade)
  expect_identical(b$tie_policy, list(scores = "exact_score_blocks", objective = "fewer_grades_then_lexicographic_cuts", epsilon = 0))
  # All-tie: objective exactly 0 and risk tau.
  s1 <- postrank_settings(c(need_A = .6, need_B = .4), .25, 1L)
  a <- postrank_cuts(postrank_expected_rank(pw, s1$weights), pw, s1)
  expect_identical(a$objective, 0); expect_lt(abs(a$risk - .25), 1e-12)
  # Unsupported settings are refused.
  e <- tryCatch(postrank_cuts(postrank_expected_rank(pw), pw, postrank_settings(c(need_A = .6, need_B = .4), q = c(need_A = .2))), error = identity)
  expect_identical(e$code, "unsupported_baseline_settings")
  e <- tryCatch(postrank_cuts(postrank_expected_rank(pw), pw, postrank_settings(c(need_A = .6, need_B = .4), objective = "minimax")), error = identity)
  expect_identical(e$code, "unsupported_baseline_settings")
  e <- tryCatch(postrank_cuts(c(`001` = 1, `site-B` = 1, `site C` = 2), pw, postrank_settings(c(need_A = .6, need_B = .4), G_max = 3L, exact_G = 3L)), error = identity)
  expect_identical(e$code, "exact_G_exceeds_blocks")
})

test_that("exact score ties are never split; ID permutation preserves scores (T-base-04)", {
  ids <- c("a", "b", "c", "d"); e <- array(NA_real_, c(4, 4, 1), dimnames = list(ids, ids, "k"))
  base <- rbind(c(NA, .5, .1, .2), c(.5, NA, .1, .2), c(.9, .9, NA, .3), c(.8, .8, .7, NA))
  e[, , 1] <- base
  sc <- bl_er(e, 1); expect_identical(sc[["a"]], sc[["b"]])
  for (rule in c("optimal", "quantile")) for (G in 2:4) {
    o <- .pr_cuts_core(e, sc, c(k = 1), .25, G, NULL, "ascending", rule, if (rule == "quantile") G else NULL)
    expect_identical(o$grades[["a"]], o$grades[["b"]])
  }
  perm <- c(3, 1, 4, 2); e2 <- e[perm, perm, , drop = FALSE]
  sc2 <- bl_er(e2, 1); expect_identical(sc2[ids], sc[ids])
})

test_that("quantile labels follow 1 + floor((p - 1) G_b / n); ties merge (T-base-07)", {
  for (n in 2:12) for (Gb in seq_len(n)) {
    ids <- sprintf("e%02d", seq_len(n)); e <- array(.5, c(n, n, 1), dimnames = list(ids, ids, "k"))
    for (i in seq_len(n)) e[i, i, 1] <- NA
    sc <- stats::setNames(seq_len(n) + 0, ids)
    q <- .pr_cuts_core(e, sc, c(k = 1), .25, n, NULL, "ascending", "quantile", Gb)
    expect_identical(unname(q$grades), as.integer(1L + floor((seq_len(n) - 1L) * Gb / n)))
  }
  ids <- sprintf("e%02d", 1:6); e <- array(.5, c(6, 6, 1), dimnames = list(ids, ids, "k")); for (i in 1:6) e[i, i, 1] <- NA
  sc <- stats::setNames(c(1, 2, 2, 3, 4, 5), ids)
  q <- .pr_cuts_core(e, sc, c(k = 1), .25, 6L, NULL, "ascending", "quantile", 3L)
  expect_identical(q$grades[["e02"]], q$grades[["e03"]]); expect_lte(max(q$grades), 3L)
})

test_that("engine-order identity (n + 1) - 2 r_i = sum_j C_ji - sum_j C_ij (T-base-09)", {
  set.seed(9); n <- 6; K <- 2
  ids <- letters[1:n]; e <- array(NA_real_, c(n, n, K), dimnames = list(ids, ids, c("k1", "k2")))
  for (k in 1:K) for (i in 1:(n - 1)) for (j in (i + 1):n) { p <- stats::runif(1); e[i, j, k] <- p; e[j, i, k] <- 1 - p }
  w <- c(k1 = .3, k2 = .7); r <- bl_er(e, w)
  C <- w[1] * e[, , 1] + w[2] * e[, , 2]; diag(C) <- 0
  expect_lt(max(abs(((n + 1) - 2 * r) - (colSums(C) - rowSums(C)))), 1e-12)
})

test_that("objective ties: fewer grades, then lexicographically earlier cuts; no epsilon (T-base-12)", {
  ids <- c("a", "b", "c"); e <- array(NA_real_, c(3, 3, 1), dimnames = list(ids, ids, "k"))
  e[, , 1] <- rbind(c(NA, .25, .25), c(.75, NA, .25), c(.75, .75, NA))  # every disclosure costs exactly tau
  o <- .pr_cuts_core(e, c(a = 1, b = 2, c = 3), c(k = 1), .25, 3L, NULL, "ascending", "optimal")
  expect_identical(unname(o$grades), c(1L, 1L, 1L)); expect_identical(o$objective, 0)
  e[, , 1] <- rbind(c(NA, .1, .3), c(.9, NA, .1), c(.7, .9, NA))
  o <- .pr_cuts_core(e, c(a = 1, b = 2, c = 3), c(k = 1), .25, 2L, NULL, "ascending", "optimal")
  # Cuts after a or after b both give Z = -0.1; the earlier cut vector (after block 1) wins.
  expect_equal(o$objective, -.1, tolerance = 1e-12)
  expect_identical(o$cuts, 1L)
  sc <- c(a = 1, b = 1 + 1e-9, c = 3)
  o2 <- .pr_cuts_core(e, sc, c(k = 1), .25, 3L, NULL, "ascending", "optimal")
  expect_identical(o2$blocks, 3L)
  o3 <- .pr_cuts_core(e, c(a = 1, b = 1, c = 3), c(k = 1), .25, 3L, NULL, "ascending", "optimal")
  expect_identical(o3$blocks, 2L)
})

test_that("composite scores use declared scales and centers only", {
  m <- matrix(c(1, 2, 3, 10, 20, 30), 3, 2, dimnames = list(c("a", "b", "c"), c("k1", "k2")))
  expect_equal(as.numeric(postrank_composite(m, c(k1 = .5, k2 = .5), scales = c(1, 10))), c(1, 2, 3))
  expect_equal(as.numeric(postrank_composite(m, c(.5, .5), centers = 1)), c(4.5, 10, 15.5))
  expect_error(postrank_composite(m, c(k1 = .5, k2 = .5), scales = 0), "positive")
  expect_identical(attr(postrank_composite(m, c(.5, .5)), "score_method"), "composite")
})
