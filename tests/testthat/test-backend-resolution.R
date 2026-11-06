# T-api-05: explicit backend -> getOption("postrank.backend") -> "gurobi" for every
# solving verb; an unavailable backend fails without fallback; explicit HiGHS is
# independent of the default. Solver-free except the final tier-2 HiGHS block.
br_problem <- function() {
  draws <- read_postrank_draws(system.file("examples", "synthetic-iid.json", package = "postrank", mustWork = TRUE))
  pw <- postrank_pairwise(draws)
  list(draws = draws, pw = pw, problem = postrank_problem(pw, c(need_A = .6, need_B = .4), .25, 3L))
}

test_that("resolver order is explicit, then option, then gurobi, with validation", {
  withr::local_options(postrank.backend = NULL)
  expect_identical(.pr_resolve_backend(NULL), list(name = "gurobi", resolution = "default"))
  expect_identical(.pr_resolve_backend("highs"), list(name = "highs", resolution = "explicit"))
  withr::local_options(postrank.backend = "highs")
  expect_identical(.pr_resolve_backend(NULL), list(name = "highs", resolution = "option"))
  expect_identical(.pr_resolve_backend("gurobi"), list(name = "gurobi", resolution = "explicit"))
  withr::local_options(postrank.backend = "cplex")
  e <- tryCatch(.pr_resolve_backend(NULL), error = identity)
  expect_s3_class(e, "postrank_input_error"); expect_identical(e$code, "invalid_backend")
  expect_error(.pr_resolve_backend(c("gurobi", "highs")), "gurobi")
  expect_error(.pr_resolve_backend(NA_character_), "gurobi")
})

test_that("every solving verb resolves backend and strategy before entering its core", {
  withr::local_options(postrank.backend = NULL)
  x <- br_problem(); seen <- list()
  rec <- function(verb) function(...) { a <- list(...); seen[[length(seen) + 1L]] <<- list(verb = verb, args = a); NULL }
  local_mocked_bindings(
    .pr_solve_core = function(problem, backend, control, strategy) { seen[[length(seen) + 1L]] <<- list(verb = "solve", backend = backend, strategy = strategy, control = control); list(backend = list(name = backend), incumbent_validated = FALSE) },
    .pr_frontier_core = function(pairwise, weights, tau, G_max, objective, q, exact_G, minimax_criteria, q_criterion, q_grid, backend, control, strategy, minimax_refine) { seen[[length(seen) + 1L]] <<- list(verb = "frontier", backend = backend, strategy = strategy); NULL },
    .pr_commonality_core = function(fit, backend, control, strategy, protection) { seen[[length(seen) + 1L]] <<- list(verb = "commonality", backend = backend, strategy = strategy); NULL },
    .pr_crossfit_core = function(draws, fit, settings, backend, control, strategy) { seen[[length(seen) + 1L]] <<- list(verb = "crossfit", backend = backend, strategy = strategy); NULL },
    .pr_run_protection_analysis = function(envelopes, backend, control, solver) { seen[[length(seen) + 1L]] <<- list(verb = "protection", backend = backend); NULL },
    .pr_backend_require = function(backend) invisible(list()))
  fit <- postrank_solve(x$problem)
  expect_identical(fit$backend$resolution, "default")
  postrank_frontier(x$pw, c(need_A = .6, need_B = .4), tau = c(.2, .3), G_max = 3L)
  postrank_commonality_cost(structure(list(), class = "postrank_fit"))
  postrank_crossfit(x$draws, settings = list(weights = c(need_A = .6, need_B = .4), tau = .25, G_max = 3L))
  postrank_protection_analysis(list())
  expect_identical(vapply(seen, `[[`, "", "verb"), c("solve", "frontier", "commonality", "crossfit", "protection"))
  expect_true(all(vapply(seen, `[[`, "", "backend") == "gurobi"))
  expect_true(all(vapply(seen[1:4], `[[`, "", "strategy") == "staged"))
  expect_identical(names(seen[[1]]$control), c("time_limit", "threads", "seed", "absolute_risk_gap", "relative_gap", "output", "tolerances", "engine"))
  seen <- list()
  withr::local_options(postrank.backend = "highs")
  fit <- postrank_solve(x$problem, control = list(strategy = "label_mip"))
  expect_identical(fit$backend$resolution, "option")
  postrank_frontier(x$pw, c(need_A = .6, need_B = .4), tau = .3, G_max = 3L, strategy = "label_mip")
  expect_identical(vapply(seen, `[[`, "", "backend"), c("highs", "highs"))
  expect_identical(vapply(seen, `[[`, "", "strategy"), c("label_mip", "label_mip"))
  fit <- postrank_solve(x$problem, backend = "gurobi")
  expect_identical(fit$backend$resolution, "explicit")
})

