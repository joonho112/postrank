# T-obj-06 / T-base-10 / T-base-11 and the comparison row contract.
cmp_mock <- function(grade = "auto", status = "optimal") function(problem, backend, control, strategy) {
  ids <- problem$pairwise$entity_ids
  g <- if (is.null(grade)) NULL else if (identical(grade, "auto")) stats::setNames(c(1L, rep(2L, length(ids) - 1L)), ids) else grade[ids]
  primal <- if (is.null(g)) NULL else .pr_engine_primal(problem, g)
  obj <- if (is.null(primal)) NA_real_ else sum(problem$model$objective * primal)
  .pr_normalize_solver_result(problem, list(primal = primal, raw_status = "MOCK", raw_message = "mock", status_normalized = status,
    termination_reason = "mock", has_incumbent = !is.null(primal), raw_objective = obj, raw_lower_bound = obj,
    relative_gap = NA_real_, runtime = 0, backend = list(name = backend, wrapper_version = "mock", solver_version = NA_character_,
      options = list()), raw = list(execution_scope = "mock", native_solver_called = FALSE), warnings = character(),
    bound_source = "backend_reported_dual_bound"), .pr_control(control))
}
cw <- c(need_A = .6, need_B = .4)

test_that("comparison rows, relation accounting and the reference direction (T-base-11)", {
  local_mocked_bindings(.pr_solve_core = cmp_mock())
  a <- postrank(postrank_toy, weights = cw, tau = .25, G_max = 3L, backend = "highs", fragility = FALSE)
  cmp <- postrank_compare(a)
  expect_s3_class(cmp, "postrank_comparison")
  expect_identical(cmp$table$method, c("joint", "expected_rank", "composite"))
  expect_identical(names(cmp$table)[1:10], c("method", "risk", "N", "disclosure_rate", "G", "status", "optimality_scope", "reason",
    "risk_lower_bound", "risk_absolute_gap"))
  expect_true(all(is.na(cmp$table$risk_lower_bound[-1])))
  expect_identical(cmp$table$status[-1], c("optimal", "optimal"))
  M <- 3
  r <- cmp$relations
  expect_true(all(r$n_same + r$n_new_disclosed + r$n_new_withheld + r$n_reversed == M))
  expect_equal(r$agreement, r$n_same / M)
  same <- postrank_compare(a, joint_again = get_grades(a), baselines = character())
  expect_equal(same$relations$n_same, M)
  g <- get_grades(a); flipped <- g; flipped[c("001", "site-B")] <- g[c("site-B", "001")]
  rev1 <- postrank_compare(a, flipped = flipped, baselines = character())
  expect_equal(rev1$relations$n_reversed, 1)
  expect_identical(rev1$table$status[2], "evaluated")
  expect_identical(dim(cmp$relation_codes), c(3L, 3L, 3L))
})

test_that("mixed policies or inputs are refused; a different label is accepted (T-obj-06, T-base-10)", {
  local_mocked_bindings(.pr_solve_core = cmp_mock())
  a <- postrank(postrank_toy, weights = cw, tau = .25, G_max = 3L, backend = "highs", fragility = FALSE)
  pw <- postrank_pairwise(postrank_toy)
  other_tau <- postrank_cuts(postrank_expected_rank(pw, cw), pw, postrank_settings(cw, .3, 3L))
  e <- tryCatch(postrank_compare(a, other_tau), error = identity)
  expect_s3_class(e, "postrank_input_error"); expect_identical(e$code, "comparison_settings_mismatch")
  relabel <- postrank_cuts(postrank_expected_rank(pw, cw), pw, postrank_settings(cw, .25, 3L, label = "another label"))
  ok <- postrank_compare(a, relabel, baselines = character())
  expect_identical(nrow(ok$table), 2L)
  ex_pw <- postrank_pairwise(pr_example_draws); w3 <- c(poverty = .5, frl = .25, snap = .25)
  foreign <- postrank_cuts(postrank_expected_rank(ex_pw, w3), ex_pw, postrank_settings(w3, .25, 3L))
  e <- tryCatch(postrank_compare(a, foreign), error = identity)
  expect_identical(e$code, "comparison_input_mismatch")
})

test_that("missing means, no-incumbent fits and impossible baselines keep explicit rows", {
  local_mocked_bindings(.pr_solve_core = cmp_mock())
  pw <- postrank_pairwise(postrank_toy)
  fit <- postrank_solve(postrank_problem(pw, cw, .25, 3L), backend = "highs")
  e <- tryCatch(postrank_compare(fit), error = identity); expect_identical(e$code, "missing_posterior_means")
  expect_s3_class(postrank_compare(fit, baselines = "expected_rank"), "postrank_comparison")
  expect_s3_class(postrank_compare(fit, means = postrank_posterior_means(postrank_toy)), "postrank_comparison")
  local_mocked_bindings(.pr_solve_core = cmp_mock(grade = NULL, status = "time_limit"))
  nofit <- postrank_solve(postrank_problem(pw, cw, .25, 3L), backend = "highs")
  e <- tryCatch(postrank_compare(nofit, baselines = "expected_rank"), error = identity)
  expect_identical(e$code, "no_validated_incumbent")
  local_mocked_bindings(.pr_solve_core = cmp_mock())
  c2 <- postrank_compare(fit, timed_out = nofit, baselines = "expected_rank")
  row <- c2$table[c2$table$method == "timed_out", ]
  expect_identical(row$status, "time_limit"); expect_identical(row$reason, "no_validated_incumbent"); expect_true(is.na(row$risk))
  expect_true(is.na(c2$relations$n_same[c2$relations$method == "timed_out"]))
  # exact_G larger than the number of exact-score blocks: a not_comparable row.
  s <- postrank_settings(cw, .25, 3L, exact_G = 3L)
  local_mocked_bindings(.pr_solve_core = cmp_mock(grade = c("001" = 1L, "site-B" = 2L, "site C" = 3L)))
  a3 <- postrank(postrank_toy, settings = s, backend = "highs", fragility = FALSE, report_card = FALSE)
  local_mocked_bindings(postrank_expected_rank = function(pairwise, weights = NULL) structure(c(`001` = 1, `site-B` = 1, `site C` = 2), score_method = "expected_rank"))
  c3 <- postrank_compare(a3, baselines = "expected_rank")
  r3 <- c3$table[c3$table$method == "expected_rank", ]
  expect_identical(r3$status, "not_comparable"); expect_identical(r3$reason, "exact_G_exceeds_blocks")
})

test_that("tier 2: joint, ER and composite on the 30 x 3 example (HiGHS)", {
  skip_if_not_installed("highs")
  a <- postrank(pr_example_draws, weights = c(poverty = .5, frl = .25, snap = .25), tau = .35, G_max = 4L,
    backend = "highs", control = postrank_control(time_limit = 30), fragility = FALSE, report_card = FALSE)
  cmp <- postrank_compare(a)
  expect_identical(cmp$table$status[1], a$fit$status$normalized)
  # Numerical full-family risk is no worse than either restricted baseline, up to the reported gap.
  gap <- a$fit$objective$risk_absolute_gap
  expect_true(all(cmp$table$risk[1] <= cmp$table$risk[-1] + gap + 1e-9))
})
