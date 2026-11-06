md_assess_grades <- function(input) matrix(c(1,2,3,3,2,1), 3L,
  dimnames=list(input$unit_ids, input$domain_ids))

test_that("finite assessment preserves exact supplied-law values and certificate scope", {
  skip_if_not_installed("gmp")
  input <- md_test_input(); grades <- md_assess_grades(input)
  decision <- postrank_mdomain_decision(q="0", alpha="3/4")
  design <- list(role="complete_declared_law")
  result <- postrank_mdomain_assess(input, grades, decision, method="exact", design=design)
  expect_s3_class(result, "postrank_mdomain_assessment")
  expect_s3_class(result$evaluation, "postrank_mdomain_evaluation")
  expect_s3_class(result$native, "p2_joint_evaluation")
  expect_identical(result$native, result$evaluation$evaluation)
  expect_identical(result$input, input)
  expect_identical(result$status, "evaluated_declared_finite_law")
  expect_identical(result$risk_exact, "1/2")
  expect_identical(result$J_exact, "3/4")
  expect_identical(result$spec_hashes, result$evaluation$receipts$validation_spec_hashes)
  expect_identical(result$design, design)
  expect_true(result$joint_certificate)
  expect_false(result$evaluation$mean_feasible)
  expect_false(result$evaluation$feasible_for_represented_measure)
  expect_identical(result$certificate_scope, "specified declared-finite-law joint event only")
  expect_false(result$assurance$assumptions_verified)
  expect_false(result$assurance$numerical_guarantee)
  expect_false(result$assurance$intended_posterior_feasibility_certified)
  expect_true(result$assurance$no_mean_or_optimality_or_model_certificate)
  failed <- postrank_mdomain_assess(input, grades, method="exact")
  expect_false(failed$joint_certificate)
  expect_identical(failed$certificate_scope, "none")
  disabled <- postrank_mdomain_assess(input, grades,
    postrank_mdomain_decision(t=NULL), method="exact")
  expect_false(disabled$joint_certificate)
  expect_identical(disabled$certificate_scope, "none")
})

test_that("finite route reports actual floating arithmetic without upgrading assurance", {
  skip_if_not_installed("gmp")
  input <- postrank_mdomain_input(md_test_array(), targets=md_test_targets(),
    provenance=md_test_provenance(), representation="exact_finite_law",
    masses=list(encoding="float64", values=rep(.25, 4L)))
  result <- postrank_mdomain_assess(input, md_assess_grades(input), method="exact")
  expect_null(result$risk_exact)
  expect_null(result$J_exact)
  expect_equal(result$risk, .5, tolerance=0)
  expect_equal(result$J, .75, tolerance=0)
  expect_identical(result$evaluation$status$arithmetic, "contains_approximate_expectations")
  expect_identical(result$assurance$numerical_basis, "declared_finite_law")
  expect_false(result$assurance$numerical_guarantee)
})

