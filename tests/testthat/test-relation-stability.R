pr_stability_input <- function() {
  x <- pr_test_payload(S = 7L, n = 3L, K = 2L, regime = "mcmc")
  for (s in 5:7) {
    x$joint_draws$draw_index[[s]]$chain_id <- "chain2"
    x$joint_draws$draw_index[[s]]$iteration <- s
  }
  x$joint_draws$sampling$chain_history <- list(
    list(chain_id = "chain1", retained_iterations = 3:6, warmup_iterations = 1:2,
      discarded_sampling_iterations = 7:8, selection_note = "Explicit original chain1 history"),
    list(chain_id = "chain2", retained_iterations = 5:7, warmup_iterations = 1:2,
      discarded_sampling_iterations = 3:4, selection_note = "Explicit original chain2 history"))
  as_postrank_draws(x)
}
pr_stability_settings <- function() list(weights = c(need1 = .5, need2 = .5), tau = .25, G_max = 3L)
pr_stability_config <- function() list(backend = "highs", control = list(seed = 17L, threads = 1L, time_limit = 1))
pr_stability_reference <- function(x) stats::setNames(rep(1L, length(x$entity_ids)), x$entity_ids)
pr_stability_mock_fit <- function(problem, control, grade = NULL, no_incumbent = FALSE) {
  if (is.null(grade)) grade <- rep(1L, length(problem$pairwise$entity_ids))
  primal <- numeric(length(problem$model$objective)); primal[problem$index$labels] <- grade
  primal[problem$index$pairs] <- as.numeric(grade[problem$index$pair_i] < grade[problem$index$pair_j])
  if (!is.null(problem$index$assignment)) primal[problem$index$assignment[cbind(seq_along(grade), grade)]] <- 1L
  evaluation <- postrank_evaluate(stats::setNames(grade, problem$pairwise$entity_ids), problem$pairwise,
    problem$settings$weights, problem$settings$tau, problem$settings$objective, problem$settings$minimax_criteria)
  if (!is.null(problem$index$t)) primal[problem$index$t] <- evaluation$primary_risk
  objective <- sum(primal * problem$model$objective)
  raw <- list(primal = if (no_incumbent) NULL else primal,
    raw_status = "EXPLICIT_TEST_MOCK", raw_message = "Unit-test mock; no backend was executed",
    status_normalized = if (no_incumbent) "time_limit" else "feasible_not_certified", termination_reason = "mock",
    has_incumbent = !no_incumbent, raw_objective = if (no_incumbent) NA_real_ else objective,
    raw_lower_bound = NA_real_, relative_gap = NA_real_, runtime = 0,
    backend = list(name = "highs_test_mock", options = list(random_seed = control$seed),
      wrapper_version = "mock", solver_version = NA_character_),
    raw = list(mock = TRUE), warnings = character())
  .pr_normalize_solver_result(problem, raw, control)
}

testthat::test_that("ordered joint subsets preserve values, identities and complete source history", {
  x <- pr_stability_input(); before <- .pr_identity(x)
  subset <- .pr_subset_joint_draws(x, c(1L, 2L, 5L, 6L))
  b <- subset$draws$joint_draws; receipt <- subset$receipt
  testthat::expect_identical(b$tensor$values, x$joint_draws$tensor$values[c(1L, 2L, 5L, 6L), , , drop = FALSE])
  testthat::expect_identical(vapply(b$draw_index, `[[`, character(1L), "original_draw_id"), c("orig1", "orig2", "orig5", "orig6"))
  testthat::expect_identical(vapply(b$draw_index, `[[`, integer(1L), "iteration"), c(3L, 4L, 5L, 6L))
  testthat::expect_equal(b$sampling$chain_history[[1L]]$discarded_sampling_iterations, 5:8)
  testthat::expect_equal(b$sampling$chain_history[[2L]]$discarded_sampling_iterations, c(3, 4, 7))
  testthat::expect_identical(b$sampling$chain_history[[1L]]$warmup_iterations, 1:2)
  testthat::expect_identical(receipt$source_sampling, x$joint_draws$sampling)
  testthat::expect_identical(receipt$source_input_identity, x$validation$input_identity)
  testthat::expect_identical(receipt$derived_input_identity, subset$draws$validation$input_identity)
  testthat::expect_identical(receipt$derived_provenance, subset$draws$provenance)
  testthat::expect_false(identical(receipt$derived_input_identity, receipt$source_input_identity))
  testthat::expect_true(receipt$local_subset_values_checked)
  testthat::expect_false(receipt$independent_resampling)
  testthat::expect_identical(.pr_identity(x), before)
  omitted <- .pr_subset_joint_draws(x, 1:4)
  testthat::expect_identical(omitted$receipt$omitted_chain_ids, "chain2")
  testthat::expect_length(omitted$draws$joint_draws$sampling$chain_history, 1L)
  testthat::expect_length(omitted$receipt$source_sampling$chain_history, 2L)
  testthat::expect_equal(omitted$receipt$omitted_chain_histories[[1L]]$discarded_sampling_iterations, 3:7)
  testthat::expect_length(omitted$receipt$omitted_chain_histories[[1L]]$retained_iterations, 0L)
  full <- .pr_subset_joint_draws(x, 1:7)
  testthat::expect_identical(full$draws, x)
  testthat::expect_identical(full$receipt$derived_provenance, x$provenance)
  testthat::expect_true(full$receipt$is_identity_subset)
})

