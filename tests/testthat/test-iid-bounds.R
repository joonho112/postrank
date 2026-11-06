pr_iid_test_design <- function(S) list(sample_sizes_fixed_before_sampling = TRUE,
  alpha_fixed_before_sampling = TRUE, adaptive_stopping = FALSE,
  planned_sample_sizes = S, declaration_note = "Explicit synthetic fixed design, declared before sampling.")

testthat::test_that("IID radii use unordered pairs, actual counts and explicit alpha allocations", {
  x <- pr_test_payload(S = 100L)
  allocation <- c(need2 = .02, need1 = .03)
  b <- postrank_iid_bounds(x, .05, allocation, pr_iid_test_design(c(need2 = 100, need1 = 100)))
  expected <- sqrt(log(2 * 3 / c(need1 = .03, need2 = .02)) / 200)
  testthat::expect_s3_class(b, "postrank_iid_bounds")
  testthat::expect_equal(b$M, 3)
  testthat::expect_identical(b$S, c(need1 = 100, need2 = 100))
  testthat::expect_identical(names(b$epsilon), x$criterion_ids)
  testthat::expect_equal(b$raw_radius, expected, tolerance = 1e-15)
  testthat::expect_identical(b$epsilon, b$raw_radius)
  testthat::expect_identical(b$alpha_by_criterion, c(need1 = .03, need2 = .02))
  testthat::expect_true(b$bound_computed)
  testthat::expect_identical(b$guarantee_status, "conditional_bound")
  testthat::expect_false(b$numerically_verified)
  testthat::expect_false(b$finite_sample_certificate)
  testthat::expect_false(b$guarantee_issued)
  testthat::expect_silent(.pr_validate_iid_bounds(b))
})

testthat::test_that("criterionwise counts and reordered blocks retain their own sample sizes", {
  x <- pr_test_criterionwise(); x$criterion_blocks <- rev(x$criterion_blocks)
  b <- postrank_iid_bounds(x, .1, c(need1 = .04, need2 = .05),
    pr_iid_test_design(c(need1 = 4, need2 = 5)))
  testthat::expect_identical(b$S, c(need1 = 4, need2 = 5))
  testthat::expect_equal(b$raw_radius, sqrt((log(6) - log(c(need1 = .04, need2 = .05))) / c(8, 10)))
  testthat::expect_identical(b$epsilon, pmin(b$raw_radius, 1))
  testthat::expect_identical(b$dependence_mode, "criterionwise_expected_only")
  testthat::expect_false(b$assumptions$cross_pair_or_criterion_independence_required)
})

testthat::test_that("fixed design rejects MCMC, exact laws, stopping, count overrides and implicit inputs", {
  x <- pr_test_payload(); S <- c(need1 = 4, need2 = 4); a <- c(need1 = .02, need2 = .02)
  d <- pr_iid_test_design(S)
  testthat::expect_error(postrank_iid_bounds(pr_test_payload(regime = "mcmc"), .05, a, d),
    "MCMC ESS", class = "postrank_input_error")
  testthat::expect_error(postrank_iid_bounds(pr_test_exact(), .05, a, d), "exact finite law")
  for (field in c("sample_sizes_fixed_before_sampling", "alpha_fixed_before_sampling", "adaptive_stopping")) {
    bad <- d; bad[[field]] <- !bad[[field]]
    testthat::expect_error(postrank_iid_bounds(x, .05, a, bad), "Fixed sample sizes")
  }
  bad <- d; bad$planned_sample_sizes[1] <- 3
  testthat::expect_error(postrank_iid_bounds(x, .05, a, bad), "actual retained")
  bad <- d; bad$ESS <- 500
  testthat::expect_error(postrank_iid_bounds(x, .05, a, bad), "unknown fields")
  bad <- d; bad$declaration_note <- "\u2003"
  testthat::expect_error(postrank_iid_bounds(x, .05, a, bad), "nonblank")
  testthat::expect_error(postrank_iid_bounds(x), "must all be explicit")
  testthat::expect_error(postrank_iid_bounds(x, .05, a, d, S = 500), "unused argument")
  mixed <- pr_test_criterionwise(); z <- pr_test_payload(S = 5, regime = "mcmc")$joint_draws
  mixed$criterion_blocks[[2]]$sampling <- z$sampling
  mixed$criterion_blocks[[2]]$draw_index <- z$draw_index
  testthat::expect_error(postrank_iid_bounds(mixed, .05, a, pr_iid_test_design(c(need1 = 4, need2 = 5))), "MCMC ESS")
})

testthat::test_that("alpha underflow and allocations are rejected without normalization", {
  x <- pr_test_payload(); d <- pr_iid_test_design(c(need1 = 4, need2 = 4))
  for (alpha in c(0, 1, -1, Inf, NaN, 1e-400))
    testthat::expect_error(postrank_iid_bounds(x, alpha, c(need1 = .02, need2 = .02), d), "alpha must")
  for (allocation in list(c(.01, .01), c(need1 = 0, need2 = .02), c(need1 = .03, need2 = .03),
    c(need1 = .02, need1 = .02), c(need1 = .01, wrong = .01), c(need1 = .02 + 0i, need2 = .02)))
    testthat::expect_error(postrank_iid_bounds(x, .05, allocation, d), class = "postrank_input_error")
  tiny <- .Machine$double.xmin * .Machine$double.eps
  b <- postrank_iid_bounds(x, 4 * tiny, c(need1 = tiny, need2 = tiny), d)
  testthat::expect_true(all(is.finite(b$raw_radius)))
  testthat::expect_identical(b$epsilon, c(need1 = 1, need2 = 1))
})

testthat::test_that("bound identity prevents stale values and certificate promotion", {
  b <- postrank_iid_bounds(pr_test_payload(), .05, c(need1 = .02, need2 = .02),
    pr_iid_test_design(c(need1 = 4, need2 = 4)))
  for (field in c("numerically_verified", "numerical_certification", "finite_sample_certificate", "guarantee_issued")) {
    bad <- b; bad[[field]] <- TRUE
    testthat::expect_error(.pr_validate_iid_bounds(bad), "changed after construction")
  }
  for (field in c("epsilon", "S", "alpha_by_criterion")) {
    bad <- b; bad[[field]][1] <- bad[[field]][1] / 2
    testthat::expect_error(.pr_validate_iid_bounds(bad), "changed after construction")
  }
  bad <- b; bad$input_identity <- "other"
  testthat::expect_error(.pr_validate_iid_bounds(bad), "changed after construction")
  bad <- b; bad$design$adaptive_stopping <- TRUE
  testthat::expect_error(.pr_validate_iid_bounds(bad), "changed after construction")
  bad <- b; bad$schema_version <- "future"
  testthat::expect_error(.pr_validate_iid_bounds(bad), "current postrank_iid_bounds")
  # A recomputed hash is not permission to promote unsupported capabilities.
  for (field in c("numerically_verified", "numerical_certification", "finite_sample_certificate", "guarantee_issued")) {
    bad <- b; bad[[field]] <- TRUE; bad$bound_identity <- NULL; bad$bound_identity <- .pr_identity(bad)
    testthat::expect_error(.pr_validate_iid_bounds(bad), "disagree with the theoretical")
  }
  for (field in c("scientific_declarations_verified", "numerical_enclosure_verified")) {
    bad <- b; bad$assumptions[[field]] <- TRUE; bad$bound_identity <- NULL; bad$bound_identity <- .pr_identity(bad)
    testthat::expect_error(.pr_validate_iid_bounds(bad), "cannot be promoted")
  }
})
