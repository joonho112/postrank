# 014 repair Phase 3 (Step 3.1): minimax as a secondary mode with a weighted
# second stage, and the degeneracy diagnostic.
pr_r03_payload <- function() {
  # 014 R03(a): criterion 1 puts entity 1 on top and reverses 2-3-4 in three of
  # four draws; criterion 2 is the clear order 1 > 2 > 3 > 4.
  x <- pr_test_payload(S = 4L, n = 4L, K = 2L); v <- x$joint_draws$tensor$values
  v[1, , 1] <- c(10, 1, 2, 3); for (s in 2:4) v[s, , 1] <- c(10, 3, 2, 1)
  for (s in 1:4) v[s, , 2] <- c(10, 3, 2, 1) + s / 100
  x$joint_draws$tensor$values <- v; x
}

pr_lexicographic_oracle <- function(e, w, tau, G, q = NULL, exact_G = NULL) {
  n <- dim(e)[1L]; K <- dim(e)[3L]; M <- choose(n, 2)
  acts <- pr_oracle_ordered_partitions(n, if (is.null(exact_G)) G else exact_G)
  tab <- t(vapply(acts, function(g) {
    if (!is.null(exact_G) && max(g) != exact_G) return(rep(NA_real_, K + 1L))
    x <- outer(g, g, `<`); N <- sum(x); E <- vapply(seq_len(K), function(k) sum(e[, , k][x]), numeric(1L))
    if (!is.null(q)) for (k in names(q)) if (E[as.integer(k)] > q[[k]] * N + 1e-12) return(rep(NA_real_, K + 1L))
    Rk <- (E + tau * (M - N)) / M
    c(Rk, sum(w * Rk))
  }, numeric(K + 1L)))
  ok <- stats::complete.cases(tab); mm <- apply(tab[, seq_len(K), drop = FALSE], 1L, max)
  t_star <- min(mm[ok]); arg <- ok & mm <= t_star + 1e-12
  list(t_star = t_star, weighted = min(tab[arg, K + 1L]), table = tab, minimax = mm, ok = ok)
}

testthat::test_that("the weighted second stage removes the Pareto-dominated minimax optimum of 014 R03(a)", {
  testthat::skip_if_not_installed("highs")
  pw <- postrank_pairwise(pr_r03_payload()); w <- c(need1 = .5, need2 = .5)
  e <- unname(pw$e); oracle <- pr_lexicographic_oracle(e, w, .25, 4L)
  testthat::expect_equal(oracle$t_star, .125)
  for (strategy in c("staged", "label_mip")) {
    fit <- postrank_solve(postrank_problem(pw, w, .25, 4L, objective = "minimax"), "highs",
      list(time_limit = 20, seed = 1L), strategy = strategy)
    testthat::expect_identical(fit$status$normalized, "optimal", info = strategy)
    testthat::expect_equal(fit$objective$primary_action_risk, .125, tolerance = 1e-12, info = strategy)
    testthat::expect_equal(fit$objective$weighted_auxiliary_risk, oracle$weighted, tolerance = 1e-12, info = strategy)
    testthat::expect_equal(unname(fit$evaluation$criterion_risk), c(.125, 0), tolerance = 1e-12, info = strategy)
    testthat::expect_true(fit$minimax_refine$applied, info = strategy)
    Rk <- unname(fit$evaluation$criterion_risk)
    dominated <- any(oracle$ok & oracle$table[, 1] <= Rk[1] + 1e-12 & oracle$table[, 2] <= Rk[2] + 1e-12 &
      (oracle$table[, 1] < Rk[1] - 1e-12 | oracle$table[, 2] < Rk[2] - 1e-12))
    testthat::expect_false(dominated, info = strategy)
    # Stage 1 gets three quarters of the limit; the record keeps both budgets
    # and fit$backend$options holds stage 1's.
    tl <- fit$minimax_refine$time_limits
    testthat::expect_equal(c(tl$total, tl$stage1), c(20, 15), info = strategy)
    testthat::expect_true(tl$stage2 >= 1 && tl$stage2 <= 20, info = strategy)
    testthat::expect_equal(fit$backend$options$time_limit, 15, info = strategy)
  }
  none <- postrank_solve(postrank_problem(pw, w, .25, 4L, objective = "minimax", minimax_refine = "none"), "highs",
    list(time_limit = 20, seed = 1L))
  testthat::expect_identical(none$minimax_refine, list(mode = "none", applied = FALSE))
  testthat::expect_equal(none$backend$options$time_limit, 20)
  testthat::expect_equal(none$objective$primary_action_risk, .125, tolerance = 1e-12)
})

