testthat::test_that("basic report makes all-tie abstention and undefined conditional ratios visible",{
  p<-postrank_problem(postrank_pairwise(pr_test_payload()),c(need1=.5,need2=.5),.25,3)
  z<-rep(0,length(p$model$objective));z[p$index$labels]<-1
  raw<-.pr_gurobi_raw_result(list(status="OPTIMAL",x=z,objval=0,objbound=0,mipgap=0,runtime=.01),list(name="mock",options=list()))
  fit<-.pr_normalize_solver_result(p,raw,.pr_control());report<-postrank_report(fit)
  testthat::expect_equal(report$disclosure$N,0)
  testthat::expect_true(all(is.na(report$criterion_profile$error_per_disclosed_pair)))
  testthat::expect_equal(report$objective$risk_upper_bound,.25)
  # 0.9.0 D-7 migration: the inherited Korean assertion becomes its English semantic replacement.
  testthat::expect_match(paste(capture.output(print(report)),collapse="\n"),"All comparisons withheld")
})
testthat::test_that("no-incumbent report exposes absence instead of invented grade or zero risk",{
  p<-postrank_problem(postrank_pairwise(pr_test_payload()),c(need1=.5,need2=.5),.25,3)
  raw<-.pr_gurobi_raw_result(list(status="TIME_LIMIT",runtime=.01),list(name="mock",options=list()))
  report<-postrank_report(.pr_normalize_solver_result(p,raw,.pr_control()))
  testthat::expect_null(report$grade);testthat::expect_null(report$disclosure)
  testthat::expect_true(is.na(report$objective$risk_upper_bound))
  # 0.9.0 D-7 migration: the inherited Korean assertion becomes its English semantic replacement.
  testthat::expect_match(paste(capture.output(print(report)),collapse="\n"),"No validated grades")
})
