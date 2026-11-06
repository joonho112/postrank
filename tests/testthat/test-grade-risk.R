pr_reference_test_pw <- function(x) {
  d<-as_postrank_draws(x);mats<-.pr_draw_matrices(d);e<-.pr_empty_e(d$entity_ids,d$criterion_ids)
  for(k in seq_along(mats))e[,,k]<-.pr_pairwise_reference_one(mats[[k]])
  .pr_new_pairwise(d,e,vapply(mats,nrow,integer(1L)),"reference")
}
testthat::test_that("canonical grades preserve pair relations and all-tie means abstention",{
  p<-pr_reference_test_pw(pr_test_payload());ids<-p$entity_ids;w<-c(need1=.7,need2=.3)
  g<-stats::setNames(c(9,9,42),ids);z<-postrank_evaluate(g,p,w,.25)
  testthat::expect_identical(unname(z$grade),c(1L,1L,2L))
  testthat::expect_equal(z$N,2);testthat::expect_equal(z$disclosure_rate,2/3)
  a<-postrank_evaluate(stats::setNames(rep(8,3),ids),p,w,.25)
  testthat::expect_equal(a$N,0);testthat::expect_equal(a$G,1)
  testthat::expect_true(all(is.na(a$E_over_N)));testthat::expect_equal(unname(a$E),c(0,0));testthat::expect_equal(a$weighted_risk,.25)
  testthat::expect_error(canonical_postrank_grade(c(1,2,3),ids),class="postrank_input_error")
})
testthat::test_that("pairwise risk equals independent complete-state loss expectation",{
  x<-pr_test_payload(S=7L);p<-pr_reference_test_pw(x);g<-stats::setNames(c(1,3,2),x$entity_ids)
  w<-c(need2=.2,need1=.8);tau<-.17;loss<-numeric(7)
  for(s in 1:7){total<-0;for(i in 1:2)for(j in (i+1):3){
    if(g[i]==g[j])total<-total+tau else {
      ahead<-if(g[i]<g[j])i else j;behind<-if(ahead==i)j else i
      for(k in 1:2) total<-total+w[x$criterion_ids[k]]*as.integer(x$joint_draws$tensor$values[s,ahead,k]<=x$joint_draws$tensor$values[s,behind,k])
    }
  };loss[s]<-total/3}
  z<-postrank_evaluate(g,p,w,tau)
  testthat::expect_equal(z$weighted_risk,mean(loss),tolerance=1e-15)
  testthat::expect_equal(z$weighted_risk,tau+z$weighted_raw_objective/z$M,tolerance=1e-15)
  testthat::expect_equal(z$E_over_M,z$E/z$M);testthat::expect_equal(z$E_over_N,z$E/z$N)
  testthat::expect_error(postrank_evaluate(g,p,c(need1=1,need2=1),tau),"sum to one")
  testthat::expect_error(postrank_evaluate(g,p,c(need1=1,need2=0),0),"tau")
  testthat::expect_error(postrank_evaluate(g,p,c(need1=1,need2=-0.01),tau),"nonnegative")
})

testthat::test_that("unsupported complex loss settings fail with structured input errors",{
  p<-pr_reference_test_pw(pr_test_payload());g<-stats::setNames(c(1,2,3),p$entity_ids)
  testthat::expect_error(canonical_postrank_grade(g+1i,p$entity_ids),class="postrank_input_error")
  testthat::expect_error(postrank_evaluate(g,p,c(need1=.5+1i,need2=.5),.25),class="postrank_input_error")
  testthat::expect_error(postrank_evaluate(g,p,c(need1=.5,need2=.5),.25+1i),class="postrank_input_error")
})
