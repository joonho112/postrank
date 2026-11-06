test_that("pairwise plot data retain the ordered event and NA diagonals", {
  x <- pr_case_cde$input
  d <- postrank_plot_data(x)
  expect_identical(nrow(d), 144L)
  expect_identical(names(d), c("entity_i", "entity_j", "criterion", "error_probability"))
  ids <- x$entity_ids
  pick <- d$entity_i == ids[1] & d$entity_j == ids[2]
  reverse <- d$entity_i == ids[2] & d$entity_j == ids[1]
  expect_equal(d$error_probability[pick], x$e[1, 2, 1])
  expect_equal(d$error_probability[reverse], x$e[2, 1, 1])
  expect_equal(d$error_probability[pick] + d$error_probability[reverse], 1)
  expect_true(all(is.na(d$error_probability[d$entity_i == d$entity_j])))
  a <- pr_cached("case_cde_12")
  expect_identical(postrank_plot_data(a, "pairwise"), d)
  expect_identical(postrank_plot_data(a$fit, "pairwise"), d)
  expect_identical(names(postrank_plot_data(a)), c("report_card", "relations", "profile"))
})

test_that("pairwise display selection preserves full grades and raw values", {
  a <- pr_cached("case_alabama67")
  p <- postrank_plot_pairwise(a, max_entities = 12)
  ids <- unique(as.character(p$data$entity_i))
  expect_length(ids, 12L)
  expect_setequal(unname(a$fit$grade[ids]), unique(unname(a$fit$grade)))
  expect_identical(nrow(p$data), 12L * 12L * 2L)
  i <- match(as.character(p$data$entity_i), a$input$entity_ids)
  j <- match(as.character(p$data$entity_j), a$input$entity_ids)
  k <- match(as.character(p$data$criterion), a$input$criterion_ids)
  expect_equal(p$data$error_probability, a$input$e[cbind(i, j, k)])
  selected <- a$input$entity_ids[c(2, 7, 12, 27, 42, 66)]
  p2 <- postrank_plot_pairwise(a, entities = selected, max_entities = 2,
    criteria = "income", entity_labels = setNames("One named county", selected[1]),
    criterion_labels = c(income = "Income rank (points)"), ncol = 1)
  expect_setequal(as.character(p2$data$entity_i), selected)
  expect_identical(levels(p2$data$criterion), "income")
  expect_identical(nrow(p2$data), 36L)
  expect_identical(unname(p2$scales$get_scales("x")$labels[selected[1]]), "One named county")
  expect_true(all(grepl("^01[0-9]{3}$", as.character(p2$data$entity_i))))
})

test_that("pairwise heatmaps are prepared-input views even without an action", {
  a <- pr_cached("case_cde_12")
  guard <- function(...) stop("pairwise figure attempted fresh computation")
  local_mocked_bindings(.pr_solve_core = guard, postrank_pairwise = guard,
    postrank_evaluate = guard, .pr_posterior_summaries = guard)
  expect_s3_class(postrank_plot_pairwise(a), "ggplot")
  expect_s3_class(postrank_plot_pairwise(pr_example_gaussian,
    entities = pr_example_gaussian$entity_ids[1:3]), "ggplot")
  # Explicit display fixture: the prepared input is genuine; there is no action.
  fit <- a$fit; fit$incumbent_validated <- FALSE; fit$grade <- NULL
  p <- postrank_plot_pairwise(fit)
  expect_identical(nrow(p$data), 144L)
  expect_match(p$labels$caption, "Input entity order", fixed = TRUE)
  expect_match(gsub("\n", " ", p$labels$caption), "no grade is computed", fixed = TRUE)
  for (input in list(pr_example_draws, structure(list(), class = "postrank_tie_pairwise"))) {
    error <- tryCatch(postrank_plot_pairwise(input), error = identity)
    expect_s3_class(error, "postrank_input_error")
    expect_identical(error$code, "unsupported_plot_input")
  }
})

test_that("pairwise plot invalid display choices are rejected before drawing", {
  x <- pr_case_cde$input
  expect_error(postrank_plot_pairwise(x, max_entities = 1), "max_entities")
  expect_error(postrank_plot_pairwise(x, max_entities = 2.5), "max_entities")
  expect_error(postrank_plot_pairwise(x, entities = x$entity_ids[1]), "at least two")
  expect_error(postrank_plot_pairwise(x, entities = c("missing", "other")), "entities")
  expect_error(postrank_plot_pairwise(x, criteria = character()), "criteria")
  expect_error(postrank_plot_pairwise(x, ncol = NA_real_), "ncol")
  expect_error(postrank_plot_pairwise(x, ncol = 1.2), "ncol")
  expect_error(postrank_plot_pairwise(x, entity_labels = c(missing = "Unknown")), "entity_labels")
  expect_error(postrank_plot_data(x, "profile"), "pairwise")
})