testthat::test_that("the second stage equals the enumerated lexicographic optimum across modes", {
  testthat::skip_if_not_installed("highs")
  for (case in list(list(seed = 71L, S = 30L, n = 5L, K = 2L, conflict = TRUE),
                    list(seed = 72L, S = 30L, n = 5L, K = 3L, conflict = FALSE))) {
    x <- do.call(pr_random_payload, case); pw <- postrank_pairwise(x)
    e <- pr_oracle_e_from_draws(x$joint_draws$tensor$values)
    w <- seq_len(case$K) / sum(seq_len(case$K)); names(w) <- pw$criterion_ids
    for (s in list(list(G = 3L), list(G = 3L, exact_G = 3L), list(G = 4L, q = stats::setNames(.2, pw$criterion_ids[1])))) {
      q_index <- if (is.null(s$q)) NULL else stats::setNames(list(s$q[[1L]]), "1")
      oracle <- pr_lexicographic_oracle(e, w, .2, s$G, q_index, s$exact_G)
      problem <- postrank_problem(pw, w, .2, s$G, objective = "minimax", q = s$q, exact_G = s$exact_G)
      for (strategy in c("staged", "label_mip")) {
        fit <- postrank_solve(problem, "highs", list(time_limit = 30, seed = 1L), strategy = strategy)
        label <- paste("case", case$seed, strategy, paste(names(s), unlist(s), collapse = " "))
        testthat::expect_identical(fit$status$normalized, "optimal", info = label)
        testthat::expect_equal(fit$objective$primary_action_risk, oracle$t_star, tolerance = 1e-9, info = label)
        testthat::expect_equal(fit$objective$weighted_auxiliary_risk, oracle$weighted, tolerance = 1e-9, info = label)
        testthat::expect_true(fit$objective$weighted_auxiliary_risk <= fit$minimax_refine$stage1$weighted_risk + 1e-12, info = label)
        testthat::expect_true(fit$minimax_refine$lexicographic_certified, info = label)
      }
    }
  }
})

testthat::test_that("degenerate minimax criteria are diagnosed and reported", {
  testthat::skip_if_not_installed("highs")
  pw <- postrank_pairwise(pr_test_payload())
  problem <- postrank_problem(pw, c(need1 = .5, need2 = .5), .25, 3L, objective = "minimax")
  testthat::expect_identical(problem$minimax_diagnostics$degenerate_criteria, c("need1", "need2"))
  fit <- postrank_solve(problem, "highs", list(time_limit = 20))
  testthat::expect_equal(fit$objective$primary_action_risk, .25)
  testthat::expect_match(fit$warnings, "Minimax criterion need1, need2 is degenerate", all = FALSE, fixed = TRUE)
  testthat::expect_match(postrank_report(fit)$warnings, "all-tie attains it", all = FALSE)
  exact <- postrank_problem(pw, c(need1 = .5, need2 = .5), .25, 3L, objective = "minimax", exact_G = 2L)
  testthat::expect_match(.pr_minimax_degeneracy_warning(exact), "can exceed tau", fixed = TRUE)
  weighted <- postrank_problem(pw, c(need1 = .5, need2 = .5), .25, 3L)
  testthat::expect_null(weighted$minimax_diagnostics); testthat::expect_null(weighted$settings$minimax_refine)
  pw2 <- postrank_pairwise(pr_r03_payload())
  testthat::expect_identical(postrank_problem(pw2, c(need1 = .5, need2 = .5), .25, 4L, objective = "minimax")$minimax_diagnostics$degenerate_criteria, character())
})

