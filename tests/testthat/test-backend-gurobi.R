# Tier C (T-rel-08, Chapter 15): the default licensed Gurobi backend on the oracle cases.
# Skipped unless POSTRANK_TEST_GUROBI=true; a skip is not default-backend acceptance.
pr_gurobi_sandwich <- function(fit, optimum, delta = 1e-9) {
  U <- fit$objective$risk_upper_bound; L <- fit$objective$risk_lower_bound
  expect_true(isTRUE(fit$incumbent_validated))
  expect_true(is.finite(L) && is.finite(U))
  expect_lte(L, optimum + delta)
  expect_lte(optimum, U + delta)
  expect_lte(U - optimum, U - L + 2 * delta)
}

test_that("the default backend resolves to Gurobi and solves the oracle cases", {
  pr_skip_unless_gurobi()
  withr::local_options(postrank.backend = NULL)
  for (seed in c(11L, 12L, 13L)) {
    x <- pr_random_payload(seed, 60L, 5L, 2L, conflict = seed == 13L)
    pw <- postrank_pairwise(as_postrank_draws(x))
    oracle <- pr_oracle_solve(pr_oracle_e_from_draws(x$joint_draws$tensor$values), c(.6, .4), .25, 3L)
    fit <- postrank_solve(postrank_problem(pw, c(need1 = .6, need2 = .4), .25, 3L), control = postrank_control(time_limit = 30))
    expect_identical(fit$backend$name, "gurobi")
    expect_identical(fit$backend$resolution, "default")
    expect_identical(fit$status$normalized, "optimal")
    pr_gurobi_sandwich(fit, oracle$optimum)
  }
})

test_that("Gurobi's label MIP, minimax and the one-call analysis agree with the oracle", {
  pr_skip_unless_gurobi()
  x <- pr_random_payload(21L, 60L, 5L, 2L)
  pw <- postrank_pairwise(as_postrank_draws(x)); e <- pr_oracle_e_from_draws(x$joint_draws$tensor$values)
  w <- c(need1 = .5, need2 = .5)
  lab <- postrank_solve(postrank_problem(pw, w, .3, 3L), backend = "gurobi", strategy = "label_mip",
    control = postrank_control(time_limit = 30))
  pr_gurobi_sandwich(lab, pr_oracle_solve(e, c(.5, .5), .3, 3L)$optimum)
  mm <- postrank_solve(postrank_problem(pw, w, .3, 3L, objective = "minimax"), backend = "gurobi",
    control = postrank_control(time_limit = 30))
  expect_true(isTRUE(mm$incumbent_validated))
  expect_lte(abs(mm$objective$risk_upper_bound - pr_oracle_solve(e, c(.5, .5), .3, 3L, objective = "minimax")$optimum),
    mm$objective$risk_absolute_gap + 1e-8)
  a <- postrank(postrank_toy, weights = c(need_A = .6, need_B = .4), tau = .25, G_max = 3L, backend = "gurobi")
  ref <- pr_cached("toy_analysis")
  expect_identical(a$fit$backend$name, "gurobi")
  expect_lte(abs(get_risk(a)$risk - get_risk(ref)$risk), get_risk(a)$gap + get_risk(ref)$gap + 1e-8)
})
