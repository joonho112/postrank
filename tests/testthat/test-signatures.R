# T-ref-05: the 24 inherited and 5 ported exports keep their formal names in source order and
# their default expressions, except for the enumerated Appendix C changes (dagger rows).
# T-rel-03: DESCRIPTION metadata of the 0.9.0 candidate. T-doc-09: the live-reproduction record.
test_that("inherited and ported signatures change only where Appendix C says so", {
  ref <- jsonlite::read_json(test_path("fixtures", "inherited-formals.json"))
  expect_length(ref, 29L)
  allowed <- list(
    postrank_solve = list(changed = c(backend = "NULL", strategy = "NULL")),
    postrank_commonality_cost = list(changed = c(backend = "NULL", strategy = "NULL")),
    postrank_crossfit = list(changed = c(backend = "NULL", strategy = "NULL")),
    postrank_protection_analysis = list(changed = c(backend = "NULL")),
    postrank_problem = list(changed = c(weights = "NULL", tau = "NULL", G_max = "NULL"), appended = "settings"),
    postrank_evaluate = list(changed = c(weights = "NULL", tau = "NULL"), appended = "settings"),
    postrank_frontier = list(changed = c(weights = "NULL", G_max = "NULL", backend = "NULL", strategy = "NULL"), appended = "settings"),
    postrank_report = list(changed = c(lang = "\"en\""), appended = c("figures", "analysis")))
  for (n in names(ref)) {
    cur <- lapply(as.list(formals(getExportedValue("postrank", n))), function(v) paste(deparse(v), collapse = " "))
    old <- ref[[n]]$formals
    expect_identical(names(cur)[seq_along(old)], names(old), info = n)
    expect_identical(as.character(setdiff(names(cur), names(old))), allowed[[n]]$appended %||% character(), info = n)
    for (a in names(old)) {
      want <- if (a %in% names(allowed[[n]]$changed)) allowed[[n]]$changed[[a]] else old[[a]]
      expect_identical(cur[[a]], want, info = paste(n, a))
    }
  }
})

test_that("DESCRIPTION carries the release's version, author, DOI and dependency sets", {
  d <- utils::packageDescription("postrank")
  expect_identical(d$Version, "1.2.0")
  expect_match(d$`Authors@R`, "0009-0006-4019-8703", fixed = TRUE)
  expect_match(d$Description, "<doi:10.1257/aer.20230700>", fixed = TRUE)
  deps <- function(field) sort(trimws(sub("\\(.*$", "", strsplit(gsub("\\s+", " ", d[[field]]), ",")[[1]])))
  expect_identical(deps("Imports"), sort(c("cli", "digest", "ggplot2", "grDevices", "jsonlite", "Matrix", "methods", "scales", "stats", "utils")))
  expect_identical(deps("Suggests"), sort(c("callr", "ggrepel", "gmp", "gurobi", "highs", "knitr", "patchwork", "posterior", "rmarkdown",
    "svglite", "testthat", "vdiffr", "withr")))
  expect_identical(d$License, "file LICENSE"); expect_identical(d$Language, "en-US")
  expect_identical(d$`Config/postrank/Data-Distribution`, "public-source-case-studies")
  expect_null(d$Date)
})

test_that("an explicit live reproduction records both results and their agreement (T-doc-09)", {
  skip_if_not_installed("highs")
  e <- new.env(); sys.source(system.file("scripts", "_vignette-setup.R", package = "postrank", mustWork = TRUE), e)
  x <- e$load_or_compute("toy_analysis",
    postrank(postrank_toy, weights = c(need_A = .6, need_B = .4), tau = .25, G_max = 3L, backend = "highs"), live = TRUE)
  lc <- attr(x, "live_comparison")
  expect_true(all(c("cached", "live") %in% names(lc)))
  for (side in c("cached", "live")) expect_true(all(c("status", "risk", "gap", "backend") %in% names(lc[[side]])), info = side)
  expect_identical(lc$live$backend, "highs")
  expect_lte(abs(lc$live$risk - lc$cached$risk), lc$live$gap + lc$cached$gap + 1e-8)
  expect_true(isTRUE(lc$comparable)); expect_true(is.numeric(lc$relation_agreement) && lc$relation_agreement >= 0 && lc$relation_agreement <= 1)
  expect_error(e$load_or_compute("toy_analysis", live = TRUE), "explicit expression")
})