testthat::test_that("legacy minimax problems without the refine setting keep the single-stage behaviour", {
  testthat::skip_if_not_installed("highs")
  pw <- postrank_pairwise(pr_r03_payload())
  legacy <- postrank_problem(pw, c(need1 = .5, need2 = .5), .25, 4L, objective = "minimax")
  legacy$settings$minimax_refine <- NULL; legacy$minimax_diagnostics <- NULL
  legacy$problem_identity <- NULL; legacy$problem_identity <- .pr_identity(legacy)
  fit <- postrank_solve(legacy, "highs", list(time_limit = 20))
  testthat::expect_identical(fit$minimax_refine$mode, "none_legacy_problem")
  testthat::expect_equal(fit$objective$primary_action_risk, .125, tolerance = 1e-12)
})

testthat::test_that("the second stage matters when the minimax argmin is large (tie-heavy lattice)", {
  testthat::skip_if_not_installed("highs")
  exercised <- FALSE
  for (seed in 201:206) {
    set.seed(seed); x <- pr_test_payload(S = 4L, n = 5L, K = 2L)
    x$joint_draws$tensor$values[] <- stats::rnorm(4 * 5 * 2)
    pw <- postrank_pairwise(x); e <- pr_oracle_e_from_draws(x$joint_draws$tensor$values)
    w <- c(need1 = .3, need2 = .7); oracle <- pr_lexicographic_oracle(e, w, .25, 3L)
    arg <- oracle$ok & oracle$minimax <= oracle$t_star + 1e-12
    if (max(oracle$table[arg, 3]) > oracle$weighted + 1e-9) exercised <- TRUE
    for (strategy in c("staged", "label_mip")) {
      fit <- postrank_solve(postrank_problem(pw, w, .25, 3L, objective = "minimax"), "highs", list(time_limit = 30, seed = 1L),
        strategy = strategy)
      label <- paste("seed", seed, strategy)
      testthat::expect_equal(fit$objective$primary_action_risk, oracle$t_star, tolerance = 1e-12, info = label)
      testthat::expect_equal(fit$objective$weighted_auxiliary_risk, oracle$weighted, tolerance = 1e-12, info = label)
    }
  }
  testthat::expect_true(exercised)
})

testthat::test_that("a starved first stage still leaves the second stage at least one second", {
  testthat::skip_if_not_installed("highs")
  x <- pr_random_payload(74L, 30L, 12L, 3L); pw <- postrank_pairwise(x)
  w <- c(need1 = .4, need2 = .3, need3 = .3)
  fit <- postrank_solve(postrank_problem(pw, w, .25, 4L, objective = "minimax", exact_G = 4L), "highs", list(time_limit = 1e-3))
  testthat::expect_true(fit$minimax_refine$applied)
  testthat::expect_false(fit$minimax_refine$lexicographic_certified)
  testthat::expect_true(fit$incumbent_validated)
  testthat::expect_true(fit$objective$weighted_auxiliary_risk <= fit$minimax_refine$stage1$weighted_risk + 1e-12)
})

testthat::test_that("a zero weight does not release a Pareto-dominated tie", {
  testthat::skip_if_not_installed("highs")
  x <- pr_test_payload(S = 4L, n = 2L, K = 2L); v <- x$joint_draws$tensor$values
  v[, , 1] <- cbind(c(1, 3, 3, 3), c(2, 2, 2, 2))   # criterion 1: P(theta_1 <= theta_2) = .25 = tau
  v[, , 2] <- cbind(c(5, 5, 5, 5), c(1, 2, 3, 4))   # criterion 2: entity 1 always above entity 2
  x$joint_draws$tensor$values <- v; pw <- postrank_pairwise(x)
  problem <- postrank_problem(pw, c(need1 = 1, need2 = 0), .25, 2L, objective = "minimax")
  for (strategy in c("staged", "label_mip")) {
    fit <- postrank_solve(problem, "highs", list(time_limit = 20), strategy = strategy)
    testthat::expect_false(fit$minimax_refine$stage2_weights_perturbed, info = strategy)
    testthat::expect_true(fit$minimax_refine$pareto_certified, info = strategy)
    testthat::expect_equal(unname(fit$evaluation$criterion_risk), c(.25, 0), info = strategy)
  }
})

