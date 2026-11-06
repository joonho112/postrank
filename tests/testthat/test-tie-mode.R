test_that("tie-aware evaluated risks match raw-state losses for every small action", {
  skip_if_not_installed("gmp")
  v <- array(c(3, 3, 1, 2, 2, 1, 0, 0, 1, 1, 1, 2, 0, 0, 0, 2, 2, 1), c(3L, 3L, 2L))
  mass <- c(2L, 3L, 5L)
  pw <- postrank_tie_pairwise(as_postrank_tie_draws(pr_tie_fixture(v, mass)))
  w <- c(need1 = .4, need2 = .6); tau <- .25
  for (g0 in pr_tie_all_actions(3L, 3L)) {
    g <- stats::setNames(g0, pw$entity_ids)
    oracle <- pr_tie_state_oracle(v, mass / sum(mass), g, w, tau)
    ev <- postrank_tie_evaluate(g, pw, w, tau)
    expect_equal(ev$weighted_risk, oracle$risk, tolerance = 1e-12)
    expect_equal(unname(ev$criterion_risk), oracle$criterion_risk, tolerance = 1e-12)
    expect_equal(unname(ev$E), oracle$E, tolerance = 1e-12)
    expect_equal(unname(ev$D_k), oracle$D_k, tolerance = 1e-12)
    expect_equal(unname(ev$T_k), oracle$T_k, tolerance = 1e-12)
    expect_equal(c(ev$D, ev$T, ev$N, ev$M), unname(c(oracle$D, oracle$T, oracle$N, oracle$M)), tolerance = 1e-12)
    expect_equal(ev$all_withhold_risk, oracle$baseline, tolerance = 1e-12)
    expect_equal(ev$all_withhold_risk + ev$weighted_raw_objective / ev$M, ev$weighted_risk, tolerance = 1e-12)
  }
})

test_that("no-tie reduction is exact per action and old golden identities remain intact", {
  old <- pr_test_payload(S = 5L, n = 3L, K = 2L)
  legacy <- postrank_pairwise(old, method = "reference"); golden <- legacy$pairwise_identity
  tied <- postrank_tie_pairwise(as_postrank_tie_draws(pr_tie_fixture(old$joint_draws$tensor$values)), method = "reference")
  expect_equal(tied$b, legacy$e, tolerance = 0)
  for (k in seq_len(2L)) {
    off <- row(tied$d[, , k]) != col(tied$d[, , k])
    expect_true(all(tied$d[, , k][off] == 1)); expect_true(all(tied$t[, , k][off] == 0))
  }
  w <- c(need1 = .3, need2 = .7)
  for (g0 in pr_tie_all_actions(3L, 3L)) {
    g <- stats::setNames(g0, legacy$entity_ids)
    a <- postrank_evaluate(g, legacy, w, .25); b <- postrank_tie_evaluate(g, tied, w, .25)
    expect_equal(b$weighted_risk, a$weighted_risk, tolerance = 1e-15)
    expect_equal(b$weighted_raw_objective, a$weighted_raw_objective, tolerance = 1e-15)
    expect_equal(b$N, a$N); expect_equal(unname(b$D), a$N)
  }
  expect_identical(postrank_pairwise(old, method = "reference")$pairwise_identity, golden)
  expect_false(identical(tied$pairwise_identity, legacy$pairwise_identity))
  expect_false(inherits(tied, "postrank_pairwise")); expect_false(inherits(tied, "postrank_coefficients"))
  expect_error(postrank_evaluate(stats::setNames(1:3, legacy$entity_ids), tied, w, .25))
  gi <- jsonlite::read_json(test_path("fixtures", "golden-identities.json"))
  expect_identical(postrank_pairwise(postrank_toy)$pairwise_identity, gi$postrank_toy$pairwise_identity)
  expect_identical(postrank_problem(postrank_pairwise(postrank_toy), c(need_A = .6, need_B = .4), .25, 3L)$problem_identity,
    gi$postrank_toy$problem_identity)
})