test_that("verified stored reports preserve exact bound recipes on actual supplied states", {
  skip_if_not_installed("gmp")
  input <- md_test_input(); grades <- md_assess_grades(input)
  scope <- matrix(c(0,1,0,1,0,0,0,0,0), 3L,
    dimnames=list(input$unit_ids,input$unit_ids))
  decision <- postrank_mdomain_decision(weights=c(need="0",cost="1"),
    tau=c(need="1/5",cost="1/3"), scope=list(first_pair=scope),
    expected=data.frame(domain_id="cost",scope_id="first_pair",q="1/2"),
    joint=data.frame(domain_id=c("need","cost"),scope_id="first_pair",t=c("0","1/3")),
    alpha="7/8")
  card <- postrank_mdomain_evaluate(input, grades, decision, mode="expected")
  values <- md_test_array()[4:1, , , drop=FALSE]
  dimnames(values)[[1L]] <- paste0("actual-", 1:4)
  actual <- postrank_mdomain_input(values, targets=md_test_targets(),
    provenance=md_test_provenance(), representation="exact_finite_law",
    masses=c("1/10","2/10","3/10","4/10"))
  result <- postrank_mdomain_assess(actual, card, method="exact")
  direct <- postrank_mdomain_evaluate(actual, grades, decision)
  expect_identical(result$evaluation$input, actual)
  expect_identical(result$risk_exact, direct$risk_exact)
  expect_identical(result$J_exact, direct$J_exact)
  expect_identical(result$spec_hashes, card$receipts$validation_spec_hashes)
  expect_identical(result$evaluation$decision$weights_exact, card$decision$weights_exact)
  expect_identical(result$evaluation$decision$tau_exact, card$decision$tau_exact)
  expect_identical(result$evaluation$decision$joint_t_exact, card$decision$joint_t_exact)
  expect_true(result$receipts$frozen_contract_matched)
  expect_true(result$receipts$frozen_card_supplied)
  expect_identical(postrank_mdomain_assess(actual, card, decision, method="exact")$J_exact,
    result$J_exact)
  changed <- postrank_mdomain_decision(alpha="1")
  error <- tryCatch(postrank_mdomain_assess(actual, card, changed, method="exact"), error=identity)
  expect_s3_class(error, "postrank_mdomain_error")
  expect_identical(error$code, "mdomain_frozen_event_mismatch")
  expect_identical(error$field, "grades")
})

test_that("stored-card identity, target-law and mutation mismatches refuse assessment", {
  skip_if_not_installed("gmp")
  input <- md_test_input(); grades <- md_assess_grades(input)
  card <- postrank_mdomain_evaluate(input, grades)
  targets <- md_test_targets(); targets$need$definition <- "A changed target definition"
  changed <- postrank_mdomain_input(md_test_array(), targets=targets,
    provenance=md_test_provenance(), representation="exact_finite_law", masses=rep("1/4",4L))
  error <- tryCatch(postrank_mdomain_assess(changed, card, method="exact"), error=identity)
  expect_identical(error$code, "mdomain_frozen_event_mismatch")
  provenance <- md_test_provenance(); provenance$law_id <- "different-declared-law"
  changed <- postrank_mdomain_input(md_test_array(), targets=md_test_targets(),
    provenance=provenance, representation="exact_finite_law", masses=rep("1/4",4L))
  expect_error(postrank_mdomain_assess(changed, card, method="exact"), "target law",
    class="postrank_mdomain_error")
  values <- md_test_array()[, c(2,1,3), , drop=FALSE]
  targets <- md_test_targets()
  for (d in names(targets)) targets[[d]]$equality_classes <-
    targets[[d]]$equality_classes[dimnames(values)[[2L]]]
  reordered <- postrank_mdomain_input(values, targets=targets,
    provenance=md_test_provenance(), representation="exact_finite_law", masses=rep("1/4",4L))
  error <- tryCatch(postrank_mdomain_assess(reordered, card, method="exact"), error=identity)
  expect_identical(error$code, "mdomain_frozen_event_mismatch")
  expect_identical(error$field, "input")
  for (field in c("grades", "decision", "validation_spec_hashes", "risk")) {
    stale <- card
    if (field == "grades") stale$grades[1L,1L] <- 2L
    if (field == "decision") stale$decision$alpha_exact <- gmp::as.bigq(1)
    if (field == "validation_spec_hashes") stale$receipts$validation_spec_hashes$report <- "changed"
    if (field == "risk") stale$risk <- 0
    error <- tryCatch(postrank_mdomain_assess(input, stale, method="exact"), error=identity)
    expect_identical(error$code, "mdomain_result_mutated", info=field)
  }
})

