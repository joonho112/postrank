# T-fig-01 / T-fig-02 / T-fig-05: the seven shipped verbs on prepared fixtures and degenerate
# cases; stored values unchanged; no solve or recomputation from a view.
ps_layer_data <- function(p, i) ggplot2::layer_data(p, i)

test_that("seven shipped verbs return ggplots on the sealed fixtures", {
  a <- pr_cached("analysis_30x3_tau35")
  plots <- list(card = postrank_plot_report_card(a), relations = postrank_plot_relations(a), profile = postrank_plot_profile(a),
    frontier = postrank_plot_frontier(pr_cached("frontier_30x3")), commonality = postrank_plot_commonality(pr_cached("commonality_30x3_tau35")),
    compare = postrank_plot_compare(pr_cached("comparison_30x3_tau35")),
    compare_rel = postrank_plot_compare(pr_cached("comparison_30x3_tau35"), view = "relations"),
    pairwise = postrank_plot_pairwise(a, max_entities = 6))
  for (nm in names(plots)) { expect_s3_class(plots[[nm]], "ggplot"); expect_silent(ggplot2::ggplot_build(plots[[nm]])) }
  expect_identical(pr_unwrap(plots$card$labels$title), "Grade report card")
  expect_match(pr_unwrap(plots$card$labels$caption), "90% equal-tail posterior intervals")
  expect_match(pr_unwrap(plots$card$labels$caption), "not equality")
})

test_that("the report card draws stored means and intervals unchanged, including a mean outside its interval", {
  a <- pr_cached("analysis_30x3_tau35")
  p <- postrank_plot_report_card(a)
  pd <- postrank_plot_data(a, "report_card")
  seg <- ps_layer_data(p, 2); pts <- ps_layer_data(p, 3)
  expect_setequal(round(pts$x, 12), round(pd$mean, 12))
  expect_setequal(round(seg$x, 12), round(pd$lower, 12)); expect_setequal(round(seg$xend, 12), round(pd$upper, 12))
  # Skewed finite law: mean 1 with interval [0, 0] is preserved, not clipped.
  x <- pr_test_exact(); a0 <- matrix(c(0, 1, 2, 0, 1, 2), 3, 2, dimnames = list(entity = x$entity_ids, criterion = x$criterion_ids))
  b0 <- a0; b0[1, ] <- 100
  x$finite_law <- list(denominator = 100L, value_representation = "safe_integer",
    states = list(list(state_id = "s1", mass_numerator = 99L, theta = a0), list(state_id = "s2", mass_numerator = 1L, theta = b0)),
    law_definition = "Skewed two-state law", not_empirical_posterior_relabeling = TRUE)
  local_mocked_bindings(.pr_solve_core = pr_mock_solver())
  sk <- postrank(as_postrank_draws(x), weights = c(need1 = .5, need2 = .5), tau = .25, G_max = 3L, backend = "highs")
  q <- postrank_plot_report_card(sk); d <- postrank_plot_data(sk, "report_card")
  r <- d[d$entity_id == "001" & d$criterion == "need1", ]
  expect_equal(r$mean, 1); expect_identical(c(r$lower, r$upper), c(0, 0))
  expect_true(1 %in% ps_layer_data(q, 3)$x)
  # Truncation is announced; order options keep grades contiguous.
  t <- postrank_plot_report_card(a, max_rows = 10, order = "label")
  expect_match(pr_unwrap(t$labels$subtitle), "30 entities in 4 grades; showing 10")
})