test_that("T01-T07 distinguish criterion equality, direction uncertainty and conflict", {
  skip_if_not_installed("gmp")
  cases <- list(
    T01 = list(v = pr_tie_pair_values(1L, 1:2), expected = c(.15, .85, .25)),
    T02 = list(v = pr_tie_pair_values(1L, integer(), tie_C = 1:10), expected = c(.05, .45, .125)),
    T03 = list(v = pr_tie_pair_values(integer(), integer(), tie_S = 1:10), expected = c(0, .5, .125)),
    T04 = list(v = pr_tie_pair_values(integer(), integer(), tie_S = 1:10, tie_C = 1:10), expected = c(0, 0, 0)),
    T05 = list(v = pr_tie_pair_values(1L, tie_S = 7:10), expected = c(.1, .5, .15)),
    T07 = list(v = pr_tie_pair_values(integer(), 1:10), expected = c(.5, .5, .25)))
  for (name in names(cases)) {
    z <- cases[[name]]; K <- dim(z$v)[3L]
    pw <- postrank_tie_pairwise(as_postrank_tie_draws(pr_tie_fixture(z$v, rep(1L, 10L))))
    w <- stats::setNames(rep(1 / K, K), pw$criterion_ids)
    costs <- vapply(list(c(1L, 2L), c(2L, 1L), c(1L, 1L)), function(g)
      postrank_tie_evaluate(stats::setNames(g, pw$entity_ids), pw, w, .25)$weighted_risk, numeric(1L))
    expect_equal(costs, z$expected, tolerance = 1e-12, info = name)
  }
  # T06 is an equal-weight close-valued sample, not a declared exact continuous law.
  v <- pr_tie_pair_values(1:49, S = 100L) * 1e-9
  pw <- postrank_tie_pairwise(as_postrank_tie_draws(pr_tie_fixture(v)))
  costs <- vapply(list(c(1L, 2L), c(2L, 1L), c(1L, 1L)), function(g)
    postrank_tie_evaluate(stats::setNames(g, pw$entity_ids), pw, c(need1 = 1), .25)$weighted_risk, numeric(1L))
  expect_equal(costs, c(.49, .51, .25), tolerance = 1e-12)
  expect_equal(pw$t[1, 2, 1], 0)
})

test_that("T08 precision review and T10 identification require explicit scientific declarations", {
  old <- pr_test_payload(S = 2L, n = 2L, K = 1L); old$joint_draws$tensor$values[] <- 0
  expect_error(as_postrank_draws(old), class = "postrank_input_error")
  expect_error(as_postrank_tie_draws(old), class = "postrank_input_error")
  x <- pr_tie_fixture(array(0, c(2L, 2L, 1L))); bad <- x; bad$identification$status <- "unresolved"
  expect_error(as_postrank_tie_draws(bad), class = "postrank_input_error")
  # Sampled equality does not create structural classes: singleton declarations
  # stay singletons even when both retained target coordinates happen to match.
  pw <- postrank_tie_pairwise(as_postrank_tie_draws(x))
  ev <- postrank_tie_evaluate(stats::setNames(1:2, pw$entity_ids), pw, c(need1 = 1), .25)
  expect_true(ev$guard_satisfied)
})

test_that("full active-profile guards retain entity multiplicity and respect zero weights", {
  skip_if_not_installed("gmp")
  v <- array(0, c(1L, 3L, 2L)); v[1, , 1] <- c(2, 2, 0); v[1, , 2] <- c(0, 1, 2)
  pw <- postrank_tie_pairwise(as_postrank_tie_draws(pr_tie_fixture(v, 1L)))
  g <- stats::setNames(c(1L, 2L, 3L), pw$entity_ids)
  a <- postrank_tie_evaluate(g, pw, c(need1 = 1, need2 = 0), .25)
  b <- postrank_tie_evaluate(g, pw, c(need1 = .5, need2 = .5), .25)
  expect_false(a$guard_satisfied); expect_true(b$guard_satisfied)
  expect_equal(a$M, 3); expect_equal(a$N, 3)
  p <- postrank_tie_problem(pw, c(need1 = 1, need2 = 0), .25, 3L)
  expect_length(p$index$labels, 3L); expect_length(p$index$pairs, 6L)
  p2 <- postrank_tie_problem(pw, c(need1 = .5, need2 = .5), .25, 3L)
  expect_false(identical(p$problem_identity, p2$problem_identity))
})

