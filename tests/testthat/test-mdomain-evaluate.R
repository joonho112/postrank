md_evaluation_grades <- function(input) matrix(c(10,20,30,30,20,10),3L,
  dimnames=list(input$unit_ids,input$domain_ids))

test_that("fixed public evaluation exposes verified tables and exact finite-law values", {
  skip_if_not_installed("gmp")
  input <- md_test_input()
  grades <- md_evaluation_grades(input)
  result <- postrank_mdomain_evaluate(input,grades)
  expect_s3_class(result,"postrank_mdomain_evaluation")
  expect_identical(result$input,input)
  expect_s3_class(result$action,"p2_profile_action")
  expect_s3_class(result$decision,"p2_profile_decision")
  expect_s3_class(result$evaluation,"p2_joint_evaluation")
  expect_identical(result$grades,matrix(c(1L,2L,3L,3L,2L,1L),3L,
    dimnames=dimnames(grades)))
  expect_identical(postrank_mdomain_grades(result),result$grades)
  expect_identical(result$action$receipt$original_grades,grades)
  # The independently listed state errors are (0,1,1,3) and (0,2,2,3).
  # Their union has three of four states; each of six pairs has weight 1/6.
  expect_identical(result$domain_table$EF_exact,c("5/4","7/4"))
  expect_identical(result$domain_table$loss_exact,c("5/12","7/12"))
  expect_identical(result$risk_exact,"1/2")
  expect_equal(result$risk,.5,tolerance=0)
  expect_identical(result$J_exact,"3/4")
  expect_equal(result$J,.75,tolerance=0)
  expect_identical(result$event_table$p_exact,c("3/4","3/4"))
  expect_equal(result$M,3,tolerance=0)
  expect_true(result$mean_feasible)
  expect_false(result$joint_feasible)
  expect_false(result$feasible_for_represented_measure)
  expect_true(result$joint_evaluated)
  expect_true(result$joint_protection_enabled)
  expect_identical(result$status$joint,"evaluated")
  expect_identical(result$assurance$numerical_basis,"declared_finite_law")
  expect_false(result$assurance$numerical_guarantee)
  expect_false(result$assurance$intended_posterior_feasibility_certified)
  expect_false(result$receipts$candidate_family_membership_checked)
})

test_that("expected-only, disabled guards and analytic zero retain distinct states", {
  skip_if_not_installed("gmp")
  input <- md_test_input(); grades <- md_evaluation_grades(input)
  expected <- postrank_mdomain_evaluate(input,grades,mode="expected")
  expect_s3_class(expected$evaluation,"p2_expected_evaluation")
  expect_identical(expected$risk_exact,"1/2")
  expect_identical(expected$J,NA_real_)
  expect_identical(expected$J_exact,NA_character_)
  expect_identical(expected$joint_feasible,NA)
  expect_identical(expected$feasible_for_represented_measure,NA)
  expect_false(expected$joint_evaluated)
  expect_true(expected$joint_protection_enabled)
  expect_identical(expected$status$joint,"not_evaluated")
  expect_null(expected$event_table)
  decision <- postrank_mdomain_decision(t=NULL)
  skipped <- postrank_mdomain_evaluate(input,grades,decision,mode="expected")
  expect_identical(skipped$joint_feasible,NA)
  expect_false(skipped$joint_protection_enabled)
  disabled <- postrank_mdomain_evaluate(input,grades,decision)
  expect_identical(disabled$J_exact,"0")
  expect_true(disabled$joint_feasible)
  expect_true(disabled$feasible_for_represented_measure)
  expect_true(disabled$joint_evaluated)
  expect_false(disabled$joint_protection_enabled)
  expect_identical(disabled$status$joint,"disabled")
  expect_equal(nrow(disabled$event_table),0L)
  withheld <- grades*0
  analytic <- postrank_mdomain_evaluate(input,withheld)
  expect_identical(analytic$risk_exact,"1/10")
  expect_identical(analytic$J_exact,"0")
  expect_identical(analytic$status$joint,"analytic_zero")
  expect_true(analytic$joint_protection_enabled)
  expect_true(all(analytic$event_table$analytically_inactive))
  expect_identical(analytic$event_table$inactive_reason,rep("no_disclosure",2L))
  expect_true(all(is.na(analytic$domain_table$eFDP)))
  expect_identical(analytic$domain_table$eFDP_zero_exact,c("0","0"))
  upper <- postrank_mdomain_evaluate(input,grades,postrank_mdomain_decision(t="1"))
  expect_identical(upper$status$joint,"analytic_zero")
  expect_identical(upper$event_table$inactive_reason,rep("cutoff_exceeds_N",2L))
})

