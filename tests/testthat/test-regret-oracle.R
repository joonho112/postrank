pr_regret_test_design <- function(S = 100) list(sample_sizes_fixed_before_sampling = TRUE,
  alpha_fixed_before_sampling = TRUE, adaptive_stopping = FALSE,
  planned_sample_sizes = c(need1 = S, need2 = S), declaration_note = "Explicit fixed synthetic design.")
pr_regret_test_fit <- function(problem, grade = stats::setNames(rep(1L, 3), problem$pairwise$entity_ids), lower = -.3) {
  primal <- rep(0, length(problem$model$objective)); primal[problem$index$labels] <- grade
  primal[problem$index$pairs] <- as.numeric(grade[problem$index$pair_i] < grade[problem$index$pair_j])
  if (!is.null(problem$index$assignment)) {
    primal[problem$index$assignment] <- 0
    for (i in seq_along(grade)) primal[problem$index$assignment[i, grade[i]]] <- 1
  }
  if (!is.null(problem$index$t)) primal[problem$index$t] <- .5
  objective <- sum(problem$model$objective * primal)
  raw <- list(primal = primal, raw_status = "mock", raw_message = "pure test mock",
    status_normalized = "time_limit", termination_reason = "time_limit", has_incumbent = TRUE,
    raw_objective = objective, raw_lower_bound = lower, relative_gap = 999, runtime = 0,
    backend = list(name = "pure_mock"), raw = list(), warnings = character())
  .pr_normalize_solver_result(problem, raw, .pr_control())
}

testthat::test_that("regret uses the full normalized absolute risk gap and supports fixed exact-G", {
  x <- pr_test_payload(S = 100L); pairwise <- postrank_pairwise(x)
  b <- postrank_iid_bounds(x, .05, c(need1 = .02, need2 = .03), pr_regret_test_design())
  problem <- postrank_problem(pairwise, c(need1 = .25, need2 = .75), .25, 3)
  fit <- pr_regret_test_fit(problem)
  out <- postrank_regret_bound(fit, b)
  testthat::expect_s3_class(out, "postrank_regret_bound")
  testthat::expect_equal(out$delta_w, sum(problem$settings$weights * b$epsilon))
  testthat::expect_equal(out$eta, .1, tolerance = 1e-15)
  testthat::expect_equal(out$regret_upper_bound, 2 * out$delta_w + .1)
  testthat::expect_identical(out$eta_source, "normalized_whole_problem_risk_absolute_gap")
  testthat::expect_identical(out$guarantee_status, "conditional_bound")
  testthat::expect_false(out$numerically_verified)
  testthat::expect_false(out$guarantee_issued)
  fit$objective$solver_relative_gap <- 0
  testthat::expect_identical(postrank_regret_bound(fit, b)$eta, out$eta)
  exact <- postrank_problem(pairwise, c(need1 = .25, need2 = .75), .25, 3, exact_G = 2)
  g <- stats::setNames(c(1L, 2L, 2L), pairwise$entity_ids)
  exact_result <- postrank_regret_bound(pr_regret_test_fit(exact, g, lower = -1), b)
  testthat::expect_true(exact_result$bound_computed)
  testthat::expect_identical(exact_result$action_space$type, "exact_G")
  testthat::expect_equal(exact_result$action_space$exact_G, 2)
})

testthat::test_that("missing or rejected bounds and invalid primals never invent eta", {
  x <- pr_test_payload(S = 100L); p <- postrank_problem(postrank_pairwise(x), c(need1 = .5, need2 = .5), .25, 3)
  b <- postrank_iid_bounds(x, .05, c(need1 = .02, need2 = .02), pr_regret_test_design())
  for (lower in c(NA_real_, .01)) {
    result <- postrank_regret_bound(pr_regret_test_fit(p, lower = lower), b)
    testthat::expect_identical(result$guarantee_status, "not_established")
    testthat::expect_false(result$bound_computed)
    testthat::expect_true(is.na(result$eta))
    testthat::expect_true(is.na(result$regret_upper_bound))
    testthat::expect_false(result$finite_sample_certificate)
  }
  # 014 repair policy (CP-3): a within-tolerance inversion is clamped (gap 0)
  # and remains a usable whole-problem bound, so eta is 0 rather than unavailable.
  clamped <- postrank_regret_bound(pr_regret_test_fit(p, lower = 1e-12), b)
  testthat::expect_true(clamped$bound_computed)
  testthat::expect_identical(clamped$eta, 0)
  testthat::expect_false(clamped$finite_sample_certificate)
  fit <- pr_regret_test_fit(p); fit$objective$risk_absolute_gap <- 0
  testthat::expect_identical(postrank_regret_bound(fit, b)$unavailable_reason, "normalized_risk_gap_is_inconsistent")
  fit <- pr_regret_test_fit(p); fit$raw_solution[p$index$labels[1]] <- 1.5
  testthat::expect_identical(postrank_regret_bound(fit, b)$unavailable_reason, "no_independently_validated_incumbent")
  fit <- pr_regret_test_fit(p); fit$raw_solution <- NULL; fit$incumbent_validated <- FALSE
  testthat::expect_identical(postrank_regret_bound(fit, b)$guarantee_status, "not_established")
})

