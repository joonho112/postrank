testthat::test_that("criterionwise draws preserve unequal lengths and local rows", {
  x <- pr_test_criterionwise(); z <- as_postrank_draws(x)
  testthat::expect_identical(z$criterion_blocks, x$criterion_blocks)
  testthat::expect_identical(vapply(z$criterion_blocks, function(b) nrow(b$matrix$values), integer(1)), c(4L, 5L))
  testthat::expect_null(z$joint_draws)
  x$criterion_blocks <- rev(x$criterion_blocks)
  testthat::expect_identical(as_postrank_draws(x)$criterion_blocks, x$criterion_blocks)
  x <- pr_test_criterionwise()
  mcmc <- pr_test_payload(S = 5L, regime = "mcmc")$joint_draws
  x$criterion_blocks[[2L]]$sampling <- mcmc$sampling
  x$criterion_blocks[[2L]]$draw_index <- mcmc$draw_index
  testthat::expect_true(validate_postrank_draws(x)$valid)
})

testthat::test_that("criterionwise entity order and complete criterion coverage are required", {
  x <- pr_test_criterionwise(); x$criterion_blocks[[2L]]$criterion_id <- x$criterion_ids[1L]
  testthat::expect_error(as_postrank_draws(x), class = "postrank_input_error")
  x <- pr_test_criterionwise(); x$criterion_blocks <- x$criterion_blocks[1L]
  testthat::expect_error(as_postrank_draws(x), "cover", class = "postrank_input_error")
  x <- pr_test_criterionwise(); x$criterion_blocks[[1L]]$matrix$dimnames$entity <- rev(x$entity_ids)
  testthat::expect_error(as_postrank_draws(x), "ID order", class = "postrank_input_error")
  x <- pr_test_criterionwise(); x$criterion_blocks[[1L]]$matrix$values[1L, 1L] <- Inf
  testthat::expect_error(as_postrank_draws(x), "target cell", class = "postrank_input_error")
  x <- pr_test_criterionwise()
  x$criterion_blocks[[1L]]$matrix$values[1L, 1L] <- x$criterion_blocks[[1L]]$matrix$values[1L, 2L]
  testthat::expect_error(as_postrank_draws(x), "tie", class = "postrank_input_error")
})

testthat::test_that("source and fit declarations remain consistent across blocks", {
  x <- pr_test_criterionwise()
  x$criterion_blocks[[2L]]$origin <- x$criterion_blocks[[1L]]$origin
  testthat::expect_true(validate_postrank_draws(x)$valid)
  x$criterion_blocks[[2L]]$origin$source_hash <- "contradictory hash"
  testthat::expect_error(as_postrank_draws(x), "source_id", class = "postrank_input_error")
  x <- pr_test_criterionwise()
  x$criterion_blocks[[2L]]$origin$fit_id <- x$criterion_blocks[[1L]]$origin$fit_id
  x$criterion_blocks[[2L]]$origin$model_id <- "contradictory-model"
  testthat::expect_error(as_postrank_draws(x), "fit_id", class = "postrank_input_error")
  x <- pr_test_criterionwise(); x$criterion_blocks[[2L]]$origin <- x$criterion_blocks[[1L]]$origin
  x$criterion_blocks[[2L]]$variable_map[[1L]]$source_target_variable_id <- x$criterion_blocks[[1L]]$variable_map[[1L]]$source_target_variable_id
  testthat::expect_error(as_postrank_draws(x), "variable ID reused", class = "postrank_input_error")
  x <- pr_test_criterionwise()
  for (k in seq_along(x$criterion_blocks)) {
    mc <- pr_test_payload(S = x$criterion_blocks[[k]]$matrix$shape$S, regime = "mcmc")$joint_draws
    x$criterion_blocks[[k]]$sampling <- mc$sampling
    x$criterion_blocks[[k]]$draw_index <- mc$draw_index
    x$criterion_blocks[[k]]$origin$fit_id <- "common-fit"
  }
  x$criterion_blocks[[2L]]$sampling$chain_history[[1L]]$warmup_iterations <- 1L
  testthat::expect_error(as_postrank_draws(x), "contradictory warmup", class = "postrank_input_error")
})

testthat::test_that("opaque scoped original IDs need not be globally renamed", {
  x <- pr_test_criterionwise()
  # Both local inputs name their first original draw orig1, in distinct fits.
  testthat::expect_identical(x$criterion_blocks[[1L]]$draw_index[[1L]]$original_draw_id,
                             x$criterion_blocks[[2L]]$draw_index[[1L]]$original_draw_id)
  testthat::expect_true(validate_postrank_draws(x)$valid)
})