test_that("capability errors identify active requested domains and available information", {
  skip_if_not_installed("gmp")
  values <- md_test_array()
  separate <- postrank_mdomain_input(list(need=values[,,1L],cost=values[,,2L]),
    targets=md_test_targets(),provenance=md_test_provenance(),
    representation="exact_finite_law",masses=list(need=rep("1/4",4L),cost=rep("1/4",4L)))
  grades <- md_evaluation_grades(separate)
  error <- tryCatch(postrank_mdomain_evaluate(separate,grades),error=identity)
  expect_s3_class(error,"postrank_mdomain_error")
  expect_identical(error$code,"mdomain_capability")
  expect_identical(error$field,"capabilities")
  expect_identical(error$requested,list(mode="joint",domains=c("need","cost")))
  expect_identical(error$available,separate$capabilities)
  one <- postrank_mdomain_evaluate(separate,grades,
    postrank_mdomain_decision(t=c(need="0",cost="1")))
  expect_identical(one$J_exact,"3/4")
  expect_identical(one$evaluation$receipts$active_domains,"need")
  zero <- postrank_mdomain_evaluate(separate,grades*0)
  expect_identical(zero$J_exact,"0")
  summary_input <- postrank_mdomain_input(md_test_summary_spec())
  expect_error(postrank_mdomain_evaluate(summary_input,grades),class="postrank_mdomain_error")
  summary_expected <- postrank_mdomain_evaluate(summary_input,grades,mode="expected")
  expect_null(summary_expected$risk_exact)
  expect_identical(summary_expected$status$arithmetic,"contains_approximate_expectations")
  expect_identical(summary_expected$assurance$numerical_basis,"supplied_pair_probability_summary")
  expect_identical(postrank_mdomain_evaluate(summary_input,grades*0)$J_exact,"0")
})

test_that("empirical zero events remain empirical and trace retention changes no values", {
  skip_if_not_installed("gmp")
  values <- md_test_array()
  # All supplied states support the report, but this is still an iid assertion.
  for (s in seq_len(dim(values)[1L])) {
    values[s,,1L] <- c(3,2,1); values[s,,2L] <- c(1,2,3)
  }
  provenance <- md_test_provenance()
  provenance$sampling_assumptions <- list(iid=TRUE)
  input <- postrank_mdomain_input(values,targets=md_test_targets(),
    provenance=provenance,representation="iid_equal_weight_draws")
  grades <- md_evaluation_grades(input)
  full <- postrank_mdomain_evaluate(input,grades)
  thin <- postrank_mdomain_evaluate(input,grades,keep_traces=FALSE)
  expect_identical(full$J_exact,"0")
  expect_identical(full$status$joint,"evaluated")
  expect_false(any(full$event_table$analytically_inactive))
  expect_match(full$event_table$arithmetic[1L],"exact_empirical")
  expect_identical(full$assurance$numerical_basis,"supplied_empirical_measure")
  expect_false(full$assurance$intended_posterior_feasibility_certified)
  expect_identical(thin$risk_exact,full$risk_exact)
  expect_identical(thin$J_exact,full$J_exact)
  expect_identical(thin$event_table,full$event_table)
  expect_null(thin$evaluation$traces)
  expect_null(thin$evaluation$expected$traces)
  expect_identical(postrank_mdomain_grades(thin),thin$grades)
})

