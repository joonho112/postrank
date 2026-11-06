# T-doc-14: every chunk of the retired 0.0.1.9002 guide (frozen copy in fixtures/) has exactly
# one built destination among the four shipped vignettes; non-executed sketches stay
# unevaluated and the retired index entry is gone.
test_that("each inherited guide chunk lands in exactly one shipped vignette", {
  legacy <- setdiff(pr_chunk_labels(test_path("fixtures", "postrank-guide-0.0.1.9002.Rmd")), "setup")
  expect_length(legacy, 16L)
  srcs <- vapply(pr_vignette_names, pr_vignette_source, "")
  labels <- lapply(srcs, pr_chunk_labels)
  home <- vapply(legacy, function(l) paste(names(labels)[vapply(labels, function(x) l %in% x, TRUE)], collapse = ","), "")
  expected <- c(`load-example` = "inputs-and-producers", `inspect-generator` = "inputs-and-producers",
    pairwise = "inputs-and-producers", `all-abstain` = "inputs-and-producers", problems = "inputs-and-producers",
    `backend-metadata` = "inputs-and-producers", `solve-example` = "inputs-and-producers",
    `solve-highs` = "inputs-and-producers", `minimax-highs` = "inputs-and-producers",
    `side-outputs` = "baselines-and-the-cost-of-a-common-grade", `mc-diagnostics` = "inputs-and-producers",
    diagnostics = "inputs-and-producers", `report-example` = "quickstart", `iid-reference` = "inputs-and-producers",
    roundtrip = "inputs-and-producers", `stan-repository-workflow` = "inputs-and-producers")
  expect_identical(home[names(expected)], expected)
  expect_setequal(names(home), names(expected))
})

test_that("historical Gurobi and producer sketches stay unevaluated; executed solver chunks read caches", {
  v2 <- readLines(pr_vignette_source("inputs-and-producers"), warn = FALSE)
  for (l in c("solve-example", "stan-repository-workflow", "producer-sketch", "criterionwise-sketch"))
    expect_true(any(grepl(sprintf("^```\\{r %s, eval = FALSE\\}", l), v2)), info = l)
  code <- readLines(pr_purl("inputs-and-producers"), warn = FALSE)
  live <- code[!grepl("^\\s*#", code)]
  expect_false(any(grepl("postrank_solve\\(|postrank_crossfit\\(|postrank_frontier\\(|postrank_commonality_cost\\(", live)))
  expect_true(any(grepl("control <- list(time_limit = 10, threads = 1L, seed = 1304L)", code, fixed = TRUE)))
  # The retired index entry is not shipped and the examples README points to V2.
  expect_false(file.exists(pr_source_path("vignettes", "postrank-guide.Rmd")))
  readme <- readLines(system.file("examples", "README.txt", package = "postrank", mustWork = TRUE))
  expect_true(any(grepl('vignette("inputs-and-producers", package="postrank")', readme, fixed = TRUE)))
  expect_false(any(grepl("postrank-guide", readme, fixed = TRUE)))
})
