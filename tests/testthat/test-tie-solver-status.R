pr_tie_raw_result <- function(problem, grade) {
  primal <- .pr_tie_primal(problem, grade)
  objective <- sum(problem$model$objective * primal)
  list(primal = primal, raw_status = "MOCK", raw_message = "status fixture",
    status_normalized = "feasible_not_certified", termination_reason = "fixture",
    has_incumbent = TRUE, raw_objective = objective, raw_lower_bound = objective - .3,
    relative_gap = NA_real_, runtime = 0, backend = list(name = "mock"),
    engine = list(strategy = "label_mip"), raw = list(native_solver_called = FALSE),
    warnings = character(), bound_source = "backend_reported_dual_bound")
}

test_that("new-domain normalization converts bounds with R0 and preserves limits", {
  skip_if_not_installed("gmp")
  z <- pr_tie_t11()
  pw <- postrank_tie_pairwise(pr_tie_fixture(z$values, z$masses))
  p <- postrank_tie_problem(pw, z$weights, .1, 2L)
  grade <- stats::setNames(c(2L, 2L, 1L, 1L), pw$entity_ids)
  raw <- pr_tie_raw_result(p, grade)
  fit <- .pr_tie_normalize_solver_result(p, raw, .pr_control())
  expect_true(fit$incumbent_validated)
  expect_equal(fit$objective$risk_lower_bound, p$objective_units$offset + raw$raw_lower_bound / 6)
  expect_equal(fit$objective$risk_upper_bound, 1 / 60)
  expect_equal(fit$objective$risk_absolute_gap, .05)
  expect_identical(fit$status$normalized, "feasible_not_certified")
  expect_false(fit$objective$numerical_certification)
  expect_false(inherits(fit, "postrank_fit"))
})

test_that("new-domain normalizer refuses contradictory objectives, bounds and primals", {
  skip_if_not_installed("gmp")
  z <- pr_tie_t11(); pw <- postrank_tie_pairwise(pr_tie_fixture(z$values, z$masses))
  p <- postrank_tie_problem(pw, z$weights, .1, 2L)
  raw <- pr_tie_raw_result(p, stats::setNames(c(2L, 2L, 1L, 1L), pw$entity_ids))
  for (kind in c("objective", "bound", "source", "flag", "no_primal", "missing_objective")) {
    bad <- raw
    if (kind == "objective") bad$raw_objective <- bad$raw_objective + 1
    if (kind == "bound") bad$raw_lower_bound <- bad$raw_objective + 1
    if (kind == "source") bad$bound_source <- "invented_certificate"
    if (kind == "flag") bad$has_incumbent <- FALSE
    if (kind == "no_primal") {
      bad$primal <- NULL; bad$has_incumbent <- FALSE; bad$status_normalized <- "optimal"
    }
    if (kind == "missing_objective") bad$raw_objective <- NA_real_
    fit <- .pr_tie_normalize_solver_result(p, bad, .pr_control())
    expect_identical(fit$status$normalized, "numerical_error", info = kind)
    expect_true(is.na(fit$objective$risk_lower_bound), info = kind)
    if (kind == "no_primal") { expect_false(fit$incumbent_validated); expect_null(fit$grade) }
    else expect_true(fit$incumbent_validated, info = kind)
  }
  bad <- raw; bad$primal <- numeric(length(bad$primal))
  fit <- .pr_tie_normalize_solver_result(p, bad, .pr_control(list(tolerances = list(feasibility = 2))))
  expect_false(fit$incumbent_validated); expect_null(fit$grade)
  expect_identical(fit$status$normalized, "numerical_error")
})

