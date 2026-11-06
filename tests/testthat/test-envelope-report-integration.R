testthat::test_that("outer incumbent is checked against signed thresholds and reported as envelope only",{
  d<-as_postrank_draws(pr_test_payload());w<-c(need1=.5,need2=.5)
  design<-list(sample_sizes_fixed_before_sampling=TRUE,alpha_fixed_before_sampling=TRUE,adaptive_stopping=FALSE,
    planned_sample_sizes=c(need1=4,need2=4),declaration_note="Declared deterministic software fixture, not proof of IID generation")
  b<-postrank_iid_bounds(d,.05,c(need1=.025,need2=.025),design)
  p<-postrank_problem(postrank_pairwise(d),w,.25,3,q=c(need1=.25))
  env<-postrank_protection_envelopes(p,b);outer<-env$outer_problem
  testthat::expect_true(env$thresholds$inner[1]<0)
  testthat::expect_true(env$thresholds$outer[1]>1)
  x<-numeric(length(outer$model$objective));x[outer$index$labels]<-1:3
  x[outer$index$pairs]<-as.numeric(x[outer$index$labels][outer$index$pair_i]<x[outer$index$labels][outer$index$pair_j])
  v<-validate_postrank_solution(outer,x)
  testthat::expect_true(v$valid)
  testthat::expect_true(v$evaluation$E['need1']-.25*v$evaluation$N>0)
  raw<-list(primal=x,raw_status="MOCK_FEASIBLE",raw_message="mock feasible outer candidate",status_normalized="feasible_not_certified",
    termination_reason="mock",has_incumbent=TRUE,raw_objective=sum(outer$model$objective*x),raw_lower_bound=NA_real_,
    relative_gap=NA_real_,runtime=0,backend=list(name="mock",options=list()),raw=list(),warnings=character())
  fit<-.pr_normalize_solver_result(outer,raw,.pr_control())
  r<-postrank_report(fit)
  testthat::expect_match(r$protection$status,"diagnostic_outer_envelope_only")
  testthat::expect_true(r$protection$margins$margin>0)
  testthat::expect_true(r$protection$margins$envelope_margin<=0)
  testthat::expect_identical(fit$settings$q,p$settings$q)
  tamper<-env$inner_problem;tamper$protection_envelope$thresholds[]<-0;tamper$problem_identity<-NULL;tamper$problem_identity<-.pr_identity(tamper)
  testthat::expect_error(.pr_validate_problem(tamper),"without clipping")
  testthat::expect_error(postrank_problem(postrank_pairwise(d),w,.25,3,q=env$thresholds$inner),"q must")
})
