testthat::test_that("reference calculation states cannot issue a numerical or safety certificate",{
  for(kind in c("not_established","diagnostic_only","conditional_bound")) {
    x<-.pr_guarantee_status(kind,TRUE,"Explicit software reference calculation")
    testthat::expect_true(x$bound_computed)
    testthat::expect_false(x$numerically_verified)
    testthat::expect_false(x$guarantee_issued)
    testthat::expect_false(x$finite_sample_certificate)
    testthat::expect_false(x$numerical_certification)
  }
  x<-postrank_guarantee_capabilities()
  testthat::expect_false(x$formal_numerical_certifier)
  testthat::expect_false(x$conditional_IID_safe_certificate)
  testthat::expect_false(x$general_MCMC_finite_sample_certificate)
  testthat::expect_false(x$optional_stopping_certificate)
  testthat::expect_false(x$minimax_regret_bound)
  testthat::expect_error(.pr_guarantee_status("verified_safe",TRUE))
  testthat::expect_error(.pr_guarantee_status("conditional_bound",1))
})
