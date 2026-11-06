# T-ux-02 / T-ux-07 / T-ux-14: every printed class has a result-first English view whose
# formatter returns lines no wider than the requested width, and print() returns its input
# invisibly. Objects come from sealed caches, pure constructors or (tier B) small HiGHS solves.
pr_print_objects <- function() {
  ta <- pr_cached("toy_analysis"); fit <- ta$fit; pw <- postrank_pairwise(postrank_toy)
  design <- list(sample_sizes_fixed_before_sampling = TRUE, alpha_fixed_before_sampling = TRUE, adaptive_stopping = FALSE,
    planned_sample_sizes = c(need_A = 32L, need_B = 32L), declaration_note = "Fixed in the shipped toy generator before generation.")
  bounds <- postrank_iid_bounds(postrank_toy, alpha = .05, alpha_by_criterion = c(need_A = .025, need_B = .025), design = design)
  pq <- postrank_problem(pw, c(need_A = .6, need_B = .4), .25, 3L, q = c(need_B = .3))
  a35 <- pr_cached("analysis_30x3_tau35")
  list(analysis = a35, fit = a35$fit, report_card = a35$report_card, draws = postrank_toy,
    validation = validate_postrank_draws(postrank_toy), pairwise = pw, coefficients = pr_example_gaussian,
    coefficient_diagnostics = postrank_coefficient_diagnose(pr_example_gaussian, fit = pr_cached("gaussian_analysis_30x3")$fit),
    settings = postrank_settings(c(need_A = .6, need_B = .4)), control = postrank_control(), problem = pq,
    solution_validation = fit$solution_validation, report = postrank_report(fit, figures = FALSE),
    baseline = postrank_cuts(postrank_expected_rank(a35$pairwise, a35$settings$weights), a35$pairwise, a35$settings),
    comparison = pr_cached("comparison_30x3_tau35"), frontier = pr_cached("frontier_30x3"),
    commonality_cost = pr_cached("commonality_30x3_tau35"), crossfit = pr_cached("toy_crossfit"),
    mc_fragility = postrank_mc_fragility(postrank_toy, fit = fit), diagnostics = postrank_diagnose(postrank_toy, fit = fit),
    iid_bounds = bounds, regret_bound = postrank_regret_bound(fit, bounds), protection_envelopes = postrank_protection_envelopes(pq, bounds),
    backend_availability = postrank_backend_available("highs"), summary = summary(a35))
}

pr_check_view <- function(x, nm, width = 72L) {
  lines <- format(x, width = width)
  expect_true(is.character(lines) && length(lines) >= 2L, info = nm)
  expect_true(all(nchar(lines) <= width), info = paste(nm, paste(lines[nchar(lines) > width], collapse = " | ")))
  expect_match(lines[1L], "^<postrank_", info = nm)
  out <- NULL
  printed <- utils::capture.output(out <- withVisible(print(x)))
  expect_false(out$visible, info = nm)
  expect_identical(out$value, x, info = nm)
  expect_identical(printed, format(x, width = getOption("width")), info = nm)
  expect_identical(.pr_cli_guard(lines), character(), info = nm)
}

test_that("every cached or pure-constructed class prints result-first, invisibly and within 72 columns", {
  objs <- pr_print_objects()
  expect_length(objs, 25L)
  for (nm in names(objs)) pr_check_view(objs[[nm]], nm)
})

test_that("sensitivity grids and protection analyses print the same way (tier 2)", {
  skip_if_not_installed("highs")
  base <- postrank_settings(c(need_A = .6, need_B = .4), .25, 3L)
  s <- postrank_sensitivity(postrank_pairwise(postrank_toy), postrank_settings_grid(base, tau = .3), backend = "highs")
  pr_check_view(s, "sensitivity")
  design <- list(sample_sizes_fixed_before_sampling = TRUE, alpha_fixed_before_sampling = TRUE, adaptive_stopping = FALSE,
    planned_sample_sizes = c(need_A = 32L, need_B = 32L), declaration_note = "Fixed in the shipped toy generator before generation.")
  bounds <- postrank_iid_bounds(postrank_toy, alpha = .05, alpha_by_criterion = c(need_A = .025, need_B = .025), design = design)
  env <- postrank_protection_envelopes(postrank_problem(postrank_pairwise(postrank_toy), c(need_A = .6, need_B = .4), .25, 3L,
    q = c(need_B = .3)), bounds)
  pr_check_view(postrank_protection_analysis(env, backend = "highs"), "protection_analysis")
})

