# pr_status_problem() and pr_status_raw() are defined in helper-status.R.

testthat::test_that("Gurobi exact status mapping never promotes SUBOPTIMAL or local optimality", {
  testthat::expect_identical(.pr_gurobi_status("OPTIMAL")$normalized, "optimal")
  testthat::expect_identical(.pr_gurobi_status("SUBOPTIMAL", TRUE)$normalized, "feasible_not_certified")
  testthat::expect_identical(.pr_gurobi_status("SUBOPTIMAL", FALSE)$normalized, "unknown")
  testthat::expect_identical(.pr_gurobi_status("TIME_LIMIT")$normalized, "time_limit")
  testthat::expect_identical(.pr_gurobi_status("INF_OR_UNBD")$normalized, "unknown")
  testthat::expect_identical(.pr_gurobi_status("LOCALLY_OPTIMAL", TRUE)$normalized, "feasible_not_certified")
  testthat::expect_identical(.pr_gurobi_status("NUMERIC")$normalized, "numerical_error")
  testthat::expect_identical(.pr_gurobi_status("WORK_LIMIT", TRUE)$normalized, "feasible_not_certified")
  testthat::expect_identical(.pr_gurobi_status("WORK_LIMIT", FALSE)$normalized, "unknown")
  testthat::expect_identical(.pr_gurobi_status("NOT_OPTIMAL")$normalized, "unknown")
  testthat::expect_identical(.pr_gurobi_status(2L)$normalized, "unknown")
  p <- pr_status_problem(); fit <- .pr_normalize_solver_result(p, pr_status_raw(p, "SUBOPTIMAL"), .pr_control())
  testthat::expect_identical(fit$status$normalized, "feasible_not_certified")
  testthat::expect_identical(fit$status$termination_reason, "suboptimal")
  testthat::expect_true(fit$incumbent_validated)
})

testthat::test_that("risk bounds and absolute gaps use scale and offset instead of raw gap units", {
  p <- pr_status_problem(); fit <- .pr_normalize_solver_result(p, pr_status_raw(p, lower = -.3), .pr_control())
  testthat::expect_equal(fit$objective$raw_incumbent, 0)
  testthat::expect_equal(fit$objective$raw_lower_bound, -.3)
  testthat::expect_equal(fit$objective$risk_upper_bound, .25)
  testthat::expect_equal(fit$objective$risk_lower_bound, .15)
  testthat::expect_equal(fit$objective$risk_absolute_gap, .1)
  testthat::expect_identical(fit$objective$raw_units, "weighted_Z")
  testthat::expect_true(fit$incumbent_validated)
  testthat::expect_equal(fit$evaluation$weighted_risk, fit$objective$risk_upper_bound)
})

testthat::test_that("missing bound and time limit preserve incumbent existence independently", {
  p <- pr_status_problem(); raw <- pr_status_raw(p, "TIME_LIMIT", lower = NA_real_)
  fit <- .pr_normalize_solver_result(p, raw, .pr_control())
  testthat::expect_identical(fit$status$normalized, "time_limit")
  testthat::expect_true(fit$has_incumbent); testthat::expect_true(fit$incumbent_validated)
  testthat::expect_false(is.null(fit$grade))
  testthat::expect_true(is.na(fit$objective$risk_lower_bound)); testthat::expect_true(is.na(fit$objective$risk_absolute_gap))
  raw$primal <- NULL; raw$has_incumbent <- FALSE; raw$raw_objective <- NA_real_
  fit <- .pr_normalize_solver_result(p, raw, .pr_control())
  testthat::expect_identical(fit$status$normalized, "time_limit")
  testthat::expect_false(fit$has_incumbent); testthat::expect_false(fit$incumbent_validated)
  testthat::expect_null(fit$grade); testthat::expect_true(is.na(fit$objective$risk_upper_bound))
})

testthat::test_that("inverted bounds and objective mismatches are retained as numerical issues", {
  p <- pr_status_problem(); raw <- pr_status_raw(p, lower = .01)
  fit <- .pr_normalize_solver_result(p, raw, .pr_control())
  testthat::expect_identical(fit$status$raw_code, "OPTIMAL")
  testthat::expect_identical(fit$status$normalized, "numerical_error")
  testthat::expect_identical(fit$numerical_issues[[1L]]$code, "bound_above_incumbent")
  testthat::expect_equal(fit$objective$raw_lower_bound, .01)
  testthat::expect_true(is.na(fit$objective$risk_lower_bound)); testthat::expect_true(is.na(fit$objective$risk_absolute_gap))
  testthat::expect_true(fit$incumbent_validated)
  raw <- pr_status_raw(p); raw$raw_objective <- 1
  fit <- .pr_normalize_solver_result(p, raw, .pr_control())
  testthat::expect_identical(fit$status$normalized, "numerical_error")
  testthat::expect_equal(fit$objective$raw_incumbent, 1)
  testthat::expect_equal(fit$objective$recomputed_raw_incumbent, 0)
  testthat::expect_true(is.na(fit$objective$risk_lower_bound))
})

testthat::test_that("invalid primal cannot release a grade despite optimal solver status", {
  p <- pr_status_problem(); raw <- pr_status_raw(p)
  raw$primal[p$index$labels[1L]] <- 1.4
  fit <- .pr_normalize_solver_result(p, raw, .pr_control())
  testthat::expect_true(fit$has_incumbent); testthat::expect_false(fit$incumbent_validated)
  testthat::expect_identical(fit$status$normalized, "numerical_error")
  testthat::expect_null(fit$grade); testthat::expect_null(fit$evaluation)
  testthat::expect_true(is.na(fit$objective$risk_upper_bound))
  testthat::expect_identical(fit$raw_solution, raw$primal)
})

