# Every shipped vignette runs without native solver calls; m2-several-criteria
# runs two bounded 30-entity dynamic-programming score cuts.
test_that("the vignettes run with zero native solver calls", {
  skip_on_cran()
  boom <- function(...) stop("solver entry point called by a vignette")
  # .pr_backend_require() is on every solve path outside any error handler (commonality and the LP engine included).
  local_mocked_bindings(.pr_backend_require = boom, .pr_solve_core = boom, .pr_backend_highs = boom, .pr_backend_gurobi = boom)
  native <- 0L
  if (requireNamespace("highs", quietly = TRUE)) {
    local_mocked_bindings(highs_solve = function(...) { native <<- native + 1L; stop("native HiGHS call") },
      highs_solver = function(...) { native <<- native + 1L; stop("native HiGHS call") }, .package = "highs")
  }
  for (v in pr_vignette_names) {
    env <- expect_no_error(pr_run_vignette(v))
    expect_true(is.environment(env), info = v)
  }
  readme <- pr_source_path("README.Rmd")
  if (!is.na(readme) && file.exists(readme))
    expect_no_error(pr_run_vignette("README", readme))
  expect_identical(native, 0L)
})

test_that("knitted examples expose the calls they execute in the same chunk", {
  skip_if_not_installed("knitr")
  src <- withr::local_tempfile(fileext = ".Rmd")
  load <- 'one <- postrank_example("tutorial_one")'
  writeLines(c('```{r hidden, include=FALSE}', load, '```',
    '```{r display-only, eval=FALSE}', load, '```'), src)
  expect_error(pr_run_vignette("fixture", src), "chunk hidden does not show postrank_example")
  writeLines(c('```{r setup, include=FALSE}', 'knitr::opts_chunk$set(echo = FALSE)', '```',
    '```{r read}', load, '```'), src)
  expect_error(pr_run_vignette("fixture", src), "chunk read does not show postrank_example")
  writeLines(c('```{r read, echo=2}', 'i <- 1L', load, '```'), src)
  expect_no_error(pr_run_vignette("fixture", src))
})

test_that("executed vignette code respects its declared computation scope", {
  verbs <- c("postrank_solve", "postrank_tie_solve", "postrank_cuts", "postrank",
    "postrank_frontier", "postrank_sensitivity", "postrank_commonality_cost", "postrank_crossfit")
  for (v in pr_vignette_names) {
    pd <- utils::getParseData(parse(pr_purl(v), keep.source = TRUE))
    called <- unique(pd$text[pd$token == "SYMBOL_FUNCTION_CALL"])
    forbidden <- if (identical(v, "m2-several-criteria"))
      setdiff(verbs, "postrank_cuts") else verbs
    expect_identical(intersect(forbidden, called), character(), info = v)
  }
})

test_that("stored example results are introduced with a plain non-solving note", {
  known <- postrank_example()[["name"]]
  with_stored <- character()
  for (v in pr_vignette_names) {
    src <- readLines(pr_vignette_source(v), warn = FALSE)
    expect_false(any(grepl("\\bload_or_compute\\s*\\(", src)), info = v)
    keys <- unique(unlist(regmatches(src, gregexpr('postrank_example\\("[^"]+"\\)', src))))
    keys <- sub('^postrank_example\\("([^"]+)"\\)$', "\\1", keys)
    if (!length(keys)) next
    with_stored <- c(with_stored, v)
    expect_true(all(keys %in% known), info = v)
    prose <- paste(pr_vignette_prose(pr_vignette_source(v)), collapse = " ")
    expect_match(prose, "\\b(stored|precomputed)\\b", ignore.case = TRUE, info = v)
    expect_match(prose, "without (fitting a model or )?running|runs no solver|needs no (external LP or MIP |optimization )?solver|without model fitting or optimization",
      ignore.case = TRUE, info = v)
  }
  expect_gte(length(with_stored), 11L)
  e <- new.env(); sys.source(system.file("scripts", "_vignette-setup.R", package = "postrank", mustWork = TRUE), e)
  note <- e$cache_note("analysis_30x3_tau35")
  expect_match(note, "explicitly selected highs backend", fixed = TRUE)
  expect_match(note, "[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}Z")
  expect_error(e$cache_note("no_such_asset"), "no such cached asset")
})


test_that("local redirect pages link to the destination even without automatic refresh", {
  finish <- pr_source_path("tools", "finish-site.R")
  skip_if(is.na(finish) || !file.exists(finish), "website sources not available")
  skip_if_not_installed("pkgdown")
  scripts <- new.env()
  sys.source(finish, scripts)
  site <- withr::local_tempdir()
  dir.create(file.path(site, "articles"))
  dir.create(file.path(site, "news"))
  writeLines('<html><body><h1>Getting started</h1></body></html>', file.path(site, "articles", "start.html"))
  writeLines('<html><body><h2 id="migration">Migration notes</h2></body></html>', file.path(site, "news", "index.html"))
  refresh <- function(file, target) writeLines(sprintf(
    '<html><head><meta http-equiv="refresh" content="0;URL=%s"></head></html>', target),
    file.path(site, "articles", file))
  refresh("old.html", "start.html")
  refresh("migration.html", "https://example.org/pkg/news/index.html#migration")
  result <- scripts$localize_alias_redirects(site, "https://example.org/pkg/")
  expect_equal(result$aliases_localized_this_run, 2L)
  start <- paste(readLines(file.path(site, "articles", "old.html")), collapse = " ")
  migration <- paste(readLines(file.path(site, "articles", "migration.html")), collapse = " ")
  expect_match(start, '<a href="start.html">Getting started</a>', fixed = TRUE)
  expect_match(migration, '<a href="../news/index.html#migration">Migration notes</a>', fixed = TRUE)
  expect_match(migration, 'content="0;URL=../news/index.html#migration"', fixed = TRUE)
  expect_equal(scripts$localize_alias_redirects(site, "https://example.org/pkg/")$aliases_localized_this_run, 0L)
})
