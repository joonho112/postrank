# Frozen-table fixtures exercise presentation independently of a model or solver.
md_view_data <- function() {
  units <- c("U3", "U1", "U2")
  domains <- c("need", "cost", "constant", "identity")
  grades <- matrix(c(1L, 2L, 3L, 3L, 2L, 1L, 1L, 1L, 1L, 1L, 1L, 2L),
    3L, dimnames = list(units, domains))
  long <- data.frame(unit_id = rep(units, length(domains)),
    domain_id = rep(domains, each = length(units)),
    grade = as.vector(grades), stringsAsFactors = FALSE)
  pair <- data.frame(domain_id = domains,
    unit_i = "U3", unit_j = "U1", grade_i = c(1L, 3L, 1L, 1L),
    grade_j = c(2L, 2L, 1L, 1L), sign = c(1L, -1L, 0L, 0L),
    direction_label = c("U3 has higher priority", "U1 has higher priority",
      "Direction withheld", "Direction withheld"),
    structural_identity = c(FALSE, FALSE, FALSE, TRUE), stringsAsFactors = FALSE)
  list(grades = grades, full_grades = grades, unit_ids = units,
    domain_ids = domains, K = setNames(c(3L, 3L, 1L, 2L), domains),
    long = long, pair = pair, n_original = 3L, M = 3,
    caption = "Stored exact finite-law card; original three units and four domains.",
    unit_labels = c(U3 = "Unit Three", U1 = "Unit One", U2 = "Unit Two"),
    domain_labels = c(need = "Need", cost = "Cost", constant = "Constant", identity = "Identity"))
}

test_that("grade view keeps frozen integer grades, IDs and requested ordering", {
  d <- md_view_data()
  original <- d
  p <- .md_plot_grades(d)
  expect_s3_class(p, "ggplot")
  expect_identical(p$data[names(d$long)], d$long)
  expect_type(p$data$grade, "integer")
  expect_identical(levels(p$data$.domain), d$domain_ids)
  expect_identical(levels(p$data$.unit), rev(d$unit_ids))
  expect_identical(p$scales$get_scales("fill")$limits, c("1", "2", "3"))
  expect_identical(d, original)
  fills <- unname(postrank_palette(max(d$K))[p$data$.grade_label])
  fills[p$data$.all_withheld] <- "grey90"
  contrasts <- mapply(.pr_contrast, p$data$.text_colour, fills)
  expect_true(all(contrasts >= 4.5))
  caption <- gsub("\n", " ", p$labels$caption, fixed = TRUE)
  expect_match(gsub("\n", " ", p$labels$subtitle, fixed = TRUE), "Grade 1 has highest reported priority", fixed = TRUE)
  expect_match(caption, "Equal grades withhold a comparison", fixed = TRUE)
  expect_silent(ggplot2::ggplotGrob(p))
})

test_that("all-withheld columns are explicit even when a subset appears constant", {
  d <- md_view_data()
  # The displayed subset omits grades 1 and 2 in cost, without renumbering grade 3.
  d$unit_ids <- "U3"
  d$grades <- d$grades["U3", , drop = FALSE]
  d$long <- d$long[d$long$unit_id == "U3", , drop = FALSE]
  p <- .md_plot_grades(d)
  expect_identical(p$data$grade, c(1L, 3L, 1L, 1L))
  expect_identical(p$data$.all_withheld, c(FALSE, FALSE, TRUE, FALSE))
  xlabels <- p$scales$get_scales("x")$labels
  expect_match(gsub("\n", " ", xlabels[["constant"]], fixed = TRUE), "all withheld")
  expect_false(grepl("withheld", xlabels[["cost"]], fixed = TRUE))
  expect_identical(p$scales$get_scales("fill")$limits, c("1", "2", "3"))
})

test_that("pair view distinguishes actual favored units, withholding and identity", {
  d <- md_view_data()
  d$unit_ids <- c("U3", "U1")
  original <- d$pair
  p <- .md_plot_pair(d)
  expect_s3_class(p, "ggplot")
  expect_identical(p$data[names(original)], original)
  expect_identical(p$data$.symbol, c("+", "-", "0", "0"))
  expect_identical(p$data$.direction_text[1:3],
    c("Favors Unit Three", "Favors Unit One", "Direction withheld"))
  expect_match(p$data$.direction_text[4L], "Same modeled target")
  expect_identical(levels(p$data$.domain), rev(d$domain_ids))
  expect_match(gsub("\n", " ", p$labels$subtitle, fixed = TRUE), "Opposite reported directions")
  expect_identical(p$data$.direction_text[1L], "Favors Unit Three")
  expect_identical(d$pair, original)
  expect_silent(ggplot2::ggplotGrob(p))
})

test_that("view labels and large grade counts affect display without changing tables", {
  d <- md_view_data()
  d$unit_labels["U3"] <- "A long descriptive unit label with several words and a line break\nSecond line"
  d$domain_labels["need"] <- "An unusually long descriptive domain label"
  d$K["need"] <- 65L
  grades <- .md_plot_grades(d, title = "Custom grade title", base_size = 12)
  expect_identical(grades$labels$title, "Custom grade title")
  expect_identical(grades$data[names(d$long)], d$long)
  expect_silent(ggplot2::ggplotGrob(grades))
  d$unit_ids <- c("U3", "U1")
  pair <- .md_plot_pair(d, title = "Custom pair title", base_size = 12)
  expect_identical(pair$labels$title, "Custom pair title")
  expect_identical(pair$data[names(d$pair)], d$pair)
  expect_match(gsub("\n", " ", pair$data$.direction_text[1L], fixed = TRUE), "A long descriptive unit label")
  expect_silent(ggplot2::ggplotGrob(pair))
})

test_that("empty frozen tables produce a clear display status", {
  d <- md_view_data()
  d$long <- d$long[FALSE, , drop = FALSE]
  d$pair <- d$pair[FALSE, , drop = FALSE]
  grades <- .md_plot_grades(d)
  pair <- .md_plot_pair(d)
  expect_match(gsub("\n", " ", grades$labels$subtitle, fixed = TRUE), "No stored grade report card")
  expect_match(gsub("\n", " ", pair$labels$subtitle, fixed = TRUE), "No stored pair directions")
  expect_equal(nrow(grades$data), 0L)
  expect_equal(nrow(pair$data), 0L)
  expect_silent(ggplot2::ggplotGrob(grades))
  expect_silent(ggplot2::ggplotGrob(pair))
})

test_that("public evaluated cards pass through grade and pair displays unchanged", {
  skip_if_not_installed("gmp")
  input <- md_test_input()
  grades <- matrix(c(1L, 2L, 3L, 3L, 2L, 1L), 3L,
    dimnames = list(input$unit_ids, input$domain_ids))
  evaluated <- postrank_mdomain_evaluate(input, grades)
  gp <- postrank_plot_mdomain(evaluated, "grades", units = c("C", "A"),
    domains = c("cost", "need"))
  expect_identical(gp$data$grade, c(1L, 3L, 3L, 1L))
  expect_identical(gp$data$unit_id, c("C", "A", "C", "A"))
  pp <- postrank_plot_mdomain(evaluated, "pair", units = c("A", "B"),
    unit_labels = c(A = "First unit", B = "Second unit"))
  expect_identical(pp$data$sign, c(1L, -1L))
  expect_identical(pp$data$.direction_text, c("Favors First unit", "Favors Second unit"))
  expect_identical(evaluated$grades, grades)
})