test_that("an unavailable resolved backend errors with both remedies and no fallback", {
  withr::local_options(postrank.backend = NULL)
  x <- br_problem(); highs_calls <- 0L
  local_mocked_bindings(
    .pr_backend_require = function(backend) .pr_stop("Gurobi R package is unavailable.", "postrank_backend_unavailable",
      "gurobi_package_missing", details = list(backend = backend)),
    .pr_backend_highs = function(...) { highs_calls <<- highs_calls + 1L; stop("fallback attempted") })
  e <- tryCatch(postrank_solve(x$problem), error = identity)
  expect_s3_class(e, "postrank_backend_unavailable")
  expect_identical(e$code, "gurobi_package_missing")
  expect_identical(e$details$resolution, "default")
  expect_identical(e$details$resolved_backend, "gurobi")
  expect_match(conditionMessage(e), "install.packages(\"highs\")", fixed = TRUE)
  expect_match(conditionMessage(e), "options(postrank.backend = \"gurobi\")", fixed = TRUE)
  expect_match(conditionMessage(e), "never switches backends", fixed = TRUE)
  expect_identical(highs_calls, 0L)
  # The same rule holds inside a frontier grid: the first unavailable solve stops it.
  e2 <- tryCatch(postrank_frontier(x$pw, c(need_A = .6, need_B = .4), tau = c(.2, .3), G_max = 3L), error = identity)
  expect_s3_class(e2, "postrank_backend_unavailable"); expect_identical(highs_calls, 0L)
  expect_identical(e2$details$resolution, "default")
  # Protection analysis stops too (Phase 2 review H1): no quiet attempt record, no fallback.
  e3 <- tryCatch(postrank_protection_analysis(list()), error = identity)
  expect_s3_class(e3, "postrank_backend_unavailable"); expect_identical(e3$code, "gurobi_package_missing")
  expect_identical(e3$details$resolution, "default"); expect_identical(highs_calls, 0L)
})

test_that("nested solves record the outer call's resolution", {
  withr::local_options(postrank.backend = "highs")
  x <- br_problem(); res <- character()
  local_mocked_bindings(.pr_solve_core = function(problem, backend, control, strategy)
    list(backend = list(name = backend), incumbent_validated = FALSE))
  fits <- .pr_with_resolution(.pr_resolve_backend(NULL), lapply(1:2, function(i) postrank_solve(x$problem, "highs")))
  expect_identical(vapply(fits, function(f) f$backend$resolution, ""), c("option", "option"))
  expect_identical(postrank_solve(x$problem, "highs")$backend$resolution, "explicit")
})

test_that("an explicit HiGHS solve is independent of the Gurobi default (tier 2)", {
  skip_if_not_installed("highs")
  withr::local_options(postrank.backend = NULL)
  x <- br_problem()
  fit <- postrank_solve(x$problem, backend = "highs", control = postrank_control(time_limit = 10))
  expect_identical(fit$backend$name, "highs")
  expect_identical(fit$backend$resolution, "explicit")
  expect_identical(fit$backend$channel, "in-process")
  expect_true(fit$incumbent_validated)
  expect_identical(dim(fit$relations), c(3L, 3L))
  g <- fit$grade
  expect_identical(fit$relations[1, 2], as.integer(sign(g[[2]] - g[[1]])))
  expect_true(all(diag(fit$relations) == 0L))
  bare <- postrank_solve(x$problem, backend = "highs", control = list(time_limit = 10))
  expect_identical(bare$grade, fit$grade)
  expect_identical(bare$problem_identity, fit$problem_identity)
})

test_that("the one-call analysis and sensitivity grids resolve the backend the same way (T-api-05)", {
  withr::local_options(postrank.backend = NULL)
  local_mocked_bindings(.pr_solve_core = pr_mock_solver(), .pr_backend_require = function(backend) invisible(list()))
  a <- postrank(postrank_toy, weights = c(need_A = .6, need_B = .4), tau = .25, G_max = 3L, fragility = FALSE)
  expect_identical(a$fit$backend$name, "gurobi"); expect_identical(a$fit$backend$resolution, "default")
  base <- postrank_settings(c(need_A = .6, need_B = .4), .25, 3L)
  s <- postrank_sensitivity(postrank_pairwise(postrank_toy), postrank_settings_grid(base, tau = .3))
  expect_identical(s$backend$name, "gurobi")
  expect_true(all(vapply(s$fits, function(f) identical(f$backend$name, "gurobi"), TRUE)))
  withr::local_options(postrank.backend = "highs")
  expect_identical(postrank(postrank_toy, weights = c(need_A = .6, need_B = .4), tau = .25, G_max = 3L, fragility = FALSE)$fit$backend$resolution, "option")
})