testthat::test_that("tiny positive bound inversions are clamped to the action risk and flagged", {
  # 014 repair policy (CP-3): a reported bound above the validated action risk by
  # at most the objective tolerance is floating-point rounding or a solver
  # tolerance effect; it is clamped (gap 0) and flagged instead of discarding the bound.
  p <- pr_status_problem(); raw <- pr_status_raw(p, lower = 1e-12)
  fit <- .pr_normalize_solver_result(p, raw, .pr_control())
  testthat::expect_identical(fit$status$normalized, "optimal")
  testthat::expect_length(fit$numerical_issues, 0L)
  testthat::expect_true(fit$objective$bound_inversion_within_tolerance)
  testthat::expect_equal(fit$objective$raw_bound_minus_action_raw, 1e-12)
  testthat::expect_identical(fit$objective$risk_lower_bound, fit$objective$risk_upper_bound)
  testthat::expect_identical(fit$objective$risk_absolute_gap, 0)
  testthat::expect_identical(fit$objective$bound_source, "backend_reported_dual_bound_clamped")
  testthat::expect_match(fit$warnings, "clamped to the action risk", all = FALSE)
  testthat::expect_false(any(grepl("larger than the requested gap", fit$warnings)))
  testthat::expect_false(fit$objective$numerical_certification)
  # Phase 5 review of L5: a clamped inversion above the absolute gap control is
  # still clamped, with an extra warning (here 2e-8 risk > 1e-8 requested).
  wide <- .pr_normalize_solver_result(p, pr_status_raw(p, lower = 6e-8), .pr_control())
  testthat::expect_true(wide$objective$bound_inversion_within_tolerance)
  testthat::expect_equal(wide$objective$risk_bound_minus_action_risk, 2e-8)
  testthat::expect_match(wide$warnings, "larger than the requested gap", all = FALSE)
  # The second warning uses the gap controls (absolute, or relative on the raw
  # objective). All-tie has raw objective 0, so use an action with disclosures.
  primal <- .pr_engine_primal(p, c(1L, 2L, 3L)); z <- sum(p$model$objective * primal)
  testthat::expect_gt(abs(z), 1e-3)
  mock <- function(delta) .pr_gurobi_raw_result(list(status = "OPTIMAL", x = primal, objval = z, objbound = z + delta,
    mipgap = 0, runtime = .01), backend = list(name = "gurobi_mock", wrapper_version = "mock",
    solver_version = NA_character_, options = list()))
  absolute <- .pr_normalize_solver_result(p, mock(6e-8), .pr_control())
  testthat::expect_true(absolute$objective$bound_inversion_within_tolerance)
  testthat::expect_match(absolute$warnings, "larger than the requested gap", all = FALSE)
  relative <- .pr_normalize_solver_result(p, mock(6e-8), .pr_control(list(relative_gap = .01)))
  testthat::expect_match(relative$warnings, "clamped to the action risk", all = FALSE)
  testthat::expect_false(any(grepl("larger than the requested gap", relative$warnings)))
  # When another issue rejects the bound, no clamp warning is emitted.
  rejected <- .pr_normalize_solver_result(p, pr_status_raw(p, status = "NUMERIC", lower = 6e-8), .pr_control())
  testthat::expect_identical(rejected$status$normalized, "numerical_error")
  testthat::expect_true(is.na(rejected$objective$risk_lower_bound))
  testthat::expect_false(any(grepl("clamped|larger than the requested gap", rejected$warnings)))
  raw$status_normalized <- "suboptimal"
  testthat::expect_error(.pr_normalize_solver_result(p, raw, .pr_control()), "public status enum", class = "postrank_input_error")
})

testthat::test_that("Gurobi row conversion preserves inequalities, ranges, equality and free rows", {
  model <- list(A = Matrix::Diagonal(4L), objective = rep(0, 4), var_lower = rep(0, 4), var_upper = rep(1, 4),
    row_lower = c(-Inf, 0, 1, -Inf), row_upper = c(1, 2, 1, Inf),
    types = c("I", "B", "C", "C"), var_names = paste0("v", 1:4), row_names = paste0("r", 1:4), sense = "min")
  converted <- .pr_gurobi_model(model)
  testthat::expect_identical(converted$row_map$source_row, c(1L, 2L, 2L, 3L))
  testthat::expect_identical(converted$model$sense, c("<", ">", "<", "="))
  testthat::expect_equal(converted$model$rhs, c(1, 0, 2, 1))
  testthat::expect_identical(converted$model$vtype, model$types)
  testthat::expect_identical(converted$free_source_rows, 4L)
  testthat::expect_equal(as.matrix(converted$model$A), as.matrix(model$A)[c(1, 2, 2, 3), , drop = FALSE])
})

testthat::test_that("an infeasible fit reports no lower bound whatever the backend returned (014 repair)", {
  p <- pr_status_problem()
  raw <- .pr_gurobi_raw_result(list(status = "INFEASIBLE", x = NULL, objval = NULL, objbound = .1, mipgap = NULL, runtime = .01),
    backend = list(name = "gurobi_mock", wrapper_version = "mock", solver_version = NA_character_, options = list()))
  fit <- .pr_normalize_solver_result(p, raw, .pr_control())
  testthat::expect_identical(fit$status$normalized, "infeasible")
  testthat::expect_false(fit$incumbent_validated)
  testthat::expect_identical(fit$objective$bound_source, "missing")
  testthat::expect_true(is.na(fit$objective$risk_lower_bound))
  testthat::expect_true(is.na(fit$objective$risk_absolute_gap))
  # The backend's raw value is preserved as raw information.
  testthat::expect_identical(fit$objective$raw_lower_bound, .1)
})
