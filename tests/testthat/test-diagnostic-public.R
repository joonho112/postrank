# Explicit mock incumbent to test diagnostics/reporting without invoking solvers.
pr_diag_mock_fit <- function(d) {
  p<-postrank_problem(postrank_pairwise(d),stats::setNames(rep(1/length(d$criterion_ids),length(d$criterion_ids)),d$criterion_ids),.25,length(d$entity_ids))
  x<-numeric(length(p$model$objective));x[p$index$labels]<-1
  raw<-list(primal=x,raw_status="OPTIMAL",raw_message="mock",status_normalized="optimal",termination_reason="optimal",
    has_incumbent=TRUE,raw_objective=0,raw_lower_bound=0,relative_gap=0,runtime=0,backend=list(name="mock",options=list()),raw=list(),warnings=character())
  .pr_normalize_solver_result(p,raw,.pr_control())
}
testthat::test_that("public diagnostics binds source, settings, grade and descriptive selection",{
  d<-as_postrank_draws(pr_test_payload());f<-pr_diag_mock_fit(d)
  z<-postrank_diagnose(d,fit=f,pairs=data.frame(entity_i="001",entity_j="002",criterion_id="need1"))
  testthat::expect_s3_class(z,"postrank_diagnostics")
  testthat::expect_identical(postrank_diagnose(d,fit=f,settings=f$settings)$settings,f$settings)
  testthat::expect_true(z$post_selection_descriptive)
  testthat::expect_true(z$total_loss$available)
  testthat::expect_equal(z$summaries$weighted_total_loss$mean,.25)
  testthat::expect_false(z$finite_sample_certificate)
  testthat::expect_null(z$stability)
  testthat::expect_length(z$traces$pair_1$values,4)
  testthat::expect_error(postrank_diagnose(d,fit=f,grade=stats::setNames(c(1,2,2),d$entity_ids)),"disagrees")
  altered<-pr_test_payload();altered$context$data_version<-"different"
  testthat::expect_error(postrank_diagnose(altered,fit=f),"different input")
  testthat::expect_error(postrank_diagnose(d,grade=f$grade),"explicit weights")
  testthat::expect_error(postrank_diagnose(d,fit=f,settings=list(weights=c(need1=.6,need2=.4),tau=.25,G_max=3)),"disagree")
})
testthat::test_that("criterionwise diagnostics exposes missing total covariance and finite law has no MC approximation",{
  d<-as_postrank_draws(pr_test_criterionwise());g<-stats::setNames(c(1,2,2),d$entity_ids)
  z<-postrank_diagnose(d,grade=g,settings=list(weights=c(need1=.5,need2=.5),tau=.25))
  testthat::expect_false(z$total_loss$available)
  testthat::expect_match(z$total_loss$unavailable_reason,"no_joint_MC_covariance")
  testthat::expect_null(z$traces$weighted_total_loss)
  testthat::expect_equal(c(z$summaries$criterion_error_1$S,z$summaries$criterion_error_2$S),c(4,5))
  e<-as_postrank_draws(pr_test_exact());a<-postrank_diagnose(e,grade=g,settings=list(weights=c(need1=.5,need2=.5),tau=.25))
  testthat::expect_false(a$summaries$weighted_total_loss$diagnostics$mcse_mean$available)
  testthat::expect_identical(a$summaries$weighted_total_loss$regime,"exact_law")
})
testthat::test_that("offline HTML preserves NA, abstention, provenance and refuses overwrite",{
  d<-as_postrank_draws(pr_test_payload());f<-pr_diag_mock_fit(d);z<-postrank_diagnose(d,fit=f)
  file<-tempfile(fileext=".html");on.exit(unlink(file),add=TRUE)
  r<-postrank_report(f,z,file)
  testthat::expect_true(file.exists(r$output_file))
  html<-paste(readLines(file,warn=FALSE),collapse="\n")
  # 0.9.0 D-7 migrations: inherited Korean HTML assertions -> English semantic replacements.
  testthat::expect_match(html,"All comparisons withheld",fixed=TRUE)
  testthat::expect_match(html,"E/N is NA",fixed=TRUE)
  testthat::expect_match(html,"post-selection",fixed=TRUE)
  testthat::expect_match(html,f$input_identity,fixed=TRUE)
  testthat::expect_match(html,"viewport",fixed=TRUE)
  testthat::expect_error(postrank_report(f,z,file),"already exists")
  changed<-z;changed$posterior_profiles$mean[1]<-999
  testthat::expect_error(postrank_report(f,changed),"changed after")
})