test_that("all equality gives zero risk and undefined distinct-opportunity denominators", {
  skip_if_not_installed("gmp")
  pw <- postrank_tie_pairwise(as_postrank_tie_draws(pr_tie_fixture(array(7, c(1L, 3L, 2L)), 1L)))
  ev <- postrank_tie_evaluate(stats::setNames(rep(1L, 3L), pw$entity_ids), pw, c(need1 = .5, need2 = .5), .25)
  expect_equal(unname(c(ev$all_withhold_risk, ev$weighted_risk, ev$D, ev$T, ev$N)), rep(0, 5))
  expect_true(is.na(ev$D_over_T)); expect_true(all(is.na(ev$E_over_D)))
  expect_true(all(is.na(ev$E_over_N))); expect_true(ev$guard_satisfied)
})

test_that("T09 and deferred capabilities fail without silently using legacy paths", {
  skip_if_not_installed("gmp")
  pw <- postrank_tie_pairwise(as_postrank_tie_draws(pr_tie_fixture(array(c(1, 0, 0, 0), c(1L, 2L, 2L)), 1L)))
  w <- c(need1 = .5, need2 = .5)
  expect_error(postrank_tie_problem(pw, w, .25, 2L, exact_G = 2L))
  expect_error(postrank_tie_problem(pw, w, .25, 2L, q = c(need1 = .2)))
  expect_error(postrank_tie_problem(pw, w, .25, 2L, objective = "minimax"))
  p <- postrank_tie_problem(pw, w, .25, 2L)
  expect_error(postrank_tie_solve(p, backend = "highs", strategy = "staged"))
  expect_error(postrank_problem(pw, w, .25, 2L)); expect_error(postrank_solve(p, backend = "highs"))
  expect_error(postrank_diagnose(pw))
})

test_that("T11 actual HiGHS minima match the exhaustive guarded raw-state oracle", {
  skip_if_not_installed("highs"); skip_if_not_installed("gmp")
  z <- pr_tie_t11(); pw <- postrank_tie_pairwise(as_postrank_tie_draws(pr_tie_fixture(z$values, z$masses))); fits <- list()
  for (tau in c(.1, .3)) {
    p <- postrank_tie_problem(pw, z$weights, tau, 2L)
    oracle <- pr_tie_oracle_optimum(z$values, z$masses / sum(z$masses), z$weights, tau, 2L)
    fit <- postrank_tie_solve(p, backend = "highs", control = list(time_limit = 15, threads = 1L, seed = 1L))
    expect_true(fit$incumbent_validated); expect_identical(fit$status$normalized, "optimal")
    expect_equal(fit$evaluation$primary_risk, oracle$value, tolerance = 1e-10)
    expect_true(fit$evaluation$guard_satisfied); expect_equal(unname(fit$grade[1]), unname(fit$grade[2]))
    expect_equal(p$M, 6); expect_equal(p$objective_units$offset, tau * 3.5 / 6, tolerance = 1e-12)
    expect_equal(fit$objective$risk_upper_bound, oracle$value, tolerance = 1e-10)
    expect_lte(fit$objective$risk_lower_bound, oracle$value + 1e-9)
    expect_lte(fit$objective$risk_absolute_gap, 1e-7)
    expect_equal(fit$objective$offset, p$objective_units$offset)
    expect_false(isTRUE(fit$objective$numerical_certification)); expect_false(inherits(fit, "postrank_fit"))
    fits[[length(fits) + 1L]] <- fit
  }
  expect_equal(vapply(fits, function(f) f$evaluation$N, numeric(1L)), c(4, 3))
  expect_equal(unname(vapply(fits, function(f) f$evaluation$D, numeric(1L))), c(2.5, 3), tolerance = 1e-12)
  expect_equal(unname(fits[[1]]$grade), c(2L, 2L, 1L, 1L))
  expect_equal(unname(fits[[2]]$grade), c(2L, 2L, 2L, 1L))
})

