testthat::test_that("saved sparse problems initialize Matrix in a fresh R process", {
  problem <- postrank_problem(postrank_pairwise(pr_test_payload()),
    c(need1 = .5, need2 = .5), .25, 3L)
  workspace <- tempfile("postrank-fresh-sparse-", tmpdir = tempdir())
  dir.create(workspace)
  on.exit(unlink(workspace, recursive = TRUE), add = TRUE)
  problem_path <- file.path(workspace, "problem.rds")
  saveRDS(problem, problem_path)
  root <- normalizePath(testthat::test_path("..", ".."))
  source_mode <- file.exists(file.path(root, "R", "problem-class.R"))
  config <- list(problem = problem_path, source_root = if (source_mode) root else NULL,
    library_paths = .libPaths(), expected_dimensions = c(12L, 9L))
  config_path <- file.path(workspace, "config.rds")
  saveRDS(config, config_path)
  child <- file.path(workspace, "child.R")
  writeLines(c(
    "args <- commandArgs(TRUE); config <- readRDS(args[[1L]])",
    "receipt <- list(Matrix_before_bootstrap = isNamespaceLoaded('Matrix'))",
    "status <- tryCatch({",
    "  stopifnot(!receipt$Matrix_before_bootstrap)",
    "  .libPaths(config$library_paths)",
    "  if (!is.null(config$source_root)) {",
    "    core <- new.env(parent = globalenv())",
    "    for (file in sort(list.files(file.path(config$source_root, 'R'), pattern = '[.]R$', full.names = TRUE))) sys.source(file, core)",
    "    fn <- function(name) get(name, envir = core, inherits = FALSE)",
    "  } else {",
    "    loadNamespace('postrank')",
    "    fn <- function(name) getFromNamespace(name, 'postrank')",
    "  }",
    "  problem <- readRDS(config$problem)",
    "  receipt$Matrix_before_entry <- isNamespaceLoaded('Matrix')",
    "  if (identical(args[[3L]], 'validate_solution')) {",
    "    primal <- rep(0, length(problem$model$objective))",
    "    primal[problem$index$labels] <- 1",
    "    validation <- fn('validate_postrank_solution')(problem, primal)",
    "    stopifnot(validation$valid)",
    "  } else fn('.pr_validate_problem')(problem)",
    "  receipt$Matrix_after_entry <- isNamespaceLoaded('Matrix')",
    "  converted <- fn('.pr_highs_model')(problem$model)",
    "  receipt$converted_dimensions <- dim(converted$A)",
    "  receipt$first_nrow <- nrow(converted$A)",
    "  receipt$first_ncol <- ncol(converted$A)",
    "  receipt$backend_namespaces_loaded <- vapply(c('gurobi', 'highs', 'cmdstanr'), isNamespaceLoaded, logical(1L))",
    "  stopifnot(receipt$Matrix_after_entry, identical(receipt$converted_dimensions, config$expected_dimensions),",
    "    identical(receipt$first_nrow, 12L), identical(receipt$first_ncol, 9L), !any(receipt$backend_namespaces_loaded))",
    "  receipt$passed <- TRUE; 0L",
    "}, error = function(e) { receipt$error <<- conditionMessage(e); receipt$passed <<- FALSE; 1L })",
    "saveRDS(receipt, args[[2L]]); quit(status = status)"
  ), child)
  withr::local_envvar(c(R_TESTS = ""))
  for (entry in c("validate_problem", "validate_solution")) {
    output <- file.path(workspace, paste0(entry, ".rds"))
    stdout <- file.path(workspace, paste0(entry, ".stdout"))
    stderr <- file.path(workspace, paste0(entry, ".stderr"))
    argv <- c("--vanilla", child, config_path, output, entry)
    exit <- system2(file.path(R.home("bin"), "Rscript"),
      vapply(argv, shQuote, character(1L)), stdout = stdout, stderr = stderr)
    receipt <- if (file.exists(output)) readRDS(output) else list(passed = FALSE)
    info <- paste(entry, receipt$error,
      paste(readLines(stdout, warn = FALSE), collapse = "\n"),
      paste(readLines(stderr, warn = FALSE), collapse = "\n"))
    testthat::expect_identical(exit, 0L, info = info)
    testthat::expect_true(receipt$passed, info = info)
    testthat::expect_false(receipt$Matrix_before_bootstrap)
    if (source_mode) testthat::expect_false(receipt$Matrix_before_entry)
    if (isTRUE(receipt$passed)) {
      testthat::expect_true(receipt$Matrix_after_entry)
      testthat::expect_identical(receipt$converted_dimensions, c(12L, 9L))
      testthat::expect_false(any(receipt$backend_namespaces_loaded))
    }
  }
})