test_that("new-domain bounds clamp only tolerance-scale inversions and label the limit", {
  skip_if_not_installed("gmp")
  z <- pr_tie_t11(); pw <- postrank_tie_pairwise(pr_tie_fixture(z$values, z$masses))
  p <- postrank_tie_problem(pw, z$weights, .1, 2L)
  raw <- pr_tie_raw_result(p, stats::setNames(c(2L, 2L, 1L, 1L), pw$entity_ids))
  raw$raw_lower_bound <- raw$raw_objective + 1e-8
  fit <- .pr_tie_normalize_solver_result(p, raw, .pr_control())
  expect_true(fit$incumbent_validated)
  expect_identical(fit$objective$bound_source, "backend_reported_dual_bound_clamped")
  expect_equal(fit$objective$risk_absolute_gap, 0)
  expect_true(fit$objective$bound_inversion_within_tolerance)
  expect_true(any(grepl("not a numerical certificate", fit$warnings, fixed = TRUE)))
})

test_that("unknown native termination cannot supply a reusable tie-aware bound", {
  skip_if_not_installed("gmp")
  z <- pr_tie_t11(); pw <- postrank_tie_pairwise(pr_tie_fixture(z$values, z$masses))
  p <- postrank_tie_problem(pw, z$weights, .1, 2L)
  for (status in c("LOADED", "INF_OR_UNBD", "FUTURE_STATUS")) {
    raw <- pr_tie_raw_result(p, stats::setNames(c(2L, 2L, 1L, 1L), pw$entity_ids))
    raw$raw_status <- status; raw$status_normalized <- "unknown"
    fit <- .pr_tie_normalize_solver_result(p, raw, .pr_control())
    expect_true(fit$incumbent_validated)
    expect_identical(fit$status$normalized, "unknown")
    expect_true(is.na(fit$objective$risk_lower_bound))
    expect_true(is.na(fit$objective$risk_absolute_gap))
    expect_equal(fit$objective$raw_lower_bound, raw$raw_lower_bound)
    expect_identical(fit$objective$bound_source, "backend_reported_rejected_status")
  }
})

# Synthetic backend records on the complete T11 law, not native solve results.
# Of six original pairs, distinctness totals are 5 and 3 for the two criteria.
# At weights (.25, .75), tau=.1: R0=.1*(.25*5+.75*3)/6=7/120.
# The report (2,2,1,1) makes no strict errors and withholds only one
# distinct pair on each criterion, so its risk is .1/6=1/60 and raw loss=-1/4.
pr_tie_optimal_status_fixture <- function(all_withheld = FALSE) {
  z <- pr_tie_t11()
  pw <- postrank_tie_pairwise(pr_tie_fixture(z$values, z$masses))
  problem <- postrank_tie_problem(pw, z$weights, .1, 2L)
  grade <- stats::setNames(if (all_withheld) rep(1L, 4L) else c(2L, 2L, 1L, 1L), pw$entity_ids)
  raw <- pr_tie_raw_result(problem, grade)
  raw$status_normalized <- "optimal"
  raw$raw_status <- "SYNTHETIC_OPTIMAL"
  raw$raw_message <- "Synthetic bound-qualification record, not a native solver run"
  raw$raw_lower_bound <- if (all_withheld) 0 else -1 / 4
  list(problem = problem, raw = raw, grade = grade)
}

test_that("tie optimal without a usable lower bound retains only feasibility", {
  skip_if_not_installed("gmp")
  f <- pr_tie_optimal_status_fixture()
  for (lower in c(NA_real_, Inf, -Inf)) {
    raw <- f$raw; raw$raw_lower_bound <- lower
    fit <- .pr_tie_normalize_solver_result(f$problem, raw, .pr_control())
    expect_identical(fit$status$normalized, "feasible_not_certified")
    expect_identical(fit$status$raw_code, raw$raw_status)
    expect_identical(fit$status$raw_message, raw$raw_message)
    expect_identical(fit$status$termination_reason, raw$termination_reason)
    expect_true(fit$incumbent_validated)
    expect_identical(fit$grade, f$grade)
    expect_identical(fit$raw_solution, raw$primal)
    expect_equal(fit$objective$offset, 7 / 120)
    expect_equal(fit$objective$scale, 1 / 6)
    expect_equal(fit$objective$risk_upper_bound, 1 / 60)
    expect_true(is.na(fit$objective$risk_lower_bound))
    expect_true(is.na(fit$objective$risk_absolute_gap))
    expect_identical(fit$objective$bound_source, "missing")
    expect_length(fit$numerical_issues, 0L)
    expect_match(fit$warnings, "no usable whole-problem lower bound", all = FALSE)
  }
})

