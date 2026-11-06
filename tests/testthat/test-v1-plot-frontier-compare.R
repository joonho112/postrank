# Display-only fixtures below deliberately alter stored rows; they are not solver results.
test_that("frontier lines stop at unavailable incumbents and undefined E/N", {
  fr <- pr_cached("frontier_30x3"); original <- postrank_plot_data(fr)
  fr$table$G[6] <- NA_integer_; fr$table$status[6] <- "time_limit"
  fr$table$disclosure_rate[6] <- fr$table$primary_risk[6] <- NA_real_
  fr$table[6, grep("^E_over_N_", names(fr$table))] <- NA_real_
  p <- postrank_plot_frontier(fr)
  d <- p$data[p$data$series_id == "metric:risk", ]
  expect_false(d$available[d$x == .35])
  expect_false(d$line_group[abs(d$x - .30) < 1e-12] == d$line_group[abs(d$x - .40) < 1e-12])
  lines <- p$layers[[1]]$data
  expect_false(any(vapply(split(lines$x, lines$line_group), function(z) min(z) < .35 && max(z) > .35, logical(1))))
  expect_identical(postrank_plot_data(fr), fr$table)
  expect_identical(postrank_plot_data(pr_cached("frontier_30x3")), original)

  fr <- pr_cached("frontier_30x3")
  fr$table$N[6] <- 0; fr$table$disclosure_rate[6] <- 0
  fr$table[6, grep("^E_over_N_", names(fr$table))] <- NA_real_
  p <- postrank_plot_frontier(fr)
  d <- p$data[p$data$series_id == "criterion:1", ]
  expect_false(d$available[d$x == .35])
  expect_false(d$line_group[abs(d$x - .30) < 1e-12] == d$line_group[abs(d$x - .40) < 1e-12])
  expect_match(pr_unwrap(p$labels$subtitle), "E/N undefined")
  expect_match(pr_unwrap(p$labels$caption), "risks do not rank policies on a shared loss", fixed = TRUE)
})

test_that("single-point and all-withheld frontier views render without line warnings", {
  fr <- pr_cached("toy_frontier"); fr$table <- fr$table[2, , drop = FALSE]
  p <- postrank_plot_frontier(fr)
  expect_equal(nrow(p$layers[[1]]$data), 0L)
  expect_silent(ggplot2::ggplotGrob(p))
  fr <- pr_cached("frontier_30x3"); fr$table <- fr$table[fr$table$N == 0, , drop = FALSE]
  expect_true(all(is.na(postrank_plot_data(fr)[, grep("^E_over_N_", names(fr$table))])))
  expect_silent(ggplot2::ggplotGrob(postrank_plot_frontier(fr)))
  expect_match(pr_unwrap(postrank_plot_frontier(fr, panels = "error")$labels$subtitle), "nothing disclosed")
})

test_that("frontier q columns keep separate losses and disclose unfinished gaps", {
  fr <- pr_cached("toy_frontier")
  a <- fr$table; a$q_value <- a$tau; a$tau <- .25
  b <- a; b$tau <- .35
  fr$table <- rbind(a, b); fr$q_criterion <- "need_A"
  fr$table$status[2] <- "time_limit"; fr$table$risk_absolute_gap[2] <- .02
  p <- postrank_plot_frontier(fr)
  d <- p$layers[[1]]$data
  expect_true(all(vapply(split(d$tau_lab, d$line_group), function(z) length(unique(z)) == 1L, logical(1))))
  expect_match(pr_unwrap(p$labels$subtitle), "different losses")
  expect_match(pr_unwrap(p$labels$subtitle), "time_limit (gap 0.02)", fixed = TRUE)
  expect_silent(ggplot2::ggplotGrob(p))
})

