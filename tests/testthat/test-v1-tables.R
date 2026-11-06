# Version 1 table contract. Stored native fits and mocked degenerate cases are
# fixtures; none of the views may solve, evaluate, or compute new summaries.
v1_table_guard <- function() stop("table conversion attempted computation")

test_that("stored native analyses and fits share the basic input-order table", {
  a <- pr_cached("toy_analysis")
  expect_identical(a$fit$backend$name, "highs")
  expect_false(identical(a$fit$backend$wrapper_version, "mock"))
  local_mocked_bindings(.pr_solve_core = v1_table_guard,
    postrank_evaluate = v1_table_guard, .pr_posterior_summaries = v1_table_guard,
    postrank_report_card = v1_table_guard)
  before <- serialize(a, NULL)
  d <- as.data.frame(a)
  expect_identical(d, as.data.frame(a$fit))
  expect_identical(names(d), c("entity_id", "grade"))
  expect_identical(d$entity_id, a$pairwise$entity_ids)
  expect_identical(d$grade, unname(get_grades(a)[a$pairwise$entity_ids]))
  expect_type(d$entity_id, "character"); expect_type(d$grade, "integer")
  expect_identical(as.data.frame(a, what = "grades"), d)
  expect_identical(as.data.frame(a, what = "report_card"), a$report_card$data)
  expect_identical(as.data.frame(a$report_card), a$report_card$data)
  expect_false(identical(d$entity_id, a$report_card$data$entity_id))
  expect_error(as.data.frame(a, what = "profile"), "arg.*should be one of")
  expect_identical(serialize(a, NULL), before)
})

test_that("report-card availability cannot change the default table", {
  local_mocked_bindings(.pr_solve_core = pr_mock_solver())
  with_card <- postrank(postrank_toy, c(need_A = .6, need_B = .4),
    G_max = 3L, backend = "highs", fragility = FALSE)
  no_card <- postrank(postrank_toy, c(need_A = .6, need_B = .4),
    G_max = 3L, backend = "highs", fragility = FALSE, report_card = FALSE)
  expected <- as.data.frame(with_card$fit)
  expect_identical(as.data.frame(with_card), expected)
  expect_identical(as.data.frame(no_card), expected)
  expect_identical(get_grades(with_card), get_grades(no_card))
  expect_identical(get_profile(with_card), get_profile(no_card))
  expect_identical(get_risk(with_card), get_risk(no_card))
  err <- tryCatch(as.data.frame(no_card, what = "report_card"), error = identity)
  expect_s3_class(err, "postrank_input_error")
  expect_identical(err$code, "report_card_unavailable")
  expect_match(conditionMessage(err), "postrank_report_card\\(x\\)")
  expect_match(conditionMessage(err), "No prepared report card")
})

test_that("no-incumbent and all-withheld tables remain distinct", {
  local_mocked_bindings(.pr_solve_core = pr_mock_solver(grade = NULL, status = "time_limit"))
  empty <- postrank(postrank_toy, c(need_A = .6, need_B = .4),
    G_max = 3L, backend = "highs", fragility = FALSE)
  typed_empty <- data.frame(entity_id = character(), grade = integer(), stringsAsFactors = FALSE)
  expect_identical(as.data.frame(empty), typed_empty)
  expect_identical(as.data.frame(empty$fit), typed_empty)
  expect_identical(as.data.frame(empty, row.names = character(), optional = TRUE),
    as.data.frame(typed_empty, row.names = character(), optional = TRUE))
  expect_null(get_grades(empty)); expect_identical(get_risk(empty)$status, "time_limit")
  expect_error(as.data.frame(empty, what = "report_card"), "validated grade.*get_risk")
  expect_error(as.data.frame(empty, row.names = "invented"), "invalid 'row.names'")
  # An invalid leftover grade cannot become a reported incumbent.
  leftover <- empty$fit; leftover$grade <- stats::setNames(rep(1L, 3), postrank_toy$entity_ids)
  expect_identical(as.data.frame(leftover), typed_empty)

  local_mocked_bindings(.pr_solve_core = pr_mock_solver(
    stats::setNames(rep(1L, 3), postrank_toy$entity_ids)))
  tied <- postrank(postrank_toy, c(need_A = .6, need_B = .4),
    G_max = 3L, backend = "highs", fragility = FALSE)
  expect_identical(nrow(as.data.frame(tied)), 3L)
  expect_identical(as.data.frame(tied)$grade, rep(1L, 3))
  expect_identical(tied$evaluation$N, 0L)
  expect_true(all(is.na(get_profile(tied)$E_over_N)))
})

