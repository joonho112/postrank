# Every chunk of the earlier package guide (reference copy in fixtures/) has
# exactly one home among the shipped vignettes; non-executed sketches stay
# unevaluated and the retired index entry is gone.
test_that("each inherited guide chunk lands in exactly one shipped vignette", {
  legacy <- setdiff(pr_chunk_labels(test_path("fixtures", "postrank-guide-0.0.1.9002.Rmd")), "setup")
  expect_length(legacy, 16L)
  srcs <- vapply(pr_vignette_names, pr_vignette_source, "")
  labels <- lapply(srcs, pr_chunk_labels)
  home <- vapply(legacy, function(l) paste(names(labels)[vapply(labels, function(x) l %in% x, TRUE)], collapse = ","), "")
  expected <- c(
    `load-example` = "a5-your-posterior-results",
    `inspect-generator` = "a5-your-posterior-results",
    roundtrip = "a5-your-posterior-results",
    `report-example` = "a6-reading-exporting-results",
    `side-outputs` = "a7-figures-sensitivity",
    pairwise = "m3-posterior-inputs",
    `all-abstain` = "m3-posterior-inputs",
    `stan-repository-workflow` = "m3-posterior-inputs",
    problems = "m5-computing-grades",
    `backend-metadata` = "m5-computing-grades",
    `solve-example` = "m5-computing-grades",
    `solve-highs` = "m5-computing-grades",
    `minimax-highs` = "m5-computing-grades",
    `mc-diagnostics` = "m6-uncertainty-diagnostics",
    diagnostics = "m6-uncertainty-diagnostics",
    `iid-reference` = "m6-uncertainty-diagnostics"
  )
  expect_identical(home[names(expected)], expected)
  expect_setequal(names(home), names(expected))
})

test_that("historical Gurobi and producer sketches stay unevaluated; executed solver chunks read stored results", {
  unevaluated_homes <- c(
    `criterionwise-sketch` = "a5-your-posterior-results",
    `producer-sketch` = "m3-posterior-inputs",
    `stan-repository-workflow` = "m3-posterior-inputs",
    `solve-example` = "m5-computing-grades"
  )
  for (l in names(unevaluated_homes)) {
    src <- readLines(pr_vignette_source(unevaluated_homes[[l]]), warn = FALSE)
    expect_true(any(grepl(sprintf("^```\\{r %s, eval = FALSE\\}", l), src)), info = l)
  }
  destinations <- unique(c(unevaluated_homes, "a6-reading-exporting-results",
    "a7-figures-sensitivity", "m6-uncertainty-diagnostics"))
  for (v in destinations) {
    code <- readLines(pr_purl(v), warn = FALSE)
    live <- code[!grepl("^\\s*#", code)]
    expect_false(any(grepl("postrank_solve\\(|postrank_crossfit\\(|postrank_frontier\\(|postrank_commonality_cost\\(", live)), info = v)
  }
  m5_code <- readLines(pr_purl("m5-computing-grades"), warn = FALSE)
  expect_true(any(grepl("control <- list(time_limit = 10, threads = 1L, seed = 1304L)", m5_code, fixed = TRUE)))
  expect_false(file.exists(pr_source_path("vignettes", "postrank-guide.Rmd")))
  readme <- readLines(system.file("examples", "README.txt", package = "postrank", mustWork = TRUE))
  expect_true(any(grepl('vignette("a5-your-posterior-results", package="postrank")', readme, fixed = TRUE)))
  expect_false(any(grepl("postrank-guide", readme, fixed = TRUE)))
})
