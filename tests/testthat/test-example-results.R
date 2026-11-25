# postrank_example() lists and reads the stored example results without a solver.
ex_manifest <- function() jsonlite::read_json(system.file("extdata", "manifests", "cache-manifest.json", package = "postrank", mustWork = TRUE))

test_that("the listing covers every stored result with its recorded call", {
  man <- ex_manifest()
  ex <- postrank_example()
  expect_s3_class(ex, "data.frame")
  expect_identical(names(ex), c("name", "class", "description", "call", "computed_with", "solves", "created"))
  expect_identical(ex$name, sort(names(man$assets), method = "radix"))
  expect_length(ex$name, 21L)
  expect_identical(ex$class, vapply(ex$name, function(k) man$assets[[k]]$object_class, "", USE.NAMES = FALSE))
  expect_identical(ex$call, vapply(ex$name, function(k) man$assets[[k]]$call, "", USE.NAMES = FALSE))
  expect_false(anyNA(ex$description))
  expect_true(all(nzchar(ex$description)))
  expect_setequal(names(postrank:::.pr_example_descriptions), names(man$assets))
  expect_identical(startsWith(ex$computed_with, "postrank 1.1.0, highs "), ex$solves > 0L)
  expect_identical(ex$computed_with[ex$solves == 0L], rep("postrank 1.1.0, no solver", sum(ex$solves == 0L)))
})

test_that("every stored result reads with its recorded class and no solver call", {
  boom <- function(...) stop("solver entry point called")
  local_mocked_bindings(.pr_backend_require = boom, .pr_solve_core = boom, .pr_backend_highs = boom, .pr_backend_gurobi = boom)
  man <- ex_manifest()
  for (k in names(man$assets)) expect_s3_class(postrank_example(k), man$assets[[k]]$object_class)
})

test_that("a stored result is the object the vignette reader returns", {
  reader <- new.env()
  sys.source(system.file("scripts", "_vignette-setup.R", package = "postrank", mustWork = TRUE), reader)
  for (k in c("tutorial_one", "toy_minimax", "comparison_30x3")) expect_identical(postrank_example(k), reader$load_or_compute(k))
})

test_that("unknown and malformed names give clear errors", {
  err <- tryCatch(postrank_example("no_such_result"), error = identity)
  expect_identical(err$code, "unknown_example")
  expect_match(conditionMessage(err), "tutorial_one", fixed = TRUE)
  for (bad in list(1, c("tutorial_one", "tutorial_two"), NA_character_)) {
    err <- tryCatch(postrank_example(bad), error = identity)
    expect_identical(err$code, "invalid_example_name")
  }
})

test_that("a reader failure gives a user message and keeps the reader's condition", {
  msg <- "cached asset 'tutorial_one': asset digest differs (sha256). Rebuild with POSTRANK_BUILD_CACHED_ASSETS=true Rscript inst/scripts/build-cached-assets.R"
  local_mocked_bindings(.pr_example_reader = function() {
    e <- new.env(); e$load_or_compute <- function(key) stop(msg, call. = FALSE); e
  })
  err <- tryCatch(postrank_example("tutorial_one"), error = identity)
  expect_identical(err$code, "example_unreadable")
  expect_false(grepl("Rebuild|POSTRANK_BUILD|cached asset", conditionMessage(err)))
  expect_match(conditionMessage(err), "asset digest differs (sha256)", fixed = TRUE)
  expect_match(conditionMessage(err), "Reinstall postrank", fixed = TRUE)
  expect_identical(conditionMessage(err$parent), msg)
})
