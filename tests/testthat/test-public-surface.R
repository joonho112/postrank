# T-ref-01 / T-ref-04 / T-fig-07 / T-api-02: the exported surface equals release-roster.json
# (83 legacy + 11 tie-aware + 2 supplied-probability + 1 visualization + 8 multidomain exports, 142 S3 registrations); unshipped designs are absent; layering holds.
roster_path <- function() {
  cands <- c(test_path("fixtures", "release-roster.json"))
  cands[!is.na(cands) & file.exists(cands)][1]
}

test_that("exports and S3 registrations equal the release roster", {
  ns <- asNamespace("postrank")
  exports <- getNamespaceExports(ns)
  rp <- roster_path(); skip_if(is.na(rp), "roster file not available (installed package)")
  r <- jsonlite::fromJSON(rp)
  expect_setequal(exports, r$api$exports)
  expect_identical(length(exports), 105L)
  expect_setequal(r$api$probability_input_additions$exports,
    c("postrank_probabilities", "validate_postrank_probabilities"))
  expect_length(setdiff(exports, c(r$api$tie_aware_additions$exports,
    r$api$probability_input_additions$exports, r$api$v1_visualization_additions$exports, r$api$mdomain_additions$exports)), 83L)
  expect_setequal(r$api$mdomain_additions$exports, c(
    "postrank_mdomain_input", "postrank_mdomain_evaluate", "postrank_mdomain_solve",
    "postrank_mdomain_assess", "postrank_mdomain_grades", "postrank_mdomain_decision",
    "postrank_mdomain_family", "postrank_plot_mdomain"))
  expect_length(r$api$v1_1_exports, 97L)
  expect_setequal(setdiff(exports, r$api$mdomain_additions$exports), r$api$v1_1_exports)
  expect_length(r$api$v1_1_s3_methods$generic, 127L)
  m <- getNamespaceInfo(ns, "S3methods")
  reg <- paste(r$api$s3_methods$generic, r$api$s3_methods$class, sep = ".")
  expect_setequal(paste(m[, 1], m[, 2], sep = "."), reg)
  expect_identical(length(reg), 142L)
  expect_identical(postrank::autoplot, ggplot2::autoplot)
  for (f in c("postrank_plot_sensitivity", "postrank_plot_fragility", "postrank_plot_crossfit",
              "postrank_plot_trace", "postrank_plot_dispersion", "postrank_coefficients")) expect_false(f %in% exports, info = f)
})

test_that("exactly seven autoplot and seven plot methods; no pairwise or reserved plotting methods (T-fig-07)", {
  m <- getNamespaceInfo(asNamespace("postrank"), "S3methods"); s3 <- paste(m[, 1], m[, 2], sep = ".")
  expect_identical(sort(grep("^autoplot\\.", s3, value = TRUE)), sort(paste0("autoplot.postrank_", c("analysis", "fit", "report_card",
    "frontier", "commonality_cost", "comparison", "baseline"))))
  expect_identical(length(grep("^plot\\.", s3, value = TRUE)), 7L)
  expect_false(any(grepl("^(autoplot|plot)\\.postrank_(pairwise|coefficients|sensitivity|crossfit|mc_fragility|diagnostics)$", s3)))
})

test_that("the seven figures need no optional helper package (actual absence is the G6 isolation scenario)", {
  root <- pr_source_path("R"); skip_if_not(dir.exists(root), "source not available")
  src <- unlist(lapply(list.files(root, "\\.R$", full.names = TRUE), readLines, warn = FALSE))
  expect_false(any(grepl("ggrepel|patchwork", src[!grepl("^\\s*#", src)])))
  a <- pr_cached("analysis_30x3_tau35")
  ps <- list(postrank_plot_report_card(a), postrank_plot_relations(a), postrank_plot_profile(a), postrank_plot_pairwise(a),
    postrank_plot_frontier(pr_cached("frontier_30x3")), postrank_plot_commonality(pr_cached("commonality_30x3_tau35")),
    postrank_plot_compare(pr_cached("comparison_30x3_tau35")))
  for (p in ps) expect_silent(ggplot2::ggplot_build(p))
})

test_that("view files call no engine internals (layering rule, PR-DEC-09-C)", {
  root <- pr_source_path("R"); skip_if_not(dir.exists(root), "source not available")
  views <- file.path(root, c("plots-card.R", "plots-relations.R", "plots-profile.R", "plots-frontier.R", "plots-compare.R", "plots-pairwise.R", "plots-utils.R", "plots-data.R", "theme.R", "print-methods.R", "utils-cli.R"))
  internals <- c(".pr_solve_raw", ".pr_solve_core", ".pr_engine_staged", ".pr_backend_highs", ".pr_backend_gurobi", "postrank_solve(",
    ".pr_weighted_model", "postrank_pairwise(", ".pr_posterior_summaries", "postrank_evaluate(")
  internals <- sub("\\($", "", internals)
  for (f in views) {
    pd <- utils::getParseData(parse(f, keep.source = TRUE))
    called <- unique(pd$text[pd$token %in% c("SYMBOL_FUNCTION_CALL", "SYMBOL")])
    for (i in internals) expect_false(i %in% called, info = paste(basename(f), i))
  }
})

test_that("inherited positional calls keep their meaning (T-api-02)", {
  pw <- postrank_pairwise(postrank_toy)
  p <- postrank_problem(pw, c(need_A = .6, need_B = .4), .25, 3L, "minimax")
  expect_identical(p$settings$objective, "minimax")
  expect_identical(names(formals(postrank_problem))[1:9], c("pairwise", "weights", "tau", "G_max", "objective", "q", "exact_G",
    "minimax_criteria", "minimax_refine"))
  expect_identical(utils::tail(names(formals(postrank_problem)), 1), "settings")
  expect_identical(names(formals(postrank_solve)), c("problem", "backend", "control", "strategy"))
  expect_identical(names(formals(postrank_report))[1:4], c("fit", "diagnostics", "output_file", "lang"))
})
