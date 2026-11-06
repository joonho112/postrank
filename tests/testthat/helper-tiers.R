# Execution tiers (Chapter 15): solver-free everywhere; HiGHS when installed; licensed
# Gurobi only off CRAN, with the package installed and POSTRANK_TEST_GUROBI=true.
pr_skip_unless_highs <- function() testthat::skip_if_not_installed("highs")
pr_skip_unless_gurobi <- function() {
  testthat::skip_on_cran()
  testthat::skip_if_not_installed("gurobi")
  testthat::skip_if(!identical(Sys.getenv("POSTRANK_TEST_GUROBI"), "true"),
    "licensed Gurobi tier requires explicit opt-in (POSTRANK_TEST_GUROBI=true)")
}
