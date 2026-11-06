pc_ids <- function(p) rev(levels(p$data$entity_id))

test_that("report-card selection covers grades without taking a priority prefix", {
  a <- pr_cached("case_alabama67")
  full <- a$report_card$data
  p <- postrank_plot_report_card(a)
  expect_length(pc_ids(p), 30L)
  expect_setequal(as.integer(as.character(p$data$grade)), unique(full$grade))
  expect_identical(pc_ids(p), pc_ids(postrank_plot_report_card(a)))
  expect_false(identical(pc_ids(p), full$entity_id[1:30]))
  expect_identical(pc_ids(postrank_plot_report_card(a, max_rows = NULL)), full$entity_id)
  for (limit in c(1L, 3L, 5L, 12L, 30L, 67L, 100L)) {
    idx <- .pr_plot_select_rows(full, limit)
    expect_length(idx, min(limit, nrow(full)))
    expect_identical(idx, sort(unique(idx)))
    if (limit >= max(full$grade)) expect_setequal(full$grade[idx], unique(full$grade))
  }
  chosen <- rev(full$entity_id[seq_len(40)])
  explicit <- postrank_plot_report_card(a, max_rows = 3, entities = chosen)
  expect_identical(pc_ids(explicit), full$entity_id[full$entity_id %in% chosen])
  expect_match(explicit$labels$subtitle, "Selected entities")
  expect_match(explicit$labels$subtitle, "showing 40")
  expect_match(postrank_plot_report_card(a, max_rows = 3)$labels$subtitle, "Some grades are not[[:space:]]+shown")
})

test_that("display labels preserve entity keys, criterion keys and numerical values", {
  a <- pr_cached("case_alabama67")
  id <- a$report_card$data$entity_id[1]
  labels <- setNames("A county with a readable name", id)
  raw <- postrank_plot_report_card(a, max_rows = 12)
  p <- postrank_plot_report_card(a, max_rows = 12, entity_labels = labels,
    criterion_labels = c(income = "Income rank (percentile points)"), ncol = 1)
  expect_identical(p$data, raw$data)
  expect_identical(p$scales$get_scales("y")$labels[[id]], labels[[1]])
  remaining <- setdiff(a$report_card$data$entity_id, id)
  expect_identical(unname(p$scales$get_scales("y")$labels[remaining]), remaining)
  expect_identical(levels(p$data$criterion), c("income", "incarceration"))
  built <- ggplot2::ggplot_build(p)
  expect_identical(as.numeric(built$data[[2]]$x), p$data$lower)
  expect_identical(as.numeric(built$data[[2]]$xend), p$data$upper)
  expect_identical(as.numeric(built$data[[3]]$x), p$data$mean)
  expect_identical(unique(built$layout$layout$COL), 1L)
  collision_ids <- c("a_b", "a b", "third_name")
  fallback <- .pr_plot_entity_labels(collision_ids, readable = TRUE)
  expect_identical(unname(fallback), c("a_b", "a b", "third name"))
  partial <- .pr_plot_entity_labels(collision_ids, c(third_name = "Third"), readable = TRUE)
  expect_identical(unname(partial), c("a_b", "a b", "Third"))
  expect_error(.pr_plot_entity_labels(c("a", "b"), c(a = "same", b = "same")), "distinct")
})

test_that("mean ordering names a criterion and is invariant to positive unit changes", {
  a <- pr_cached("case_alabama67"); card <- a$report_card
  rescaled <- card
  for (prefix in c("mean_", "lower_", "upper_"))
    rescaled$data[[paste0(prefix, "income")]] <- rescaled$data[[paste0(prefix, "income")]] / 100
  expect_error(postrank_plot_report_card(card, order = "mean"), "order_by")
  expect_error(postrank_report_card(a, level = .95, order = "mean"), "order_by")
  for (criterion in c("income", "incarceration")) {
    p <- postrank_plot_report_card(card, order = "mean", order_by = criterion, max_rows = NULL)
    q <- postrank_plot_report_card(rescaled, order = "mean", order_by = criterion, max_rows = NULL)
    expect_identical(pc_ids(p), pc_ids(q))
    expected <- card$data$entity_id[order(card$data$grade,
      -card$data[[paste0("mean_", criterion)]], card$data$entity_id)]
    expect_identical(pc_ids(p), expected)
    made <- postrank_report_card(a, level = .95, order = "mean", order_by = criterion)
    expect_identical(names(made), names(card))
    expect_identical(made$data$entity_id, expected)
    expect_identical(made$provenance$ordering_criterion, criterion)
    expect_identical(made$input_identity, card$input_identity)
  }
  expect_identical(pc_ids(postrank_plot_report_card(card, criteria = "income", order = "mean", max_rows = NULL)),
    pc_ids(postrank_plot_report_card(card, order = "mean", order_by = "income", max_rows = NULL)))
  cde <- pr_cached("case_cde_12")
  expect_s3_class(postrank_report_card(cde, order = "mean"), "postrank_report_card")
  expect_s3_class(postrank_plot_report_card(cde, order = "mean"), "ggplot")
  expect_error(postrank_report_card(a, level = .95, order_by = "income"), "only used")
  expect_error(postrank_plot_report_card(a, order_by = "income"), "only used")
})