testthat::test_that("subset rows cannot be duplicated, reordered, empty or out of range", {
  x <- pr_stability_input()
  for (rows in list(c(2L, 1L), c(1L, 1L), integer(), 8L))
    testthat::expect_error(.pr_subset_joint_draws(x, rows), class = "postrank_input_error")
  one <- .pr_subset_joint_draws(x, 1L)
  testthat::expect_identical(dim(one$draws$joint_draws$tensor$values), c(1L, 3L, 2L))
})

testthat::test_that("relation stability separates reversals and withheld-public changes", {
  ids <- c("001", "002", "003")
  ref <- stats::setNames(c(1, 1, 2), ids)
  candidate <- stats::setNames(c(1, 2, 1), ids)
  comparison <- .pr_compare_stability_relations(ref, candidate, ids)
  testthat::expect_identical(comparison$direction_reversals, 1L)
  testthat::expect_identical(comparison$public_to_withheld, 1L)
  testthat::expect_identical(comparison$withheld_to_public, 1L)
  testthat::expect_identical(comparison$changed, 3L)
  same <- .pr_compare_stability_relations(ref, stats::setNames(c(10, 10, 20), ids), ids)
  testthat::expect_identical(same$changed, 0L)
  testthat::expect_identical(same$agreement_rate, 1)
  four_ids <- c("a", "b", "c", "d")
  four <- stats::setNames(c(1, 2, 1, 2), four_ids)
  testthat::expect_identical(.pr_compare_stability_relations(four, four, four_ids)$reference_relation,
    c(1, 0, 1, -1, 0, 1))
})

testthat::test_that("stability planning is explicit, bounded and never clamps chain prefixes", {
  x <- pr_stability_input(); cfg <- pr_stability_config()
  disabled <- .pr_diagnose_stability(NULL, NULL, NULL, NULL)
  testthat::expect_identical(disabled$solve_calls, 0L)
  testthat::expect_identical(disabled$status, "not_requested")
  cfg$prefixes <- 2L; cfg$chain_subsets <- list(all = c("chain1", "chain2"), first = "chain1")
  cfg$settings_grid <- list(base = list(), tau_low = list(tau = .2))
  prep <- .pr_prepare_stability(x, pr_stability_reference(x), pr_stability_settings(), cfg)
  testthat::expect_identical(prep$planned_attempts, 8L)
  testthat::expect_identical(vapply(prep$selections, function(s) s$draws$joint_draws$tensor$shape$S, integer(1L)), c(7L, 4L, 4L, 2L))
  too_many <- cfg; too_many$prefixes <- 1:3
  testthat::expect_error(.pr_prepare_stability(x, pr_stability_reference(x), pr_stability_settings(), too_many), "max_solves", class = "postrank_input_error")
  too_long <- cfg; too_long$prefixes <- 4L
  testthat::expect_error(.pr_prepare_stability(x, pr_stability_reference(x), pr_stability_settings(), too_long), "no truncation", class = "postrank_input_error")
  implicit_backend <- cfg; implicit_backend$backend <- NULL
  testthat::expect_error(.pr_prepare_stability(x, pr_stability_reference(x), pr_stability_settings(), implicit_backend), class = "postrank_input_error")
  multithreaded <- cfg; multithreaded$control$threads <- 2L
  testthat::expect_error(.pr_prepare_stability(x, pr_stability_reference(x), pr_stability_settings(), multithreaded), "threads=1", class = "postrank_input_error")
  too_many_grids <- cfg; too_many_grids$settings_grid <- rep(list(list()), 7L)
  testthat::expect_error(.pr_prepare_stability(x, pr_stability_reference(x), pr_stability_settings(), too_many_grids), "1 to 6", class = "postrank_input_error")
})