test_that("successful fit is a fixed card and retains its selected decision", {
  skip_if_not_installed("gmp")
  input <- md_test_input()
  columns <- setNames(rep(list(list(forward=setNames(1:3,input$unit_ids))), input$D),
    input$domain_ids)
  family <- postrank_mdomain_family(input, columns=columns)
  fit <- postrank_mdomain_solve(input, family,
    postrank_mdomain_decision(tau="1/3", alpha="1"))
  result <- postrank_mdomain_assess(input, fit, method="exact")
  expect_identical(result$grades, fit$grades)
  expect_identical(result$spec_hashes, fit$evaluation$receipts$validation_spec_hashes)
  expect_identical(result$risk_exact, fit$evaluation$risk_exact)
  expect_identical(result$J_exact, fit$evaluation$J_exact)
  expect_true(result$receipts$frozen_contract_matched)
  stale <- fit; stale$selected_id <- "changed"
  expect_error(postrank_mdomain_assess(input, stale, method="exact"), "search record has changed")
  absent <- structure(list(evaluation=NULL), class="postrank_mdomain_fit")
  expect_error(postrank_mdomain_assess(input, absent, method="exact"), "no validated report card")
})

test_that("method, option and input errors are typed before native routing", {
  skip_if_not_installed("gmp")
  input <- md_test_input(); grades <- md_assess_grades(input)
  for (method in c("mcmc", "iid")) {
    error <- tryCatch(postrank_mdomain_assess(input, grades, method=method), error=identity)
    expect_s3_class(error, "postrank_mdomain_error")
    expect_identical(error$code, "mdomain_assessment_method")
    expect_identical(error$field, "method")
    expect_identical(error$available, input$representation)
  }
  summary_input <- postrank_mdomain_input(md_test_summary_spec())
  for (method in c("mcmc", "iid", "exact"))
    expect_error(postrank_mdomain_assess(summary_input, grades, method=method),
      "never relabeled", class="postrank_mdomain_error")
  for (dots in list(list(TRUE), list(keep_traces=TRUE, keep_traces=FALSE),
      list(batch_size=2L), list(max_S=2L), list(unsupported=1))) {
    error <- tryCatch(do.call(postrank_mdomain_assess,
      c(list(input=input, grades=grades, decision=NULL, method="exact",
        design=NULL, beta="1/20"), dots)), error=identity)
    expect_identical(error$code, "mdomain_assessment_invalid")
    expect_identical(error$field, "...")
  }
  for (bad in list(NULL, NA, 1, c(TRUE,FALSE)))
    expect_error(postrank_mdomain_assess(input, grades, method="exact", keep_traces=bad),
      "keep_traces", class="postrank_mdomain_error")
  error <- tryCatch(postrank_mdomain_assess(input, grades, method="invalid"), error=identity)
  expect_identical(error$code, "mdomain_assessment_invalid")
  expect_identical(error$field, "method")
  error <- tryCatch(postrank_mdomain_assess(input, grades, method="exact", design=TRUE), error=identity)
  expect_identical(error$code, "mdomain_assessment_design")
  input$n <- 2L
  error <- tryCatch(postrank_mdomain_assess(input, grades, method="invalid"), error=identity)
  expect_identical(error$code, "mdomain_input_mutated")
})

test_that("assessment display and summaries consume stored results only", {
  skip_if_not_installed("gmp")
  input <- md_test_input()
  result <- postrank_mdomain_assess(input, md_assess_grades(input), method="exact", keep_traces=FALSE)
  expect_null(result$evaluation$evaluation$traces)
  expect_null(result$native$traces)
  # These computational records can be removed without invoking a validator,
  # evaluator, native diagnostic or optional arithmetic dependency on display.
  display <- result
  display$input <- NULL
  display$evaluation$input <- NULL
  display$evaluation$evaluation <- NULL
  display$evaluation$action <- NULL
  expect_output(print.postrank_mdomain_assessment(display), "Risk: 1/2; joint probability: 3/4")
  expect_output(print.postrank_mdomain_assessment(display), "Joint certificate: none")
  summarized <- summary.postrank_mdomain_assessment(display)
  expect_s3_class(summarized, "summary.postrank_mdomain_assessment")
  expect_identical(summarized$native, result$native)
  expect_identical(summarized$design, result$design)
  expect_identical(summarized$assurance, result$assurance)
  expect_identical(summarized$evaluation$risk_exact, "1/2")
  expect_output(print.summary.postrank_mdomain_assessment(summarized), "evaluated_declared_finite_law")
})