testthat::test_that("legacy minimax fits keep working with diagnostics and stability", {
  testthat::skip_if_not_installed("highs")
  x <- pr_test_payload(S = 8L, n = 4L, K = 2L, regime = "mcmc"); x$joint_draws$tensor$values[] <- {set.seed(75); stats::rnorm(64)}
  d <- as_postrank_draws(x); pw <- postrank_pairwise(d); w <- c(need1 = .5, need2 = .5)
  legacy <- postrank_problem(pw, w, .25, 3L, objective = "minimax")
  legacy$settings$minimax_refine <- NULL; legacy$minimax_diagnostics <- NULL
  legacy$problem_identity <- NULL; legacy$problem_identity <- .pr_identity(legacy)
  fit <- postrank_solve(legacy, "highs", list(time_limit = 10, threads = 1L))
  testthat::expect_s3_class(postrank_diagnose(d, fit = fit), "postrank_diagnostics")
  testthat::expect_s3_class(postrank_diagnose(d, fit = fit, settings = list(weights = w, tau = .25, G_max = 3L, objective = "minimax")),
    "postrank_diagnostics")
  stab <- postrank_diagnose(d, fit = fit, stability = list(backend = "highs", control = list(threads = 1L, time_limit = 5)))
  testthat::expect_identical(stab$stability$status, "completed")
  cf <- postrank_crossfit(d, fit = fit, backend = "highs", control = list(time_limit = 5))
  testthat::expect_identical(cf$settings$minimax_refine, "none")
})

# AUD-01: literal six-state counterexample. Its selected minimax criterion is
# constant, while the small positive ORIGINAL weight must still be optimized.
pr_aud01_payload <- function() {
  x <- pr_test_payload(S = 6L, n = 5L, K = 3L)
  x$joint_draws$tensor$values[] <- c(1,1,5,5,5,1,5,5,1,1,1,5,3,2,2,3,4,4,4,4,4,2,2,2,2,3,3,4,3,3,
    4,4,3,3,3,4,5,5,5,5,5,5,3,1,4,4,4,1,2,3,2,2,1,3,1,2,1,1,2,2,
    2,1,1,2,2,4,3,2,2,3,1,3,5,4,5,5,5,1,1,5,3,4,4,5,4,3,4,1,3,2)
  x
}

# This oracle enumerates grades and computes risk from the draw tensor directly;
# it does not use package model rows, cost helpers or staged-engine candidates.
pr_aud01_oracle <- function(x, weights, tau = .5) {
  v <- x$joint_draws$tensor$values; n <- dim(v)[2L]; K <- dim(v)[3L]; M <- choose(n, 2)
  actions <- pr_oracle_ordered_partitions(n, n)
  table <- t(vapply(actions, function(g) {
    ahead <- which(outer(g, g, `<`), arr.ind = TRUE)
    E <- vapply(seq_len(K), function(k) if (!nrow(ahead)) 0 else
      sum(vapply(seq_len(nrow(ahead)), function(h) mean(v[, ahead[h, 1L], k] <= v[, ahead[h, 2L], k]), numeric(1L))), numeric(1L))
    (E + tau * (M - nrow(ahead))) / M
  }, numeric(K)))
  # Center before combining: no constant tau can hide the 1e-9 contribution.
  secondary <- as.vector((table - tau) %*% weights)
  first <- table[, 1L] <= min(table[, 1L]) + 1e-14
  second_min <- min(secondary[first]); second <- first & abs(secondary - second_min) <= 1e-22
  list(actions = actions, risk = table, primary = min(table[, 1L]), secondary = secondary,
    secondary_min = second_min, tertiary_min = min(rowMeans(table[second, , drop = FALSE])))
}

