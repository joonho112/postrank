# T-test-08: the execution tiers skip exactly as declared (Chapter 15).
pr_tier_outcome <- function(guard) tryCatch({ guard(); "ran" }, skip = function(e) "skipped")

test_that("the licensed Gurobi tier needs the explicit opt-in", {
  withr::local_envvar(POSTRANK_TEST_GUROBI = "", NOT_CRAN = "true")
  expect_identical(pr_tier_outcome(pr_skip_unless_gurobi), "skipped")
  withr::local_envvar(POSTRANK_TEST_GUROBI = "yes")
  expect_identical(pr_tier_outcome(pr_skip_unless_gurobi), "skipped")
  withr::local_envvar(POSTRANK_TEST_GUROBI = "true", NOT_CRAN = "false")
  expect_identical(pr_tier_outcome(pr_skip_unless_gurobi), "skipped")
})

test_that("the HiGHS tier follows package availability only", {
  expect_identical(pr_tier_outcome(pr_skip_unless_highs), if (requireNamespace("highs", quietly = TRUE)) "ran" else "skipped")
})