test_that("tie optimal with a wide valid bound retains the bound and action", {
  skip_if_not_installed("gmp")
  f <- pr_tie_optimal_status_fixture(); raw <- f$raw
  # A lower bound of -1/30 is valid because equality-neutral risk is nonnegative.
  raw$raw_lower_bound <- -1 / 4 - 6 * .05
  fit <- .pr_tie_normalize_solver_result(f$problem, raw, .pr_control())
  expect_identical(fit$status$normalized, "feasible_not_certified")
  expect_identical(fit$status$raw_code, raw$raw_status)
  expect_identical(fit$grade, f$grade)
  expect_identical(fit$raw_solution, raw$primal)
  expect_true(fit$incumbent_validated)
  expect_equal(fit$objective$risk_lower_bound, -1 / 30)
  expect_equal(fit$objective$risk_absolute_gap, .05)
  expect_identical(fit$objective$raw_lower_bound, raw$raw_lower_bound)
  expect_identical(fit$objective$bound_source, "backend_reported_dual_bound")
  expect_length(fit$numerical_issues, 0L)
  expect_match(fit$warnings, "available risk gap.*exceeds the requested gap", all = FALSE)
})

test_that("tie absolute gap qualification allows only comparison roundoff", {
  skip_if_not_installed("gmp")
  f <- pr_tie_optimal_status_fixture()
  control <- .pr_control(list(absolute_risk_gap = 1e-8, relative_gap = 0))
  for (extra in c(-1e-10, 0, 2 * .Machine$double.eps, 1e-12)) {
    raw <- f$raw; raw$raw_lower_bound <- -1 / 4 - 6 * (1e-8 + extra)
    fit <- .pr_tie_normalize_solver_result(f$problem, raw, control)
    expect_identical(fit$status$normalized,
      if (extra <= 2 * .Machine$double.eps) "optimal" else "feasible_not_certified",
      info = paste("extra", extra))
    expect_lt(abs(fit$objective$risk_absolute_gap - (1e-8 + extra)), 1e-15)
    expect_identical(fit$grade, f$grade)
    expect_length(fit$numerical_issues, 0L)
  }
  # Loose objective-validation tolerances do not license a positive gap.
  strict <- .pr_control(list(absolute_risk_gap = 0, relative_gap = 0,
    tolerances = list(objective = 1e-3)))
  for (gap in c(0, 2 * .Machine$double.eps, 128 * .Machine$double.eps, 1e-12)) {
    raw <- f$raw; raw$raw_lower_bound <- -1 / 4 - 6 * gap
    fit <- .pr_tie_normalize_solver_result(f$problem, raw, strict)
    expect_identical(fit$status$normalized,
      if (gap <= 2 * .Machine$double.eps) "optimal" else "feasible_not_certified")
    expect_lt(abs(fit$objective$risk_absolute_gap - gap), 1e-15)
    # At exact zero, the R0 + raw/M conversion can round above the separately
    # evaluated action by one ulp; that existing clamp remains legitimate.
    if (gap > 0) expect_false(fit$objective$bound_inversion_within_tolerance)
    expect_length(fit$numerical_issues, 0L)
  }
})

