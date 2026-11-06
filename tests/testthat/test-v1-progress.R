# Progress is a presentation side effect, outside the numerical solver control.
vp_capture <- function(expr) {
  messages <- character()
  value <- withCallingHandlers(expr, message = function(m) {
    messages <<- c(messages, conditionMessage(m))
    invokeRestart("muffleMessage")
  })
  list(value = value, messages = messages)
}

vp_problem <- function() {
  postrank_problem(postrank_pairwise(postrank_toy), c(need_A = .6, need_B = .4), .25, 3L)
}

test_that("progress is quiet by default and explicit controls override the global option", {
  withr::local_options(postrank.verbose = NULL)
  local_mocked_bindings(.pr_solve_core = pr_mock_solver())
  p <- vp_problem()
  inherited <- postrank_control()
  expect_null(inherited$verbose)
  expect_length(vp_capture(postrank_solve(p, "highs"))$messages, 0L)
  expect_length(vp_capture(postrank_solve(p, "highs", inherited))$messages, 0L)
  withr::local_options(postrank.verbose = TRUE)
  # A typed control created before the option changed still inherits at solve time.
  for (ctrl in list(list(), inherited, list(verbose = NULL))) {
    messages <- vp_capture(postrank_solve(p, "highs", ctrl))$messages
    expect_length(messages, 2L)
    expect_match(messages[[1L]], "finding grades with HiGHS", fixed = TRUE)
    expect_match(messages[[2L]], "a validated grade report is available", fixed = TRUE)
  }
  for (ctrl in list(list(verbose = FALSE), postrank_control(verbose = FALSE)))
    expect_length(vp_capture(postrank_solve(p, "highs", ctrl))$messages, 0L)
  withr::local_options(postrank.verbose = FALSE)
  expect_length(vp_capture(postrank_solve(p, "highs", inherited))$messages, 0L)
  for (ctrl in list(list(verbose = TRUE), postrank_control(verbose = TRUE)))
    expect_length(vp_capture(postrank_solve(p, "highs", ctrl))$messages, 2L)
})

test_that("invalid verbosity options are actionable and explicit values still win", {
  local_mocked_bindings(.pr_solve_core = pr_mock_solver())
  p <- vp_problem()
  for (invalid in list("yes", 1, NA, logical(), c(TRUE, FALSE), matrix(TRUE))) {
    withr::local_options(postrank.verbose = invalid)
    for (ctrl in list(list(), postrank_control())) {
      err <- tryCatch(postrank_solve(p, "highs", ctrl), error = identity)
      expect_s3_class(err, "postrank_input_error")
      expect_identical(err$code, "invalid_control")
      expect_match(conditionMessage(err), 'options(postrank.verbose = FALSE)', fixed = TRUE)
    }
    expect_length(vp_capture(postrank_solve(p, "highs", list(verbose = FALSE)))$messages, 0L)
    expect_length(vp_capture(postrank_solve(p, "highs", postrank_control(verbose = TRUE)))$messages, 2L)
    expect_error(postrank_control(verbose = invalid), class = "postrank_input_error")
    err <- tryCatch(.pr_core_control(list(verbose = invalid)), error = identity)
    expect_s3_class(err, "postrank_input_error")
    expect_identical(err$code, "invalid_control")
  }
})

test_that("progress leaves core controls, solver output, complete mocked fits and RNG untouched", {
  withr::local_options(postrank.verbose = FALSE)
  withr::local_seed(98213)
  rng <- .Random.seed
  p <- vp_problem()
  seen <- list()
  solve <- pr_mock_solver()
  local_mocked_bindings(.pr_solve_core = function(problem, backend, control, strategy) {
    seen[[length(seen) + 1L]] <<- list(control = control, strategy = strategy)
    solve(problem, backend, control, strategy)
  })
  for (output in c(FALSE, TRUE)) {
    quiet <- vp_capture(postrank_solve(p, "highs", list(verbose = FALSE, output = output)))
    loud <- vp_capture(postrank_solve(p, "highs", list(verbose = TRUE, output = output)))
    expect_identical(quiet$value, loud$value)
    expect_identical(seen[[length(seen) - 1L]], seen[[length(seen)]])
    expect_identical(seen[[length(seen)]]$control$output, output)
    expect_false("verbose" %in% names(seen[[length(seen)]]$control))
    expect_identical(.Random.seed, rng)
    expect_length(quiet$messages, 0L)
    expect_length(loud$messages, 2L)
  }
})

