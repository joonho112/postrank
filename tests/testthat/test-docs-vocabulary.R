# T-doc-16: contextual wording checks on the authored prose of the shipped vignettes and the
# README. Prohibited claims are rejected unless the sentence negates them; technical field
# names and code are not scanned.
pr_doc_sentences <- function(path) {
  txt <- paste(pr_vignette_prose(path), collapse = " ")
  txt <- gsub("`[^`]*`", " ", txt)
  s <- unlist(strsplit(tolower(gsub("\\s+", " ", txt)), "(?<=[.;!?])\\s+", perl = TRUE))
  s[nzchar(trimws(s))]
}
pr_never_say <- c("improves rank accuracy", "more informative", "exploits joint dependence", "is superior",
  "universally optimal", "confidence interval", "significant", "the entities are equal", "unique optimum",
  "probability of improvement", "error-free ranking", "proves that")
pr_negation <- "\\b(not|never|no|cannot|isn't|neither|nor|without)\\b"

pr_doc_files <- function() {
  files <- vapply(pr_vignette_names, pr_vignette_source, "")
  readme <- pr_source_path("README.Rmd")
  if (file.exists(readme)) files <- c(files, README = readme)
  files
}

test_that("authored prose passes the contextual wording guard", {
  for (f in pr_doc_files()) expect_identical(.pr_cli_guard(pr_doc_sentences(f)), character(), info = basename(f))
})

test_that("prohibited claims appear only in negated sentences", {
  for (f in pr_doc_files()) for (s in pr_doc_sentences(f)) for (p in pr_never_say)
    if (grepl(p, s, fixed = TRUE)) expect_match(s, pr_negation, perl = TRUE, info = paste(basename(f), p))
})

test_that("the guard distinguishes claims from negations", {
  expect_length(.pr_cli_guard("The joint rule found the unique optimum."), 1L)
  expect_length(.pr_cli_guard("The grade is certified."), 1L)
  expect_identical(.pr_cli_guard("It is not a numerical certificate; the number of optima is unknown."), character())
  expect_identical(.pr_cli_guard("A shared grade does not assert equality, and all-tie is not an error-free ranking."), character())
})
