# These view fixtures are complete stored grades, independent of a solver or
# posterior evaluation. Expected occupancy is recomputed from unit tuples.
md_cells_fixture <- function(units = NULL, domains = c("need", "cost")) {
  full <- matrix(c(1L, 1L, 2L, 2L, 3L, 3L, 1L,
                   1L, 2L, 1L, 2L, 1L, 3L, 1L,
                   1L, 2L, 2L, 1L, 2L, 1L, 2L), 7L,
    dimnames = list(c("uZ", "uB", "uA", "uC", "uD", "uE", "uF"),
      c("need", "cost", "access")))
  if (is.null(units)) units <- rownames(full)
  selected <- full[units, domains, drop = FALSE]
  long <- expand.grid(unit_id = units, domain_id = domains,
    KEEP.OUT.ATTRS = FALSE, stringsAsFactors = FALSE)
  long$grade <- as.integer(selected)
  list(grades = selected, full_grades = full, unit_ids = units,
    domain_ids = domains, K = vapply(domains, function(domain) max(full[, domain]), 1L),
    long = long, n_original = nrow(full), M = 21,
    unit_labels = stats::setNames(units, units),
    domain_labels = stats::setNames(domains, domains),
    caption = paste("Declared finite-law basis; exact arithmetic.",
      "Original card: 7 units; all-pair denominator M = 21; original family scope.",
      "Risks and guards refer to the original card. Aggregated over unshown domains: access."))
}

md_cells_expected_counts <- function(prepared, plotted) {
  vapply(seq_len(nrow(plotted)), function(i) {
    sum(vapply(seq_len(nrow(prepared$grades)), function(j) {
      tuple <- prepared$grades[j, , drop = TRUE]
      expected <- if (length(tuple) == 1L) plotted$grade_x[i]
        else c(plotted$grade_x[i], plotted$grade_y[i])
      all(tuple == expected)
    }, logical(1)))
  }, integer(1))
}

test_that("one-domain cells show original grades and independently counted occupancy", {
  d <- md_cells_fixture(domains = "need")
  p <- .md_plot_cells(d)
  expect_s3_class(p, "ggplot")
  expect_identical(p$data$grade_x, 1:3)
  expect_identical(p$data$count, md_cells_expected_counts(d, p$data))
  expect_identical(p$data$count, c(3L, 2L, 2L))
  expect_identical(p$data$domain_x, rep("need", 3L))
  expect_true(all(is.na(p$data$grade_y)))
  expect_identical(p$data$unit_ids[[1L]], c("uZ", "uB", "uF"))
  expect_identical(attr(p$data, "grades"), d$grades)
  expect_identical(attr(p$data, "full_grades"), d$full_grades)
  expect_identical(attr(p$data, "grade_rows"), d$long)
  built <- ggplot2::ggplot_build(p)
  expect_identical(built$data[[1L]]$y, as.numeric(p$data$count))
  expect_identical(as.character(built$data[[2L]]$label), as.character(p$data$count))
})

test_that("two-domain cells retain the full original grid including zero occupancy", {
  d <- md_cells_fixture()
  p <- .md_plot_cells(d)
  expect_identical(nrow(p$data), 9L)
  expect_identical(p$data$count, md_cells_expected_counts(d, p$data))
  expect_identical(sum(p$data$count), 7L)
  expect_identical(sum(p$data$count == 0L), 3L)
  expect_identical(p$data$count[p$data$grade_x == 1L & p$data$grade_y == 1L], 2L)
  expect_identical(p$data$cell_label, paste0("(", p$data$grade_x, ", ", p$data$grade_y, ")"))
  expect_identical(unname(unlist(p$data$unit_ids, use.names = FALSE)),
    c("uZ", "uF", "uA", "uD", "uB", "uC", "uE"))
  empty <- which(p$data$count == 0L)
  expect_true(all(lengths(p$data$unit_ids[empty]) == 0L))
  expect_true(all(lengths(p$data$unit_labels[empty]) == 0L))
  built <- ggplot2::ggplot_build(p)
  expect_equal(nrow(built$data[[1L]]), 9L)
  expect_equal(nrow(built$data[[2L]]), 9L)
  expect_identical(as.character(built$data[[2L]]$label), as.character(p$data$count))
  contrast <- vapply(seq_len(nrow(p$data)), function(i)
    .pr_contrast(built$data[[2L]]$colour[i], built$data[[1L]]$fill[i]), 0)
  expect_true(all(contrast >= 4.5))
})

