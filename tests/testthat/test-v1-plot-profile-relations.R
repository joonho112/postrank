v1_profile_points <- function(p) {
  i <- which(vapply(p$layers, function(z) inherits(z$geom, "GeomPoint") && "size" %in% names(z$mapping), TRUE))
  if (!length(i)) return(NULL)
  ggplot2::layer_data(p, i[1L])
}

test_that("case profiles draw the stored metric and use nonnegative readable axes", {
  for (key in c("case_cde_12", "case_krw_signed97", "case_alabama67", "analysis_30x3_tau35")) {
    a <- pr_cached(key); before <- a; profile <- postrank_plot_data(a, "profile")
    for (show in c("E_over_N", "E_over_M", "risk")) {
      p <- postrank_plot_profile(a, show = show)
      b <- ggplot2::ggplot_build(p); axis <- b$layout$panel_params[[1L]]
      expect_identical(as.character(p$data$criterion), profile$criterion)
      expect_identical(p$data$value, profile[[show]])
      expect_equal(v1_profile_points(p)$x, profile[[show]], tolerance = 0)
      expect_gte(min(axis$x.range), 0)
      if (show != "risk") expect_lte(max(axis$x.range), 1)
      expect_match(pr_unwrap(p$labels$subtitle), paste0(a$evaluation$N, "/", a$evaluation$M), fixed = TRUE)
      if (show == "E_over_N") expect_match(pr_unwrap(p$labels$caption), "per disclosed pair", fixed = TRUE)
      if (show == "E_over_M") expect_match(pr_unwrap(p$labels$caption), "all unordered pairs", fixed = TRUE)
    }
    expect_identical(a, before)
  }
  p <- postrank_plot_profile(pr_cached("case_cde_12"))
  axis <- ggplot2::ggplot_build(p)$layout$panel_params[[1L]]$x
  breaks <- axis$get_breaks(); labels <- axis$get_labels()
  keep <- is.finite(breaks) & breaks > 0
  expect_true(any(keep))
  expect_true(all(as.numeric(gsub(",", "", labels[keep], fixed = TRUE)) > 0))
  expect_false(anyDuplicated(labels[is.finite(breaks)]) > 0L)
  expect_gt(v1_profile_points(p)$x, 0)
  expect_lt(v1_profile_points(p)$x, .001)
})

test_that("withheld, zero-error and missing-incumbent profiles remain distinct", {
  all <- pr_cached("analysis_30x3")
  p <- postrank_plot_profile(all)
  expect_null(v1_profile_points(p))
  expect_true(all(is.na(p$data$value)))
  expect_false(any(vapply(p$layers, function(z) inherits(z$geom, "GeomPoint"), TRUE)))
  expect_match(pr_unwrap(p$labels$subtitle), "E/N NA: no disclosed pairs", fixed = TRUE)
  expect_identical(v1_profile_points(postrank_plot_profile(all, "E_over_M"))$x, rep(0, 3L))
  expect_equal(v1_profile_points(postrank_plot_profile(all, "risk"))$x, rep(.25, 3L))
  # Display-only fixture: positive N with exactly zero stored errors.
  zero <- pr_cached("case_cde_12")$fit
  zero$evaluation$E[] <- zero$evaluation$E_over_N[] <- zero$evaluation$E_over_M[] <- 0
  p0 <- postrank_plot_profile(zero)
  expect_identical(v1_profile_points(p0)$x, 0)
  expect_identical(ggplot2::ggplot_build(p0)$layout$panel_params[[1L]]$x.range, c(0, 1))
  none <- structure(list(incumbent_validated = FALSE, status = list(normalized = "time_limit")), class = "postrank_fit")
  for (p in list(postrank_plot_profile(none), postrank_plot_relations(none))) {
    expect_match(pr_unwrap(p$labels$subtitle), "no validated incumbent", fixed = TRUE)
    expect_match(pr_unwrap(p$labels$subtitle), "time limit", fixed = TRUE)
    expect_silent(ggplot2::ggplot_build(p))
  }
  expect_equal(nrow(postrank_plot_data(none, "profile")), 0L)
  expect_null(postrank_plot_data(none, "relations"))
  partial <- pr_cached("case_cde_12")
  partial$fit$status$normalized <- "time_limit"
  expect_match(pr_unwrap(postrank_plot_profile(partial)$labels$subtitle), "time limit", fixed = TRUE)
})

