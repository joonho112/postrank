testthat::test_that("minimax upper bound is the validated action risk; the epigraph value is kept separately",{
  # 014 repair policy (TH-3): the reported risk upper bound is max_k R_k of the
  # released grade, not a possibly slack epigraph value t.
  problem<-postrank_problem(postrank_pairwise(pr_test_payload()),c(need1=1,need2=0),.25,3,objective="minimax")
  primal<-numeric(length(problem$model$objective));primal[problem$index$labels]<-1;primal[problem$index$t]<-.35
  raw<-list(primal=primal,raw_status="TIME_LIMIT",raw_message="mock limit",status_normalized="time_limit",
    termination_reason="time_limit",has_incumbent=TRUE,raw_objective=.35,raw_lower_bound=.20,relative_gap=NA_real_,
    runtime=.01,backend=list(name="mock",options=list()),raw=list(),warnings=character())
  fit<-.pr_normalize_solver_result(problem,raw,.pr_control())
  testthat::expect_true(fit$incumbent_validated)
  testthat::expect_equal(fit$objective$primary_action_risk,.25)
  testthat::expect_equal(fit$objective$risk_upper_bound,.25)
  testthat::expect_equal(fit$objective$epigraph_value,.35)
  testthat::expect_identical(fit$objective$upper_bound_source,"validated_action_primary_risk")
  testthat::expect_equal(fit$objective$risk_lower_bound,.20)
  testthat::expect_equal(fit$objective$risk_absolute_gap,.05)
  testthat::expect_identical(fit$objective$raw_units,"minimax_risk_t")
  testthat::expect_equal(fit$objective$scale,1)
  testthat::expect_equal(fit$objective$offset,0)
  testthat::expect_identical(postrank_report(fit)$settings$objective,"minimax")
  primal[problem$index$t]<-.24
  testthat::expect_false(validate_postrank_solution(problem,primal)$valid)
})

testthat::test_that("an epigraph shortfall within tolerance is raised to the action risk before row checks",{
  problem<-postrank_problem(postrank_pairwise(pr_test_payload()),c(need1=1,need2=0),.25,3,objective="minimax")
  primal<-numeric(length(problem$model$objective));primal[problem$index$labels]<-1
  primal[problem$index$t]<-.25-5e-8
  result<-validate_postrank_solution(problem,primal)
  testthat::expect_true(result$valid)
  testthat::expect_equal(result$epigraph_shortfall,5e-8,tolerance=1e-6)
  testthat::expect_true(result$epigraph_repaired)
  testthat::expect_identical(result$rounded_solution[problem$index$t],.25)
})