test_that("comparison labels expose scope, status, gaps and unavailable actions in both views", {
  cmp <- pr_cached("comparison_30x3_tau35")
  cmp$table$status[1] <- "time_limit"; cmp$table$risk_absolute_gap[1] <- .02
  cmp$table$risk_lower_bound[1] <- cmp$table$risk[1] - .02
  cmp$table$status[3] <- "time_limit"; cmp$table$reason[3] <- "no_validated_incumbent"
  cmp$table[3, c("risk", "N", "disclosure_rate", "G", "risk_lower_bound", "risk_absolute_gap")] <- NA_real_
  cmp$relations[cmp$relations$method == "composite", -1] <- NA_real_
  old <- postrank_plot_data(cmp)
  for (view in c("summary", "relations")) {
    p <- postrank_plot_compare(cmp, view)
    lab <- p$scales$get_scales("y")$labels
    expect_match(lab[["expected_rank"]], "fixed score order", fixed = TRUE)
    expect_match(lab[["composite"]], "time_limit", fixed = TRUE)
    expect_false(p$scales$get_scales("y")$drop)
    expect_match(pr_unwrap(p$labels$subtitle), "no_validated_incumbent", fixed = TRUE)
    expect_silent(ggplot2::ggplotGrob(p))
  }
  p <- postrank_plot_compare(cmp)
  lab <- p$scales$get_scales("y")$labels
  expect_match(lab[["joint"]], "time_limit\nfull family; gap 0.02", fixed = TRUE)
  expect_equal(p$layers[[1]]$data$value, cmp$table$risk_lower_bound[is.finite(cmp$table$risk_lower_bound)])
  expect_identical(postrank_plot_data(cmp), old)
  p <- postrank_plot_compare(cmp, "relations")
  expect_match(pr_unwrap(p$labels$x), "all unordered entity pairs (M)", fixed = TRUE)
  expect_match(pr_unwrap(p$labels$caption), "withheld by both actions", fixed = TRUE)
  expect_match(pr_unwrap(p$labels$subtitle), "reference joint: time_limit; gap 0.02", fixed = TRUE)
})

test_that("comparison retains outside-family and empty relation explanations", {
  cmp <- pr_cached("comparison_30x3_tau35")
  cmp$table$family_feasible[3] <- FALSE; cmp$table$feasibility_reason[3] <- "grade_limit_violation"
  for (view in c("summary", "relations")) {
    p <- postrank_plot_compare(cmp, view)
    expect_match(p$scales$get_scales("y")$labels[["composite"]], "[outside family]", fixed = TRUE)
    expect_match(pr_unwrap(p$labels$subtitle), "grade_limit_violation", fixed = TRUE)
  }
  cmp$relations <- cmp$relations[FALSE, , drop = FALSE]
  expect_match(pr_unwrap(postrank_plot_compare(cmp, "relations")$labels$subtitle), "no compared action with a grade")
})

test_that("commonality labels expose own numerical status and unavailable bounds", {
  cc <- pr_cached("commonality_30x3_tau35")
  cc$table$own_status[1] <- "time_limit"; cc$table$own_lower_bound[1] <- NA_real_; cc$table$cost_upper[1] <- NA_real_
  old <- postrank_plot_data(cc)
  p <- postrank_plot_commonality(cc)
  labels <- p$scales$get_scales("y")$labels
  expect_match(labels[["poverty"]], "time_limit\ngap unavailable", fixed = TRUE)
  expect_match(labels[["frl"]], "optimal (numerical)", fixed = TRUE)
  expect_match(pr_unwrap(p$labels$subtitle), "upper bound unavailable: poverty", fixed = TRUE)
  expect_match(pr_unwrap(p$labels$caption), "solver bounds, not posterior intervals", fixed = TRUE)
  expect_identical(postrank_plot_data(cc), old)
  expect_silent(ggplot2::ggplotGrob(p))
})