testthat::test_that("AUD-01 preserves original zero and tiny positive weights before Pareto tie-breaking", {
  testthat::skip_if_not_installed("highs")
  x <- pr_aud01_payload(); pw <- postrank_pairwise(x)
  w <- c(need1 = 1 - 1e-9, need2 = 0, need3 = 1e-9)
  oracle <- pr_aud01_oracle(x, w)
  testthat::expect_equal(oracle$primary, .5)
  testthat::expect_equal(oracle$secondary_min, -2.5e-10, tolerance = 1e-22)
  p <- postrank_problem(pw, w, .5, 5L, objective = "minimax", minimax_criteria = "need1")
  for (strategy in c("staged", "label_mip")) for (tight in c(FALSE, TRUE)) {
    ctrl <- list(time_limit = 10, seed = 1L)
    if (tight) ctrl <- c(ctrl, list(absolute_risk_gap = 1e-12,
      tolerances = list(feasibility = 1e-10, integrality = 1e-10, objective = 1e-12)))
    f <- postrank_solve(p, "highs", ctrl, strategy)
    r <- unname(f$evaluation$criterion_risk); label <- paste(strategy, "tight", tight)
    secondary <- sum(w * (r - .5))
    dominates <- apply(oracle$risk, 1L, function(z) all(z <= r + 1e-14) && any(z < r - 1e-14))
    testthat::expect_equal(f$objective$primary_action_risk, oracle$primary, tolerance = 1e-14, info = label)
    testthat::expect_equal(secondary, oracle$secondary_min, tolerance = 1e-22, info = label)
    testthat::expect_equal(mean(r), oracle$tertiary_min, tolerance = 1e-14, info = label)
    testthat::expect_false(any(dominates), info = label)
    testthat::expect_true(f$minimax_refine$lexicographic_certified, info = label)
    testthat::expect_true(f$minimax_refine$pareto_certified, info = label)
    testthat::expect_false(f$minimax_refine$stage2_weights_perturbed, info = label)
    testthat::expect_identical(f$minimax_refine$released_relation_identity, f$solution_identity$relation_identity, info = label)
    testthat::expect_true(f$minimax_refine$stage2_optimization$coefficient_magnitude < 1e-9, info = label)
    testthat::expect_true(f$minimax_refine$stage2_optimization$scaled_raw_gap <=
      f$minimax_refine$stage2_optimization$scaled_raw_gap_target + 1e-12, info = label)
  }
})

testthat::test_that("AUD-01 strictly positive tiny weights are preserved without a tertiary stage", {
  testthat::skip_if_not_installed("highs")
  x <- pr_aud01_payload(); pw <- postrank_pairwise(x)
  w <- c(need1 = 1 - 2e-9, need2 = 1e-9, need3 = 1e-9)
  oracle <- pr_aud01_oracle(x, w)
  for (strategy in c("staged", "label_mip")) {
    f <- postrank_solve(postrank_problem(pw, w, .5, 5L, objective = "minimax", minimax_criteria = "need1"),
      "highs", list(time_limit = 10), strategy)
    r <- unname(f$evaluation$criterion_risk)
    testthat::expect_equal(sum(w * (r - .5)), oracle$secondary_min, tolerance = 1e-22, info = strategy)
    testthat::expect_true(f$minimax_refine$lexicographic_certified, info = strategy)
    testthat::expect_true(f$minimax_refine$pareto_certified, info = strategy)
    testthat::expect_null(f$minimax_refine$stage3, info = strategy)
  }
})

testthat::test_that("a heuristic-only refinement cannot certify the released minimax action", {
  testthat::skip_if_not_installed("highs")
  pw <- postrank_pairwise(pr_aud01_payload()); w <- c(need1 = 1 - 1e-9, need2 = 0, need3 = 1e-9)
  f <- postrank_solve(postrank_problem(pw, w, .5, 5L, objective = "minimax", minimax_criteria = "need1"),
    "highs", list(time_limit = 2, engine = list(mip = "never", max_cut_rounds = 0L)))
  testthat::expect_true(f$incumbent_validated)
  testthat::expect_false(f$minimax_refine$lexicographic_certified)
  testthat::expect_false(f$minimax_refine$pareto_certified)
  testthat::expect_true(f$objective$weighted_auxiliary_risk <= f$minimax_refine$stage1$weighted_risk)
  testthat::expect_match(f$warnings, "Minimax refinement was not certified", all = FALSE)
  testthat::expect_identical(f$minimax_refine$released_relation_identity, f$solution_identity$relation_identity)
})

