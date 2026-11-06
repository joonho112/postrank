testthat::test_that("criterionwise pairwise denominators remain criterion-specific", {
  x <- pr_test_criterionwise()
  p <- postrank_pairwise(x, "reference")
  testthat::expect_identical(p$sample_sizes, c(need1 = 4, need2 = 5))
  testthat::expect_equal(unname(p$e[1L, 2L, ]), c(3/4, 3/5))
  testthat::expect_identical(p$coefficient_type, "monte_carlo")
  x$criterion_blocks <- rev(x$criterion_blocks)
  reversed <- postrank_pairwise(x, "reference")
  testthat::expect_identical(reversed$e, p$e)
  testthat::expect_identical(reversed$sample_sizes, p$sample_sizes)
  testthat::expect_identical(postrank_pairwise(x, "blocks", 1L)$e, p$e)
})

testthat::test_that("pairwise dispatch preserves K1 and S1 and revalidates mutated inputs", {
  x <- pr_test_payload(S = 1L, n = 2L, K = 1L)
  p <- postrank_pairwise(x, "reference")
  testthat::expect_identical(dim(p$e), c(2L, 2L, 1L))
  testthat::expect_identical(unname(p$sample_sizes), 1)
  testthat::expect_identical(p$e[1L, 2L, 1L], 1)
  testthat::expect_identical(p$e[2L, 1L, 1L], 0)
  testthat::expect_true(all(is.na(diag(p$e[, , 1L]))))
  testthat::expect_identical(postrank_pairwise(x, "blocks", 1L)$e, p$e)
  testthat::expect_error(postrank_pairwise(x, block_size = 0L), class = "postrank_input_error")
  z <- as_postrank_draws(x); z$joint_draws$tensor$values[1L, 1L, 1L] <- z$joint_draws$tensor$values[1L, 2L, 1L]
  testthat::expect_error(postrank_pairwise(z), "tie", class = "postrank_input_error")
})

testthat::test_that("all six exact-law coefficients match the independently checked book oracle", {
  testthat::skip_if_not_installed("gmp")
  fixture_path <- testthat::test_path("..", "fixtures", "exact", "core-cases.json")
  fixture <- jsonlite::read_json(fixture_path, simplifyVector = FALSE)
  oracle <- jsonlite::read_json(testthat::test_path("..", "fixtures", "exact", "pairwise-expectations.json"), simplifyVector = FALSE)
  for (case in fixture$cases) {
    payload <- pr_fixture_payload(case, fixture_path)
    p <- postrank_pairwise(payload)
    ref <- oracle$cases[[which(vapply(oracle$cases, function(z) z$id == case$id, logical(1L)))]]
    expected <- array(NA_character_, dim(p$e), dimnames(p$e))
    for (k in seq_len(case$K)) for (i in seq_len(case$n)) for (j in seq_len(case$n)) if (i != j)
      expected[i, j, k] <- ref$pairwise_error_probabilities[[k]][[i]][[j]]
    testthat::expect_identical(p$exact$rationals, expected, info = case$id)
    testthat::expect_true(all(is.na(p$sample_sizes)), info = case$id)
    testthat::expect_identical(p$exact$state_count, length(case$states))
    testthat::expect_identical(p$exact$denominator, as.character(case$denominator))
    testthat::expect_false(p$exact$numerical_certification)
    testthat::expect_identical(p$coefficient_type, "exact_rational_with_double_projection")
    testthat::expect_identical(p$provenance$artifact_hash, digest::digest(file = fixture_path, algo = "sha256"))
  }
})

testthat::test_that("exact zero-one coefficients and actual projection differences remain visible", {
  testthat::skip_if_not_installed("gmp")
  x <- pr_test_exact()
  p <- postrank_pairwise(x)
  # First criterion has P(theta1 <= theta2) = 1/3 and reverse = 2/3.
  testthat::expect_identical(p$exact$rationals[1L, 2L, 1L], "1/3")
  testthat::expect_identical(p$exact$numerators[1L, 2L, 1L], "1")
  difference <- gmp::as.bigq(p$e[1L, 2L, 1L]) - gmp::as.bigq(1, 3)
  testthat::expect_identical(p$exact$projection_difference_rationals[1L, 2L, 1L], as.character(difference))
  testthat::expect_false(identical(as.character(difference), "0"))
  testthat::expect_identical(p$e[1L, 3L, 1L], 0)
  testthat::expect_identical(p$e[3L, 1L, 1L], 1)
  testthat::expect_identical(p$exact$rationals[1L, 3L, 1L], "0")
  testthat::expect_identical(p$exact$rationals[3L, 1L, 1L], "1")
  testthat::expect_true(is.na(p$exact$numerators[1L, 1L, 1L]))
})