test_that("named summary ncol changes layout without changing values", {
  cmp <- pr_cached("comparison_30x3_tau35")
  wide <- postrank_plot_compare(cmp)
  narrow <- postrank_plot_compare(cmp, ncol = 1L)
  expect_equal(wide$facet$params$ncol, 3L)
  expect_equal(narrow$facet$params$ncol, 1L)
  expect_identical(wide$data, narrow$data)
  expect_silent(ggplot2::ggplotGrob(narrow))
  expect_identical(postrank_plot_compare(cmp, "relations")$data,
                   postrank_plot_compare(cmp, "relations", ncol = 1L)$data)
  for (bad in list(0, -1, 1.5, NA_real_, Inf, "1", numeric()))
    expect_error(postrank_plot_compare(cmp, ncol = bad), class = "postrank_input_error")
  expect_gt(match("ncol", names(formals(postrank_plot_compare))), match("...", names(formals(postrank_plot_compare))))
})

test_that("analysis and fit autoplot pairwise dispatch reaches the supplied view", {
  a <- pr_cached("toy_analysis")
  local_mocked_bindings(postrank_plot_pairwise = function(object, ...) list(object = object, args = list(...)))
  for (x in list(a, a$fit)) {
    p <- ggplot2::autoplot(x, type = "pairwise", max_rows = 3L)
    expect_identical(p$object, x)
    expect_identical(p$args, list(max_rows = 3L))
  }
})

test_that("frontier probability and risk domains start at zero and adapt to small values", {
  fr <- pr_cached("frontier_30x3")
  fr$table <- fr$table[fr$table$N == 0, , drop = FALSE]
  p <- postrank_plot_frontier(fr)
  b <- ggplot2::ggplot_build(p)
  for (panel in b$layout$panel_params) {
    expect_equal(panel$y.range[1], 0)
    expect_true(all(panel$y$breaks[is.finite(panel$y$breaks)] >= 0))
  }
  expect_equal(b$layout$panel_params[[1]]$y.range, c(0, 1))
  expect_identical(postrank_plot_data(fr), fr$table)
  # Explicit display fixture, not a solve: a valid positive metric scale near zero.
  tiny <- pr_cached("toy_frontier")
  tiny$table <- tiny$table[2:3, , drop = FALSE]
  tiny$table$primary_risk <- c(1e-6, 2e-6)
  tiny$table$E_over_N_need_A <- c(1e-5, 2e-5)
  tiny$table$E_over_N_need_B <- c(3e-5, 4e-5)
  p <- postrank_plot_frontier(tiny)
  b <- ggplot2::ggplot_build(p)
  expect_lt(b$layout$panel_params[[2]]$y.range[2], 1e-3)
  expect_gte(b$layout$panel_params[[2]]$y.range[2], 4e-5)
  expect_lt(b$layout$panel_params[[3]]$y.range[2], 1e-4)
  expect_gte(b$layout$panel_params[[3]]$y.range[2], 2e-6)
  expect_identical(postrank_plot_data(tiny), tiny$table)
})

test_that("tiny positive commonality ticks remain visibly nonzero", {
  cc <- pr_cached("toy_commonality")
  cc$table$cost_lower <- c(1e-7, 2e-7)
  cc$table$cost_upper <- c(1.5e-7, 2.5e-7)
  p <- postrank_plot_commonality(cc)
  panel <- ggplot2::ggplot_build(p)$layout$panel_params[[1]]
  labels <- panel$x$get_labels(); ticks <- panel$x$breaks
  keep <- is.finite(ticks) & ticks > 0
  expect_true(any(keep))
  expect_true(all(as.numeric(labels[keep]) > 0))
  expect_equal(as.numeric(labels[keep]), ticks[keep], tolerance = 1e-12)
  expect_equal(p$layers[[2]]$data$cost_lower, cc$table$cost_lower)
  expect_equal(p$layers[[2]]$data$cost_upper, cc$table$cost_upper)
  expect_identical(postrank_plot_data(cc), cc$table)
})