test_that("tie relative gaps use the R0-centered raw objective", {
  skip_if_not_installed("gmp")
  f <- pr_tie_optimal_status_fixture()
  # |U-R0|=|1/60-7/120|=1/24. Neither U nor U-tau is the correct scale.
  control <- .pr_control(list(absolute_risk_gap = 0, relative_gap = .01))
  for (factor in c(.5, 1, 1.01)) {
    raw <- f$raw; raw$raw_lower_bound <- -1 / 4 - factor * .01 / 4
    fit <- .pr_tie_normalize_solver_result(f$problem, raw, control)
    expect_identical(fit$status$normalized,
      if (factor <= 1) "optimal" else "feasible_not_certified")
    expect_equal(fit$objective$risk_absolute_gap, factor * .01 / 24)
    expect_equal(fit$objective$offset, 7 / 120)
    expect_length(fit$numerical_issues, 0L)
  }
  # For all-withheld, raw objective=0, so relative allowance=0 despite R0>0.
  held <- pr_tie_optimal_status_fixture(all_withheld = TRUE)
  raw <- held$raw; raw$raw_lower_bound <- -6e-4
  fit <- .pr_tie_normalize_solver_result(held$problem, raw, control)
  expect_identical(fit$status$normalized, "feasible_not_certified")
  expect_equal(fit$objective$risk_upper_bound, 7 / 120)
  expect_equal(fit$objective$risk_absolute_gap, 1e-4)
  expect_identical(fit$grade, held$grade)
  expect_length(fit$numerical_issues, 0L)
})

test_that("tie qualification preserves tiny-inversion clamping and other terminations", {
  skip_if_not_installed("gmp")
  f <- pr_tie_optimal_status_fixture()
  raw <- f$raw; raw$raw_lower_bound <- -1 / 4 + 1e-8
  clamp <- .pr_tie_normalize_solver_result(f$problem, raw,
    .pr_control(list(absolute_risk_gap = 0, relative_gap = 0)))
  expect_identical(clamp$status$normalized, "optimal")
  expect_identical(clamp$grade, f$grade)
  expect_identical(clamp$objective$bound_source, "backend_reported_dual_bound_clamped")
  expect_equal(clamp$objective$risk_lower_bound, 1 / 60)
  expect_identical(clamp$objective$risk_absolute_gap, 0)
  expect_true(clamp$objective$bound_inversion_within_tolerance)
  expect_match(clamp$warnings, "clamped to the action risk", all = FALSE)
  expect_match(clamp$warnings, "larger than the requested gap", all = FALSE)
  expect_length(clamp$numerical_issues, 0L)
  for (status in c("time_limit", "feasible_not_certified")) {
    for (lower in c(-1 / 4, -1 / 4 - .3, NA_real_)) {
      raw <- f$raw; raw$status_normalized <- status; raw$raw_lower_bound <- lower
      fit <- .pr_tie_normalize_solver_result(f$problem, raw, .pr_control())
      expect_identical(fit$status$normalized, status)
      expect_identical(fit$grade, f$grade)
      expect_true(fit$incumbent_validated)
      expect_length(fit$numerical_issues, 0L)
      expect_false(any(grepl("Backend reported optimal", fit$warnings)))
    }
  }
})

test_that("tie qualification never creates a grade without a valid candidate", {
  skip_if_not_installed("gmp")
  f <- pr_tie_optimal_status_fixture()
  for (status in c("optimal", "time_limit")) {
    raw <- f$raw; raw$status_normalized <- status
    raw$primal <- NULL; raw$has_incumbent <- FALSE; raw$raw_objective <- NA_real_
    fit <- .pr_tie_normalize_solver_result(f$problem, raw, .pr_control())
    expect_identical(fit$status$normalized,
      if (status == "optimal") "numerical_error" else "time_limit")
    expect_false(fit$incumbent_validated)
    expect_null(fit$grade)
    expect_true(is.na(fit$objective$risk_upper_bound))
    expect_true(is.na(fit$objective$risk_absolute_gap))
    expect_identical(fit$status$raw_code, raw$raw_status)
    if (status == "time_limit") {
      expect_equal(fit$objective$risk_lower_bound, 1 / 60)
      expect_length(fit$numerical_issues, 0L)
    } else {
      expect_true(is.na(fit$objective$risk_lower_bound))
      expect_identical(fit$numerical_issues[[1L]]$code, "optimal_without_valid_incumbent")
    }
  }
})
