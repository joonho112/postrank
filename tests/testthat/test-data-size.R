# T-doc-04 / T-rel-14: source data/*.rda use xz and stay within 4 MiB; the installed data/
# directory stays within 5 MiB; no data/*.R generator exists. Cache bytes are measured
# separately and are not part of either data budget.
test_that("source data files are xz-compressed .rda within the 4 MiB budget", {
  src <- pr_source_path("data"); skip_if_not(dir.exists(src), "source checkout not available")
  files <- list.files(src, full.names = TRUE)
  expect_true(all(grepl("\\.rda$", files)), info = paste(basename(files), collapse = ", "))
  expect_length(files, 8L)
  info <- tools::checkRdaFiles(files)
  expect_true(all(info$compress == "xz"), info = paste(rownames(info)[info$compress != "xz"], collapse = ", "))
  expect_lte(sum(file.size(files)), 4194304)
})

test_that("the installed data directory stays within the 5 MiB budget", {
  inst <- system.file("data", package = "postrank")
  skip_if(!nzchar(inst), "no data directory")
  files <- list.files(inst, full.names = TRUE, recursive = TRUE)
  expect_false(any(grepl("\\.R$", files)))
  expect_lte(sum(file.size(files)), 5242880)
})

test_that("the data manifest records the measured source bytes and both budgets", {
  man <- jsonlite::read_json(system.file("extdata", "manifests", "data-manifest.json", package = "postrank", mustWork = TRUE))
  expect_identical(man$source_data_budget_bytes, 4194304L)
  expect_identical(man$installed_data_budget_bytes, 5242880L)
  expect_identical(as.numeric(man$source_data_bytes), sum(vapply(man$objects, function(o) as.numeric(o$bytes), 1)))
  expect_lte(man$source_data_bytes, 4194304)
  src <- pr_source_path("data")
  if (dir.exists(src)) for (o in man$objects)
    expect_identical(as.numeric(file.size(pr_source_path(o$file))), as.numeric(o$bytes), info = o$object)
})
