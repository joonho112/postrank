testthat::test_that("multidomain rational text has an exact decimal grammar", {
  testthat::skip_if_not_installed("gmp")
  text <- c("1/20", "0.05", "+0005/0010", "-0003/0006", "008",
            "0010.250", "+000.010", "-000.125", "-0", "-0.000")
  exact <- p2_parse_rational(text)
  testthat::expect_s3_class(exact, "bigq")
  testthat::expect_identical(as.character(exact),
                           c("1/20", "1/20", "1/2", "-1/2", "8",
                             "41/4", "1/100", "-1/8", "0", "0"))
  # This integer cannot be recovered from an already rounded double.
  testthat::expect_identical(as.character(p2_parse_rational("9007199254740993")),
                           "9007199254740993")
})

testthat::test_that("rational text rejects expressions and alternate numeric syntax", {
  testthat::skip_if_not_installed("gmp")
  invalid <- c("", " ", " 1", "1 ", ".5", "1.", "1e-2", "1E2", "0x10",
               "1/-2", "1/+2", "1/2/3", "NaN", "Inf", "-Inf", "NA",
               "1+1", "1,0", "1; stop('evaluated')")
  for (value in invalid)
    testthat::expect_error(p2_parse_rational(value), "rational_text", info = value)
  for (value in list(character(), NA_character_, c("1", NA_character_),
                     1, TRUE, list("1"), matrix("1")))
    testthat::expect_error(p2_parse_rational(value), "rational_text")
  testthat::expect_error(p2_parse_rational("1/0"), "denominator must be positive")
  testthat::expect_error(p2_parse_rational("0/000"), "denominator must be positive")
})

testthat::test_that("numeric decision values retain their stored binary rationals", {
  testthat::skip_if_not_installed("gmp")
  binary <- p2_decision_numbers(c(0.1, 0.3, 5L), "t")
  decimal <- p2_decision_numbers(c("0.1", "0.3", "5"), "t")
  testthat::expect_identical(binary$encoding, "stored_binary_rational")
  testthat::expect_identical(decimal$encoding, "rational_text")
  testthat::expect_identical(as.character(binary$exact),
                           c("3602879701896397/36028797018963968",
                             "5404319552844595/18014398509481984", "5"))
  testthat::expect_identical(as.character(decimal$exact), c("1/10", "3/10", "5"))
  testthat::expect_true(binary$exact[1L] > decimal$exact[1L])
  testthat::expect_true(binary$exact[2L] < decimal$exact[2L])
  testthat::expect_identical(binary$numeric, c(0.1, 0.3, 5))
  testthat::expect_equal(decimal$numeric, c(0.1, 0.3, 5),
                         tolerance = .Machine$double.eps)
})

testthat::test_that("supplied bigq values and explicitly empty vectors are preserved", {
  testthat::skip_if_not_installed("gmp")
  rational <- gmp::as.bigq(c(1L, -3L), c(20L, 7L))
  parsed <- p2_decision_numbers(rational, "weights")
  testthat::expect_identical(parsed$encoding, "supplied_bigq")
  testthat::expect_identical(parsed$exact, rational)
  empty <- p2_decision_numbers(numeric(), "q", allow_empty = TRUE)
  testthat::expect_identical(empty$encoding, "empty")
  testthat::expect_length(empty$exact, 0L)
  testthat::expect_identical(empty$numeric, numeric())
  testthat::expect_error(p2_decision_numbers(numeric(), "q"), "nonempty")
})

testthat::test_that("nonfinite or nonvector decision numbers fail with field context", {
  testthat::skip_if_not_installed("gmp")
  for (value in list(NA_real_, NaN, Inf, -Inf, 1 + 0i, TRUE,
                     list(0.1), factor("0.1"), matrix(0.1))) {
    error <- tryCatch(.md_attempt(p2_decision_numbers(value, "alpha"),
                                 field = "alpha"), error = identity)
    testthat::expect_s3_class(error, "postrank_mdomain_error")
    testthat::expect_identical(error$code, "mdomain_invalid")
    testthat::expect_identical(error$field, "alpha")
    testthat::expect_match(conditionMessage(error), "alpha")
  }
  testthat::expect_error(p2_decision_numbers(gmp::as.bigq(NA_real_), "alpha"),
                        "missing rational")
})