test_that("HiGHS handles a medium guarded problem with original-pair scaling", {
  skip_if_not_installed("highs"); skip_if_not_installed("gmp")
  n <- 24L; v <- array(0, c(1L, n, 2L)); v[1, , 1] <- rep(4:1, each = 6L); v[1, , 2] <- v[1, , 1] * 2
  pw <- postrank_tie_pairwise(as_postrank_tie_draws(pr_tie_fixture(v, 1L)))
  p <- postrank_tie_problem(pw, c(need1 = .5, need2 = .5), .25, 4L)
  fit <- postrank_tie_solve(p, backend = "highs", control = list(time_limit = 20, threads = 1L, seed = 2L))
  expect_true(fit$incumbent_validated); expect_equal(fit$evaluation$weighted_risk, 0, tolerance = 1e-10)
  expect_true(fit$evaluation$guard_satisfied); expect_equal(length(fit$grade), n)
  expect_equal(fit$evaluation$M, choose(n, 2)); expect_equal(fit$evaluation$N, 216)
  for (idx in split(seq_len(n), rep(1:4, each = 6L))) expect_equal(length(unique(fit$grade[idx])), 1L)
})

test_that("independent primal validation rejects split classes and inconsistent relations", {
  skip_if_not_installed("gmp")
  z <- pr_tie_t11(); pw <- postrank_tie_pairwise(as_postrank_tie_draws(pr_tie_fixture(z$values, z$masses)))
  p <- postrank_tie_problem(pw, z$weights, .25, 2L)
  primal <- function(g) {
    ans <- numeric(length(p$model$objective))
    ans[p$index$labels] <- g
    ans[p$index$pairs] <- as.numeric(g[p$index$pair_i] < g[p$index$pair_j])
    ans
  }
  good <- primal(c(2, 2, 1, 1)); ok <- validate_postrank_tie_solution(p, good)
  expect_true(ok$valid); expect_true(ok$evaluation$guard_satisfied)
  bad <- validate_postrank_tie_solution(p, primal(c(1, 2, 1, 1)))
  expect_false(bad$valid); expect_null(bad$grade); expect_null(bad$evaluation)
  expect_true("full_profile_guard_violation" %in% vapply(bad$issues, `[[`, character(1L), "code"))
  wrong <- good; wrong[p$index$pairs[1L]] <- 1 - wrong[p$index$pairs[1L]]
  expect_false(validate_postrank_tie_solution(p, wrong)$valid)
  fractional <- good; fractional[p$index$labels[1L]] <- 1.5
  expect_false(validate_postrank_tie_solution(p, fractional)$valid)
  expect_false(validate_postrank_tie_solution(p, NULL)$valid)
  broken <- good; broken[1L] <- NA_real_
  expect_false(validate_postrank_tie_solution(p, broken)$valid)
  expect_false(validate_postrank_tie_solution(p, good[-1L])$valid)
  changed <- p; changed$model$objective[1L] <- 1
  expect_error(validate_postrank_tie_solution(changed, good), class = "postrank_input_error")
})

test_that("withholding uses expected distinct mass and retains distinct error denominators", {
  skip_if_not_installed("gmp")
  v <- pr_tie_pair_values(1L, tie_S = 7:10)
  pw <- postrank_tie_pairwise(as_postrank_tie_draws(pr_tie_fixture(v, rep(1L, 10L))))
  hold <- postrank_tie_evaluate(stats::setNames(c(1L, 1L), pw$entity_ids), pw, c(need1 = 1), .25)
  order <- postrank_tie_evaluate(stats::setNames(c(1L, 2L), pw$entity_ids), pw, c(need1 = 1), .25)
  expect_equal(hold$weighted_risk, .15, tolerance = 1e-12)
  expect_equal(unname(order$E_over_N), .1, tolerance = 1e-12)
  expect_equal(unname(order$E_over_D), 1 / 6, tolerance = 1e-12)
  expect_equal(order$D, .6, tolerance = 1e-12)
  oracle <- pr_tie_state_oracle(v, rep(.1, 10L), c(1, 1), 1, .25)
  expect_gt(stats::var(oracle$state_loss), 0)
  expect_equal(mean(oracle$state_loss), hold$weighted_risk, tolerance = 1e-12)
})

