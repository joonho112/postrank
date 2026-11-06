# Regression tests for the findings of the Phase 6 independent review (log 010): each block
# reproduces a reported failure on documented input and asserts the repaired behavior.

test_that("postrank() keeps its solve for minimax and for budgets given out of criterion order (H1)", {
  skip_if_not_installed("highs")
  w <- c(need_A = .6, need_B = .4)
  mm <- postrank(postrank_toy, weights = w, tau = .25, G_max = 3L, objective = "minimax", backend = "highs", fragility = FALSE)
  expect_s3_class(mm, "postrank_analysis"); expect_identical(mm$fit$problem$settings$objective, "minimax")
  rq <- postrank(postrank_toy, weights = w, tau = .25, G_max = 3L, q = c(need_B = .3, need_A = .3), backend = "highs", fragility = FALSE)
  expect_s3_class(rq, "postrank_analysis")
  expect_identical(.pr_policy_key(postrank_settings(w, q = c(need_B = .3, need_A = .3))),
    .pr_policy_key(postrank_settings(w, q = c(need_A = .3, need_B = .3))))
})

test_that("comparison rows report the declared objective's risk for every action (H2)", {
  skip_if_not_installed("highs")
  w <- c(need_A = .6, need_B = .4)
  mm <- postrank(postrank_toy, weights = w, tau = .25, G_max = 3L, objective = "minimax", backend = "highs", fragility = FALSE)
  alt <- stats::setNames(c(1L, 2L, 2L), postrank_toy$entity_ids)
  cmp <- postrank_compare(mm, again = mm, alt = alt, baselines = character())
  expect_identical(cmp$table$risk[cmp$table$method == "again"], cmp$table$risk[cmp$table$method == "joint"])
  ev <- postrank_evaluate(alt, mm$fit$problem$pairwise, settings = .pr_settings_bind(mm$settings, mm$fit$problem$pairwise)$settings)
  expect_equal(cmp$table$risk[cmp$table$method == "alt"], ev$primary_risk)
})

test_that("settings grids keep unnamed weight profiles, cross q in the full design and never share labels (M6/M7/L10)", {
  g <- postrank_settings_grid(postrank_settings(c(.6, .4)), weights = list(alt = c(.5, .5), alt2 = c(.3, .7)))
  expect_identical(nrow(g), 3L)
  b <- postrank_settings(c(a = .6, b = .4), tau = .25, G_max = 3L)
  full <- postrank_settings_grid(b, tau = .3, q = list(a = c(.1, .2)), design = "full")
  expect_identical(nrow(full), 6L)
  expect_setequal(stats::na.omit(full$q_a), c(.1, .2))
  expect_false(anyDuplicated(postrank_settings_grid(b, tau = c(.12, .125, .4))$label) > 0L)
  expect_identical(postrank_settings_grid(b, tau = .1)$label[2], "tau=0.10")
})

test_that("the report shows source transforms and the analysis's stored diagnostics and cross-fit (M1/M2)", {
  skip_if_not_installed("highs")
  a <- postrank(postrank_toy, weights = c(need_A = .6, need_B = .4), tau = .25, G_max = 3L, backend = "highs",
    crossfit = TRUE, diagnostics = TRUE)
  path <- withr::local_tempfile(fileext = ".html")
  rep <- postrank_report(a$fit, analysis = a, output_file = path, figures = FALSE)
  html <- paste(readLines(path, warn = FALSE), collapse = "\n")
  expect_false(grepl("diagnostics_not_provided", html, fixed = TRUE))
  expect_match(html, "Cross-fit (prepared by the analysis; descriptive)", fixed = TRUE)
  expect_match(html, "source_transform", fixed = TRUE)
  expect_false(grepl(">not declared<", html, fixed = TRUE))
  expect_identical(rep$diagnostics$diagnostics_identity, a$diagnostics$diagnostics_identity)
})

test_that("an unknown figure reason and a bare typed fit keep the report valid and consistent (L6/L8)", {
  expect_match(.pr_report_figure_html(list(id = "fig-x", available = FALSE, reason = "something_new")), "something_new", fixed = TRUE)
  g <- pr_cached("gaussian_analysis_30x3")
  expect_identical(postrank_report(g$fit, figures = FALSE)$declarations$status, postrank_report(g$fit, analysis = g, figures = FALSE)$declarations$status)
})

test_that("frontier and comparison figures handle many grade counts, q grids over tau and missing bounds (M3/M4/M5)", {
  fr <- pr_cached("frontier_30x3")
  f8 <- fr; f8$table$G <- 1:8; f8$table$status <- "optimal"
  expect_false(anyNA(ggplot2::ggplot_build(postrank_plot_frontier(f8))$data[[2]]$shape))
  fe <- fr; fe$table$G <- NA; fe$table$disclosure_rate <- NA; fe$table$primary_risk <- NA
  fe$table[, grep("^E_over_N_", names(fe$table))] <- NA
  expect_match(pr_unwrap(postrank_plot_frontier(fe)$labels$subtitle), "Unavailable", fixed = TRUE)
  cmp <- pr_cached("comparison_30x3_tau35"); cmp$table$risk_lower_bound <- NA
  expect_silent(ggplot2::ggplot_build(postrank_plot_compare(cmp)))
  fq <- fr; fq$q_criterion <- "frl"; fq$table$q_value <- rep(c(.1, .2), length.out = nrow(fq$table))
  fq$table$tau <- rep(c(.2, .4), each = nrow(fq$table) / 2)
  b <- ggplot2::ggplot_build(postrank_plot_frontier(fq))
  expect_true(length(unique(b$layout$layout$tau_lab)) == 2L)
  expect_match(pr_unwrap(postrank_plot_frontier(fq)$labels$subtitle), "one panel column per tau", fixed = TRUE)
})

test_that("report-card captions keep the stored level and more than 64 grades draw in neutral ink (L2/L3)", {
  a <- pr_cached("analysis_30x3_tau35"); rc <- a$report_card; rc$level <- .975
  expect_match(pr_unwrap(postrank_plot_report_card(rc)$labels$caption), "^97.5% equal-tail")
  big <- rc; n <- nrow(big$data); big$data$grade <- seq_len(n) + 60L   # synthetic labels above the palette range
  expect_s3_class(suppressWarnings(postrank_plot_report_card(big)), "ggplot")
})

test_that("live cache reproduction evaluates its expression once (L1)", {
  skip_if_not_installed("highs")
  e <- new.env(); sys.source(system.file("scripts", "_vignette-setup.R", package = "postrank", mustWork = TRUE), e)
  n <- 0L
  x <- e$load_or_compute("toy_analysis", { n <- n + 1L
    postrank(postrank_toy, weights = c(need_A = .6, need_B = .4), tau = .25, G_max = 3L, backend = "highs") }, live = TRUE)
  expect_identical(n, 1L)
  expect_false(is.null(attr(x, "live_comparison")))
})

test_that("declarations reject ellipsis placeholders copied from the template", {
  for (p in c("...", "\u2026", "TBD")) {
    e <- tryCatch(.pr_declaration_text(p, "identification_note"), error = identity)
    expect_identical(e$code, "placeholder_declaration", info = p)
  }
})