test_that("unit subsets preserve missing original grades, zeros and card context", {
  d <- md_cells_fixture(units = c("uD", "uF"))
  p <- .md_plot_cells(d)
  expect_identical(nrow(p$data), 9L)
  expect_identical(p$data$count, md_cells_expected_counts(d, p$data))
  expect_identical(sum(p$data$count), 2L)
  expect_identical(p$data$count[p$data$grade_x == 2L], c(0L, 0L, 0L))
  expect_identical(attr(p$data, "grades"), d$grades)
  expect_identical(attr(p$data, "K"), c(need = 3L, cost = 3L))
  expect_identical(p$scales$get_scales("x")$breaks, 1:3)
  expect_identical(p$scales$get_scales("y")$breaks, 1:3)
  caption <- gsub("\\s+", " ", p$labels$caption)
  expect_match(caption, "all-pair denominator M = 21", fixed = TRUE)
  expect_match(caption, "original family scope", fixed = TRUE)
  expect_match(caption, "Risks and guards refer to the original card", fixed = TRUE)
  expect_identical(p$scales$get_scales("x")$breaks, 1:3)
  one <- .md_plot_cells(md_cells_fixture(units = c("uD", "uF"), domains = "need"))
  expect_identical(one$data$count, c(1L, 0L, 1L))
})

test_that("projected cells explicitly aggregate unshown domains without ranking cells", {
  d <- md_cells_fixture(domains = c("cost", "need"))
  p <- .md_plot_cells(d)
  expect_identical(p$data$count, md_cells_expected_counts(d, p$data))
  expect_identical(p$data$count[p$data$grade_x == 1L & p$data$grade_y == 1L], 2L)
  expect_identical(p$data$unit_ids[[1L]], c("uZ", "uF"))
  expect_identical(d$full_grades[c("uZ", "uF"), "access"], c(uZ = 1L, uF = 2L))
  caption <- gsub("\\s+", " ", p$labels$caption)
  expect_match(caption, "Aggregated over unshown domains: access", fixed = TRUE)
  expect_identical(p$scales$get_scales("x")$breaks, 1:3)
  expect_error(.md_plot_cells(md_cells_fixture(domains = c("need", "cost", "access"))),
    "requires one or two domains", class = "postrank_mdomain_error")
})

test_that("display labels leave grade coordinates, counts and IDs unchanged", {
  d <- md_cells_fixture()
  before <- .md_plot_cells(d)
  changed <- d
  changed$unit_labels <- stats::setNames(paste("Long fictional unit", rev(seq_along(d$unit_ids))), d$unit_ids)
  changed$domain_labels <- c(need = "Need with a long readable label", cost = "Cost for a fictional service")
  after <- .md_plot_cells(changed, title = "Stored multidomain cell occupancy", base_size = 9)
  for (field in c("grade_x", "grade_y", "count", "domain_x", "domain_y", "unit_ids", "cell_label"))
    expect_identical(after$data[[field]], before$data[[field]], info = field)
  expect_identical(after$data$unit_labels[[1L]],
    unname(changed$unit_labels[c("uZ", "uF")]))
  expect_match(after$labels$x, "Need with a long", fixed = TRUE)
  expect_match(after$labels$y, "Cost for a fictional", fixed = TRUE)
  for (layer in seq_len(2L)) {
    a <- ggplot2::layer_data(before, layer)
    b <- ggplot2::layer_data(after, layer)
    expect_identical(a$x, b$x)
    expect_identical(a$y, b$y)
  }
})

