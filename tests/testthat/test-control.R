# T-obj-04: bare and typed controls map to the identical eight-field core list.
ctl_core_names <- c("time_limit", "threads", "seed", "absolute_risk_gap", "relative_gap", "output", "tolerances", "engine")

test_that("default bare list and default postrank_control give identical core lists", {
  bare <- .pr_core_control(list())
  typed <- .pr_core_control(postrank_control())
  expect_identical(names(bare$core), ctl_core_names)
  expect_identical(bare$core, typed$core)
  expect_identical(bare$strategy, "staged"); expect_identical(typed$strategy, "staged")
  expect_false(bare$verbose); expect_false(typed$verbose)
  # The legacy normalizer agrees on every scalar default (0.0.1.9002 values).
  legacy <- .pr_control(list())
  for (f in c("time_limit", "threads", "seed", "absolute_risk_gap", "relative_gap", "output", "engine"))
    expect_identical(bare$core[[f]], legacy[[f]], info = f)
  expect_identical(bare$core$tolerances, .pr_solution_tolerances(list()))
})

test_that("non-default output, tolerances and engine survive both routes identically", {
  args <- list(time_limit = 7, threads = 2L, seed = 9L, absolute_risk_gap = 1e-6, relative_gap = 1e-4,
    output = TRUE, tolerances = list(feasibility = 1e-6), engine = list(mip = "never", local_search_passes = 3L))
  bare <- .pr_core_control(args)
  typed <- .pr_core_control(do.call(postrank_control, args))
  expect_identical(bare$core, typed$core)
  expect_true(bare$core$output)
  expect_identical(bare$core$tolerances$feasibility, 1e-6)
  expect_identical(bare$core$tolerances$integrality, 1e-6)
  expect_identical(bare$core$engine$mip, "never")
  expect_identical(bare$core$engine$local_search_passes, 3L)
})

test_that("strategy resolution: explicit wins, then control$strategy, then staged", {
  expect_identical(.pr_core_control(list(strategy = "label_mip"))$strategy, "label_mip")
  expect_identical(.pr_core_control(list(strategy = "label_mip"), "staged")$strategy, "staged")
  expect_identical(.pr_core_control(postrank_control(strategy = "label_mip"))$strategy, "label_mip")
  expect_identical(.pr_core_control(postrank_control(strategy = "label_mip"), "staged")$strategy, "staged")
  expect_identical(.pr_core_control(list(), NULL)$strategy, "staged")
  expect_error(.pr_core_control(list(), "fast"), class = "postrank_input_error")
  expect_identical(.pr_core_control(list(verbose = TRUE))$verbose, TRUE)
  expect_false("strategy" %in% names(.pr_core_control(list(strategy = "label_mip"))$core))
  expect_false("verbose" %in% names(.pr_core_control(list(verbose = TRUE))$core))
})

test_that("seed NULL, unknown fields and malformed controls are rejected", {
  expect_error(postrank_control(seed = NULL), "seed")
  expect_error(.pr_core_control(list(seed = NULL)), "seed")
  e <- tryCatch(.pr_core_control(list(timelimit = 5)), error = identity)
  expect_s3_class(e, "postrank_input_error"); expect_identical(e$code, "invalid_control")
  expect_error(.pr_core_control(list(time_limit = -1)), "time_limit")
  expect_error(.pr_core_control(list(tolerances = list(bogus = 1))), "tolerance")
  expect_error(.pr_core_control(list(engine = list(mip = "sometimes"))), "mip")
  expect_error(.pr_core_control("fast"), "control")
  bad <- postrank_control(); bad$time_limit <- -1
  expect_error(.pr_core_control(bad), "time_limit")
  bad <- postrank_control(); bad$extra <- 1
  expect_error(.pr_core_control(bad), "ordered fields")
})

test_that("postrank_control has the documented ordered fields and audit slots", {
  x <- postrank_control()
  expect_s3_class(x, "postrank_control")
  expect_identical(names(x), c("time_limit", "threads", "seed", "absolute_risk_gap", "relative_gap", "strategy",
    "engine", "verbose", "output", "tolerances", "schema_version", "provenance", "warnings"))
  expect_identical(x$time_limit, 60); expect_identical(x$threads, 1L); expect_identical(x$seed, 1304L)
  expect_identical(x$absolute_risk_gap, 1e-8); expect_identical(x$relative_gap, 0)
  expect_identical(x$tolerances, list(feasibility = 1e-7, integrality = 1e-6, objective = 1e-7))
  expect_identical(x$engine$mip, "auto"); expect_identical(x$engine$mip_max_n, 200L)
  expect_null(x$engine$cuts_per_round)
  expect_identical(x$provenance$producing_function, "postrank_control")
})
