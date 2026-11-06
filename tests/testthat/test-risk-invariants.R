pr_invariant_payload <- function() {
  x <- pr_test_payload(S = 7L, n = 4L, K = 3L)
  for (s in 1:7) for (k in 1:3)
    x$joint_draws$tensor$values[s, , k] <- ((seq_len(4L) + s + 2L * k - 3L) %% 4L) + 1 + s / 100 + k / 1000
  x$joint_draws$origin$source_hash <- digest::digest(x$joint_draws$tensor$values, algo = "sha256")
  x
}
pr_invariant_permute <- function(x, entities = seq_along(x$entity_ids), criteria = seq_along(x$criterion_ids)) {
  x$entity_ids <- x$entity_ids[entities]
  x$criterion_ids <- x$criterion_ids[criteria]
  x$targets <- x$targets[criteria]
  x$joint_draws$tensor$values <- x$joint_draws$tensor$values[, entities, criteria, drop = FALSE]
  x$joint_draws$tensor$dimnames <- dimnames(x$joint_draws$tensor$values)
  x
}
pr_invariant_permutations <- function(n) {
  grid <- as.matrix(expand.grid(rep(list(seq_len(n)), n)))
  grid[apply(grid, 1L, function(z) !anyDuplicated(z)), , drop = FALSE]
}

testthat::test_that("all small entity and criterion permutations preserve aligned decisions", {
  x <- pr_invariant_payload()
  p <- postrank_pairwise(x)
  grade <- stats::setNames(c(1L, 2L, 2L, 3L), x$entity_ids)
  weights <- stats::setNames(c(0.2, 0.3, 0.5), x$criterion_ids)
  risk <- postrank_evaluate(grade, p, weights, 0.3)
  for (row in seq_len(nrow(pr_invariant_permutations(4L)))) {
    perm <- pr_invariant_permutations(4L)[row, ]
    pp <- postrank_pairwise(pr_invariant_permute(x, entities = perm))
    rr <- postrank_evaluate(grade[perm], pp, weights, 0.3)
    testthat::expect_identical(pp$e, p$e[perm, perm, , drop = FALSE])
    testthat::expect_equal(rr$weighted_risk, risk$weighted_risk, tolerance = 1e-14)
    testthat::expect_identical(rr$N, risk$N)
  }
  for (row in seq_len(nrow(pr_invariant_permutations(3L)))) {
    perm <- pr_invariant_permutations(3L)[row, ]
    pp <- postrank_pairwise(pr_invariant_permute(x, criteria = perm))
    rr <- postrank_evaluate(grade, pp, weights[perm], 0.3)
    testthat::expect_identical(pp$e, p$e[, , perm, drop = FALSE])
    testthat::expect_equal(rr$weighted_risk, risk$weighted_risk, tolerance = 1e-14)
    testthat::expect_identical(rr$E, risk$E[perm])
  }
  pp <- postrank_pairwise(pr_invariant_permute(x, c(4, 2, 1, 3), c(3, 1, 2)))
  testthat::expect_equal(postrank_evaluate(grade[c(4, 2, 1, 3)], pp, weights[c(3, 1, 2)], 0.3)$weighted_risk,
    risk$weighted_risk, tolerance = 1e-14)
})

testthat::test_that("strictly increasing transforms, full-row permutations and block sizes preserve risk", {
  x <- pr_invariant_payload()
  p <- postrank_pairwise(x, method = "reference")
  grade <- stats::setNames(c(1, 2, 2, 3), x$entity_ids)
  weights <- stats::setNames(c(0.2, 0.3, 0.5), x$criterion_ids)
  target <- postrank_evaluate(grade, p, weights, 0.25)$weighted_risk
  y <- x
  y$joint_draws$tensor$values[, , 1] <- exp(y$joint_draws$tensor$values[, , 1])
  y$joint_draws$tensor$values[, , 2] <- y$joint_draws$tensor$values[, , 2]^3
  y$joint_draws$tensor$values[, , 3] <- 2 * y$joint_draws$tensor$values[, , 3] + 7
  pp <- postrank_pairwise(y)
  testthat::expect_identical(pp$e, p$e)
  testthat::expect_equal(postrank_evaluate(grade, pp, weights, 0.25)$weighted_risk, target, tolerance = 1e-14)
  y <- x
  perm <- c(7L, 2L, 5L, 1L, 6L, 4L, 3L)
  y$joint_draws$tensor$values <- y$joint_draws$tensor$values[perm, , , drop = FALSE]
  dimnames(y$joint_draws$tensor$values)$draw <- x$joint_draws$tensor$dimnames$draw
  y$joint_draws$draw_index <- y$joint_draws$draw_index[perm]
  for (s in seq_along(perm)) y$joint_draws$draw_index[[s]]$slot_id <- x$joint_draws$tensor$dimnames$draw[[s]]
  testthat::expect_identical(postrank_pairwise(y)$e, p$e)
  for (size in c(1L, 2L, 5L, 12L, 13L, 128L)) {
    pp <- postrank_pairwise(x, method = "blocks", block_size = size)
    testthat::expect_identical(pp$e, p$e)
    testthat::expect_equal(postrank_evaluate(grade, pp, weights, 0.25)$weighted_risk, target, tolerance = 1e-14)
  }
})

