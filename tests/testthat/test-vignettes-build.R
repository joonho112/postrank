# T-doc-02 / T-doc-15: every vignette avoids native backend solves. The retained
# advanced baseline article also demonstrates two bounded, 30-entity DP cuts.
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
  expect_identical(native, 0L)
})

test_that("executed vignette code respects its declared computation scope", {
  verbs <- c("postrank_solve", "postrank_tie_solve", "postrank_cuts", "postrank",
    "postrank_frontier", "postrank_sensitivity", "postrank_commonality_cost", "postrank_crossfit")
  for (v in pr_vignette_names) {
    pd <- utils::getParseData(parse(pr_purl(v), keep.source = TRUE))
    called <- unique(pd$text[pd$token == "SYMBOL_FUNCTION_CALL"])
    forbidden <- if (identical(v, "baselines-and-the-cost-of-a-common-grade"))
      setdiff(verbs, "postrank_cuts") else verbs
    expect_identical(intersect(forbidden, called), character(), info = v)
  }
})

test_that("cached results are introduced with their source note", {
  for (v in c("quickstart", "inputs-and-producers", "baselines-and-the-cost-of-a-common-grade")) {
    src <- readLines(pr_vignette_source(v), warn = FALSE)
    keys <- unique(sub('.*load_or_compute\\("([^"]+)"\\).*', "\\1", grep('load_or_compute\\("', src, value = TRUE)))
    noted <- unique(sub('.*cache_note\\("([^"]+)"\\).*', "\\1", grep('cache_note\\("', src, value = TRUE)))
    expect_gt(length(noted), 0L)
    expect_true(all(noted %in% keys), info = v)
    expect_match(paste(src, collapse = " "), "(sealed|source-bound)\\s+cache|caches?\\s+bound\\s+to\\s+their\\s+source", info = v)
  }
  e <- new.env(); sys.source(system.file("scripts", "_vignette-setup.R", package = "postrank", mustWork = TRUE), e)
  note <- e$cache_note("analysis_30x3_tau35")
  expect_match(note, "explicitly selected highs backend", fixed = TRUE)
  expect_match(note, "[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}Z")
  expect_error(e$cache_note("no_such_asset"), "no such cached asset")
})
