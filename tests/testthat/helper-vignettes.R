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
pr_method_vignette_names <- c("m1-ranking-and-loss", "m2-several-criteria", "m3-posterior-inputs",
  "m4-ties-and-withholding", "m5-computing-grades", "m6-uncertainty-diagnostics")
pr_reference_vignette_names <- c("figure-gallery")
pr_mdomain_vignette_names <- c("mdomain-quickstart", "mdomain-decisions")
pr_vignette_names <- c(pr_mdomain_vignette_names, pr_applied_vignette_names, pr_method_vignette_names, pr_reference_vignette_names)
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
# Knit in a temporary directory so figures and exports stay out of the source tree.
# Compare each executed public example call with the source knitr shows in its chunk.
pr_run_vignette <- function(name, path = pr_vignette_source(name)) {
  txt <- readLines(path, warn = FALSE, encoding = "UTF-8")
  withr::local_dir(withr::local_tempdir())
  env <- new.env(parent = globalenv())
  reader <- postrank::postrank_example
  reads <- list()
  testthat::local_mocked_bindings(postrank_example = function(...) {
    label <- knitr::opts_current$get("label")
    reads[[label]] <<- c(reads[[label]], paste(deparse(sys.call(), width.cutoff = 500L), collapse = " "))
    reader(...)
  }, .package = "postrank")

  old_hooks <- knitr::knit_hooks$get()
  old_options <- knitr::opts_chunk$get()
  on.exit({
    knitr::knit_hooks$restore(old_hooks)
    knitr::opts_chunk$restore(old_options)
  }, add = TRUE)
  knitr::render_markdown()
  original_source <- knitr::knit_hooks$get("source")
  shown <- list()
  knitr::knit_hooks$set(source = function(x, options) {
    if (isTRUE(options$include))
      shown[[options$label]] <<- c(shown[[options$label]], x)
    original_source(x, options)
  })
  knitr::opts_chunk$set(error = FALSE)
  invisible(knitr::knit(text = txt, quiet = TRUE, envir = env))
  # Compare parsed source so spacing, line wrapping and the choice of quotes do not matter.
  for (label in names(reads)) {
    code <- parse(text = if (is.null(shown[[label]])) character() else shown[[label]], keep.source = FALSE)
    displayed <- paste(vapply(code, deparse1, "", width.cutoff = 500L), collapse = " ")
    for (call in unique(reads[[label]])) {
      if (!grepl(call, displayed, fixed = TRUE)) stop(name, " chunk ", label, " does not show ", call)
    }
  }
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