test_that("the baseline table uses input order and preserves grade accessors", {
  a <- pr_cached("toy_analysis"); ids <- a$pairwise$entity_ids
  scores <- stats::setNames(c(30, 10, 20), ids)
  b <- postrank_cuts(scores, a$pairwise, a$settings, rule = "quantile", G_b = 3L)
  expect_false(identical(b$order, ids))
  local_mocked_bindings(.pr_solve_core = v1_table_guard,
    postrank_evaluate = v1_table_guard, .pr_posterior_summaries = v1_table_guard)
  d <- as.data.frame(b)
  expect_identical(names(d), c("entity_id", "grade"))
  expect_identical(d$entity_id, ids)
  expect_identical(d$grade, unname(get_grades(b)[ids]))
  expect_type(d$grade, "integer")
  expect_identical(nrow(d), length(ids))
})

test_that("row names and optional are honored by every table method", {
  a <- pr_cached("toy_analysis")
  b <- postrank_cuts(postrank_expected_rank(a$pairwise, a$settings$weights),
    a$pairwise, a$settings)
  custom <- c("row C", "row A", "row B")
  views <- list(
    function(...) as.data.frame(a, ...),
    function(...) as.data.frame(a$fit, ...),
    function(...) as.data.frame(b, ...),
    function(...) as.data.frame(a$report_card, ...),
    function(...) as.data.frame(a, what = "report_card", ...))
  for (view in views) {
    d <- view(); renamed <- view(row.names = custom, optional = TRUE)
    expect_identical(rownames(renamed), custom)
    rownames(renamed) <- NULL
    expect_identical(renamed, d)
    expect_identical(view(optional = FALSE), view(optional = TRUE))
    expect_error(view(row.names = "entity_id"), "invalid 'row.names'")
    expect_identical(names(view(row.names = custom)), names(d))
  }
})

test_that("probability summaries are not invented to fulfill a rich-table request", {
  p <- matrix(c(NA, .2, .8, NA), 2L, 2L, dimnames = list(c("A", "B"), c("A", "B")))
  x <- postrank_probabilities(p, "higher_priority", TRUE, 0,
    list(kind = "analytic_reference", description = "Two-entity table fixture",
      conditioning = "Fixed supplied probabilities"), c(need = "Oriented need score"), criterion = "need")
  local_mocked_bindings(.pr_solve_core = pr_mock_solver())
  a <- postrank(x, G_max = 2L, backend = "highs")
  local_mocked_bindings(.pr_solve_core = v1_table_guard,
    postrank_evaluate = v1_table_guard, .pr_posterior_summaries = v1_table_guard,
    postrank_report_card = v1_table_guard)
  expect_identical(as.data.frame(a), as.data.frame(a$fit))
  expect_identical(nrow(as.data.frame(a)), 2L)
  expect_error(as.data.frame(a, what = "report_card"), "No marginal intervals.*same-target")
})

test_that("CSV and RDS views preserve stored values without computation", {
  a <- pr_cached("toy_analysis")
  local_mocked_bindings(.pr_solve_core = v1_table_guard,
    postrank_evaluate = v1_table_guard, .pr_posterior_summaries = v1_table_guard,
    postrank_report_card = v1_table_guard)
  csv <- tempfile(fileext = ".csv"); rds <- tempfile(fileext = ".rds")
  withr::defer(unlink(c(csv, rds)))
  d <- as.data.frame(a)
  utils::write.csv(d, csv, row.names = FALSE)
  restored <- utils::read.csv(csv, colClasses = c(entity_id = "character", grade = "integer"))
  expect_identical(restored, d)
  saveRDS(a, rds)
  expect_identical(as.data.frame(readRDS(rds)), d)
  expect_identical(as.data.frame(readRDS(rds), what = "report_card"), a$report_card$data)
})
