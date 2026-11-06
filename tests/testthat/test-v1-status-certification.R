test_that("optimal without a finite lower bound retains the action without certification", {
  p <- pr_status_problem()
  for (lower in c(NA_real_, Inf, -Inf)) {
    raw <- pr_status_raw(p, lower = lower)
    fit <- .pr_normalize_solver_result(p, raw, .pr_control())
    expect_identical(fit$status$normalized, "feasible_not_certified")
    expect_identical(fit$status$raw_code, raw$raw_status)
    expect_identical(fit$status$termination_reason, raw$termination_reason)
    expect_true(fit$incumbent_validated)
    expect_identical(fit$raw_solution, raw$primal)
    expect_equal(unname(fit$grade), rep(1L, 3L))
    expect_equal(fit$objective$risk_upper_bound, .25)
    expect_true(is.na(fit$objective$risk_lower_bound))
    expect_true(is.na(fit$objective$risk_absolute_gap))
    expect_identical(fit$objective$bound_source, "missing")
    expect_length(fit$numerical_issues, 0L)
    expect_match(fit$warnings, "no usable whole-problem lower bound", all = FALSE)
  }
})

test_that("optimal with a wide positive gap retains its valid lower bound", {
  p <- pr_status_problem()
  raw <- pr_status_raw(p, lower = -.6)
  fit <- .pr_normalize_solver_result(p, raw,
    .pr_control(list(absolute_risk_gap = 1e-8, relative_gap = 1e-6)))
  expect_identical(fit$status$normalized, "feasible_not_certified")
  expect_identical(fit$status$raw_code, "OPTIMAL")
  expect_identical(fit$status$raw_message, raw$raw_message)
  expect_identical(fit$raw_solution, raw$primal)
  expect_true(fit$incumbent_validated)
  expect_equal(fit$objective$risk_lower_bound, .05)
  expect_equal(fit$objective$risk_absolute_gap, .2)
  expect_identical(fit$objective$raw_lower_bound, -.6)
  expect_identical(fit$objective$bound_source, "backend_reported_dual_bound")
  expect_length(fit$numerical_issues, 0L)
  expect_match(fit$warnings, "available risk gap.*exceeds the requested gap", all = FALSE)
})

test_that("absolute gap qualification permits only machine roundoff at the boundary", {
  p <- pr_status_problem()
  # For this all-withheld action M = 3 and risk = .25 + raw objective / 3.
  control <- .pr_control(list(absolute_risk_gap = 1e-8, relative_gap = 0))
  for (extra in c(-1e-10, 0, 2 * .Machine$double.eps, 1e-12)) {
    raw <- pr_status_raw(p, lower = -3 * (1e-8 + extra))
    fit <- .pr_normalize_solver_result(p, raw, control)
    expected <- if (extra <= 2 * .Machine$double.eps) "optimal" else "feasible_not_certified"
    expect_identical(fit$status$normalized, expected, info = paste("extra", extra))
    expect_length(fit$numerical_issues, 0L)
    expect_false(fit$objective$bound_inversion_within_tolerance)
    expect_lt(abs(fit$objective$risk_absolute_gap - (1e-8 + extra)), 1e-15)
  }
  # A loose objective validator tolerance cannot license a positive gap.
  strict <- .pr_normalize_solver_result(p, pr_status_raw(p, lower = -3e-12),
    .pr_control(list(absolute_risk_gap = 0, relative_gap = 0,
      tolerances = list(objective = 1e-3))))
  expect_identical(strict$status$normalized, "feasible_not_certified")
  expect_lt(abs(strict$objective$risk_absolute_gap - 1e-12), 1e-15)
})

test_that("relative gap qualification uses the raw weighted objective before its offset", {
  p <- pr_status_problem()
  primal <- .pr_engine_primal(p, c(1L, 2L, 3L))
  objective <- sum(p$model$objective * primal)
  expect_gt(abs(objective), 1e-3)
  # Raw relative target is 1% of |objective|; scale is 1/M, offset is tau.
  control <- .pr_control(list(absolute_risk_gap = 0, relative_gap = .01))
  for (factor in c(.5, 1, 1.01)) {
    raw <- pr_status_raw(p, lower = objective - factor * .01 * abs(objective), primal = primal)
    raw$raw_objective <- objective
    fit <- .pr_normalize_solver_result(p, raw, control)
    expect_identical(fit$status$normalized,
      if (factor <= 1) "optimal" else "feasible_not_certified")
    expect_equal(fit$objective$risk_absolute_gap, factor * .01 * abs(objective) / 3)
    expect_length(fit$numerical_issues, 0L)
  }
  # Raw objective zero gives zero relative tolerance even though risk is .25.
  zero <- .pr_normalize_solver_result(p, pr_status_raw(p, lower = -.003), control)
  expect_identical(zero$status$normalized, "feasible_not_certified")
  expect_equal(zero$objective$risk_absolute_gap, .001)
})

test_that("minimax qualification compares the released action risk with the lower bound", {
  p <- postrank_problem(postrank_pairwise(pr_test_payload()),
    c(need1 = 1, need2 = 0), .25, 3L, objective = "minimax")
  primal <- .pr_engine_primal(p, rep(1L, 3L))
  # A slack epigraph is valid but is not the risk of the released action.
  primal[p$index$t] <- .35
  control <- .pr_control(list(absolute_risk_gap = 0, relative_gap = .1))
  for (lower in c(.226, .224)) {
    raw <- pr_status_raw(p, lower = lower, primal = primal)
    raw$raw_objective <- .35
    fit <- .pr_normalize_solver_result(p, raw, control)
    expect_identical(fit$status$normalized,
      if (lower == .226) "optimal" else "feasible_not_certified")
    expect_equal(fit$objective$epigraph_value, .35)
    expect_equal(fit$objective$risk_upper_bound, .25)
    expect_equal(fit$objective$risk_lower_bound, lower)
    expect_length(fit$numerical_issues, 0L)
  }
})

test_that("gap qualification does not promote other terminations or alter clamping", {
  p <- pr_status_problem()
  for (status in c("TIME_LIMIT", "SUBOPTIMAL")) for (lower in c(0, -.6, NA_real_)) {
    raw <- pr_status_raw(p, status, lower)
    fit <- .pr_normalize_solver_result(p, raw, .pr_control())
    expect_identical(fit$status$normalized, raw$status_normalized)
    expect_true(fit$incumbent_validated)
    expect_length(fit$numerical_issues, 0L)
    expect_false(any(grepl("Backend reported optimal", fit$warnings)))
  }
  clamped <- .pr_normalize_solver_result(p, pr_status_raw(p, lower = 6e-8), .pr_control())
  expect_identical(clamped$status$normalized, "optimal")
  expect_identical(clamped$objective$risk_absolute_gap, 0)
  expect_identical(clamped$objective$bound_source, "backend_reported_dual_bound_clamped")
  expect_match(clamped$warnings, "clamped to the action risk", all = FALSE)
  expect_match(clamped$warnings, "larger than the requested gap", all = FALSE)
  expect_length(clamped$numerical_issues, 0L)
})
