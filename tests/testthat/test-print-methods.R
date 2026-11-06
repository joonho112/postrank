# Chapter 13 console contract: totality, tier invariance, English-only output, wording
# guard and captured snapshots. All objects are built solver-free (mocked solve).
pm_mock <- function(grade = "auto", status = "optimal") function(problem, backend, control, strategy) {
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
pm_objects <- function() {
  w <- c(need_A = .6, need_B = .4); pw <- postrank_pairwise(postrank_toy)
  prob <- postrank_problem(pw, w, .25, 3L)
  a <- postrank(postrank_toy, weights = w, tau = .25, G_max = 3L, backend = "highs", diagnostics = TRUE)
  list(draws = postrank_toy, validation = postrank_toy$validation, pairwise = pw, coefficients = pr_example_gaussian,
    settings = postrank_settings(w, .25, 3L), control = postrank_control(), problem = prob, fit = a$fit,
    solution_validation = a$fit$solution_validation, analysis = a, report_card = a$report_card, fragility = a$fragility,
    diagnostics = a$diagnostics, report = postrank_report(a$fit), backend = postrank_backend_available("highs"),
    declarations = attr(pr_toy_mcmc, "law")$declarations, guarantee = postrank_guarantee_capabilities())
}

test_that("every print-bearing object formats, prints invisibly and signals nothing", {
  local_mocked_bindings(.pr_solve_core = pm_mock())
  objs <- pm_objects(); objs$guarantee <- NULL
  for (nm in names(objs)) {
    x <- objs[[nm]]
    expect_silent(out <- format(x, width = 72, tier = 2))
    expect_type(out, "character"); expect_gt(length(out), 0L)
    expect_match(out[1], "^<postrank_", info = nm)
    expect_silent(res <- withVisible(utils::capture.output(print(x))))
    printed <- withVisible(print(x)) ; utils::capture.output(NULL)
  }
  v <- withVisible(utils::capture.output(r <- print(objs$fit)))
  expect_identical(r, objs$fit)
})

test_that("tier 1 differs from tier 2 only by ANSI styling; tier 2 is ASCII", {
  local_mocked_bindings(.pr_solve_core = pm_mock())
  objs <- pm_objects(); objs$guarantee <- NULL
  withr::local_options(cli.num_colors = 256L)
  for (nm in names(objs)) {
    t1 <- format(objs[[nm]], width = 72, tier = 1); t2 <- format(objs[[nm]], width = 72, tier = 2)
    expect_identical(cli::ansi_strip(t1), t2, info = nm)
    if (!nm %in% c("draws", "fit", "analysis", "report_card"))  # these show user identifiers verbatim
      expect_false(any(grepl("[^\x01-\x7F]", t2, perl = TRUE)), info = nm)
  }
})

test_that("degenerate objects keep totality: no incumbent, all-tie, time limit", {
  w <- c(need_A = .6, need_B = .4)
  local_mocked_bindings(.pr_solve_core = pm_mock(grade = NULL, status = "time_limit"))
  a <- postrank(postrank_toy, weights = w, tau = .25, G_max = 3L, backend = "highs")
  out <- format(a$fit, width = 72, tier = 2)
  expect_match(out[1], "No validated grades")
  expect_false(any(grepl("^  risk ", out)))
  expect_match(format(a, width = 72, tier = 2)[1], "No validated grades")
  expect_match(paste(format(postrank_report(a$fit), tier = 2), collapse = "\n"), "No validated grades")
  local_mocked_bindings(.pr_solve_core = pm_mock(grade = c("001" = 1L, "site-B" = 1L, "site C" = 1L)))
  b <- postrank(postrank_toy, weights = w, tau = .25, G_max = 3L, backend = "highs")
  ob <- format(b$fit, width = 72, tier = 2)
  expect_match(ob[1], "3 entities in 1 grade; all comparisons withheld")
  expect_true(any(grepl("NA \\(N = 0\\)", ob)))
  expect_match(gsub("\\s+", " ", paste(ob, collapse = " ")), "not an error-free ranking", fixed = TRUE)
  local_mocked_bindings(.pr_solve_core = pm_mock(status = "time_limit"))
  d <- postrank(postrank_toy, weights = w, tau = .25, G_max = 3L, backend = "highs")
  expect_true(any(grepl("upper bound", format(d$fit, tier = 2))))
})

test_that("formatters refuse the wrong class with code wrong_class", {
  e <- tryCatch(format_postrank_fit_cli(postrank_pairwise(postrank_toy)), error = identity)
  expect_s3_class(e, "postrank_input_error"); expect_identical(e$code, "wrong_class")
  expect_error(format_postrank_draws_cli(postrank_toy, tier = 4), "tier")
})

test_that("official output is English only", {
  local_mocked_bindings(.pr_solve_core = pm_mock())
  a <- postrank(postrank_toy, weights = c(need_A = .6, need_B = .4), tau = .25, G_max = 3L, backend = "highs")
  e <- tryCatch(postrank_report(a$fit, lang = "ko"), error = identity)
  expect_identical(e$code, "unsupported_language")
  expect_error(postrank_report(a$fit, lang = "fr"), class = "postrank_input_error")
  withr::local_options(postrank.lang = "ko")
  e <- tryCatch(summary(a), error = identity); expect_identical(e$code, "unsupported_language")
  expect_silent(format(a, tier = 2))   # print/format never consult the language option
  withr::local_options(postrank.lang = "en")
  html <- withr::local_tempfile(fileext = ".html")
  r <- postrank_report(a$fit, output_file = html)
  txt <- readLines(html, warn = FALSE, encoding = "UTF-8")
  cp <- utf8ToInt(enc2utf8(paste(txt, collapse = "\n")))
  expect_false(any(cp >= 0xAC00 & cp <= 0xD7A3))  # no Hangul syllables
  expect_true(any(grepl('lang="en"', txt, fixed = TRUE)))
})

test_that("summaries are typed receipts with identities and full warnings", {
  local_mocked_bindings(.pr_solve_core = pm_mock())
  a <- postrank(postrank_toy, weights = c(need_A = .6, need_B = .4), tau = .25, G_max = 3L, backend = "highs")
  s <- summary(a)
  expect_s3_class(s, c("postrank_analysis_summary", "postrank_summary"))
  expect_identical(names(s), c("object_class", "schema_version", "headline", "provenance", "declarations", "settings",
    "identities", "warnings", "interpretation"))
  expect_identical(s$identities$input, a$fit$input_identity)
  expect_identical(s$provenance$resolution, "explicit")
  expect_match(format(s, width = 72, tier = 2)[1], "^<postrank_analysis_summary>")
  for (cls in c("draws", "pairwise", "coefficients", "settings", "control", "problem"))
    expect_s3_class(summary(switch(cls, draws = postrank_toy, pairwise = postrank_pairwise(postrank_toy),
      coefficients = pr_example_gaussian, settings = postrank_settings(c(a = 1)), control = postrank_control(),
      problem = postrank_problem(postrank_pairwise(postrank_toy), c(need_A = .6, need_B = .4), .25, 3L))), "postrank_summary")
})

test_that("the wording guard flags affirmative claims and allows negations", {
  bad <- c("This is the unique optimum.", "All-tie means no error.", "The bound is certified.", "The pilot proves the joint rule superior.")
  good <- c("One validated incumbent; the number of optima is unknown.", "This is not a numerical certificate.",
    "All-tie is not an error-free ranking.", "Bounds are solver values; the gap is not regret.", "ESS is not an IID sample size.")
  for (b in bad) expect_gt(length(.pr_cli_guard(b)), 0L)
  for (g in good) expect_identical(.pr_cli_guard(g), character())
  local_mocked_bindings(.pr_solve_core = pm_mock())
  objs <- pm_objects(); objs$guarantee <- NULL
  for (nm in names(objs)) expect_identical(.pr_cli_guard(format(objs[[nm]], tier = 2)), character(), info = nm)
})

test_that("captured console boxes (snapshot)", {
  local_mocked_bindings(.pr_solve_core = pm_mock())
  testthat::local_reproducible_output(width = 72, unicode = FALSE)
  a <- postrank(postrank_toy, weights = c(need_A = .6, need_B = .4), tau = .25, G_max = 3L, backend = "highs")
  expect_snapshot(cat(format(a, width = 72, tier = 2), sep = "\n"))
  expect_snapshot(cat(format(a$fit, width = 72, tier = 2), sep = "\n"))
  expect_snapshot(cat(format(a$report_card, width = 72, tier = 2), sep = "\n"))
  expect_snapshot(cat(format(postrank_toy, width = 72, tier = 2), sep = "\n"))
  local_mocked_bindings(.pr_solve_core = pm_mock(grade = NULL, status = "time_limit"))
  b <- postrank(postrank_toy, weights = c(need_A = .6, need_B = .4), tau = .25, G_max = 3L, backend = "highs")
  expect_snapshot(cat(format(b, width = 72, tier = 2), sep = "\n"))
})