testthat::test_that("criterionwise unequal whole-vector repetition preserves per-criterion denominators", {
  x <- pr_invariant_payload()
  p <- postrank_pairwise(x)
  y <- x
  y$dependence_mode <- "criterionwise_expected_only"
  y$joint_draws <- NULL
  y$criterion_blocks <- lapply(1:3, function(k) {
    idx <- rep(1:7, times = k)
    slots <- paste0("local", seq_along(idx))
    a <- matrix(x$joint_draws$tensor$values[idx, , k], nrow = length(idx), ncol = 4,
      dimnames = list(draw = slots, entity = x$entity_ids))
    origin <- x$joint_draws$origin
    origin$source_id <- origin$fit_id <- paste0("independent-criterion-source-", k)
    list(criterion_id = x$criterion_ids[[k]],
      matrix = list(axis_order = c("draw", "entity"), shape = list(S = length(idx), n = 4L), dimnames = dimnames(a), values = a),
      origin = origin, sampling = x$joint_draws$sampling,
      draw_index = lapply(seq_along(idx), function(s) list(slot_id = slots[[s]], original_draw_id = paste0("original-", s), chain_id = NULL, iteration = NULL)),
      variable_map = Filter(function(z) z$criterion_id == x$criterion_ids[[k]], x$joint_draws$variable_map))
  })
  pp <- postrank_pairwise(y, block_size = 2L)
  testthat::expect_identical(pp$e, p$e)
  testthat::expect_equal(unname(pp$sample_sizes), c(7, 14, 21), tolerance = 0)
  grade <- stats::setNames(c(1, 2, 2, 3), x$entity_ids)
  weights <- stats::setNames(c(0.2, 0.3, 0.5), x$criterion_ids)
  testthat::expect_equal(postrank_evaluate(grade, pp, weights, 0.25)$weighted_risk,
    postrank_evaluate(grade, p, weights, 0.25)$weighted_risk, tolerance = 1e-14)
})

testthat::test_that("identical site marginals can imply different directional error probabilities", {
  x <- pr_test_payload(S = 2L, n = 2L, K = 1L)
  x$joint_draws$tensor$values[, , 1] <- cbind(c(0, 2), c(1, 3))
  y <- x
  y$joint_draws$tensor$values[, 2, 1] <- rev(y$joint_draws$tensor$values[, 2, 1])
  testthat::expect_identical(sort(unname(x$joint_draws$tensor$values[, 1, 1])), sort(unname(y$joint_draws$tensor$values[, 1, 1])))
  testthat::expect_identical(sort(unname(x$joint_draws$tensor$values[, 2, 1])), sort(unname(y$joint_draws$tensor$values[, 2, 1])))
  p <- postrank_pairwise(x)
  pp <- postrank_pairwise(y)
  testthat::expect_identical(p$e[1, 2, 1], 1)
  testthat::expect_identical(pp$e[1, 2, 1], 0.5)
  testthat::expect_identical(mean(outer(c(0, 2), c(1, 3), `<=`)), 0.75)
  grade <- stats::setNames(c(1, 2), x$entity_ids)
  weights <- stats::setNames(1, x$criterion_ids)
  testthat::expect_identical(postrank_evaluate(grade, p, weights, 0.25)$weighted_risk, 1)
  testthat::expect_identical(postrank_evaluate(grade, pp, weights, 0.25)$weighted_risk, 0.5)
})

testthat::test_that("additive expected risk does not identify cross-criterion joint-error tails", {
  x <- pr_test_payload(S = 2L, n = 2L, K = 2L)
  for (k in 1:2) x$joint_draws$tensor$values[, , k] <- rbind(c(2, 1), c(1, 2))
  y <- x
  y$joint_draws$tensor$values[, , 2] <- y$joint_draws$tensor$values[2:1, , 2]
  p <- postrank_pairwise(x)
  pp <- postrank_pairwise(y)
  testthat::expect_identical(p$e, pp$e)
  grade <- stats::setNames(c(1, 2), x$entity_ids)
  weights <- stats::setNames(c(0.5, 0.5), x$criterion_ids)
  testthat::expect_identical(postrank_evaluate(grade, p, weights, 0.25)$weighted_risk, 0.5)
  testthat::expect_identical(postrank_evaluate(grade, pp, weights, 0.25)$weighted_risk, 0.5)
  both_wrong <- function(z) mean(z$joint_draws$tensor$values[, 1, 1] < z$joint_draws$tensor$values[, 2, 1] &
    z$joint_draws$tensor$values[, 1, 2] < z$joint_draws$tensor$values[, 2, 2])
  testthat::expect_identical(both_wrong(x), 0.5)
  testthat::expect_identical(both_wrong(y), 0)
})

testthat::test_that("K1 affine KRW loss and canonical grade relations agree with literal states", {
  x <- pr_test_payload(S = 4L, n = 3L, K = 1L)
  p <- postrank_pairwise(x)
  grade <- stats::setNames(c(10, 30, 30), x$entity_ids)
  weights <- stats::setNames(1, x$criterion_ids)
  tau <- 0.4
  r <- postrank_evaluate(grade, p, weights, tau)
  testthat::expect_identical(unname(r$grade), c(1L, 2L, 2L))
  testthat::expect_identical(outer(unname(grade), unname(grade), `<`), unname(r$x))
  lambda <- tau / (1 - tau)
  state_krw <- vapply(1:4, function(s) {
    wrong <- sum(x$joint_draws$tensor$values[s, 1, 1] <= x$joint_draws$tensor$values[s, 2:3, 1])
    (wrong - lambda * (2 - wrong)) / 3
  }, numeric(1L))
  testthat::expect_equal(mean(state_krw), (1 + lambda) * r$weighted_risk - lambda, tolerance = 1e-14)
  all_tie <- postrank_evaluate(stats::setNames(rep(9L, 3L), x$entity_ids), p, weights, tau)
  testthat::expect_identical(all_tie$G, 1L)
  testthat::expect_identical(all_tie$N, 0L)
  testthat::expect_true(all(is.na(all_tie$E_over_N)))
  testthat::expect_equal(all_tie$weighted_risk, tau, tolerance = 1e-14)
})