testthat::test_that("the action-risk consistency check uses risk units (014 repair R3)", {
  x <- pr_test_payload(S = 100L); p <- postrank_problem(postrank_pairwise(x), c(need1 = .5, need2 = .5), .25, 3)
  b <- postrank_iid_bounds(x, .05, c(need1 = .02, need2 = .02), pr_regret_test_design())
  fit <- pr_regret_test_fit(p)
  validation <- validate_postrank_solution(p, fit$raw_solution, fit$solution_validation$tolerances)
  risk_tolerance <- p$objective_units$scale * .pr_objective_tolerance_raw(validation$tolerances$objective,
    .pr_objective_reference(p$model$objective, validation$rounded_solution))
  testthat::expect_lt(risk_tolerance, validation$tolerances$objective)
  shifted <- function(delta) {
    f <- fit; f$objective$risk_upper_bound <- f$objective$risk_upper_bound + delta
    f$objective$risk_absolute_gap <- f$objective$risk_upper_bound - f$objective$risk_lower_bound
    postrank_regret_bound(f, b)
  }
  # Between the risk-unit and raw-unit tolerances: rejected now, accepted before.
  far <- shifted(mean(c(risk_tolerance, validation$tolerances$objective)))
  testthat::expect_false(far$bound_computed)
  testthat::expect_identical(far$unavailable_reason, "normalized_objective_units_or_values_are_inconsistent")
  testthat::expect_true(shifted(risk_tolerance / 4)$bound_computed)
})

testthat::test_that("q, minimax, input mismatch, changed fit settings and manual eta are unsupported", {
  x <- pr_test_payload(S = 100L); pw <- postrank_pairwise(x); w <- c(need1 = .5, need2 = .5)
  b <- postrank_iid_bounds(x, .05, c(need1 = .02, need2 = .02), pr_regret_test_design())
  q <- postrank_problem(pw, w, .25, 3, q = c(need1 = .5))
  testthat::expect_error(postrank_regret_bound(pr_regret_test_fit(q), b), "q constraints")
  m <- postrank_problem(pw, w, .25, 3, objective = "minimax")
  testthat::expect_error(postrank_regret_bound(pr_regret_test_fit(m), b), "does not support minimax")
  p <- postrank_problem(pw, w, .25, 3); fit <- pr_regret_test_fit(p)
  other <- x; other$context$data_version <- "other"
  other_bound <- postrank_iid_bounds(other, .05, c(need1 = .02, need2 = .02), pr_regret_test_design())
  testthat::expect_error(postrank_regret_bound(fit, other_bound), "exactly the same input")
  fit$settings$tau <- .2
  testthat::expect_error(postrank_regret_bound(fit, b), "changed after normalization")
  fit <- pr_regret_test_fit(p)
  testthat::expect_error(postrank_regret_bound(fit, b, eta = 0), "unused argument")
  fit$grade[1] <- 2L
  testthat::expect_error(postrank_regret_bound(fit, b), "reconstructed primal")
  bad <- b; bad$finite_sample_certificate <- TRUE
  testthat::expect_error(postrank_regret_bound(pr_regret_test_fit(p), bad), "changed after construction")
})

testthat::test_that("independent binary-rational enumeration verifies uniform risk and regret inequalities", {
  # Coefficient probabilities and tau below are binary rational. Dividing by
  # M still uses ordinary floating arithmetic. Actions are enumerated directly,
  # independently of the model rows; this is not a numerical certificate.
  states <- list(c(3, 2, 1), c(2, 3, 1), c(1, 2, 3), c(3, 1, 2))
  e_true <- Reduce(`+`, lapply(states, function(v) outer(v, v, `<=`))) / 4
  e_empirical <- Reduce(`+`, lapply(states[c(1, 1, 2, 3)], function(v) outer(v, v, `<=`))) / 4
  epsilon <- max(abs(e_empirical - e_true)); M <- 3; tau <- .25
  grades <- as.matrix(expand.grid(rep(list(1:3), 3)))
  risk <- function(g, e) { x <- outer(g, g, `<`); (sum(e[x]) + tau * (M - sum(x))) / M }
  truth <- apply(grades, 1, risk, e = e_true)
  empirical <- apply(grades, 1, risk, e = e_empirical)
  N <- apply(grades, 1, function(g) sum(outer(g, g, `<`)))
  testthat::expect_true(all(abs(empirical - truth) <= N / M * epsilon + 1e-15))
  chosen <- which.min(empirical); true_best <- min(truth)
  testthat::expect_true(truth[chosen] - true_best <= 2 * epsilon)
  testthat::expect_equal(risk(c(1, 1, 1), e_true), tau)
  testthat::expect_equal(risk(c(1, 1, 1), e_empirical), tau)
  # A nonoptimal empirical candidate uses an actual absolute eta, not 0.
  candidate <- which.max(empirical); eta <- empirical[candidate] - min(empirical)
  testthat::expect_true(truth[candidate] - true_best <= 2 * epsilon + eta)
  testthat::expect_true(eta > 0)
})