test_that("Gmax1 gives the all-withhold baseline, including zero-risk identity classes", {
  skip_if_not_installed("gmp"); skip_if_not_installed("highs")
  z <- pr_tie_t11(); pw <- postrank_tie_pairwise(as_postrank_tie_draws(pr_tie_fixture(z$values, z$masses)))
  p <- postrank_tie_problem(pw, z$weights, .25, 1L)
  fit <- postrank_tie_solve(p, backend = "highs", control = list(time_limit = 10, threads = 1L))
  expect_true(fit$incumbent_validated); expect_equal(fit$evaluation$N, 0)
  expect_equal(fit$evaluation$weighted_risk, p$objective_units$offset, tolerance = 1e-12)
  equal_pw <- postrank_tie_pairwise(as_postrank_tie_draws(pr_tie_fixture(array(1, c(1L, 3L, 1L)), 1L)))
  p0 <- postrank_tie_problem(equal_pw, c(need1 = 1), .25, 3L)
  f0 <- postrank_tie_solve(p0, backend = "highs", control = list(time_limit = 10, threads = 1L))
  expect_true(f0$incumbent_validated); expect_equal(f0$evaluation$G, 1)
  expect_equal(f0$evaluation$weighted_risk, 0); expect_equal(f0$objective$risk_absolute_gap, 0, tolerance = 1e-12)
})

test_that("tie-aware controls reject staged requests and accept typed label-MIP controls", {
  skip_if_not_installed("gmp")
  pw <- postrank_tie_pairwise(as_postrank_tie_draws(pr_tie_fixture(array(c(2, 1), c(1L, 2L, 1L)), 1L)))
  p <- postrank_tie_problem(pw, c(need1 = 1), .25, 2L)
  expect_error(postrank_tie_solve(p, backend = "highs", control = list(strategy = "staged")), class = "postrank_input_error")
  expect_error(postrank_tie_solve(p, backend = "highs", control = list(engine = list(mip = "never"))), class = "postrank_input_error")
  skip_if_not_installed("highs")
  ctrl <- postrank_control(time_limit = 10, threads = 1L, strategy = "label_mip")
  fit <- postrank_tie_solve(p, backend = "highs", control = ctrl)
  expect_true(fit$incumbent_validated); expect_equal(fit$evaluation$primary_risk, 0, tolerance = 1e-12)
  expect_identical(fit$engine$strategy, "label_mip")
})

test_that("exact finite no-tie laws also reduce to the original loss for all actions", {
  skip_if_not_installed("gmp")
  old <- pr_test_exact(); values <- array(0, c(length(old$finite_law$states), length(old$entity_ids), length(old$criterion_ids)))
  for (s in seq_along(old$finite_law$states)) values[s, , ] <- old$finite_law$states[[s]]$theta
  masses <- vapply(old$finite_law$states, `[[`, numeric(1L), "mass_numerator")
  legacy <- postrank_pairwise(old)
  tied <- postrank_tie_pairwise(as_postrank_tie_draws(pr_tie_fixture(values, masses)))
  expect_equal(tied$b, legacy$e, tolerance = 0)
  w <- c(need1 = .5, need2 = .5)
  for (g0 in pr_tie_all_actions(3L, 3L)) {
    g <- stats::setNames(g0, old$entity_ids)
    a <- postrank_evaluate(g, legacy, w, .25); b <- postrank_tie_evaluate(g, tied, w, .25)
    expect_equal(b$weighted_risk, a$weighted_risk, tolerance = 1e-15)
    expect_equal(b$weighted_raw_objective, a$weighted_raw_objective, tolerance = 1e-15)
  }
})


test_that("a loose feasibility tolerance never validates absent positive labels", {
  skip_if_not_installed("gmp")
  z <- pr_tie_t11()
  pw <- postrank_tie_pairwise(as_postrank_tie_draws(pr_tie_fixture(z$values, z$masses)))
  p <- postrank_tie_problem(pw, z$weights, .1, 2L)
  bad <- numeric(length(p$model$objective))
  receipt <- validate_postrank_tie_solution(p, bad, tolerances = list(feasibility = 2))
  expect_false(receipt$valid)
  expect_null(receipt$grade); expect_null(receipt$evaluation)
  expect_true("invalid_label" %in% vapply(receipt$issues, `[[`, character(1L), "code"))
})
