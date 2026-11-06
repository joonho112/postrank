# 014 repair Phase 3 (Step 3.3): commonality cost and tau/q frontier.
testthat::test_that("commonality costs equal enumerated criterion minima", {
  testthat::skip_if_not_installed("highs")
  x <- pr_random_payload(91L, 30L, 5L, 3L, conflict = FALSE); pw <- postrank_pairwise(x)
  e <- pr_oracle_e_from_draws(x$joint_draws$tensor$values); w <- c(need1 = .5, need2 = .3, need3 = .2)
  fit <- postrank_solve(postrank_problem(pw, w, .25, 3L), "highs", list(time_limit = 20))
  cc <- postrank_commonality_cost(fit, "highs", list(time_limit = 20))
  for (k in 1:3) {
    unit <- as.numeric(1:3 == k)
    own <- pr_oracle_solve(e, unit, .25, 3L)$optimum
    row <- cc$table[k, ]
    testthat::expect_identical(row$own_status, "optimal")
    testthat::expect_equal(row$own_best_risk, own, tolerance = 1e-9)
    testthat::expect_equal(row$common_grade_risk, unname(fit$evaluation$criterion_risk[k]), tolerance = 1e-12)
    testthat::expect_equal(row$cost_lower, row$common_grade_risk - own, tolerance = 1e-9)
    testthat::expect_equal(row$cost_upper, row$cost_lower, tolerance = 1e-8)
    testthat::expect_true(row$cost_lower >= -1e-9)
  }
})

testthat::test_that("the frontier discloses no fewer pairs as tau rises and supports a q grid", {
  testthat::skip_if_not_installed("highs")
  x <- pr_random_payload(92L, 40L, 7L, 2L, conflict = TRUE); pw <- postrank_pairwise(x)
  taus <- c(.0812345, .1623457, .2434567, .3245679, .4056781)
  fr <- postrank_frontier(pw, c(need1 = .6, need2 = .4), taus, 4L, backend = "highs",
    control = list(time_limit = 20, absolute_risk_gap = 1e-12))
  testthat::expect_identical(nrow(fr$table), 5L); testthat::expect_true(all(fr$table$status == "optimal"))
  testthat::expect_true(all(diff(fr$table$N) >= 0))
  testthat::expect_true(all(c("E_over_N_need1", "E_over_N_need2", "risk_need1", "risk_need2") %in% names(fr$table)))
  fq <- postrank_frontier(pw, c(need1 = .6, need2 = .4), .3, 4L, q_criterion = "need2", q_grid = c(.05, .1, .2),
    backend = "highs", control = list(time_limit = 20))
  testthat::expect_identical(fq$table$q_value, c(.05, .1, .2))
  ok <- !is.na(fq$table$E_over_N_need2)
  testthat::expect_true(all(fq$table$E_over_N_need2[ok] <= fq$table$q_value[ok] + 1e-9))
  testthat::expect_true(all(diff(fq$table$weighted_risk) <= 1e-9))
})

testthat::test_that("commonality cost keeps exact_G and, on request, the protection rows", {
  testthat::skip_if_not_installed("highs")
  x <- pr_random_payload(93L, 30L, 5L, 2L, conflict = TRUE); pw <- postrank_pairwise(x)
  e <- pr_oracle_e_from_draws(x$joint_draws$tensor$values); w <- c(need1 = .5, need2 = .5)
  fit <- postrank_solve(postrank_problem(pw, w, .25, 3L, exact_G = 3L), "highs", list(time_limit = 20))
  cc <- postrank_commonality_cost(fit, "highs", list(time_limit = 20))
  for (k in 1:2) testthat::expect_equal(cc$table$own_best_risk[k], pr_oracle_solve(e, as.numeric(1:2 == k), .25, 3L, exact_G = 3L)$optimum,
    tolerance = 1e-9)
  qfit <- postrank_solve(postrank_problem(pw, w, .25, 3L, q = c(need1 = .05)), "highs", list(time_limit = 20))
  keep <- postrank_commonality_cost(qfit, "highs", list(time_limit = 20), protection = "keep")
  drop <- postrank_commonality_cost(qfit, "highs", list(time_limit = 20), protection = "drop")
  q_index <- list(`1` = .05)
  for (k in 1:2) {
    testthat::expect_equal(keep$table$own_best_risk[k], pr_oracle_solve(e, as.numeric(1:2 == k), .25, 3L, q = q_index)$optimum, tolerance = 1e-9)
    testthat::expect_true(keep$table$own_best_risk[k] >= drop$table$own_best_risk[k] - 1e-12)
  }
  testthat::expect_true(all(keep$table$cost_lower >= 0))
})

testthat::test_that("a binding q grid trades disclosures for criterion error", {
  testthat::skip_if_not_installed("highs")
  x <- pr_random_payload(94L, 40L, 7L, 2L); pw <- postrank_pairwise(x)
  free <- postrank_frontier(pw, c(need1 = .5, need2 = .5), .3, 4L, backend = "highs", control = list(time_limit = 20))
  q0 <- free$table$E_over_N_need2
  testthat::skip_if(!is.finite(q0) || q0 <= 0, "the unconstrained grade discloses nothing on this draw")
  grid <- c(q0 / 4, q0 / 2, q0)
  fq <- postrank_frontier(pw, c(need1 = .5, need2 = .5), .3, 4L, q_criterion = "need2", q_grid = grid,
    backend = "highs", control = list(time_limit = 20))
  ok <- !is.na(fq$table$E_over_N_need2)
  testthat::expect_true(all(fq$table$E_over_N_need2[ok] <= fq$table$q_value[ok] + 1e-9))
  testthat::expect_true(all(diff(fq$table$weighted_risk) <= 1e-9))
  testthat::expect_true(fq$table$weighted_risk[1] > free$table$weighted_risk - 1e-12)
  testthat::expect_error(postrank_frontier(pw, c(need1 = .5, need2 = .5), c(.3, .9), 4L, backend = "highs"), class = "postrank_input_error")
})
