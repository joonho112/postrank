# T-obj-03 / T-api-01: postrank() composition, capability-gated extras, no-incumbent
# branch and failure records. Solves are mocked unless the test is tier 2 (HiGHS).
ac_w <- c(need_A = .6, need_B = .4)
# A deterministic stand-in for the solver: returns the normalized fit of a fixed grade.
ac_mock_fit <- function(grade = c("001" = 1L, "site-B" = 2L, "site C" = 2L), status = "optimal") {
  force(grade)
  function(problem, backend, control, strategy) {
    ids <- problem$pairwise$entity_ids
    g <- if (is.null(grade)) NULL else if (identical(grade, "auto")) stats::setNames(c(1L, rep(2L, length(ids) - 1L)), ids) else grade[ids]
    primal <- if (is.null(g)) NULL else .pr_engine_primal(problem, g)
    obj <- if (is.null(primal)) NA_real_ else sum(problem$model$objective * primal)
    raw <- list(primal = primal, raw_status = "MOCK", raw_message = "mock", status_normalized = status,
      termination_reason = "mock", has_incumbent = !is.null(primal), raw_objective = obj,
      raw_lower_bound = obj, relative_gap = NA_real_, runtime = 0,
      backend = list(name = backend, wrapper_version = "mock", solver_version = NA_character_, options = list()),
      raw = list(execution_scope = "mock", native_solver_called = FALSE), warnings = character(),
      bound_source = "backend_reported_dual_bound")
    .pr_normalize_solver_result(problem, raw, .pr_control(control))
  }
}

test_that("postrank() composes the long form exactly under the same mocked solve", {
  local_mocked_bindings(.pr_solve_core = ac_mock_fit())
  a <- postrank(postrank_toy, weights = ac_w, tau = .25, G_max = 3L, backend = "highs", fragility = FALSE)
  expect_s3_class(a, "postrank_analysis")
  expect_identical(names(a), c("input", "pairwise", "settings", "control", "problem", "fit", "evaluation", "report_card",
    "fragility", "crossfit", "diagnostics", "backend", "metadata", "extras", "timings", "schema_version", "provenance", "warnings"))
  pw <- postrank_pairwise(postrank_toy)
  prob <- postrank_problem(pw, settings = postrank_settings(ac_w, .25, 3L))
  fit <- postrank_solve(prob, backend = "highs", control = postrank_control())
  expect_identical(a$problem$problem_identity, prob$problem_identity)
  expect_identical(a$fit$grade, fit$grade)
  expect_identical(a$evaluation, fit$evaluation)
  expect_identical(a$fit$objective, fit$objective)
  expect_identical(a$backend$name, "highs"); expect_identical(a$backend$resolution, "explicit")
  expect_identical(get_grades(a), get_grades(fit))
  expect_identical(get_relations(a), .pr_relations(fit$grade))
  expect_true(.pr_validate_analysis(a))
})

test_that("default extras follow the capability table and reason precedence", {
  local_mocked_bindings(.pr_solve_core = ac_mock_fit("auto"))
  a <- postrank(postrank_toy, weights = ac_w, tau = .25, G_max = 3L, backend = "highs")
  expect_true(a$extras$report_card$available); expect_s3_class(a$report_card, "postrank_report_card")
  expect_true(a$extras$fragility$available); expect_s3_class(a$fragility, "postrank_mc_fragility")
  expect_identical(a$extras$crossfit$reason, "not_requested"); expect_null(a$crossfit)
  expect_identical(a$extras$diagnostics$reason, "not_requested"); expect_null(a$diagnostics)
  for (e in names(a$extras)) expect_identical(names(a$extras[[e]]), c("requested", "supported", "available", "reason", "condition"))
  expect_identical(a$fragility$input_identity, a$fit$input_identity)
  # Exact finite law: fragility unsupported, report card from the finite law.
  ex <- as_postrank_draws(pr_test_exact())
  b <- postrank(ex, weights = c(need1 = .5, need2 = .5), tau = .25, G_max = 3L, backend = "highs", diagnostics = TRUE)
  expect_identical(b$extras$fragility$reason, "unsupported_input_kind"); expect_false(b$extras$fragility$supported)
  expect_identical(b$report_card$interval_source, "exact_finite_law")
  expect_true(b$extras$diagnostics$available)
  # Criterionwise draws.
  cw <- as_postrank_draws(pr_test_criterionwise())
  d <- postrank(cw, weights = c(need1 = .5, need2 = .5), tau = .25, G_max = 3L, backend = "highs", crossfit = TRUE)
  expect_identical(d$extras$fragility$reason, "unsupported_input_kind")
  expect_identical(d$extras$crossfit$reason, "unsupported_input_kind")
  expect_identical(d$report_card$interval_source, "draws_equal_tail")
  # Typed coefficients: analytic summaries, typed diagnostics.
  g <- postrank(pr_example_gaussian, weights = c(poverty = .5, frl = .25, snap = .25), tau = .25, G_max = 4L,
    backend = "highs", diagnostics = TRUE, fragility = TRUE)
  expect_identical(g$report_card$interval_source, "gaussian_analytic")
  expect_identical(g$extras$fragility$reason, "unsupported_input_kind")
  expect_s3_class(g$diagnostics, "postrank_coefficient_diagnostics")
  expect_identical(g$metadata$capabilities$interval_source, "gaussian_analytic")
})

