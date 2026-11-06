# 014 repair Phase 2: the staged strategy of postrank_solve().
pr_iid_payload <- function(seed, S, n, K) {
  set.seed(seed); x <- pr_test_payload(S = S, n = n, K = K)
  x$joint_draws$tensor$values[] <- stats::rnorm(S * n * K)
  x
}

testthat::test_that("staged and label-MIP strategies reach the same optimum (n = 10-12)", {
  testthat::skip_if_not_installed("highs")
  control <- list(time_limit = 60, threads = 1L, seed = 1L)
  for (case in list(list(seed = 41L, S = 40L, n = 10L, K = 2L, conflict = TRUE),
                    list(seed = 42L, S = 40L, n = 12L, K = 3L, conflict = FALSE))) {
    x <- do.call(pr_random_payload, case); pw <- postrank_pairwise(x)
    w <- rep(1 / case$K, case$K); names(w) <- pw$criterion_ids
    for (s in list(list(G_max = 3L), list(G_max = 4L, q = stats::setNames(.2, pw$criterion_ids[1])),
                   list(G_max = 3L, objective = "minimax"), list(G_max = 3L, exact_G = 3L))) {
      objective <- if (is.null(s$objective)) "weighted" else s$objective
      problem <- postrank_problem(pw, w, .25, s$G_max, objective = objective, q = s$q, exact_G = s$exact_G)
      staged <- postrank_solve(problem, "highs", control)
      label_mip <- postrank_solve(problem, "highs", control, strategy = "label_mip")
      label <- paste("case", case$seed, objective, paste(names(s), unlist(s), collapse = " "))
      testthat::expect_identical(c(staged$status$normalized, label_mip$status$normalized), c("optimal", "optimal"), info = label)
      testthat::expect_equal(staged$objective$primary_action_risk, label_mip$objective$primary_action_risk, tolerance = 1e-8, info = label)
      testthat::expect_true(staged$objective$bound_source %in% .pr_usable_bound_sources(), info = label)
    }
  }
})

testthat::test_that("the staged fit records each stage and keeps the label-MIP record separate", {
  testthat::skip_if_not_installed("highs")
  x <- pr_random_payload(43L, 30L, 6L, 2L); pw <- postrank_pairwise(x)
  problem <- postrank_problem(pw, c(need1 = .5, need2 = .5), .25, 3L)
  fit <- postrank_solve(problem, "highs", list(time_limit = 20, seed = 5L))
  testthat::expect_identical(fit$engine$strategy, "staged")
  testthat::expect_named(fit$engine$stages, c("incumbent", "lp", "mip"))
  testthat::expect_true(fit$engine$stages$incumbent$candidates >= 1L)
  testthat::expect_identical(fit$backend$name, "highs"); testthat::expect_identical(fit$backend$strategy, "staged")
  testthat::expect_identical(fit$backend$options$random_seed, 5L)
  testthat::expect_identical(fit$backend$options$engine, .pr_engine_options(list()))
  testthat::expect_identical(fit$status$raw_code, paste0("staged:", fit$status$termination_reason))
  reference <- postrank_solve(problem, "highs", list(time_limit = 20, seed = 5L), strategy = "label_mip")
  testthat::expect_identical(reference$engine, list(strategy = "label_mip"))
  testthat::expect_null(reference$backend$strategy)
  testthat::expect_identical(as.integer(reference$status$raw_code), 7L)
})

testthat::test_that("staged statuses: infeasible, uncertified and time-limited runs stay honest", {
  testthat::skip_if_not_installed("highs")
  x <- pr_iid_payload(44L, 30L, 6L, 2L); pw <- postrank_pairwise(x)
  testthat::expect_true(all(pw$e[, , 1][row(pw$e[, , 1]) != col(pw$e[, , 1])] > 0))
  # q = 0 forbids every disclosure with positive error probability, so exactly
  # three nonempty grades are infeasible.
  infeasible <- postrank_problem(pw, c(need1 = .5, need2 = .5), .25, 3L, q = c(need1 = 0), exact_G = 3L)
  for (strategy in c("staged", "label_mip")) {
    fit <- postrank_solve(infeasible, "highs", list(time_limit = 20), strategy = strategy)
    testthat::expect_identical(fit$status$normalized, "infeasible", info = strategy)
    testthat::expect_null(fit$grade)
    # No action exists, so no lower bound is reported by either strategy.
    testthat::expect_identical(fit$objective$bound_source, "missing", info = strategy)
    testthat::expect_true(is.na(fit$objective$risk_lower_bound), info = strategy)
  }
  problem <- postrank_problem(pw, c(need1 = .5, need2 = .5), .25, 3L)
  # Without cutting rounds and without the MIP stage there is no lower bound.
  fit <- postrank_solve(problem, "highs", list(time_limit = 20, engine = list(max_cut_rounds = 0L, mip = "never")))
  testthat::expect_identical(fit$status$normalized, "feasible_not_certified")
  testthat::expect_true(fit$incumbent_validated); testthat::expect_identical(fit$objective$bound_source, "missing")
  testthat::expect_true(is.na(fit$objective$risk_absolute_gap))
  # Expire the budget after constructing a real incumbent, allowing for the
  # elapsed clock's platform-dependent resolution.
  candidates <- .pr_engine_candidates
  testthat::local_mocked_bindings(.pr_engine_candidates = function(...) {
    out <- candidates(...)
    Sys.sleep(.1)
    out
  })
  fit <- postrank_solve(problem, "highs", list(time_limit = 1e-6))
  testthat::expect_identical(fit$status$normalized, "time_limit")
  testthat::expect_true(fit$incumbent_validated); testthat::expect_false(is.null(fit$grade))
})

