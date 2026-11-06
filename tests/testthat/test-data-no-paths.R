# T-doc-05 / T-pil-06: no shipped data object, cached asset, manifest or vignette source
# carries an absolute machine path; manifests use package-relative paths.
pr_bad_path <- function(v) any(grepl("^/|/Users/|/home/|^[A-Za-z]:\\\\", v))
pr_all_chars <- function(x) {
  if (is.character(x)) return(x)
  if (is.environment(x) || is.function(x)) return(character())
  out <- character()
  if (is.list(x)) out <- unlist(lapply(unclass(x), pr_all_chars), use.names = FALSE)
  a <- attributes(x); a$names <- NULL; a$dimnames <- NULL; a$class <- NULL; a$row.names <- NULL
  c(out, if (length(a)) unlist(lapply(a, pr_all_chars), use.names = FALSE))
}

test_that("bundled data objects carry no machine path in any character field or attribute", {
  for (nm in utils::data(package = "postrank")$results[, "Item"]) {
    e <- new.env(); utils::data(list = nm, package = "postrank", envir = e)
    expect_false(pr_bad_path(pr_all_chars(get(nm, envir = e))), info = nm)
  }
})

test_that("cached assets and manifests carry no machine path", {
  for (f in list.files(system.file("extdata", "cached", package = "postrank"), "\\.rds$", full.names = TRUE))
    expect_false(pr_bad_path(pr_all_chars(readRDS(f))), info = basename(f))
  for (f in list.files(system.file("extdata", package = "postrank"), "\\.json$", recursive = TRUE, full.names = TRUE)) {
    expect_false(pr_bad_path(pr_all_chars(jsonlite::read_json(f))), info = basename(f))
  }
  man <- jsonlite::read_json(system.file("extdata", "manifests", "cache-manifest.json", package = "postrank", mustWork = TRUE))
  expect_true(all(vapply(man$assets, function(a) startsWith(a$file, "extdata/cached/"), TRUE)))
})

test_that("vignette sources and installed documents carry no machine path", {
  dirs <- c(pr_source_path("vignettes"), system.file("doc", package = "postrank"))
  files <- unlist(lapply(dirs[!is.na(dirs) & dir.exists(dirs)], list.files, pattern = "\\.(Rmd|R|html|md)$", full.names = TRUE))
  skip_if(length(files) == 0L, "no vignette files available")
  for (f in files) expect_false(any(grepl("/Users/|/home/", readLines(f, warn = FALSE))), info = basename(f))
})
