# 014 repair (CP-4): half of the validator's tolerances is passed to both
# backends (headroom so a solver-feasible incumbent passes the validator).
testthat::test_that("validator tolerances are passed to Gurobi and HiGHS within admissible ranges", {
  problem <- list(objective_units = list(scale = 1 / 3))
  control <- .pr_control(list(tolerances = list(feasibility = 1e-7, integrality = 1e-6)))
  g <- .pr_gurobi_params(problem, control)
  testthat::expect_equal(g$FeasibilityTol, 5e-8)
  testthat::expect_equal(g$IntFeasTol, 5e-7)
  h <- .pr_highs_options(problem, control)
  testthat::expect_equal(h$primal_feasibility_tolerance, 5e-8)
  # min(.5 * integrality, .1 * absolute_risk_gap / scale) = min(5e-7, 3e-9)
  testthat::expect_equal(h$mip_feasibility_tolerance, 3e-9)
  minimax_units <- list(objective_units = list(scale = 1))
  testthat::expect_equal(.pr_highs_options(minimax_units, control)$mip_feasibility_tolerance, 1e-9)
  wide <- .pr_control(list(absolute_risk_gap = 1))
  testthat::expect_equal(.pr_highs_options(problem, wide)$mip_feasibility_tolerance, 5e-7)
  strict <- .pr_control(list(tolerances = list(feasibility = 0, integrality = 0)))
  testthat::expect_identical(.pr_gurobi_params(problem, strict)$FeasibilityTol, 1e-9)
  testthat::expect_identical(.pr_gurobi_params(problem, strict)$IntFeasTol, 1e-9)
  testthat::expect_identical(.pr_highs_options(problem, strict)$mip_feasibility_tolerance, 1e-10)
  default <- .pr_gurobi_params(problem, .pr_control())
  testthat::expect_equal(c(default$FeasibilityTol, default$IntFeasTol), c(5e-8, 5e-7))
})

testthat::test_that("usable bound sources include clamped and engine LP bounds", {
  testthat::expect_setequal(.pr_usable_bound_sources(), c("backend_reported_dual_bound",
    "backend_reported_dual_bound_clamped", "engine_lp_relaxation_bound", "engine_lp_relaxation_bound_clamped"))
})

testthat::test_that("normalization accepts only known bound-source labels", {
  p <- pr_status_problem()
  for (source in list("made_up_bound", "backend_reported_dual_bound_clamped", c("a", "b"), NA_character_, 1)) {
    raw <- pr_status_raw(p, lower = -.3); raw$bound_source <- source
    fit <- .pr_normalize_solver_result(p, raw, .pr_control())
    testthat::expect_identical(fit$status$normalized, "numerical_error")
    testthat::expect_true("unrecognized_bound_source" %in% vapply(fit$numerical_issues, `[[`, "", "code"))
    testthat::expect_true(is.na(fit$objective$risk_lower_bound))
  }
  raw <- pr_status_raw(p, lower = -.3); raw$bound_source <- "engine_lp_relaxation_bound"
  fit <- .pr_normalize_solver_result(p, raw, .pr_control())
  testthat::expect_identical(fit$objective$bound_source, "engine_lp_relaxation_bound")
  testthat::expect_length(fit$numerical_issues, 0L)
})

testthat::test_that("an infeasible or unbounded status with a validated incumbent is flagged", {
  p <- pr_status_problem()
  for (status in c("infeasible", "unbounded")) {
    raw <- pr_status_raw(p); raw$status_normalized <- status
    fit <- .pr_normalize_solver_result(p, raw, .pr_control())
    testthat::expect_identical(fit$status$normalized, "numerical_error")
    testthat::expect_true("status_incumbent_contradiction" %in% vapply(fit$numerical_issues, `[[`, "", "code"))
    testthat::expect_true(fit$incumbent_validated); testthat::expect_true(is.na(fit$objective$risk_lower_bound))
  }
})

testthat::test_that("the backend objective is compared with its own unrounded primal", {
  p <- pr_status_problem(); raw <- pr_status_raw(p)
  labels <- p$index$labels
  raw$primal[labels] <- raw$primal[labels] + c(5e-7, -5e-7, 0)[seq_along(labels)]
  raw$raw_objective <- sum(p$model$objective * raw$primal)
  fit <- .pr_normalize_solver_result(p, raw, .pr_control())
  testthat::expect_false("objective_mismatch" %in% vapply(fit$numerical_issues, `[[`, "", "code"))
  raw$raw_objective <- raw$raw_objective + 1e-3
  fit <- .pr_normalize_solver_result(p, raw, .pr_control())
  testthat::expect_true("objective_mismatch" %in% vapply(fit$numerical_issues, `[[`, "", "code"))
})

testthat::test_that("Gurobi conversion tolerates missing row names and integer bounds", {
  model <- list(A = Matrix::sparseMatrix(i = c(1, 2), j = c(1, 2), x = c(1, 1), dims = c(2, 2)), objective = c(1, 1),
    var_lower = c(0, 0), var_upper = c(1, 1), row_lower = c(1L, -Inf), row_upper = c(Inf, 2L),
    types = c("C", "C"), var_names = c("a", "b"), row_names = NULL, sense = "min")
  out <- .pr_gurobi_model(model)
  testthat::expect_identical(out$model$constrnames, c("row1_lower", "row2_upper"))
  testthat::expect_identical(out$model$rhs, c(1, 2))
})

testthat::test_that("a raw primal whose residual rounding cannot explain is flagged", {
  p <- pr_status_problem(); raw <- pr_status_raw(p)
  z <- raw$primal; idx <- p$index
  g <- c(1, 2, 2); z[idx$labels] <- g
  z[idx$pairs] <- as.numeric(g[idx$pair_i] < g[idx$pair_j])
  first <- which(g[idx$pair_i] == 1 & g[idx$pair_j] == 2)[1L]
  # Labels within the integrality tolerance but pushed apart in the harmful
  # direction, and the pair binary just above its bound.
  z[idx$labels[1L]] <- 1 + 1e-6; z[idx$labels[idx$pair_j[first]]] <- 2 - 1e-6; z[idx$pairs[first]] <- 1 + 1e-6
  raw$primal <- z; raw$raw_objective <- sum(p$model$objective * z)
  fit <- .pr_normalize_solver_result(p, raw, .pr_control())
  testthat::expect_true(fit$incumbent_validated)
  testthat::expect_true("raw_primal_residual_excessive" %in% vapply(fit$numerical_issues, `[[`, "", "code"))
  testthat::expect_identical(fit$status$normalized, "numerical_error")
})