test_that("relation maps preserve every pair and show matching complete axes", {
  for (key in c("case_cde_12", "case_krw_signed97", "case_alabama67", "analysis_30x3_tau35", "analysis_30x3")) {
    a <- pr_cached(key); p <- postrank_plot_relations(a); d <- postrank_plot_data(a, "relations")
    b <- ggplot2::ggplot_build(p); n <- length(a$fit$grade)
    expect_identical(p$data, d)
    expect_equal(nrow(b$data[[1L]]), choose(n, 2L))
    expect_equal(sum(d$code != 0), a$evaluation$N)
    expect_equal(sum(d$code == 0), a$evaluation$M - a$evaluation$N)
    expect_identical(b$layout$panel_params[[1L]]$x.range, c(.5, n + .5))
    expect_identical(b$layout$panel_params[[1L]]$y.range, c(-n - .5, -.5))
    expect_setequal(b$plot$scales$get_scales("fill")$get_breaks(), unique(as.character(d$relation)))
    expect_match(pr_unwrap(p$labels$caption), "not equality", fixed = TRUE)
    if (n > 30L) expect_true(all(is.na(b$data[[1L]]$colour)))
  }
  a <- pr_cached("case_cde_12"); p <- postrank_plot_relations(a, labels = "ids")
  axis <- ggplot2::ggplot_build(p)$layout$panel_params[[1L]]
  expect_equal(axis$x$get_breaks(), 1:12, tolerance = 0)
  expect_equal(abs(axis$y$get_breaks()), 1:12, tolerance = 0)
  expect_setequal(axis$x$get_labels(), names(a$fit$grade))
  expect_setequal(axis$y$get_labels(), names(a$fit$grade))
  dense <- postrank_plot_relations(pr_cached("analysis_30x3_tau35"))
  expect_lte(length(ggplot2::ggplot_build(dense)$layout$panel_params[[1L]]$x$get_breaks()), 4L)
  expect_match(pr_unwrap(dense$labels$caption), "positions in grade order", fixed = TRUE)
  hidden <- postrank_plot_relations(a, labels = "none")
  expect_length(ggplot2::ggplot_build(hidden)$layout$panel_params[[1L]]$x$get_breaks(), 0L)
})

test_that("relation change states agree with an independent signed comparison", {
  g0 <- setNames(c(1L, 1L, 2L, 2L), c("01", "02", "03", "04"))
  g1 <- setNames(c(2L, 3L, 1L, 3L), names(g0))
  p <- postrank_plot_relations(g0, g1); d <- p$data
  expected <- vapply(seq_len(nrow(d)), function(i) {
    a <- sign(g0[d$entity_j[i]] - g0[d$entity_i[i]])
    b <- sign(g1[d$entity_j[i]] - g1[d$entity_i[i]])
    if (a == b) "unchanged" else if (a == 0) "newly disclosed" else if (b == 0) "newly withheld" else "reversed"
  }, "")
  expect_identical(as.character(d$change), expected)
  expect_equal(as.integer(table(d$change)), c(1L, 2L, 1L, 2L))
  scale <- ggplot2::ggplot_build(p)$plot$scales$get_scales("fill")
  expect_identical(unname(scale$map("unchanged")), unname(postrank_palette(which = "change")["unchanged"]))
  expect_identical(unname(scale$map("newly withheld")), unname(postrank_palette(which = "change")["newly withheld"]))
  caption <- pr_unwrap(p$labels$caption)
  expect_match(caption, "unchanged; medium gray = newly withheld", fixed = TRUE)
  expect_match(caption, "Unchanged pairs may be disclosed or withheld", fixed = TRUE)
  expect_match(caption, "Withholding is not equality", fixed = TRUE)
})

