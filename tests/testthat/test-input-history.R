testthat::test_that("MCMC preserves unequal chain lengths and original chronology", {
  x <- pr_test_payload(S = 5L, regime = "mcmc")
  x$joint_draws$draw_index[[4L]]$chain_id <- "chain2"
  x$joint_draws$draw_index[[4L]]$iteration <- 7L
  x$joint_draws$draw_index[[5L]]$chain_id <- "chain2"
  x$joint_draws$draw_index[[5L]]$iteration <- 8L
  x$joint_draws$sampling$chain_history[[1L]]$retained_iterations <- 3:5
  x$joint_draws$sampling$chain_history[[2L]] <- list(chain_id = "chain2", retained_iterations = 7:8,
    warmup_iterations = 1:2, discarded_sampling_iterations = 3:6, selection_note = "Original chain2 sampling iterations 3:6 discarded explicitly.")
  z <- as_postrank_draws(x)
  testthat::expect_identical(z$joint_draws$draw_index, x$joint_draws$draw_index)
  testthat::expect_identical(z$joint_draws$sampling$chain_history, x$joint_draws$sampling$chain_history)
  # Record ordering does not change the mapping identified by local slot IDs.
  x$joint_draws$draw_index <- rev(x$joint_draws$draw_index)
  testthat::expect_true(validate_postrank_draws(x)$valid)
})

testthat::test_that("MCMC rejects warmup overlap, missing history and coordinate duplication", {
  x <- pr_test_payload(regime = "mcmc")
  x$joint_draws$sampling$chain_history[[1L]]$warmup_iterations <- 1:3
  testthat::expect_error(as_postrank_draws(x), "disjoint", class = "postrank_input_error")
  x <- pr_test_payload(regime = "mcmc")
  x$joint_draws$sampling$chain_history[[1L]]["warmup_iterations"] <- list(NULL)
  testthat::expect_error(as_postrank_draws(x), "unknown NULL", class = "postrank_input_error")
  x <- pr_test_payload(regime = "mcmc"); x$joint_draws$sampling$chain_history <- list()
  testthat::expect_error(as_postrank_draws(x), "explicit chain history", class = "postrank_input_error")
  x <- pr_test_payload(regime = "mcmc")
  x$joint_draws$draw_index[[2L]]$iteration <- x$joint_draws$draw_index[[1L]]$iteration
  testthat::expect_error(as_postrank_draws(x), "coordinate", class = "postrank_input_error")
  x <- pr_test_payload(regime = "mcmc")
  x$joint_draws$sampling$chain_history[[1L]]$retained_iterations <- 4:7
  testthat::expect_error(as_postrank_draws(x), "exactly match", class = "postrank_input_error")
  x <- pr_test_payload(regime = "mcmc")
  x$joint_draws$sampling$chain_history[[1L]]$retained_iterations <- 6:3
  testthat::expect_error(as_postrank_draws(x), "chronological", class = "postrank_input_error")
  x <- pr_test_payload(regime = "mcmc")
  x$joint_draws$sampling$chain_history[[1L]]$warmup_iterations <- 100:101
  testthat::expect_error(as_postrank_draws(x), "warmup must precede", class = "postrank_input_error")
  x <- pr_test_payload(regime = "mcmc")
  x$joint_draws$sampling$chain_history[[1L]]$warmup_iterations <- 2L
  x$joint_draws$sampling$chain_history[[1L]]$discarded_sampling_iterations <- 1L
  testthat::expect_error(as_postrank_draws(x), "warmup must precede", class = "postrank_input_error")
  # Explicit zero-warmup history does not imply unrecorded iteration ranges.
  x <- pr_test_payload(regime = "mcmc")
  x$joint_draws$sampling$chain_history[[1L]]$warmup_iterations <- integer()
  testthat::expect_true(validate_postrank_draws(x)$valid)
})

testthat::test_that("draw slots and original draws cannot be duplicated or fabricated", {
  x <- pr_test_payload(); x$joint_draws$draw_index[[2L]]$original_draw_id <- "orig1"
  testthat::expect_error(as_postrank_draws(x), "unique", class = "postrank_input_error")
  x <- pr_test_payload(); x$joint_draws$draw_index[[2L]]$slot_id <- "unknown"
  testthat::expect_error(as_postrank_draws(x), "cover", class = "postrank_input_error")
  x <- pr_test_payload(); x$joint_draws$draw_index[[1L]]$chain_id <- "chain1"
  testthat::expect_error(as_postrank_draws(x), "iid", class = "postrank_input_error")
  x <- pr_test_payload(); x$joint_draws$sampling$regime <- "variational"
  testthat::expect_error(as_postrank_draws(x), "iid or mcmc", class = "postrank_input_error")
  x <- pr_test_payload(); x$joint_draws$sampling$equal_weight <- FALSE
  testthat::expect_error(as_postrank_draws(x), "equal-weight", class = "postrank_input_error")
  x <- pr_test_payload(); x$joint_draws$sampling$target_distribution <- "approximate_posterior"
  testthat::expect_error(as_postrank_draws(x), "declared posterior", class = "postrank_input_error")
})

testthat::test_that("reused original identity must have consistent coordinates across criteria", {
  x <- pr_test_criterionwise()
  for (k in seq_along(x$criterion_blocks)) {
    sampling <- pr_test_payload(S = x$criterion_blocks[[k]]$matrix$shape$S, regime = "mcmc")$joint_draws
    x$criterion_blocks[[k]]$sampling <- sampling$sampling
    x$criterion_blocks[[k]]$draw_index <- sampling$draw_index
  }
  x$criterion_blocks[[2L]]$origin <- x$criterion_blocks[[1L]]$origin
  testthat::expect_true(validate_postrank_draws(x)$valid)
  S <- x$criterion_blocks[[2L]]$matrix$shape$S
  for (s in seq_len(S)) x$criterion_blocks[[2L]]$draw_index[[s]]$iteration <- s + 3L
  x$criterion_blocks[[2L]]$sampling$chain_history[[1L]]$retained_iterations <- seq_len(S) + 3L
  testthat::expect_error(as_postrank_draws(x), "contradictory original coordinates", class = "postrank_input_error")
})
