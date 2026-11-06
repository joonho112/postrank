# T-obj-05: report-card counts, independent summaries and the skewed finite-law
# counterexample (mean outside the central interval); missing sources are refused.
rc_mock <- function(grade) function(problem, backend, control, strategy) {
  primal <- .pr_engine_primal(problem, grade[problem$pairwise$entity_ids])
  obj <- sum(problem$model$objective * primal)
  .pr_normalize_solver_result(problem, list(primal = primal, raw_status = "MOCK", raw_message = "mock",
    status_normalized = "optimal", termination_reason = "mock", has_incumbent = TRUE, raw_objective = obj,
    raw_lower_bound = obj, relative_gap = NA_real_, runtime = 0,
    backend = list(name = backend, wrapper_version = "mock", solver_version = NA_character_, options = list()),
    raw = list(execution_scope = "mock", native_solver_called = FALSE), warnings = character(),
    bound_source = "backend_reported_dual_bound"), .pr_control(control))
}

test_that("counts sum to n - 1 and draw summaries match independent calculations", {
  local_mocked_bindings(.pr_solve_core = rc_mock(c("001" = 1L, "site-B" = 2L, "site C" = 2L)))
  a <- postrank(postrank_toy, weights = c(need_A = .6, need_B = .4), tau = .25, G_max = 3L, backend = "highs", fragility = FALSE)
  d <- a$report_card$data
  expect_identical(d$n_above + d$n_below + d$n_withheld, rep(2L, 3))
  expect_identical(d$entity_id[1], "001"); expect_identical(d$sort_rank, 1:3)
  v <- postrank_toy$joint_draws$tensor$values
  for (k in c("need_A", "need_B")) for (i in d$entity_id) {
    r <- match(i, d$entity_id)
    expect_equal(d[[paste0("mean_", k)]][r], mean(v[, i, k]))
    q <- stats::quantile(v[, i, k], c(.05, .95), type = 7, names = FALSE)
    expect_equal(c(d[[paste0("lower_", k)]][r], d[[paste0("upper_", k)]][r]), q)
    pw <- postrank_pairwise(postrank_toy)
    expect_equal(d[[paste0("expected_rank_", k)]][r], 1 + sum(pw$e[i, , k], na.rm = TRUE))
  }
  expect_true(all(d[grep("^lower_", names(d))] <= d[grep("^upper_", names(d))]))
  expect_identical(a$report_card$grade_identity, a$fit$solution_identity$relation_identity)
  card2 <- postrank_report_card(a, level = .5, order = "label")
  expect_identical(card2$level, .5); expect_identical(card2$secondary_order, "label")
})

test_that("a skewed finite law has its mean outside the central interval (T-obj-05 counterexample)", {
  x <- pr_test_exact()
  a <- matrix(c(0, 1, 2, 0, 1, 2), 3, 2, dimnames = list(entity = x$entity_ids, criterion = x$criterion_ids))
  b <- a; b[1, ] <- 100
  x$finite_law <- list(denominator = 100L, value_representation = "safe_integer",
    states = list(list(state_id = "s1", mass_numerator = 99L, theta = a), list(state_id = "s2", mass_numerator = 1L, theta = b)),
    law_definition = "Skewed two-state law: masses .99 and .01; entity 001 is 0 or 100", not_empirical_posterior_relabeling = TRUE)
  x$tie_policy$justification <- "Distinct site values within each declared state"
  ex <- as_postrank_draws(x)
  s <- postrank_posterior_means(ex, level = .90)
  expect_equal(s["001", "need1"], 1)
  expect_identical(attr(s, "lower")["001", "need1"], 0); expect_identical(attr(s, "upper")["001", "need1"], 0)
  expect_identical(attr(s, "interval_source"), "exact_finite_law")
  expect_gt(s["001", "need1"], attr(s, "upper")["001", "need1"])
})

test_that("Gaussian and mixture quantiles match analytic and root-finding references", {
  s <- postrank_posterior_means(pr_example_gaussian, level = .9)
  sd <- sqrt(pr_example_gaussian$source$covariance["frl", "frl", "site007"])
  expect_equal(attr(s, "lower")["site007", "frl"], stats::qnorm(.05, s["site007", "frl"], sd))
  ids <- c("A", "B"); ks <- "k1"
  cov <- array(.5, c(1, 1, 2), dimnames = list(criterion_i = ks, criterion_j = ks, entity = ids))
  st <- function(d) list(mu = c(k1 = d), Sigma = matrix(1, 1, 1, dimnames = list(criterion_i = ks, criterion_j = ks)),
    means = matrix(c(d, .4), 2, 1, dimnames = list(entity = ids, criterion = ks)), covariance = cov)
  mx <- postrank_mixture_coefficients(list(s1 = st(-1), s2 = st(1)), c(s1 = .5, s2 = .5), data.frame(state_id = c("s1", "s2")),
    "fixed_finite_mixture", "entities_given_shared_h", list(producer_id = "test", producer_version = "1", posterior_id = "toy",
      input_payload_sha256 = strrep("a", 64), source_sha256 = strrep("b", 64), config_sha256 = strrep("c", 64)))
  m <- postrank_posterior_means(mx, level = .8)
  F <- function(t) .5 * stats::pnorm((t + 1) / sqrt(.5)) + .5 * stats::pnorm((t - 1) / sqrt(.5))
  expect_lt(abs(F(attr(m, "lower")["A", "k1"]) - .1), 1e-9)
  expect_lt(abs(F(attr(m, "upper")["A", "k1"]) - .9), 1e-9)
  expect_identical(attr(m, "interval_source"), "mixture_analytic")
  expect_error(postrank_posterior_means(postrank_pairwise(postrank_toy)), "postrank_draws")
  expect_error(postrank_posterior_means(postrank_toy, level = 1), "level")
})

test_that("a bare-pairwise fit needs explicit draws; mismatched draws are refused", {
  local_mocked_bindings(.pr_solve_core = rc_mock(c("001" = 1L, "site-B" = 2L, "site C" = 2L)))
  pw <- postrank_pairwise(postrank_toy)
  fit <- postrank_solve(postrank_problem(pw, c(need_A = .6, need_B = .4), .25, 3L), backend = "highs")
  e <- tryCatch(postrank_report_card(fit), error = identity); expect_identical(e$code, "missing_posterior_source")
  card <- postrank_report_card(fit, draws = postrank_toy)
  expect_s3_class(card, "postrank_report_card")
  e <- tryCatch(postrank_report_card(fit, draws = pr_example_draws), error = identity)
  expect_identical(e$code, "diagnostic_input_mismatch")
})