test_that("display maps wrap text without changing raw criterion or entity identities", {
  a <- pr_cached("case_cde_12"); before <- a
  text <- "Lower chronic absenteeism probability conditional on the estimated statewide empirical Bayes prior"
  cm <- setNames(text, a$input$criterion_ids)
  p <- postrank_plot_profile(a, criterion_labels = cm)
  expect_identical(as.character(p$data$criterion), a$input$criterion_ids)
  y <- ggplot2::ggplot_build(p)$layout$panel_params[[1L]]$y$get_labels()
  expect_true(grepl("\n", y, fixed = TRUE))
  expect_lte(max(nchar(strsplit(y, "\n", fixed = TRUE)[[1L]])), 22L)
  em <- setNames("School with a deliberately long descriptive display name", a$input$entity_ids[1L])
  auto <- postrank_plot_relations(a, entity_labels = em)
  explicit <- postrank_plot_relations(a, labels = "ids", entity_labels = em)
  expect_identical(auto$data, postrank_plot_data(a, "relations"))
  expect_identical(explicit$data, auto$data)
  expect_lte(length(ggplot2::ggplot_build(auto)$layout$panel_params[[1L]]$x$get_breaks()), 4L)
  expect_true(any(grepl("School", ggplot2::ggplot_build(explicit)$layout$panel_params[[1L]]$x$get_labels(), fixed = TRUE)))
  expect_identical(a, before)
  for (bad in list("unnamed", c(unknown = "A"), setNames(NA_character_, a$input$entity_ids[1L]),
    setNames(c("A", "B"), rep(a$input$entity_ids[1L], 2L))))
    expect_error(postrank_plot_relations(a, entity_labels = bad), class = "postrank_input_error")
  expect_error(postrank_plot_profile(a, criterion_labels = c(unknown = "A")), class = "postrank_input_error")
  expect_error(postrank_plot_profile(a, budgets = NA), class = "postrank_input_error")
  expect_identical(.pr_relation_profile_labels(c("a_b", "a b"), NULL, "criterion_labels"),
    c(a_b = "a_b", `a b` = "a b"))
})

test_that("profile and relation views never recompute the prepared case", {
  a <- pr_cached("case_cde_12"); b <- pr_cached("case_alabama67"); mm <- pr_cached("toy_minimax")
  boom <- function(...) stop("A view called a computation")
  local_mocked_bindings(.pr_solve_core = boom, .pr_solve_raw = boom, postrank_evaluate = boom,
    postrank_pairwise = boom, .pr_posterior_summaries = boom, postrank_diagnose = boom, postrank_report_card = boom)
  for (p in list(postrank_plot_profile(a), postrank_plot_profile(a, "E_over_M"),
    postrank_plot_profile(a, "risk"), postrank_plot_relations(a),
    postrank_plot_relations(b, pr_case_alabama$reference$actions$B1), postrank_plot_profile(mm, "risk")))
    expect_silent(ggplot2::ggplot_build(p))
  expect_match(pr_unwrap(postrank_plot_profile(mm, "risk")$labels$caption), "Orange rings", fixed = TRUE)
})

test_that("zero-weight criteria keep their stored value as a hollow point", {
  # Display-only fixture: the original fixed-action criterion values are kept.
  x <- pr_cached("case_krw_signed97")$fit
  w <- setNames(c(1, 0), x$problem$pairwise$criterion_ids)
  x$problem$settings <- postrank_settings(weights = w, tau = x$problem$settings$tau,
    G_max = x$problem$settings$G_max)
  x$evaluation$weighted_risk <- sum(w * x$evaluation$criterion_risk)
  p <- postrank_plot_profile(x); b <- ggplot2::ggplot_build(p)
  i <- which(vapply(p$layers, function(z) inherits(z$geom, "GeomPoint") && identical(z$aes_params$shape, 1), TRUE))
  expect_length(i, 1L)
  expect_equal(b$data[[i]]$x, unname(x$evaluation$E_over_N[w == 0]), tolerance = 0)
  expect_true(all(b$data[[i]]$size > 0))
  expect_equal(nrow(v1_profile_points(p)) + nrow(b$data[[i]]), nrow(get_profile(x)))
  expect_identical(p$data$weight, c(1, 0))
  expect_identical(p$data$value, unname(x$evaluation$E_over_N))
  expect_true(all(b$plot$scales$get_scales("size")$get_breaks() > 0))
  expect_identical(as.character(b$layout$panel_params[[1L]]$y$get_breaks()), rev(names(w)))
  expect_match(pr_unwrap(p$labels$caption), "Hollow points mark zero-weight criteria", fixed = TRUE)
  all <- pr_cached("analysis_30x3")$fit
  all$problem$settings$weights[] <- c(1, 0, 0)
  empty <- postrank_plot_profile(all)
  expect_false(any(vapply(empty$layers, function(z) inherits(z$geom, "GeomPoint"), TRUE)))
})