testthat::test_that("strict count cutoffs withhold equality at a rational boundary", {
  testthat::skip_if_not_installed("gmp")
  cutoff <- p2_integer_cutoff("1/20", 20L)
  testthat::expect_s3_class(cutoff, "bigz")
  testthat::expect_identical(as.character(cutoff), "2")
  counts <- 0:20
  exact_event <- as.logical(gmp::as.bigq(counts, 20L) > gmp::as.bigq(1L, 20L))
  testthat::expect_identical(exact_event, counts >= 2L)
  testthat::expect_identical(as.logical(gmp::as.bigz(counts) >= cutoff), exact_event)
  testthat::expect_identical(as.character(p2_integer_cutoff("0", 20L)), "1")
  testthat::expect_identical(as.character(p2_integer_cutoff("1", 20L)), "21")
  testthat::expect_identical(as.character(p2_integer_cutoff("0", 0L)), "1")
})

testthat::test_that("binary and text thresholds can differ at a strict boundary", {
  testthat::skip_if_not_installed("gmp")
  # Stored 0.3 lies below 3/10, so three errors out of ten strictly exceed it.
  testthat::expect_identical(as.character(p2_integer_cutoff(0.3, 10L)), "3")
  testthat::expect_identical(as.character(p2_integer_cutoff("0.3", 10L)), "4")
  testthat::expect_identical(as.character(p2_integer_cutoff("3/10", 10L)), "4")
  testthat::expect_identical(as.character(p2_integer_cutoff(
    "0.299999999999999999999999999999", 10L)), "3")
})

testthat::test_that("strict count cutoffs remain exact at the numeric integer limit", {
  testthat::skip_if_not_installed("gmp")
  cutoff <- p2_integer_cutoff("1", 2^53)
  testthat::expect_s3_class(cutoff, "bigz")
  testthat::expect_identical(as.character(cutoff), "9007199254740993")
  testthat::expect_true(cutoff > gmp::as.bigz(2^53))
  for (value in list(-1, 1.5, Inf, NaN, 2^53 + 2, "20", TRUE, matrix(20)))
    testthat::expect_error(p2_integer_cutoff("1/20", value), "N must")
  for (value in list("-1/20", "21/20", c("0", "1"), NaN, Inf))
    testthat::expect_error(p2_integer_cutoff(value, 20L))
})

testthat::test_that("the optional exact arithmetic dependency is checked lazily", {
  # Only gmp is reported unavailable, leaving package/test infrastructure intact.
  actual_require <- base::requireNamespace
  testthat::local_mocked_bindings(
    requireNamespace = function(package, ...) {
      if (identical(package, "gmp")) return(FALSE)
      actual_require(package, ...)
    },
    .package = "base"
  )
  error <- tryCatch(.md_require_gmp(), error = identity)
  testthat::expect_s3_class(error, "postrank_mdomain_error")
  testthat::expect_identical(error$code, "mdomain_dependency")
  testthat::expect_identical(error$field, "gmp")
  testthat::expect_match(conditionMessage(error), "Install.*'gmp'")
  evaluated <- FALSE
  guarded <- tryCatch(.md_attempt({ evaluated <- TRUE }), error = identity)
  testthat::expect_identical(guarded$code, "mdomain_dependency")
  testthat::expect_false(evaluated)
  # P1 empirical input validation does not require the P2 rational dependency.
  testthat::expect_s3_class(as_postrank_draws(pr_test_payload()), "postrank_draws")
})

testthat::test_that("an installed gmp dependency check returns invisibly", {
  testthat::skip_if_not_installed("gmp")
  result <- withVisible(.md_require_gmp())
  testthat::expect_identical(result$value, TRUE)
  testthat::expect_false(result$visible)
})
