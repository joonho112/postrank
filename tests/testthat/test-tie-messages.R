# 014 repair (TH-4 short term): tie rejection explains count, location and remedy.
testthat::test_that("joint tie rejection reports the number of tied slices, the first location and a remedy", {
  x <- pr_test_payload(S = 4L, n = 3L, K = 2L)
  v <- x$joint_draws$tensor$values
  v[2, 3, 1] <- v[2, 1, 1]; v[4, 2, 2] <- v[4, 1, 2]
  x$joint_draws$tensor$values <- v
  err <- tryCatch(as_postrank_draws(x), error = identity)
  testthat::expect_s3_class(err, "postrank_input_error")
  testthat::expect_identical(err$code, "observed_target_tie")
  testthat::expect_match(conditionMessage(err), "2 draw-criterion slice")
  testthat::expect_match(conditionMessage(err), "first at draw slot2, criterion need1, entities 001 and 003", fixed = TRUE)
  testthat::expect_match(conditionMessage(err), "sig_figs=18", fixed = TRUE)
  testthat::expect_match(conditionMessage(err), "no jitter", fixed = TRUE)
})

testthat::test_that("criterionwise and exact tie rejections keep their codes and name the entities", {
  x <- pr_test_criterionwise()
  m <- x$criterion_blocks[[1]]$matrix$values; m[1, 2] <- m[1, 1]; x$criterion_blocks[[1]]$matrix$values <- m
  err <- tryCatch(as_postrank_draws(x), error = identity)
  testthat::expect_identical(err$code, "observed_target_tie")
  testthat::expect_match(conditionMessage(err), "entities 001 and 002", fixed = TRUE)
  testthat::skip_if_not_installed("gmp")
  e <- pr_test_exact(); th <- e$finite_law$states[[1]]$theta; th[3, 1] <- th[1, 1]; e$finite_law$states[[1]]$theta <- th
  err <- tryCatch(as_postrank_draws(e), error = identity)
  testthat::expect_identical(err$code, "observed_target_tie")
  testthat::expect_match(conditionMessage(err), "state1", fixed = TRUE)
  testthat::expect_match(conditionMessage(err), "entities 001 and 003", fixed = TRUE)
})
