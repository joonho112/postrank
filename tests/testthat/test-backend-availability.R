testthat::test_that("metadata availability distinguishes missing package, known block and untested runtime", {
  missing <- .pr_backend_availability_record("gurobi", list(installed = FALSE, package_path = NA_character_, wrapper_version = NA_character_))
  testthat::expect_false(missing$installed); testthat::expect_false(missing$available_for_attempt)
  testthat::expect_identical(missing$runtime_check$status, "not_run_package_absent")
  present <- list(installed = TRUE, package_path = "/mock/metadata-only/gurobi", wrapper_version = "mock-version")
  blocked <- .pr_backend_availability_record("gurobi", present, list(status = "absolute_R_runtime_link_mismatch"))
  testthat::expect_true(blocked$installed); testthat::expect_false(blocked$available_for_attempt)
  testthat::expect_identical(blocked$runtime_check$status, "blocked_known_R_runtime_mismatch")
  # Some older guard snapshots expose the condition code before updating the
  # details status. A known blocker cannot become available through that path.
  code_blocked <- .pr_backend_availability_record("gurobi", present,
    list(status = "not_verified_on_this_platform", condition_code = "gurobi_R_runtime_mismatch"))
  testthat::expect_false(code_blocked$available_for_attempt)
  available <- .pr_backend_availability_record("highs", present)
  testthat::expect_true(available$available_for_attempt)
  testthat::expect_false(available$runtime_check$executed)
  testthat::expect_false(available$runtime_check$general_runtime_verified)
  testthat::expect_false(available$license_check$executed)
  testthat::expect_identical(available$license_check$status, "not_applicable")
  testthat::expect_true(is.na(available$license_check$valid))
})

testthat::test_that("availability reads installed metadata without loading backend namespaces", {
  before <- vapply(c("gurobi", "highs", "cmdstanr"), isNamespaceLoaded, logical(1L))
  records <- lapply(c("gurobi", "highs"), postrank_backend_available)
  after <- vapply(c("gurobi", "highs", "cmdstanr"), isNamespaceLoaded, logical(1L))
  testthat::expect_identical(after, before)
  for (r in records) {
    path <- tryCatch(find.package(r$backend, quiet = TRUE), error = function(e) character())
    testthat::expect_identical(r$installed, length(path) > 0L)
    testthat::expect_false(r$runtime_check$executed)
    testthat::expect_false(r$license_check$executed)
    if (r$installed) {
      testthat::expect_identical(r$package_path, path[[1L]])
      testthat::expect_identical(r$wrapper_version,
        unname(read.dcf(file.path(path[[1L]], "DESCRIPTION"), fields = "Version")[1L, 1L]))
    }
  }
  testthat::expect_error(postrank_backend_available("cmdstanr"), "arg")
})

testthat::test_that("actual known global Gurobi linkage mismatch remains blocked in a fresh child", {
  testthat::skip_if(!identical(Sys.info()[["sysname"]], "Darwin") || !nzchar(Sys.which("otool")), "macOS otool guard not applicable")
  package_path <- tryCatch(find.package("gurobi", lib.loc = .Library, quiet = TRUE), error = function(e) character())
  testthat::skip_if(!length(package_path), "Global Gurobi package absent")
  observed <- tryCatch(.pr_gurobi_runtime_guard(package_path), error = function(e) e)
  testthat::skip_if(!inherits(observed, "postrank_backend_unavailable") || !identical(observed$code, "gurobi_R_runtime_mismatch"),
    "Global library does not exhibit the known runtime-link mismatch")
  root <- normalizePath(testthat::test_path("..", ".."))
  script <- testthat::test_path("..", "fixtures", "runtime", "gurobi-link-guard.R")
  output <- tempfile(fileext = ".rds")
  stdout <- tempfile(); stderr <- tempfile(); config_path <- tempfile(fileext = ".rds")
  on.exit(unlink(c(output, stdout, stderr, config_path)), add = TRUE)
  source_mode <- file.exists(file.path(root, "R", "problem-class.R"))
  saveRDS(list(output = output, global_library = .Library,
    source_root = if (source_mode) root else NULL,
    postrank_library = if (source_mode) character() else dirname(find.package("postrank"))), config_path)
  argv <- c("--vanilla", script, config_path)
  exit <- system2(file.path(R.home("bin"), "Rscript"), vapply(argv, shQuote, character(1L)),
    stdout = stdout, stderr = stderr, env = "R_TESTS=")
  testthat::expect_identical(exit, 0L, info = paste(c(readLines(stdout, warn = FALSE), readLines(stderr, warn = FALSE)), collapse = "\n"))
  if (exit == 0L) {
    record <- readRDS(output)
    testthat::expect_true(record$availability$installed)
    testthat::expect_false(record$availability$available_for_attempt)
    testthat::expect_identical(record$availability$runtime_check$status, "blocked_known_R_runtime_mismatch")
    testthat::expect_identical(record$availability$runtime_check$known_linkage_check$condition_code, "gurobi_R_runtime_mismatch")
    testthat::expect_false(record$namespace_loaded_before)
    testthat::expect_false(record$namespace_loaded_after)
  }
})