testthat::test_that("primary minimax caps cannot be relaxed by native feasibility tolerances", {
  testthat::skip_if_not_installed("highs")
  x <- pr_test_payload(S = 2L, n = 2L, K = 2L)
  x$input_kind <- "exact_finite_posterior"; x$joint_draws <- NULL
  a <- matrix(c(1, 2, 2, 1), 2, 2, dimnames = list(entity = x$entity_ids, criterion = x$criterion_ids))
  b <- matrix(c(2, 1, 2, 1), 2, 2, dimnames = dimnames(a))
  x$finite_law <- list(denominator = 100000000L, value_representation = "safe_integer",
    states = list(list(state_id = "a", mass_numerator = 25000001L, theta = a),
      list(state_id = "b", mass_numerator = 74999999L, theta = b)),
    law_definition = "Exact two-state regression law.", not_empirical_posterior_relabeling = TRUE)
  pw <- postrank_pairwise(x); p <- postrank_problem(pw, c(need1 = .5, need2 = .5), .25, 2L, objective = "minimax")
  for (strategy in c("staged", "label_mip")) {
    f <- postrank_solve(p, "highs", list(time_limit = 5, absolute_risk_gap = 1e-12), strategy)
    testthat::expect_true(f$incumbent_validated, info = strategy)
    testthat::expect_equal(f$objective$primary_action_risk, .25, tolerance = 1e-14, info = strategy)
    # The native label solve can return the feasible all-tie optimum; the
    # staged heuristic may instead propose the near-boundary disclosure. Only
    # the latter must be rejected, irrespective of its native optimal status.
    if (identical(f$minimax_refine$reason, "stage2_action_violates_primary_cap")) {
      testthat::expect_false(f$minimax_refine$lexicographic_certified, info = strategy)
      testthat::expect_false(f$minimax_refine$pareto_certified, info = strategy)
    } else {
      testthat::expect_true(f$minimax_refine$certification$primary, info = strategy)
      testthat::expect_true(f$objective$risk_absolute_gap <= 1e-12, info = strategy)
    }
  }
})

# Rebind only within this R process, restoring even after a test failure. This
# works for both directly sourced functions and the installed package namespace.
pr_minimax_with_mock <- function(name, replacement, code) {
  env <- environment(.pr_minimax_refine); old <- get(name, envir = env, inherits = FALSE)
  locked <- bindingIsLocked(name, env)
  if (locked) unlockBinding(name, env)
  assign(name, replacement, envir = env)
  if (locked) lockBinding(name, env)
  on.exit({
    if (locked) unlockBinding(name, env)
    assign(name, old, envir = env)
    if (locked) lockBinding(name, env)
  }, add = TRUE)
  force(code)
}

testthat::test_that("refinement fallback uses its existing stage budget and cannot certify", {
  testthat::skip_if_not_installed("highs")
  pr_minimax_with_mock(".pr_solve_raw", function(...) stop("injected native failure"), {
  pw <- postrank_pairwise(pr_aud01_payload()); w <- c(need1 = 1 - 1e-9, need2 = 0, need3 = 1e-9)
  p <- postrank_problem(pw, w, .5, 5L, objective = "minimax", minimax_criteria = "need1")
  p2 <- .pr_minimax_refine_problem(p, c(need1 = .5))
  out <- .pr_minimax_solve_stage(p2, "highs", .pr_control(list(time_limit = 1)), "label_mip", rep(1L, 5L))
  testthat::expect_true(out$fallback)
  testthat::expect_true(out$fit$incumbent_validated)
  testthat::expect_false(out$certified)
  testthat::expect_lte(out$optimization$time_limit, 1)
  testthat::expect_false(is.finite(out$optimization$scaled_raw_lower))
  })
})

testthat::test_that("an unavailable Pareto stage preserves only actual primary-weighted certification", {
  testthat::skip_if_not_installed("highs")
  original <- .pr_minimax_solve_stage; calls <- 0L
  replacement <- function(...) {
    calls <<- calls + 1L
    if (calls == 1L) original(...) else list(error = "injected tertiary failure", fallback = FALSE)
  }
  pr_minimax_with_mock(".pr_minimax_solve_stage", replacement, {
  pw <- postrank_pairwise(pr_aud01_payload()); w <- c(need1 = 1 - 1e-9, need2 = 0, need3 = 1e-9)
  f <- postrank_solve(postrank_problem(pw, w, .5, 5L, objective = "minimax", minimax_criteria = "need1"),
    "highs", list(time_limit = 5), "label_mip")
  testthat::expect_true(f$minimax_refine$lexicographic_certified)
  testthat::expect_false(f$minimax_refine$pareto_certified)
  testthat::expect_true(f$minimax_refine$certification$original_weighted)
  testthat::expect_false(f$minimax_refine$certification$pareto)
  testthat::expect_identical(f$minimax_refine$released_relation_identity, f$solution_identity$relation_identity)
  testthat::expect_match(f$warnings, "Minimax refinement was not certified", all = FALSE)
  })
})