testthat::test_that("an absent backend fails before any solver namespace is used", {
  testthat::skip_if(length(find.package("gurobi", quiet = TRUE)) > 0L, "gurobi is installed in this library")
  x <- pr_random_payload(45L, 20L, 4L, 2L); problem <- postrank_problem(postrank_pairwise(x), c(need1 = .5, need2 = .5), .25, 2L)
  for (strategy in c("staged", "label_mip")) {
    err <- tryCatch(postrank_solve(problem, "gurobi", strategy = strategy), error = identity)
    testthat::expect_s3_class(err, "postrank_backend_unavailable")
    testthat::expect_identical(err$code, "gurobi_package_missing")
  }
})

testthat::test_that("engine options are validated with the other controls", {
  for (engine in list(list(nope = 1), list(mip = "sometimes"), list(lp_time_share = 0), list(local_search_passes = -1),
                      list(cuts_per_round = 0), list(max_cut_rounds = 1.5), list(1)))
    testthat::expect_error(.pr_control(list(engine = engine)), class = "postrank_input_error")
  testthat::expect_identical(.pr_control()$engine, .pr_engine_options(list()))
  testthat::expect_identical(.pr_control(list(engine = list(mip = "never")))$engine$mip, "never")
})

testthat::test_that("without a MIP stage the relaxation gets the remaining time (ENGINE-SCALE-01)", {
  # The rule: lp_time_share of the remaining time while the MIP stage may run;
  # otherwise the remaining time less max(1 s, 1% of the time limit, twice the
  # incumbent stage's time), never less than the share.
  testthat::expect_equal(.pr_engine_lp_budget(800, 900, TRUE, .5), list(seconds = 400, rule = "lp_time_share"))
  testthat::expect_equal(.pr_engine_lp_budget(800, 900, FALSE, .5), list(seconds = 791, rule = "remaining_less_reserve"))
  testthat::expect_equal(.pr_engine_lp_budget(50, 60, FALSE, .25), list(seconds = 49, rule = "remaining_less_reserve"))
  testthat::expect_equal(.pr_engine_lp_budget(50, 60, FALSE, .25, 3), list(seconds = 44, rule = "remaining_less_reserve"))
  testthat::expect_equal(.pr_engine_lp_budget(1.5, 2, FALSE, .5), list(seconds = .75, rule = "lp_time_share"))
  testthat::expect_equal(.pr_engine_lp_budget(1.5, 2, TRUE, .5), list(seconds = .75, rule = "lp_time_share"))
  # In a solve with n = 8: mip_max_n >= 8 (default 200) keeps the MIP stage and
  # the share; mip_max_n = 5 or mip = "never" removes it, and the relaxation
  # gets about 30 - 1 seconds instead of 15. The recorded budget is the one the
  # relaxation received.
  testthat::skip_if_not_installed("highs")
  x <- pr_random_payload(47L, 30L, 8L, 2L); pw <- postrank_pairwise(x)
  problem <- postrank_problem(pw, c(need1 = .5, need2 = .5), .25, 3L)
  for (case in list(list(engine = list(), rule = "lp_time_share", range = c(12.5, 15)),
                    list(engine = list(mip_max_n = 8L), rule = "lp_time_share", range = c(12.5, 15)),
                    list(engine = list(mip = "always", mip_max_n = 5L), rule = "lp_time_share", range = c(12.5, 15)),
                    list(engine = list(mip_max_n = 5L), rule = "remaining_less_reserve", range = c(25, 29)),
                    list(engine = list(mip = "never"), rule = "remaining_less_reserve", range = c(25, 29)),
                    list(engine = list(mip_max_n = 5L, lp_time_share = .3), rule = "remaining_less_reserve", range = c(25, 29)))) {
    fit <- postrank_solve(problem, "highs", list(time_limit = 30, seed = 1L, engine = case$engine))
    lp <- fit$engine$stages$lp; label <- paste(names(case$engine), unlist(case$engine), collapse = " ")
    testthat::expect_true(fit$incumbent_validated, info = label)
    testthat::expect_identical(lp$time_budget_rule, case$rule, info = label)
    testthat::expect_true(lp$time_budget > case$range[1] && lp$time_budget <= case$range[2], info = label)
  }
})

