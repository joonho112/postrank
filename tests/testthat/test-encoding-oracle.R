pr_encoding_feasible <- function(model, z) {
  activity <- as.numeric(model$A %*% z)
  all(z >= model$var_lower & z <= model$var_upper) &&
    all(activity >= model$row_lower & activity <= model$row_upper)
}
pr_encoding_grid <- function(values, count) as.matrix(expand.grid(rep(list(values), count)))

testthat::test_that("small sparse feasible sets exactly encode every ordered label comparison", {
  relation_counts <- list(`2` = c(1L, 3L), `3` = c(1L, 7L, 13L))
  for (n in 2:3) for (G in seq_len(n)) {
    p <- postrank_pairwise(pr_test_payload(n = n, K = 1L))
    problem <- postrank_problem(p, stats::setNames(1, p$criterion_ids), 0.4, G)
    model <- problem$model
    pair_i <- problem$pair_map$i
    pair_j <- problem$pair_map$j
    P <- n * (n - 1L)
    testthat::expect_identical(dim(model$A), c(2L * P, n + P))
    testthat::expect_equal(sum(model$types == "B"), P)
    testthat::expect_equal(sum(model$types == "I"), n)
    labels <- pr_encoding_grid(seq_len(G), n)
    binaries <- pr_encoding_grid(0:1, P)
    relation_keys <- character(nrow(labels))
    for (r in seq_len(nrow(labels))) {
      g <- as.numeric(labels[r, ])
      expected <- as.integer(g[pair_i] < g[pair_j])
      actual_feasible <- apply(binaries, 1L, function(b) pr_encoding_feasible(model, c(g, b)))
      correct_pairs <- apply(binaries, 1L, function(b) identical(as.integer(b), expected))
      testthat::expect_identical(actual_feasible, correct_pairs, info = paste("n", n, "G", G, "labels", paste(g, collapse = ",")))
      testthat::expect_equal(sum(actual_feasible), 1)
      canonical <- canonical_postrank_grade(stats::setNames(g, p$entity_ids), p$entity_ids)
      testthat::expect_identical(outer(g, g, `<`), outer(unname(canonical), unname(canonical), `<`))
      relation_keys[[r]] <- paste(sign(outer(g, g, `-`))[upper.tri(matrix(0, n, n))], collapse = ",")
    }
    testthat::expect_equal(length(unique(relation_keys)), relation_counts[[as.character(n)]][[G]])
  }
})

testthat::test_that("Gmax is the valid tight big-M and a smaller M loses an extreme label relation", {
  p <- postrank_pairwise(pr_test_payload(n = 2L, K = 1L))
  problem <- postrank_problem(p, stats::setNames(1, p$criterion_ids), 0.4, 2L)
  g <- c(2, 1)
  z <- c(g, as.integer(g[problem$pair_map$i] < g[problem$pair_map$j]))
  testthat::expect_true(pr_encoding_feasible(problem$model, z))
  wrong <- problem$model
  # This deliberately wrong encoding uses B=Gmax-1=1 instead of B=2.
  for (r in seq_len(nrow(wrong$A))) {
    columns <- problem$index$pairs
    used <- columns[as.numeric(wrong$A[r, columns]) != 0]
    wrong$A[r, used] <- -1
  }
  wrong$row_lower[is.finite(wrong$row_lower)] <- 0
  testthat::expect_false(pr_encoding_feasible(wrong, z))
  g <- c(1, 2)
  z <- c(g, as.integer(g[problem$pair_map$i] < g[problem$pair_map$j]))
  testthat::expect_true(pr_encoding_feasible(problem$model, z))
  g <- c(1, 1)
  z <- c(g, 0, 0)
  testthat::expect_true(pr_encoding_feasible(problem$model, z))
})

testthat::test_that("objective columns equal literal expected loss for every small public relation", {
  payload <- pr_test_payload(S = 4L, n = 3L, K = 2L)
  p <- postrank_pairwise(payload)
  weights <- stats::setNames(c(0.3, 0.7), p$criterion_ids)
  tau <- 0.4
  problem <- postrank_problem(p, weights, tau, 3L)
  labels <- pr_encoding_grid(1:3, 3L)
  for (row in seq_len(nrow(labels))) {
    g <- as.numeric(labels[row, ])
    z <- c(g, as.integer(g[problem$pair_map$i] < g[problem$pair_map$j]))
    literal <- numeric(4L)
    for (s in 1:4) {
      loss <- 0
      for (i in 1:2) for (j in (i + 1L):3L) {
        if (g[i] == g[j]) loss <- loss + tau else {
          high <- if (g[i] < g[j]) i else j
          low <- if (g[i] < g[j]) j else i
          for (k in 1:2) if (payload$joint_draws$tensor$values[s, high, k] <= payload$joint_draws$tensor$values[s, low, k])
            loss <- loss + weights[[k]]
        }
      }
      literal[[s]] <- loss / 3
    }
    from_model <- problem$objective_units$offset + problem$objective_units$scale * sum(problem$model$objective * z)
    testthat::expect_equal(from_model, mean(literal), tolerance = 1e-14)
  }
})

testthat::test_that("posterior-mean order is not imposed on feasible or optimal actions", {
  payload <- pr_test_payload(S = 2L, n = 2L, K = 1L)
  payload$input_kind <- "exact_finite_posterior"
  payload$joint_draws <- NULL
  state <- function(value) matrix(c(value, 0), 2L, 1L,
    dimnames = list(entity = payload$entity_ids, criterion = payload$criterion_ids))
  payload$finite_law <- list(denominator = 4L, value_representation = "safe_integer",
    states = list(list(state_id = "majority", mass_numerator = 3L, theta = state(1)),
      list(state_id = "rare-negative", mass_numerator = 1L, theta = state(-100))),
    law_definition = "Explicit synthetic 3/4 and 1/4 finite-law counterexample to mean-order restriction.",
    not_empirical_posterior_relabeling = TRUE)
  p <- postrank_pairwise(payload)
  problem <- postrank_problem(p, stats::setNames(1, p$criterion_ids), 0.4, 2L)
  testthat::expect_true(0.75 * 1 + 0.25 * -100 < 0) # Site 1 has the lower posterior mean.
  first_high <- c(1, 2, 1, 0)
  second_high <- c(2, 1, 0, 1)
  testthat::expect_true(pr_encoding_feasible(problem$model, first_high))
  testthat::expect_true(pr_encoding_feasible(problem$model, second_high))
  testthat::expect_lt(sum(problem$model$objective * first_high), sum(problem$model$objective * second_high))
  testthat::expect_lt(sum(problem$model$objective * first_high), 0) # Better than all-abstain.
})