test_that("report-card default ordering and old prepared caches remain readable", {
  for (key in c("analysis_30x3_tau35", "analysis_30x3", "case_cde_12", "case_krw_signed97", "case_alabama67")) {
    a <- pr_cached(key)
    p <- postrank_plot_report_card(a, max_rows = NULL)
    expect_identical(pc_ids(p), a$report_card$data$entity_id)
    expect_silent(ggplot2::ggplot_build(p))
    means <- postrank_plot_data(a, "report_card")
    match_rows <- match(paste(p$data$entity_id, p$data$criterion), paste(means$entity_id, means$criterion))
    expect_identical(p$data$mean, means$mean[match_rows])
    expect_identical(p$data$lower, means$lower[match_rows])
    expect_identical(p$data$upper, means$upper[match_rows])
  }
})

test_that("view selection, labels and layout never recompute or modify a prepared card", {
  a <- pr_cached("case_alabama67"); before <- serialize(a, NULL)
  boom <- function(...) stop("view attempted new computation")
  local_mocked_bindings(.pr_solve_core = boom, .pr_solve_raw = boom,
    postrank_evaluate = boom, postrank_pairwise = boom, .pr_posterior_summaries = boom,
    postrank_diagnose = boom, postrank_report_card = boom)
  p <- postrank_plot_report_card(a, entities = a$report_card$data$entity_id[c(1, 20, 40, 65, 67)],
    order = "mean", order_by = "income", ncol = 1,
    entity_labels = setNames("One county", a$report_card$data$entity_id[1]))
  expect_silent(ggplot2::ggplot_build(p))
  expect_identical(serialize(a, NULL), before)
  expect_match(p$labels$caption, "95% supplied central")
})

test_that("report cards retain all-withheld meaning and unclipped means", {
  all <- pr_cached("analysis_30x3")
  expect_match(postrank_plot_report_card(all)$labels$subtitle, "all comparisons withheld")
  expect_match(postrank_plot_report_card(all)$labels$caption, "not equality")
  card <- all$report_card
  k <- names(card$settings$weights)[1]
  card$data[[paste0("mean_", k)]][1] <- card$data[[paste0("upper_", k)]][1] + 10
  p <- postrank_plot_report_card(card)
  row <- as.character(p$data$entity_id) == card$data$entity_id[1] & as.character(p$data$criterion) == k
  expect_gt(p$data$mean[row], p$data$upper[row])
  expect_true(p$data$mean[row] %in% ggplot2::layer_data(p, 3)$x)
  none <- all; none$report_card <- NULL; none$fit$incumbent_validated <- FALSE
  expect_match(postrank_plot_report_card(none)$labels$subtitle, "no validated incumbent")
})

test_that("invalid report-card display requests fail before ggplot layout", {
  a <- pr_cached("case_alabama67"); id <- a$report_card$data$entity_id[1]
  for (v in list(1.5, Inf, NA_real_, 0, -1))
    expect_error(postrank_plot_report_card(a, max_rows = v), "max_rows")
  for (v in list(1.5, Inf, NA_real_, 0))
    expect_error(postrank_plot_report_card(a, ncol = v), "ncol")
  expect_error(postrank_plot_report_card(a, criteria = character()), "nonempty")
  expect_error(postrank_plot_report_card(a, entities = character()), "entities")
  expect_error(postrank_plot_report_card(a, entities = c(id, id)), "entities")
  expect_error(postrank_plot_report_card(a, entities = "not an ID"), "entities")
  for (labels in list("unnamed", c(unknown = "Name"), setNames(NA_character_, id), setNames("", id),
    setNames(c("One", "Two"), c(id, id))))
    expect_error(postrank_plot_report_card(a, entity_labels = labels), "entity_labels")
  expect_error(postrank_plot_report_card(a, labels = c(a = "ignored before")), "unused plot arguments")
})