test_that("degenerate inputs build informative or status-only views", {
  a0 <- pr_cached("analysis_30x3")   # the honest all-tie result of the tau = .25 example
  expect_match(pr_unwrap(postrank_plot_report_card(a0)$labels$subtitle), "all comparisons withheld")
  expect_match(pr_unwrap(postrank_plot_profile(a0)$labels$subtitle), "E/N NA: no disclosed pairs")
  expect_s3_class(postrank_plot_profile(a0, show = "risk"), "ggplot")
  local_mocked_bindings(.pr_solve_core = pr_mock_solver(grade = NULL, status = "time_limit"))
  none <- postrank(postrank_toy, weights = c(need_A = .6, need_B = .4), tau = .25, G_max = 3L, backend = "highs")
  for (p in list(postrank_plot_report_card(none), postrank_plot_relations(none), postrank_plot_profile(none), ggplot2::autoplot(none))) {
    expect_s3_class(p, "ggplot"); expect_match(pr_unwrap(p$labels$subtitle), "Unavailable")
  }
  same <- postrank_plot_relations(pr_cached("analysis_30x3_tau35"), pr_cached("analysis_30x3_tau35"))
  expect_match(pr_unwrap(same$labels$subtitle), "identical relations \\(agreement 1.000\\)")
  fr <- pr_cached("frontier_30x3"); fr1 <- fr; fr1$table <- fr$table[1, , drop = FALSE]
  expect_s3_class(postrank_plot_frontier(fr1), "ggplot")
  frm <- fr; frm$table$G[2] <- NA; frm$table$status[2] <- "time_limit"; frm$table$disclosure_rate[2] <- NA; frm$table$primary_risk[2] <- NA
  frm$table[2, grep("^E_over_N_", names(frm$table))] <- NA
  expect_match(pr_unwrap(postrank_plot_frontier(frm)$labels$subtitle), "1 without incumbent \\(time_limit\\)")
  cc <- pr_cached("commonality_30x3_tau35"); cc$table$cost_upper[1] <- NA
  expect_match(pr_unwrap(postrank_plot_commonality(cc)$labels$subtitle), "upper bound unavailable: poverty")
  cmp <- pr_cached("comparison_30x3_tau35"); cmp$table$risk[3] <- NA; cmp$table$status[3] <- "not_comparable"; cmp$table$reason[3] <- "exact_G_exceeds_blocks"
  expect_match(pr_unwrap(postrank_plot_compare(cmp)$labels$subtitle), "composite \\(not_comparable, exact_G_exceeds_blocks\\)")
})

test_that("wrong classes and display options are rejected", {
  a <- pr_cached("analysis_30x3_tau35")
  expect_error(postrank_plot_report_card(a$fit), class = "postrank_input_error")
  expect_error(postrank_plot_frontier(a), class = "postrank_input_error")
  expect_error(postrank_plot_report_card(a, criteria = "nope"), "criteria")
  expect_error(postrank_plot_frontier(pr_cached("frontier_30x3"), panels = "x"), "panels")
  expect_s3_class(ggplot2::autoplot(a, type = "pairwise"), "ggplot")
  expect_s3_class(postrank_plot_data(a, "pairwise"), "data.frame")
  e <- tryCatch(postrank_plot_data(a, "dispersion"), error = identity); expect_identical(e$code, "unshipped_figure")
})

test_that("views never solve, evaluate or summarize (T-fig-02)", {
  a <- pr_cached("analysis_30x3_tau35"); fr <- pr_cached("frontier_30x3"); cc <- pr_cached("commonality_30x3_tau35")
  cmp <- pr_cached("comparison_30x3_tau35")
  boom <- function(...) stop("a view called a computation")
  local_mocked_bindings(.pr_solve_core = boom, .pr_solve_raw = boom, postrank_evaluate = boom, postrank_pairwise = boom,
    .pr_posterior_summaries = boom, postrank_diagnose = boom, postrank_report_card = boom)
  for (p in list(postrank_plot_report_card(a), postrank_plot_relations(a), postrank_plot_profile(a), postrank_plot_frontier(fr),
                 postrank_plot_commonality(cc), postrank_plot_compare(cmp), postrank_plot_compare(cmp, "relations"), postrank_plot_pairwise(a)))
    expect_silent(ggplot2::ggplot_build(p))
  expect_silent(format(a, tier = 2)); expect_silent(summary(a))
})

test_that("captions avoid misleading affirmative claims (T-fig-05)", {
  a <- pr_cached("analysis_30x3_tau35")
  ps <- list(postrank_plot_report_card(a), postrank_plot_relations(a), postrank_plot_profile(a),
    postrank_plot_frontier(pr_cached("frontier_30x3")), postrank_plot_commonality(pr_cached("commonality_30x3_tau35")),
    postrank_plot_compare(pr_cached("comparison_30x3_tau35")))
  for (p in ps) expect_identical(.pr_cli_guard(c(pr_unwrap(p$labels$title), pr_unwrap(p$labels$subtitle), pr_unwrap(p$labels$caption))), character())
  expect_false(grepl("min_g", postrank_plot_commonality(pr_cached("commonality_30x3_tau35"))$labels$caption))
})