testthat::test_that("all planned attempts retain errors, missing incumbents, settings and actual seeds", {
  x <- pr_stability_input(); cfg <- pr_stability_config()
  cfg$prefixes <- 2L; cfg$chain_subsets <- list(all = c("chain1", "chain2"), first = "chain1")
  cfg$settings_grid <- list(base = list(), tau_low = list(tau = .2))
  prep <- .pr_prepare_stability(x, pr_stability_reference(x), pr_stability_settings(), cfg)
  count <- 0L
  mock <- function(problem, backend, control) {
    count <<- count + 1L
    if (count == 2L) .pr_stop("Explicit mocked unavailable backend", "postrank_backend_unavailable", "test_backend_unavailable")
    pr_stability_mock_fit(problem, control, no_incumbent = count == 3L)
  }
  result <- .pr_execute_stability(prep, mock)
  testthat::expect_identical(count, 8L)
  testthat::expect_identical(result$attempt_count, 8L)
  testthat::expect_identical(result$solve_calls, 8L)
  testthat::expect_identical(result$error_count, 1L)
  testthat::expect_identical(result$no_valid_incumbent_count, 1L)
  testthat::expect_identical(result$valid_incumbent_count, 6L)
  testthat::expect_identical(result$attempts[[2L]]$error$code, "test_backend_unavailable")
  testthat::expect_identical(result$attempts[[3L]]$status$normalized, "time_limit")
  testthat::expect_null(result$attempts[[3L]]$comparison)
  testthat::expect_identical(result$attempts[[1L]]$actual_seed, 17)
  testthat::expect_true(is.na(result$attempts[[2L]]$actual_seed))
  testthat::expect_identical(result$attempts[[1L]]$settings$tau, .25)
  testthat::expect_identical(result$attempts[[2L]]$settings$tau, .2)
  testthat::expect_true(all(vapply(result$attempts, function(a) nzchar(a$input_identity) && nzchar(a$selection_identity), logical(1L))))
  testthat::expect_false(result$independent_resampling)
  testthat::expect_false(result$convergence_verified)
  testthat::expect_match(result$interpretation, "Every planned attempt")
})

testthat::test_that("problem-construction failures stay in the planned-attempt denominator", {
  x <- as_postrank_draws(pr_test_payload()); cfg <- pr_stability_config()
  cfg$settings_grid <- list(invalid_tau = list(tau = -1), baseline = list())
  prep <- .pr_prepare_stability(x, pr_stability_reference(x), pr_stability_settings(), cfg)
  count <- 0L
  mock <- function(problem, backend, control) {count <<- count + 1L; pr_stability_mock_fit(problem, control)}
  result <- .pr_execute_stability(prep, mock)
  testthat::expect_identical(result$attempt_count, 2L)
  testthat::expect_identical(result$solve_calls, 1L)
  testthat::expect_identical(count, 1L)
  testthat::expect_identical(result$error_count, 1L)
  testthat::expect_identical(result$attempts[[1L]]$error$phase, "problem_construction")
  testthat::expect_identical(result$attempts[[1L]]$settings$tau, -1)
  testthat::expect_identical(result$attempts[[2L]]$attempt_status, "completed_with_valid_incumbent")
})

testthat::test_that("scope and full-input reference checks remain explicit", {
  x <- pr_stability_input(); cfg <- pr_stability_config()
  problem <- postrank_problem(postrank_pairwise(x), c(need1 = .5, need2 = .5), .25, 3L)
  fit <- pr_stability_mock_fit(problem, .pr_control(cfg$control))
  prep <- .pr_prepare_stability(x, NULL, NULL, cfg, fit)
  testthat::expect_identical(prep$reference_grade, fit$grade)
  fit$input_identity <- "different-full-input"
  testthat::expect_error(.pr_prepare_stability(x, NULL, NULL, cfg, fit), "input differs", class = "postrank_input_error")
  testthat::expect_error(.pr_prepare_stability(pr_test_criterionwise(), pr_stability_reference(x), pr_stability_settings(), cfg),
    "joint equal-weight", class = "postrank_input_error")
  iid <- pr_test_payload(); prefixes <- cfg; prefixes$prefixes <- 2L
  testthat::expect_error(.pr_prepare_stability(iid, pr_stability_reference(x), pr_stability_settings(), prefixes),
    "joint iid", class = "postrank_input_error")
  noncanonical <- stats::setNames(rep(2L, 3L), x$entity_ids)
  testthat::expect_error(.pr_prepare_stability(x, noncanonical, pr_stability_settings(), cfg), "canonical occupied", class = "postrank_input_error")
})