testthat::test_that("each HiGHS LP call gets the run time used so far plus the remaining budget (ENGINE-SCALE-01)", {
  testthat::skip_if_not_installed("highs")
  # HiGHS checks time_limit against the solver object's cumulative run time.
  # The limit it holds for each call (read back and kept in the round trace)
  # must therefore fall from round to round by the time spent outside HiGHS,
  # here the cut separation of 12 rounds.
  x <- pr_random_payload(50L, 40L, 60L, 3L); pw <- postrank_pairwise(x)
  spec <- .pr_engine_spec(postrank_problem(pw, stats::setNames(rep(1 / 3, 3), pw$criterion_ids), .25, 4L))
  lp <- .pr_engine_lp_bound(spec, "highs", .pr_control(list(threads = 1L, seed = 1L)), time_budget = 20)
  limits <- vapply(lp$rounds, `[[`, numeric(1L), "time_limit")
  testthat::expect_identical(lp$time_budget, 20)
  testthat::expect_gte(length(limits), 3L)
  testthat::expect_true(all(is.finite(limits)) && limits[1L] <= 20)
  testthat::expect_true(all(diff(limits) <= 1e-9))
  testthat::expect_lt(limits[length(limits)], limits[1L])
})

testthat::test_that("optimal actions respond monotonically to tau and G_max and ignore entity order", {
  testthat::skip_if_not_installed("highs")
  control <- list(time_limit = 30, threads = 1L, seed = 1L, absolute_risk_gap = 1e-12)
  x <- pr_random_payload(46L, 40L, 8L, 2L, conflict = TRUE); pw <- postrank_pairwise(x)
  w <- c(need1 = .6, need2 = .4)
  # Revealed preference: with a tau-free feasible set, a larger tau never
  # lowers the number of disclosed ordered pairs at an optimum.
  disclosed <- vapply(c(.1234567, .2345678, .3456789, .4567891), function(tau) {
    fit <- postrank_solve(postrank_problem(pw, w, tau, 4L, q = c(need2 = .3)), "highs", control)
    testthat::expect_identical(fit$status$normalized, "optimal")
    fit$evaluation$N
  }, numeric(1L))
  testthat::expect_true(all(diff(disclosed) >= 0))
  risks <- vapply(1:5, function(G) {
    fit <- postrank_solve(postrank_problem(pw, w, .25, G), "highs", control)
    testthat::expect_identical(fit$status$normalized, "optimal")
    fit$objective$primary_action_risk
  }, numeric(1L))
  testthat::expect_true(all(diff(risks) <= 1e-9))
  perm <- c(5L, 2L, 8L, 1L, 7L, 3L, 6L, 4L)
  y <- x; y$joint_draws$tensor$values <- x$joint_draws$tensor$values[, perm, , drop = FALSE]
  dimnames(y$joint_draws$tensor$values) <- dimnames(x$joint_draws$tensor$values)
  for (objective in c("weighted", "minimax")) {
    a <- postrank_solve(postrank_problem(pw, w, .25, 3L, objective = objective), "highs", control)
    b <- postrank_solve(postrank_problem(postrank_pairwise(y), w, .25, 3L, objective = objective), "highs", control)
    testthat::expect_equal(a$objective$primary_action_risk, b$objective$primary_action_risk, tolerance = 1e-9, info = objective)
  }
})

testthat::test_that("HiGHS pruning cannot certify a worse minimax action (Phase 2 review case)", {
  testthat::skip_if_not_installed("highs")
  # Coefficients from the independent review's fault search (n = 6, K = 2).
  e1 <- matrix(c(NA, 1, .5, 0, .5, 1,  0, NA, 0, .5, 1, 1,  .5, 1, NA, .5, .5, .5,
                 1, .5, .5, NA, 0, 0,  .5, 0, .5, 1, NA, 0,  0, 0, .5, 1, 1, NA), 6, 6, byrow = TRUE)
  e2 <- matrix(c(NA, 0, .5, 0, 0, .5,  1, NA, 1, .5, 0, 0,  .5, 0, NA, 0, 1, 0,
                 1, .5, 1, NA, 1, 0,  1, 1, 0, 0, NA, 1,  .5, 1, 1, 1, 0, NA), 6, 6, byrow = TRUE)
  base <- postrank_pairwise(pr_test_payload(S = 4L, n = 6L, K = 2L))
  pw <- base; pw$e <- array(c(e1, e2), c(6, 6, 2), dimnames = dimnames(base$e)); pw$pairwise_identity <- NULL
  .pr_validate_pairwise(pw, allow_unidentified = TRUE); pw$pairwise_identity <- .pr_identity(pw); .pr_validate_pairwise(pw)
  w <- c(need1 = 0.0569455, need2 = 0.9430545); tau <- 0.4999995
  oracle <- pr_oracle_solve(unname(pw$e), unname(w), tau, 5L, "minimax")$optimum
  problem <- postrank_problem(pw, w, tau, 5L, objective = "minimax", minimax_refine = "none")
  for (strategy in c("staged", "label_mip")) {
    fit <- postrank_solve(problem, "highs", list(time_limit = 20, seed = 1L), strategy = strategy)
    if (identical(fit$status$normalized, "optimal"))
      testthat::expect_equal(fit$objective$primary_action_risk, oracle, tolerance = 1e-12, info = strategy)
    testthat::expect_true(is.na(fit$objective$risk_lower_bound) || fit$objective$risk_lower_bound <= oracle + 1e-12, info = strategy)
  }
})
