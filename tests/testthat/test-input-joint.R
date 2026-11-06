testthat::test_that("joint input preserves singleton axes, opaque IDs and all values", {
  x <- pr_test_payload(S = 1L, n = 2L, K = 1L)
  z <- as_postrank_draws(x)
  testthat::expect_identical(z$joint_draws, x$joint_draws)
  testthat::expect_identical(dim(z$joint_draws$tensor$values), c(1L, 2L, 1L))
  testthat::expect_identical(z$entity_ids, c("001", "002"))
  testthat::expect_false(z$validation$jointness_verified)
  testthat::expect_false(z$validation$convergence_verified)
})

testthat::test_that("joint dimensions and ID axes cannot be silently repaired", {
  x <- pr_test_payload(S = 1L, K = 1L)
  x$joint_draws$tensor$values <- x$joint_draws$tensor$values[, , 1L]
  testthat::expect_error(as_postrank_draws(x), "dimensions", class = "postrank_input_error")
  x <- pr_test_payload()
  x$joint_draws$tensor$shape$n <- 2L
  testthat::expect_error(as_postrank_draws(x), "shape", class = "postrank_input_error")
  x <- pr_test_payload()
  dimnames(x$joint_draws$tensor$values)$entity <- rev(x$entity_ids)
  testthat::expect_error(as_postrank_draws(x), "dimnames", class = "postrank_input_error")
  x <- pr_test_payload()
  names(dimnames(x$joint_draws$tensor$values)) <- c("iteration", "entity", "criterion")
  testthat::expect_error(as_postrank_draws(x), "dimnames", class = "postrank_input_error")
})

testthat::test_that("joint targets reject nonfinite cells and exact entity ties", {
  for (bad in c(NA_real_, NaN, Inf, -Inf)) {
    x <- pr_test_payload(); x$joint_draws$tensor$values[1, 1, 1] <- bad
    testthat::expect_error(as_postrank_draws(x), "target cell", class = "postrank_input_error")
  }
  x <- pr_test_payload()
  x$joint_draws$tensor$values[1, 1, 1] <- x$joint_draws$tensor$values[1, 2, 1]
  testthat::expect_error(as_postrank_draws(x), "tie", class = "postrank_input_error")
})

testthat::test_that("joint variable maps cover exact coordinates and source variables", {
  x <- pr_test_payload(); x$joint_draws$variable_map[[1L]]$entity_id <- "unknown"
  testthat::expect_error(as_postrank_draws(x), "unknown", class = "postrank_input_error")
  x <- pr_test_payload(); x$joint_draws$variable_map[[2L]] <- x$joint_draws$variable_map[[1L]]
  testthat::expect_error(as_postrank_draws(x), "duplicate", class = "postrank_input_error")
  x <- pr_test_payload()
  x$joint_draws$variable_map[[2L]]$source_target_variable_id <- x$joint_draws$variable_map[[1L]]$source_target_variable_id
  testthat::expect_error(as_postrank_draws(x), "IDs", class = "postrank_input_error")
  x <- pr_test_payload(); x$joint_draws$variable_map[[1L]]$derivation_note <- " "
  testthat::expect_error(as_postrank_draws(x), "nonblank", class = "postrank_input_error")
  x <- pr_test_payload(); x$joint_draws$origin$within_criterion_joint_declared <- FALSE
  testthat::expect_error(as_postrank_draws(x), "joint generation", class = "postrank_input_error")
  x <- pr_test_payload(); x$joint_draws$cross_criterion_joint_provenance <- ""
  testthat::expect_error(as_postrank_draws(x), "nonblank", class = "postrank_input_error")
})