test_that("one-grade and one-unit cells build while withholding remains explicit", {
  d <- md_cells_fixture(units = "uZ", domains = "need")
  d$full_grades[,] <- 1L
  d$grades[,] <- 1L
  d$long$grade[] <- 1L
  d$K[] <- 1L
  p <- .md_plot_cells(d)
  expect_identical(p$data$count, 1L)
  expect_match(gsub("\\s+", " ", p$labels$subtitle), "All comparisons withheld", fixed = TRUE)
  expect_silent(ggplot2::ggplot_build(p))
  d <- md_cells_fixture(units = "uZ")
  d$full_grades[,] <- 1L
  d$grades[,] <- 1L
  d$long$grade[] <- 1L
  d$K[] <- 1L
  p <- .md_plot_cells(d)
  expect_identical(p$data$count, 1L)
  expect_silent(ggplot2::ggplot_build(p))
})

test_that("cell rendering calls no computational or optional arithmetic routes", {
  d <- md_cells_fixture()
  seed_state <- function() if (exists(".Random.seed", envir = .GlobalEnv, inherits = FALSE))
    get(".Random.seed", envir = .GlobalEnv) else NULL
  seed_before <- seed_state()
  boom <- function(...) stop("cell rendering called a computational route")
  local_mocked_bindings(postrank_mdomain_evaluate = boom, postrank_mdomain_solve = boom,
    postrank_mdomain_input = boom, postrank_mdomain_decision = boom,
    p2_evaluate_joint = boom, p2_evaluate_expected = boom, .md_require_gmp = boom)
  expect_silent(ggplot2::ggplot_build(.md_plot_cells(d)))
  expect_identical(seed_state(), seed_before)
})

test_that("stored three-domain cards project original grades and caption scope", {
  skip_if_not_installed("gmp")
  original <- md_test_array()
  values <- array(0, c(4L, 3L, 3L),
    dimnames = list(state = dimnames(original)[[1L]], unit = dimnames(original)[[2L]],
      domain = c("need", "cost", "access")))
  values[, , 1:2] <- original
  values[, , 3L] <- original[, , 1L]
  targets <- md_test_targets()
  targets$access <- targets$need
  targets$access$definition <- "Specified fictional access coordinate"
  input <- postrank_mdomain_input(values, targets = targets, provenance = md_test_provenance(),
    representation = "exact_finite_law", masses = rep("1/4", 4L))
  grades <- matrix(c(1L, 1L, 2L, 1L, 1L, 2L, 1L, 2L, 3L), 3L,
    dimnames = list(input$unit_ids, input$domain_ids))
  result <- postrank_mdomain_evaluate(input, grades, postrank_mdomain_decision(t = NULL))
  expect_error(.md_plot_prepare(result, view = "cells"), "one or two explicit domain IDs",
    class = "postrank_mdomain_error")
  prepared <- .md_plot_prepare(result, units = c("B", "A"),
    domains = c("need", "cost"), view = "cells")
  p <- .md_plot_cells(prepared)
  expect_identical(p$data$count, md_cells_expected_counts(prepared, p$data))
  expect_identical(p$data$count, c(2L, 0L, 0L, 0L))
  expect_identical(p$data$unit_ids[[1L]], c("B", "A"))
  expect_identical(attr(p$data, "grades"), result$grades[c("B", "A"), c("need", "cost")])
  expect_identical(attr(p$data, "full_grades"), result$grades)
  expect_identical(p$scales$get_scales("x")$breaks, 1:2)
  expect_identical(p$scales$get_scales("y")$breaks, 1:2)
  caption <- gsub("\\s+", " ", p$labels$caption)
  expect_match(caption, "Showing 2/3 sites, 2/3 domains", fixed = TRUE)
  expect_match(caption, "Original-card risk", fixed = TRUE)
  expect_match(caption, "aggregate unshown domains", fixed = TRUE)
  expect_silent(ggplot2::ggplot_build(p))
})
