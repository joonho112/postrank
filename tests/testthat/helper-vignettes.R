# The package source checkout, recognized by its sources rather than by a directory name (an
# installed package also has an R/ directory, holding the lazy-load database); NULL otherwise.
pr_source_root <- function() {
  r <- testthat::test_path("..", "..")
  if (file.exists(file.path(r, "DESCRIPTION")) && file.exists(file.path(r, "R", "postrank-analysis.R"))) normalizePath(r) else NULL
}
pr_source_path <- function(...) { r <- pr_source_root(); if (is.null(r)) NA_character_ else file.path(r, ...) }
# Locate a vignette source (source checkout, else the installed doc/ copy), purl it and run
# its code in a fresh environment; solver entry points are mocked by the caller.
pr_applied_vignette_names <- c("a1-getting-started", "a2-cde-accountability", "a3-krw-race-gender",
  "a4-alabama-opportunity", "a5-your-posterior-results", "a6-reading-exporting-results", "a7-figures-sensitivity")
pr_legacy_vignette_names <- c("quickstart", "inputs-and-producers", "baselines-and-the-cost-of-a-common-grade")
pr_method_vignette_names <- c("m1-ranking-and-loss", "m2-several-criteria", "m3-posterior-inputs",
  "m4-ties-and-withholding", "m5-computing-grades", "m6-uncertainty-diagnostics")
pr_reference_vignette_names <- c("migration-from-0-9", "figure-gallery")
pr_mdomain_vignette_names <- c("mdomain-quickstart", "mdomain-decisions")
pr_vignette_names <- c(pr_mdomain_vignette_names, pr_applied_vignette_names, pr_method_vignette_names, pr_reference_vignette_names, pr_legacy_vignette_names)
pr_vignette_source <- function(name) {
  cands <- c(pr_source_path("vignettes", paste0(name, ".Rmd")), system.file("doc", paste0(name, ".Rmd"), package = "postrank"))
  cands <- cands[!is.na(cands) & nzchar(cands) & file.exists(cands)]
  if (!length(cands)) testthat::skip(paste("vignette source", name, "not available"))
  cands[[1L]]
}
pr_purl <- function(name) {
  testthat::skip_if_not_installed("knitr")
  out <- tempfile(fileext = ".R")
  knitr::purl(pr_vignette_source(name), output = out, quiet = TRUE, documentation = 0L)
  out
}
pr_run_vignette <- function(name) {
  code <- pr_purl(name)
  env <- new.env(parent = globalenv())
  grDevices::pdf(NULL); on.exit(grDevices::dev.off(), add = TRUE)
  utils::capture.output(sys.source(code, envir = env))
  env
}
# Chunk labels of an R Markdown file, in order.
pr_chunk_labels <- function(path) {
  lines <- readLines(path, warn = FALSE, encoding = "UTF-8")
  heads <- grep("^```\\{r[ ,]", lines, value = TRUE)
  sub("^```\\{r[ ,]+([^ ,}]+).*$", "\\1", heads)
}
# Prose of an R Markdown file: YAML header, code chunks and inline code removed.
pr_vignette_prose <- function(path) {
  lines <- readLines(path, warn = FALSE, encoding = "UTF-8")
  yaml_end <- which(lines == "---")[2L]
  lines <- lines[-seq_len(yaml_end)]
  inside <- cumsum(grepl("^```", lines)) %% 2L == 1L | grepl("^```", lines)
  prose <- lines[!inside]
  gsub("`r [^`]*`", " ", prose)
}
# The Rd database of the source checkout, else of the installed package, and one Rd field.
pr_rd_db <- function() {
  root <- pr_source_root()
  if (!is.null(root)) tools::Rd_db(dir = root) else tools::Rd_db("postrank", lib.loc = dirname(system.file(package = "postrank")))
}
pr_rd_field <- function(rd, tag) {
  tags <- vapply(rd, function(x) attr(x, "Rd_tag"), "")
  unlist(lapply(rd[tags == tag], function(z) paste(as.character(z), collapse = "")))
}
# Figure labels are wrapped for narrow canvases; match their text with the line breaks removed.
pr_unwrap <- function(x) if (is.null(x)) NULL else gsub("\\s*\n\\s*", " ", x)
