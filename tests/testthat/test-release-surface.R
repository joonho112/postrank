# T-doc-06 / T-ref-03 (pkgdown index), T-doc-07 (README capture), T-rel-03/04/06/13
# (metadata, citation, NEWS coverage and version agreement).
pr_inherited_exports <- c("as_postrank_draws", "as_postrank_posterior", "canonical_postrank_grade",
  "postrank_backend_available", "postrank_commonality_cost", "postrank_crossfit", "postrank_diagnose",
  "postrank_draws_from_array", "postrank_evaluate", "postrank_frontier", "postrank_guarantee_capabilities",
  "postrank_iid_bounds", "postrank_mc_fragility", "postrank_pairwise", "postrank_problem",
  "postrank_protection_analysis", "postrank_protection_envelopes", "postrank_regret_bound", "postrank_report",
  "postrank_solve", "read_postrank_draws", "validate_postrank_draws", "validate_postrank_solution", "write_postrank_draws")

test_that("every export sits in exactly one pkgdown reference group; articles are the built vignettes", {
  cfg <- pr_source_path("_pkgdown.yml"); skip_if_not(file.exists(cfg), "_pkgdown.yml is a source-only file")
  lines <- readLines(cfg)
  db <- pr_rd_db()
  concepts <- lapply(db, pr_rd_field, tag = "\\concept"); aliases <- lapply(db, pr_rd_field, tag = "\\alias")
  ref <- lines[seq(grep("^reference:", lines), length(lines))]
  items <- trimws(sub("^\\s*-\\s*", "", grep("^\\s{2}-\\s", ref, value = TRUE)))
  topics <- unlist(lapply(items, function(it) {
    if (grepl("^has_concept", it)) names(concepts)[vapply(concepts, function(cc) sub('^has_concept\\("(.*)"\\)$', "\\1", it) %in% cc, TRUE)]
    else paste0(it, ".Rd")
  }))
  root <- pr_source_root()
  exports <- parseNamespaceFile(basename(root), dirname(root))$exports
  expect_setequal(exports, getNamespaceExports("postrank"))
  for (e in exports) {
    hits <- sum(vapply(topics, function(t) e %in% aliases[[t]], TRUE))
    expect_identical(hits, 1L, info = e)
  }
  expect_length(exports, 105L)
  expect_true(all(c("postrank-package.Rd", "postrank_options.Rd") %in% topics))
  data_topics <- names(concepts)[vapply(concepts, function(cc) "data" %in% cc, TRUE)]
  expect_length(data_topics, 8L)
  arts <- trimws(sub("^\\s*-\\s*", "", grep("^  - ", lines[seq(grep("^articles:", lines), grep("^reference:", lines) - 1L)], value = TRUE)))
  expect_setequal(arts, sub("\\.Rmd$", "", list.files(pr_source_path("vignettes"), "\\.Rmd$")))
  expect_setequal(arts, pr_vignette_names)
  expect_false(any(grepl("postrank_plot_sensitivity|postrank_plot_fragility|postrank_plot_crossfit|postrank_plot_trace|postrank_plot_dispersion", lines)))
})

test_that("the README's two captured analyses equal their prepared formatters", {
  readme <- pr_source_path("README.md"); skip_if_not(file.exists(readme), "README.md not available")
  r <- readLines(readme, encoding = "UTF-8")
  i <- grep("^    #> <postrank_analysis>", r)
  expect_length(i, 2L)
  for (j in seq_along(i)) {
    expected <- format_postrank_analysis_cli(pr_cached(c("tutorial_one", "tutorial_two")[[j]]), width = 80)
    expect_identical(sub("^    #> ", "", r[i[j]:(i[j] + length(expected) - 1L)]), expected)
  }
  expect_match(paste(r, collapse = " "), "explicitly selected highs backend", fixed = TRUE)
  expect_false(any(grepl("install.packages\\(\"postrank\"\\)|CRAN version", r)))
})

test_that("NEWS names every export added since the 24 inherited ones", {
  news <- c(pr_source_path("NEWS.md"), system.file("NEWS.md", package = "postrank"))
  news <- news[!is.na(news) & nzchar(news) & file.exists(news)][1L]
  skip_if(is.na(news), "NEWS.md not available")
  l <- readLines(news, encoding = "UTF-8")
  expect_identical(l[1L], "# postrank 1.2.0")
  entry <- paste(l[seq_len(grep("^# postrank 0\\.0\\.1\\.9003", l)[1L] - 1L)], collapse = " ")
  added <- setdiff(getNamespaceExports("postrank"), pr_inherited_exports)
  expect_length(added, 81L)
  for (e in added) expect_true(grepl(paste0("`", e, "()`"), entry, fixed = TRUE), info = e)
  expect_false(grepl("`postrank_coefficients()`", entry, fixed = TRUE))   # the deferred user constructor
})

test_that("version, citation and licence agree on the public release", {
  expect_identical(as.character(utils::packageVersion("postrank")), "1.2.0")
  source_citation <- pr_source_path("inst", "CITATION")
  cit <- if (!is.na(source_citation) && file.exists(source_citation))
    utils::readCitationFile(source_citation, meta = utils::packageDescription("postrank")) else
      utils::citation("postrank")
  expect_length(cit, 3L)
  expect_match(gsub("\\s+", " ", paste(format(cit[[1]], style = "text"), collapse = " ")),
    "R package version 1.2.0", fixed = TRUE)
  expect_identical(cit[[1]]$url, "https://github.com/joonho112/postrank")
  expect_match(cit[[1]]$note, "https://joonho112.github.io/postrank/", fixed = TRUE)
  expect_identical(cit[[2]]$doi, "10.5281/zenodo.23790260")
  expect_identical(cit[[2]]$url, "https://joonho112.github.io/postrank-theory-book/")
  expect_identical(cit[[2]]$note, "Version 1.0.0")
  expect_identical(cit[[3]]$doi, "10.1257/aer.20230700")
  lic <- system.file("LICENSE", package = "postrank")
  if (nzchar(lic)) {
    text <- paste(readLines(lic), collapse = "\n")
    expect_match(text, "Copyright (c) 2026 JoonHo Lee", fixed = TRUE)
    expect_match(text, "MIT License", fixed = TRUE)
    expect_match(text, "CC-BY-NC", fixed = TRUE)
    expect_match(text, "CC BY 4.0", fixed = TRUE)
  }
  d <- utils::packageDescription("postrank")
  expect_identical(d$License, "file LICENSE")
  notice <- system.file(d$`Config/postrank/Data-Notice`, package = "postrank")
  expect_true(nzchar(notice))
  expect_match(d$URL, "https://github.com/joonho112/postrank", fixed = TRUE)
})