test_that("recorded warnings stay visible in the short view and complete in the summary (T-ux-08)", {
  a <- pr_cached("analysis_30x3_tau35")
  a$warnings <- c("first recorded warning: kept verbatim", "second recorded warning")
  lines <- format(a, width = 72L)
  expect_true(any(grepl("first recorded warning", lines, fixed = TRUE)))
  expect_true(any(grepl("2 warnings|warnings \\(2\\)|\\+1", lines)))
  s <- summary(a)
  expect_identical(s$warnings, a$warnings)
})

test_that("an unsupported report language is refused before any file is touched (T-ux-11)", {
  a <- pr_cached("toy_analysis"); path <- withr::local_tempfile(fileext = ".html")
  writeLines("existing content", path)
  e <- tryCatch(postrank_report(a$fit, output_file = path, lang = "ko"), error = identity)
  expect_identical(e$code, "unsupported_language")
  expect_identical(readLines(path), "existing content")
  fresh <- withr::local_tempfile(fileext = ".html")
  e <- tryCatch(postrank_report(a$fit, output_file = fresh, lang = "fr"), error = identity)
  expect_identical(e$code, "unsupported_language"); expect_false(file.exists(fresh))
})

test_that("30 x 3 boxes are stable at width 72 (T-ux-04)", {
  skip_on_cran()
  testthat::local_reproducible_output(width = 72, unicode = FALSE)
  for (key in c("analysis_30x3_tau35", "analysis_30x3", "comparison_30x3_tau35", "frontier_30x3", "commonality_30x3_tau35"))
    expect_snapshot(cat(format(pr_cached(key), width = 72L), sep = "\n"))
  expect_snapshot(cat(format(pr_cached("analysis_30x3_tau35")$report_card, width = 72L), sep = "\n"))
})

test_that("summary() returns a typed summary that formats within 72 columns for every class with a method", {
  objs <- pr_print_objects()
  for (nm in names(objs)) {
    x <- objs[[nm]]
    if (is.null(utils::getS3method("summary", class(x)[1L], optional = TRUE))) next
    s <- summary(x)
    expect_s3_class(s, "postrank_summary")
    lines <- format(s, width = 72L)
    expect_true(all(nchar(lines) <= 72L), info = nm)
  }
  frag <- pr_cached("analysis_30x3_tau35")$fragility
  expect_true(any(grepl("Most fragile pairs", format(frag, width = 72L), fixed = TRUE)))
})

test_that("plot data and the autoplot/plot methods cover every shipped class", {
  a <- pr_cached("analysis_30x3_tau35")
  pd <- postrank_plot_data(a)
  expect_named(pd, c("report_card", "relations", "profile"))
  expect_true(all(vapply(attr(pd, "availability"), `[[`, TRUE, "available")))
  for (w in c("report_card", "relations", "profile")) expect_s3_class(postrank_plot_data(a, w), "data.frame")
  expect_error(postrank_plot_data(a, "nonsense"), "unknown plot data component")
  expect_s3_class(postrank_plot_data(a$fit), "data.frame"); expect_s3_class(postrank_plot_data(a$fit, "profile"), "data.frame")
  expect_error(postrank_plot_data(a$fit, "report_card"), "fit")
  expect_s3_class(postrank_plot_data(a$report_card), "data.frame")
  b <- postrank_cuts(postrank_expected_rank(a$pairwise, a$settings$weights), a$pairwise, a$settings)
  expect_s3_class(postrank_plot_data(b), "data.frame")
  cmp <- pr_cached("comparison_30x3_tau35")
  expect_identical(postrank_plot_data(cmp), cmp$table); expect_identical(postrank_plot_data(cmp, "relations"), cmp$relations)
  expect_identical(postrank_plot_data(pr_cached("frontier_30x3")), pr_cached("frontier_30x3")$table)
  expect_identical(postrank_plot_data(pr_cached("commonality_30x3_tau35")), pr_cached("commonality_30x3_tau35")$table)
  e <- tryCatch(postrank_plot_data(postrank_toy), error = identity); expect_identical(e$code, "wrong_class")
  objs <- list(analysis = a, fit = a$fit, report_card = a$report_card, frontier = pr_cached("frontier_30x3"),
    commonality = pr_cached("commonality_30x3_tau35"), comparison = cmp, baseline = b)
  grDevices::pdf(NULL); on.exit(grDevices::dev.off(), add = TRUE)
  for (nm in names(objs)) {
    expect_s3_class(ggplot2::autoplot(objs[[nm]]), "ggplot")
    out <- withVisible(plot(objs[[nm]]))
    expect_false(out$visible, info = nm); expect_s3_class(out$value, "ggplot")
  }
  expect_s3_class(ggplot2::autoplot(a, type = "relations"), "ggplot")
  empty <- cmp; empty$relations$n_same <- NA_real_
  expect_match(pr_unwrap(postrank_plot_compare(empty, view = "relations")$labels$subtitle), "Unavailable", fixed = TRUE)
})
