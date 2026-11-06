testthat::test_that("exact laws preserve rational mass definitions and safe integer targets", {
  testthat::skip_if_not_installed("gmp")
  x <- pr_test_exact(); z <- as_postrank_draws(x)
  testthat::expect_identical(z$finite_law, x$finite_law)
  maximum <- 9007199254740991
  x$finite_law$denominator <- maximum
  x$finite_law$states[[1L]]$mass_numerator <- maximum - 1
  x$finite_law$states[[2L]]$mass_numerator <- 1
  x$finite_law$states[[1L]]$theta[, 1L] <- c(maximum, 0, -maximum)
  testthat::expect_true(validate_postrank_draws(x)$valid)
  x$finite_law$states[[1L]]$mass_numerator <- maximum
  testthat::expect_error(as_postrank_draws(x), "mass sum exceeds", class = "postrank_input_error")
})

testthat::test_that("exact laws reject empirical relabeling and incorrect mass arithmetic", {
  testthat::skip_if_not_installed("gmp")
  x <- pr_test_exact(); x$finite_law$not_empirical_posterior_relabeling <- FALSE
  testthat::expect_error(as_postrank_draws(x), "nonempirical", class = "postrank_input_error")
  x <- pr_test_exact(); x$finite_law$denominator <- 4L
  testthat::expect_error(as_postrank_draws(x), "sum exactly", class = "postrank_input_error")
  for (mass in list(0, -1, 1.5, TRUE, Inf)) {
    x <- pr_test_exact(); x$finite_law$states[[1L]]$mass_numerator <- mass
    testthat::expect_error(as_postrank_draws(x), class = "postrank_input_error")
  }
  x <- pr_test_exact(); x$finite_law$states[[2L]]$state_id <- "state1"
  testthat::expect_error(as_postrank_draws(x), "unique", class = "postrank_input_error")
})

testthat::test_that("exact state shape, ID order and ties are checked", {
  testthat::skip_if_not_installed("gmp")
  x <- pr_test_exact(); x$finite_law$states[[1L]]$theta[1L, 1L] <- 9007199254740992
  testthat::expect_error(as_postrank_draws(x), "safe integers", class = "postrank_input_error")
  x <- pr_test_exact(); x$finite_law$states[[1L]]$theta[1L, 1L] <- 1.5
  testthat::expect_error(as_postrank_draws(x), "safe integers", class = "postrank_input_error")
  x <- pr_test_exact(); x$finite_law$states[[1L]]$theta[1L, 1L] <- 2L
  testthat::expect_error(as_postrank_draws(x), "tie", class = "postrank_input_error")
  x <- pr_test_exact(); dimnames(x$finite_law$states[[1L]]$theta)$entity <- rev(x$entity_ids)
  testthat::expect_error(as_postrank_draws(x), "dimnames", class = "postrank_input_error")
  x <- pr_test_exact(); x$finite_law$states[[1L]]$theta <- x$finite_law$states[[1L]]$theta[, 1L]
  testthat::expect_error(as_postrank_draws(x), "matrix", class = "postrank_input_error")
})

testthat::test_that("all six unchanged book laws admit an explicit posterior-only adapter", {
  testthat::skip_if_not_installed("gmp")
  fixture <- jsonlite::read_json(testthat::test_path("..", "fixtures", "exact", "core-cases.json"), simplifyVector = FALSE)
  for (case in fixture$cases) {
    x <- pr_test_payload(n = case$n, K = case$K)
    x$input_kind <- "exact_finite_posterior"; x$joint_draws <- NULL
    x$entity_ids <- unlist(case$entity_ids); x$criterion_ids <- unlist(case$criterion_ids)
    for (k in seq_along(x$targets)) x$targets[[k]]$criterion_id <- x$criterion_ids[k]
    states <- lapply(seq_along(case$states), function(s) {
      z <- case$states[[s]]
      theta <- do.call(rbind, lapply(z$theta, unlist))
      dimnames(theta) <- list(entity = x$entity_ids, criterion = x$criterion_ids)
      list(state_id = paste0(case$id, "-state", s), mass_numerator = z$mass, theta = theta)
    })
    x$finite_law <- list(denominator = case$denominator, value_representation = "safe_integer", states = states,
      law_definition = paste("Explicit book finite law", case$id), not_empirical_posterior_relabeling = TRUE)
    # Synthetic test declarations are transparent; original decision settings
    # remain in the book fixture and do not become posterior-input fields.
    testthat::expect_true(validate_postrank_draws(x)$valid, info = case$id)
  }
})