test_that("grade extraction rejects stale results and absent fitted cards", {
  skip_if_not_installed("gmp")
  result <- postrank_mdomain_evaluate(md_test_input(),md_evaluation_grades(md_test_input()))
  for (field in c("grades","action","evaluation","risk","decision","status")) {
    stale <- result
    if (field == "grades") stale$grades[1L,1L] <- 2L
    if (field == "action") stale$action$N[1L] <- 0L
    if (field == "evaluation") stale$evaluation$action$G[1L,1L] <- 2L
    if (field == "risk") stale$risk <- 0
    if (field == "decision") stale$decision$alpha_exact <- gmp::as.bigq(1)
    if (field == "status") stale$status$joint <- "disabled"
    error <- tryCatch(postrank_mdomain_grades(stale),error=identity)
    expect_s3_class(error,"postrank_mdomain_error")
    expect_identical(error$code,"mdomain_result_mutated",info=field)
  }
  stale <- result; stale$input$payloads[[1L]]$values[1L] <- 100
  expect_error(postrank_mdomain_grades(stale),"validated input has changed")
  fit <- structure(list(input=result$input,evaluation=result,grades=result$grades),
    class="postrank_mdomain_fit")
  expect_error(postrank_mdomain_grades(fit),"search record has changed")
  fit$grades[1L,1L] <- 2L
  expect_error(postrank_mdomain_grades(fit),"search record has changed")
  empty <- structure(list(evaluation=NULL),class="postrank_mdomain_fit")
  expect_error(postrank_mdomain_grades(empty),"no validated report card")
  expect_error(postrank_mdomain_grades(result$grades),"validated multidomain report card")
})

test_that("input is revalidated before parsing modes and mutable decision recipes", {
  skip_if_not_installed("gmp")
  input <- md_test_input(); grades <- md_evaluation_grades(input)
  input$n <- 2L
  error <- tryCatch(postrank_mdomain_evaluate(input,grades,mode="invalid"),error=identity)
  expect_identical(error$code,"mdomain_input_mutated")
  expect_identical(error$field,"input")
  input <- md_test_input()
  error <- tryCatch(postrank_mdomain_evaluate(input,grades,mode="invalid"),error=identity)
  expect_identical(error$code,"mdomain_evaluation_invalid")
  expect_identical(error$field,"mode")
  for (bad in list(NULL,NA,1,c(TRUE,FALSE)))
    expect_error(postrank_mdomain_evaluate(input,grades,keep_traces=bad),
      "keep_traces",class="postrank_mdomain_error")
  decision <- postrank_mdomain_decision(); decision$t <- "2"
  expect_error(postrank_mdomain_evaluate(input,grades,decision),class="postrank_mdomain_error")
})

test_that("summaries return inspectable state and print methods use stored results", {
  skip_if_not_installed("gmp")
  input <- md_test_input(); decision <- postrank_mdomain_decision()
  result <- postrank_mdomain_evaluate(input,md_evaluation_grades(input),decision)
  si <- summary(input); sd <- summary(decision); se <- summary(result)
  expect_s3_class(si,"summary.postrank_mdomain_input")
  expect_identical(si$capabilities,input$capabilities)
  expect_identical(si$payload_table$states,4L)
  expect_identical(si$domain_ids,c("need","cost"))
  expect_s3_class(sd,"summary.postrank_mdomain_decision")
  expect_identical(sd$parameters$exact_value[sd$parameters$parameter=="alpha"],"1/20")
  expect_identical(sd$receipts$defaults$t,"0")
  expect_s3_class(se,"summary.postrank_mdomain_evaluation")
  expect_identical(se$domain_table,result$domain_table)
  expect_identical(se$scope_table,result$scope_table)
  expect_identical(se$event_table,result$event_table)
  expect_identical(se$status,result$status)
  expect_identical(se$assurance,result$assurance)
  # Deliberately strip the computational records: display still needs no solver,
  # posterior reevaluation, validation or optional rational-arithmetic package.
  display <- result; display$evaluation <- NULL; display$input$payloads <- NULL
  expect_output(print(display),"Risk: 1/2; joint probability: 3/4")
  expect_output(print(display),"Intended posterior feasibility certificate: none")
  expect_output(print(input),"Proper law: producer declaration")
  expect_output(print(si),"Numerical guarantee: none")
  expect_output(print(decision),"exact rational policy fields")
  expect_output(print(sd),"unbound recipe")
  expect_output(print(se),"declared_finite_law")
})
