# 014 repair (VA-1): R CMD check exercises the full model -> HiGHS -> normalizer
# -> validator chain and compares each released grade with an independent
# brute-force oracle (helper-oracle-enumeration.R).
# pr_random_payload() is defined in helper-oracle-enumeration.R.
testthat::test_that("HiGHS solutions are exact argmin members across modes and strategies (n <= 6)", {
  testthat::skip_if_not_installed("highs")
  cases <- list(list(seed = 11L, S = 30L, n = 5L, K = 2L, conflict = FALSE),
                list(seed = 12L, S = 30L, n = 6L, K = 2L, conflict = TRUE),
                list(seed = 13L, S = 25L, n = 5L, K = 3L, conflict = FALSE))
  control <- list(time_limit = 20, threads = 1L, seed = 1L)
  for (case in cases) {
    x <- do.call(pr_random_payload, case); pw <- postrank_pairwise(x)
    e <- pr_oracle_e_from_draws(x$joint_draws$tensor$values)
    testthat::expect_equal(unname(pw$e), e)
    K <- case$K; w <- rep(1 / K, K); names(w) <- pw$criterion_ids
    settings <- list(
      list(G_max = 3L), list(G_max = case$n),
      list(G_max = 3L, q = stats::setNames(.2, pw$criterion_ids[2])),
      list(G_max = 3L, exact_G = 3L),
      list(G_max = 3L, objective = "minimax"))
    for (s in settings) for (strategy in c("staged", "label_mip")) {
      objective <- if (is.null(s$objective)) "weighted" else s$objective
      problem <- postrank_problem(pw, w, .25, s$G_max, objective = objective, q = s$q, exact_G = s$exact_G)
      fit <- postrank_solve(problem, backend = "highs", control = control, strategy = strategy)
      q_index <- if (is.null(s$q)) NULL else stats::setNames(list(s$q[[1L]]), as.character(match(names(s$q), pw$criterion_ids)))
      oracle <- pr_oracle_solve(e, w, .25, s$G_max, objective, q_index, s$exact_G)
      label <- paste("case", case$seed, strategy, objective, paste(names(s), unlist(s), collapse = " "))
      testthat::expect_identical(fit$engine$strategy, strategy, info = label)
      testthat::expect_true(fit$incumbent_validated, info = label)
      testthat::expect_identical(fit$status$normalized, "optimal", info = label)
      testthat::expect_equal(fit$objective$primary_action_risk, oracle$optimum, tolerance = 1e-9, info = label)
      testthat::expect_true(is.finite(fit$objective$risk_absolute_gap) && fit$objective$risk_absolute_gap <= 1e-6, info = label)
      testthat::expect_true(fit$objective$risk_lower_bound <= oracle$optimum + 1e-9, info = label)
    }
  }
})