test_that("without a validated incumbent the fit is kept and extras are NULL with a reason", {
  local_mocked_bindings(.pr_solve_core = ac_mock_fit(grade = NULL, status = "time_limit"))
  a <- postrank(postrank_toy, weights = ac_w, tau = .25, G_max = 3L, backend = "highs", crossfit = TRUE, diagnostics = TRUE)
  expect_false(a$fit$incumbent_validated)
  expect_identical(a$fit$status$normalized, "time_limit")
  expect_null(a$evaluation); expect_null(a$report_card); expect_null(a$fragility); expect_null(a$crossfit); expect_null(a$diagnostics)
  for (e in names(a$extras)) expect_identical(a$extras[[e]]$reason, "no_validated_incumbent")
  expect_null(get_grades(a)); expect_null(get_relations(a))
  expect_identical(nrow(get_profile(a)), 0L)
  expect_identical(names(get_profile(a)), c("criterion", "weight", "E", "E_over_M", "E_over_N", "risk", "q", "budget_slack", "is_minimax_max"))
  r <- get_risk(a); expect_identical(r$status, "time_limit"); expect_true(is.na(r$risk))
  expect_identical(nrow(as.data.frame(a)), 0L)
  expect_error(postrank_report_card(a), class = "postrank_input_error")
})

test_that("an all-tie grade is a valid incumbent with E/N = NA", {
  local_mocked_bindings(.pr_solve_core = ac_mock_fit(grade = c("001" = 1L, "site-B" = 1L, "site C" = 1L)))
  a <- postrank(postrank_toy, weights = ac_w, tau = .25, G_max = 3L, backend = "highs")
  expect_true(a$fit$incumbent_validated)
  expect_identical(a$evaluation$N, 0L)
  expect_true(all(is.na(get_profile(a)$E_over_N)))
  expect_equal(get_risk(a)$risk, .25)
  expect_true(all(a$report_card$data$n_withheld == 2L))
})

test_that("an unexpected extra error keeps the fit, records the condition and warns", {
  local_mocked_bindings(.pr_solve_core = ac_mock_fit(),
    postrank_mc_fragility = function(...) .pr_abort("synthetic fragility failure", "synthetic_failure"))
  expect_warning(a <- postrank(postrank_toy, weights = ac_w, tau = .25, G_max = 3L, backend = "highs"), "fragility extra failed")
  expect_true(a$fit$incumbent_validated)
  expect_null(a$fragility)
  expect_identical(a$extras$fragility$reason, "extra_error")
  expect_identical(a$extras$fragility$condition$code, "synthetic_failure")
  expect_true(any(grepl("fragility extra failed", a$warnings)))
})

test_that("settings and loose policy arguments conflict; dots are restricted", {
  local_mocked_bindings(.pr_solve_core = ac_mock_fit())
  s <- postrank_settings(ac_w, .25, 3L)
  for (call in list(quote(postrank(postrank_toy, weights = ac_w, settings = s)),
                    quote(postrank(postrank_toy, tau = .25, settings = s)),
                    quote(postrank(postrank_toy, q = c(need_A = .1), settings = s)))) {
    e <- tryCatch(eval(call), error = identity); expect_identical(e$code, "settings_conflict")
  }
  expect_error(postrank(postrank_toy, weights = ac_w, G_max = 3L, backend = "highs", time_limit = 5), "may contain only")
  a <- postrank(postrank_toy, settings = s, backend = "highs", fragility = FALSE)
  expect_identical(a$settings$label, s$label)
  expect_error(postrank(postrank_toy), "weights")
  expect_error(postrank(postrank_pairwise(postrank_toy), weights = ac_w), "postrank_draws")
})

test_that("analysis metadata is the only sidecar; legacy identities are untouched", {
  local_mocked_bindings(.pr_solve_core = ac_mock_fit())
  a <- postrank(postrank_toy, weights = ac_w, tau = .25, G_max = 3L, backend = "highs")
  gi <- jsonlite::read_json(test_path("fixtures", "golden-identities.json"))
  expect_identical(a$input$validation$input_identity, gi$postrank_toy$input_identity)
  expect_identical(a$pairwise$pairwise_identity, gi$postrank_toy$pairwise_identity)
  expect_identical(a$problem$problem_identity, gi$postrank_toy$problem_identity)
  expect_identical(names(a$metadata), c("declarations", "display_cache", "capabilities", "notes"))
  expect_identical(a$metadata$declarations$status, "declared")
  b <- a; b$metadata$notes <- "display-only note"; b$settings$label <- "relabelled"
  expect_true(.pr_validate_analysis(b))
  expect_identical(b$problem$problem_identity, a$problem$problem_identity)
  expect_identical(a$metadata$display_cache[[1]]$key$input_identity, a$input$validation$input_identity)
  expect_false("summaries" %in% names(a$input))
  bad <- a; bad$fit$problem_identity <- strrep("0", 64)
  expect_error(.pr_validate_analysis(bad), "identities disagree")
})

test_that("tier 2: a real HiGHS one-call run validates and reuses the fit evaluation", {
  skip_if_not_installed("highs")
  a <- postrank(postrank_toy, weights = ac_w, tau = .25, G_max = 3L, backend = "highs",
    control = postrank_control(time_limit = 10), crossfit = TRUE)
  expect_true(a$fit$incumbent_validated)
  expect_identical(a$evaluation, a$fit$evaluation)
  expect_true(a$extras$crossfit$available)
  expect_identical(a$crossfit$input_identity, a$fit$input_identity)
  expect_true(all(c("pairwise", "build", "solve", "validate", "extras") %in% names(a$timings)))
})