test_that("nested solves and one-call crossfit extras do not repeat progress", {
  withr::local_options(postrank.verbose = TRUE)
  p <- vp_problem()
  calls <- 0L
  solve <- pr_mock_solver()
  local_mocked_bindings(.pr_solve_core = function(problem, backend, control, strategy) {
    calls <<- calls + 1L
    if (calls == 1L) postrank_solve(problem, backend, list(verbose = TRUE))
    solve(problem, backend, control, strategy)
  })
  expect_length(vp_capture(postrank_solve(p, "highs"))$messages, 2L)
  expect_identical(calls, 2L)
  calls <- 2L
  a <- vp_capture(postrank(postrank_toy, weights = c(need_A = .6, need_B = .4),
    tau = .25, G_max = 3L, backend = "highs", crossfit = TRUE, fragility = FALSE))
  expect_length(a$messages, 2L)
  expect_true(a$value$extras$crossfit$available)
  expect_identical(calls, 5L)
  # Explicit FALSE remains quiet even when extras receive only the numeric core.
  withr::local_options(postrank.verbose = "invalid but overridden")
  b <- vp_capture(postrank(postrank_toy, weights = c(need_A = .6, need_B = .4),
    tau = .25, G_max = 3L, backend = "highs", control = list(verbose = FALSE),
    crossfit = TRUE, fragility = FALSE))
  expect_length(b$messages, 0L)
  expect_true(b$value$extras$crossfit$available)
})

test_that("grid solves remain quiet instead of flooding nested progress", {
  withr::local_options(postrank.verbose = TRUE)
  local_mocked_bindings(.pr_solve_core = pr_mock_solver())
  pw <- postrank_pairwise(postrank_toy)
  frontier <- vp_capture(postrank_frontier(pw, c(need_A = .6, need_B = .4),
    tau = c(.2, .3), G_max = 3L, backend = "highs"))
  expect_length(frontier$messages, 0L)
  settings <- postrank_settings(c(need_A = .6, need_B = .4), .25, 3L)
  sensitivity <- vp_capture(postrank_sensitivity(pw, postrank_settings_grid(settings, tau = c(.2, .3)),
    backend = "highs"))
  expect_length(sensitivity$messages, 0L)
})

test_that("completion does not imply an incumbent and error scopes restore progress", {
  withr::local_options(postrank.verbose = TRUE)
  p <- vp_problem()
  no_grade <- pr_mock_solver(grade = NULL, status = "time_limit")
  calls <- 0L
  local_mocked_bindings(.pr_solve_core = function(problem, backend, control, strategy) {
    calls <<- calls + 1L
    if (calls == 1L) .pr_stop("Gurobi R package is unavailable.", "postrank_backend_unavailable",
      "gurobi_package_missing", details = list(backend = backend))
    no_grade(problem, backend, control, strategy)
  })
  failure <- vp_capture(tryCatch(postrank_solve(p, "gurobi"), error = identity))
  expect_length(failure$messages, 1L)
  expect_s3_class(failure$value, "postrank_backend_unavailable")
  expect_identical(failure$value$code, "gurobi_package_missing")
  expect_match(conditionMessage(failure$value), "never switches backends", fixed = TRUE)
  expect_identical(calls, 1L)
  restored <- vp_capture(postrank_solve(p, "highs"))
  expect_length(restored$messages, 2L)
  expect_match(restored$messages[[2L]], "no validated grade report is available", fixed = TRUE)
  expect_false(restored$value$incumbent_validated)
  expect_identical(restored$value$status$normalized, "time_limit")
})

test_that("native HiGHS actions, risks, settings and RNG agree between verbosity modes", {
  skip_if_not_installed("highs")
  withr::local_options(postrank.verbose = NULL)
  withr::local_seed(98213)
  rng <- .Random.seed
  p <- vp_problem()
  for (strategy in c("label_mip", "staged")) {
    ctrl <- postrank_control(time_limit = 10, strategy = strategy, verbose = FALSE)
    quiet <- vp_capture(postrank_solve(p, "highs", ctrl))
    expect_identical(.Random.seed, rng)
    ctrl$verbose <- TRUE
    loud <- vp_capture(postrank_solve(p, "highs", ctrl))
    expect_identical(.Random.seed, rng)
    expect_length(quiet$messages, 0L)
    expect_length(loud$messages, 2L)
    expect_true(quiet$value$incumbent_validated)
    expect_true(loud$value$incumbent_validated)
    # Wall-clock runtimes are measured independently on each native run.
    for (field in c("grade", "relations", "evaluation", "objective", "settings", "problem",
                    "problem_identity", "input_identity", "solution_identity"))
      expect_identical(quiet$value[[field]], loud$value[[field]], info = paste(strategy, field))
    expect_identical(quiet$value$backend$options, loud$value$backend$options)
    expect_identical(quiet$value$status, loud$value$status)
  }
})
